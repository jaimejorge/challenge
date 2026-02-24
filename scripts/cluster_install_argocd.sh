#!/bin/bash
# Install ArgoCD and bootstrap application
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"
load_env

export KUBECONFIG="${PROJECT_DIR}/.kube/config"

install_argocd() {
    log "Adding argo repo to helm and updating.."
    helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
    helm repo update >/dev/null

    kubectl get ns "${ARGOCD_NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${ARGOCD_NAMESPACE}"

    log "Installing Argo CD at http://${ARGOCD_DOMAIN}"

    helm upgrade --install "${ARGOCD_RELEASE}" argo/argo-cd \
        -n "${ARGOCD_NAMESPACE}" \
        --version "${ARGOCD_CHART_VERSION}" \
        --set configs.params."server\.insecure"=true \
        --set server.service.type=ClusterIP \
        --set server.ingress.enabled=true \
        --set server.ingress.ingressClassName=nginx \
        --set server.ingress.hosts[0]="${ARGOCD_DOMAIN}" \
        --set global.domain="${ARGOCD_DOMAIN}" \
        --set controller.metrics.enabled=true \
        --set controller.metrics.service.enabled=true \
        --set server.metrics.enabled=true \
        --set server.metrics.service.enabled=true \
        --set repoServer.metrics.enabled=true \
        --set repoServer.metrics.service.enabled=true \
        --wait --timeout 10m

    log "Creating bootstrap Application (Helm chart)..."
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
    helm:
      releaseName: bootstrap
      valuesObject:
        git:
          repoURL: ${BOOTSTRAP_REPO_URL}
          branch: ${BOOTSTRAP_TARGET_REVISION}
        domain: ${TLS_DOMAIN}
        ingressClassName: ${INGRESS_CLASS:-nginx}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
}


"${SCRIPT_DIR}/cluster_setup_tls.sh"
install_argocd

log "ArgoCD installed"
