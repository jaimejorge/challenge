#!/bin/bash

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:=dev01}"
NS="argocd"
RELEASE="argocd"
CHART="argo/argo-cd"
CHART_VERSION="9.4.2"

VALUES_FILE="./argocd_values.yaml"

# Overrides
DOMAIN="${ARGO_DOMAIN:-argocd.localtest.me}"
REPO_URL="${BOOTSTRAP_REPO_URL:-https://github.com/jaimejorge/challenge.git}"
REVISION="${BOOTSTRAP_TARGET_REVISION:-main}"
PATH_IN_REPO="${BOOTSTRAP_PATH:-apps/bootstrap}"
DEST_NS="${BOOTSTRAP_DEST_NAMESPACE:-default}"

log() {
	echo "[$(date +'%H:%M:%S')] $*"
}

need() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Missing dependency: $1" >&2
		echo "Docker  https://docs.docker.com/engine/install/"
		echo "kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
		exit 1
	fi
}

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
  -p "443:443@loadbalancer"
	fi
	log "insert "${CLUSTER_NAME}" to  ~/.kube/config"
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

	local NS="argocd"
	local RELEASE="argocd"
	local HOST="${ARGO_HOST:-argocd.localtest.me}"
	local CHART_VERSION="${ARGO_CHART_VERSION:-9.4.2}" #  9.4.2 (13 Feb, 2026)

	log "Adding argo repo to helm and updating.."
	helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
	helm repo update >/dev/null

	kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

	log "Installing Argo CD at http://${HOST}"

	helm upgrade --install "${RELEASE}" argo/argo-cd \
		-n "${NS}" \
		--version "${CHART_VERSION}" \
		--set configs.params."server\.insecure"=true \
		--set server.service.type=ClusterIP \
		--set server.ingress.enabled=true \
		--set server.ingress.ingressClassName=traefik \
		--set server.ingress.annotations."traefik\.ingress\.kubernetes\.io/router\.entrypoints"=web \
		--set server.ingress.hosts[0]="${HOST}" \
		--set global.domain="${HOST}" \
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
    repoURL: ${REPO_URL}
    targetRevision: ${REVISION}
    path: ${PATH_IN_REPO}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${DEST_NS}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
}

print_argocd_access() {
  local NS="argocd"
  local HOST="${ARGO_HOST:-argocd.localtest.me}"

  log "Waiting for Argo CD server to be ready"
  kubectl -n "${NS}" rollout status deploy/argocd-server --timeout=300s

  echo
  echo "=============================================="
  echo "✅ Argo CD installed successfully"
  echo
  echo "🌐 URL:"
  echo "  http://${HOST}"
  echo
  echo "👤 User:"
  echo "  admin"
  echo
  echo "🔑 Password:"
  if kubectl -n "${NS}" get secret argocd-initial-admin-secret >/dev/null 2>&1; then
    kubectl -n "${NS}" get secret argocd-initial-admin-secret \
      -o jsonpath='{.data.password}' | base64 --decode
    echo
  else
    echo "  (admin password was overridden or admin disabled)"
  fi
  echo "=============================================="
}



# Check tools:
need docker
need kubectl

install_k3d
wait_for_k3d
install_argocd
print_argocd_access
