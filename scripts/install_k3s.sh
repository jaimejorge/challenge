#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"
load_env



# Install K3d last version
install_k3d() {
	log "Install k3d (if missing)"
	if ! command -v k3d >/dev/null 2>&1; then
		curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
	fi

	log "Checking if k3d cluster '${CLUSTER_NAME}' exists"
	if k3d cluster list | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
		log "k3d cluster '${CLUSTER_NAME}' already exists"
	else
		log "Creating k3d cluster '${CLUSTER_NAME}'"
		
		k3d cluster create "${CLUSTER_NAME}" \
  --servers 1 --agents 0 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer" \
  -p "30432:30432@server:0"  # PostgreSQL NodePort
	fi
	log "insert ${CLUSTER_NAME} to  ~/.kube/config"
	k3d kubeconfig merge "${CLUSTER_NAME}" --output ~/.kube/config --kubeconfig-switch-context
}

wait_for_k3d() {
	log "Waiting for Kubernetes API"
	sleep 30
	until kubectl version --request-timeout=5s >/dev/null 2>&1; do
		sleep 2
		printf "."
	done

	log "Waiting for node condition Ready timeout 2 minutes"
	kubectl wait node --all --for=condition=Ready --timeout=120s

	log "Waiting for CoreDNS"
	wait_or_debug kube-system deploy/coredns 120s

	log "Waiting for Traefik"
	wait_or_debug kube-system deploy/traefik 120s

	log "Waiting for Metrics Server"
	wait_or_debug kube-system deploy/metrics-server 120s
}

wait_or_debug() {
	local NAMESPACE="$1"
	local RESOURCE="$2"
	local TIMEOUT="${3:-120s}"

	if ! kubectl wait -n "${NAMESPACE}" "${RESOURCE}" \
		--for=condition=Available \
		--timeout="${TIMEOUT}"; then

		echo
		echo "❌ ERROR: ${RESOURCE} in namespace ${NAMESPACE} did not become Available"
		echo "----------------------------------------"
		echo "📦 Pods:"
		kubectl get pods -n "${NAMESPACE}" -o wide || true

		echo
		echo "📣 Events (last 20):"
		kubectl get events -n "${NAMESPACE}" --sort-by=.lastTimestamp | tail -n 20 || true

		echo
		echo "🔎 Describe:"
		kubectl describe "${RESOURCE}" -n "${NAMESPACE}" || true

		exit 1
	fi
}

install_argocd() {
	# Helm chart documentation https://artifacthub.io/packages/helm/argo/argo-cd
	# Helm cannot upgrade custom resource definitions in the <chart>/crds folder.
	# Starting with 5.2.0, the CRDs have been moved to <chart>/templates to address this design decision.

	local NS="${ARGOCD_NAMESPACE:-argocd}"
	local RELEASE="${ARGOCD_RELEASE:-argocd}"
	local CHART_VERSION="${ARGOCD_CHART_VERSION:-9.4.3}"
	local DOMAIN="${ARGOCD_DOMAIN:-argocd.localtest.me}"

	log "Adding argo repo to helm and updating.."
	helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
	helm repo update >/dev/null

	kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

	log "Installing Argo CD at http://${DOMAIN}"

	helm upgrade --install "${RELEASE}" argo/argo-cd \
		-n "${NS}" \
		--version "${CHART_VERSION}" \
		--set configs.params."server\.insecure"=true \
		--set server.service.type=ClusterIP \
		--set server.ingress.enabled=true \
		--set server.ingress.ingressClassName=traefik \
		--set server.ingress.annotations."traefik\.ingress\.kubernetes\.io/router\.entrypoints"=web \
		--set server.ingress.hosts[0]="${DOMAIN}" \
		--set global.domain="${DOMAIN}" \
		--set controller.metrics.enabled=true \
		--set controller.metrics.service.enabled=true \
		--set server.metrics.enabled=true \
		--set server.metrics.service.enabled=true \
		--set repoServer.metrics.enabled=true \
		--set repoServer.metrics.service.enabled=true \
		--wait --timeout 10m

	log "Creating bootstrap Application..."
	kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bootstrap
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${BOOTSTRAP_REPO_URL}
    targetRevision: ${BOOTSTRAP_TARGET_REVISION}
    path: ${BOOTSTRAP_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${BOOTSTRAP_DEST_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
}

setup_tls() {
    local CERTS_DIR="${SCRIPT_DIR}/../certs"
    local DOMAIN="${TLS_DOMAIN:-localtest.me}"
    local SECRET_NAME="${TLS_SECRET_NAME:-localtest-tls}"

    log "Setting up TLS certificates..."

    # Check mkcert
    if ! command -v mkcert >/dev/null 2>&1; then
        log "Installing mkcert..."
        brew install mkcert
    fi

    # Install local CA if needed
    mkcert -install 2>/dev/null || true

    # Generate certs if not exist
    mkdir -p "${CERTS_DIR}"
    
    # Find existing cert files (mkcert adds +N suffix for multiple SANs)
    local CERT_FILE
    local KEY_FILE
    CERT_FILE=$(find "${CERTS_DIR}" -name "_wildcard.${DOMAIN}*.pem" ! -name "*-key.pem" 2>/dev/null | head -1)
    KEY_FILE=$(find "${CERTS_DIR}" -name "_wildcard.${DOMAIN}*-key.pem" 2>/dev/null | head -1)

    if [[ -z "${CERT_FILE}" ]] || [[ -z "${KEY_FILE}" ]]; then
        log "Generating wildcard certificate for *.${DOMAIN}..."
        cd "${CERTS_DIR}"
        mkcert "*.${DOMAIN}" "${DOMAIN}" localhost 127.0.0.1
        cd - >/dev/null
        
        # Re-find the generated files
        CERT_FILE=$(find "${CERTS_DIR}" -name "_wildcard.${DOMAIN}*.pem" ! -name "*-key.pem" | head -1)
        KEY_FILE=$(find "${CERTS_DIR}" -name "_wildcard.${DOMAIN}*-key.pem" | head -1)
    else
        log "Certificates already exist in ${CERTS_DIR}"
    fi

    log "Using cert: ${CERT_FILE}"
    log "Using key: ${KEY_FILE}"

    # Create K8s secret in multiple namespaces
    for ns in default argocd monitoring; do
        kubectl get ns "${ns}" >/dev/null 2>&1 || kubectl create ns "${ns}"
        kubectl create secret tls "${SECRET_NAME}" \
            --cert="${CERT_FILE}" \
            --key="${KEY_FILE}" \
            --namespace="${ns}" \
            --dry-run=client -o yaml | kubectl apply -f -
    done

    log "TLS secret '${SECRET_NAME}' created in namespaces: default, argocd, monitoring"
}

wait_for_apps() {
    local APPS=("bootstrap" "http-https-echo" "cnpg-operator" "postgresql-cluster" "v-metrics")
    local TIMEOUT="${ARGOCD_SYNC_TIMEOUT:-300s}"

    log "Waiting for ArgoCD apps to sync (timeout: ${TIMEOUT})..."

    # Wait for bootstrap app first
    log "Waiting for bootstrap Application to be created..."
    until kubectl get application bootstrap -n argocd >/dev/null 2>&1; do
        sleep 5
        printf "."
    done
    echo

    for app in "${APPS[@]}"; do
        if ! kubectl get application "${app}" -n argocd >/dev/null 2>&1; then
            log "⏳ ${app} not found yet, skipping..."
            continue
        fi

        log "Waiting for ${app} to sync..."
        if kubectl wait application "${app}" -n argocd \
            --for=jsonpath='{.status.sync.status}'=Synced \
            --timeout="${TIMEOUT}" 2>/dev/null; then
            log "✅ ${app} synced"
        else
            log "⚠️  ${app} sync timeout"
        fi

        log "Waiting for ${app} to be healthy..."
        if kubectl wait application "${app}" -n argocd \
            --for=jsonpath='{.status.health.status}'=Healthy \
            --timeout="${TIMEOUT}" 2>/dev/null; then
            log "✅ ${app} healthy"
        else
            log "⚠️  ${app} health timeout"
        fi
    done

    log "All apps processed"
}


# Check tools:
need docker
need kubectl
need helm

install_k3d
wait_for_k3d
setup_tls
install_argocd
wait_for_apps

# Show access info
"${SCRIPT_DIR}/argocd_info.sh"
"${SCRIPT_DIR}/grafana_info.sh" || true  # May not be deployed yet
