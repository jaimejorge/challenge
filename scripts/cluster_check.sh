#!/bin/bash
# Check cluster status and diagnose issues
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"
load_env

export KUBECONFIG="${PROJECT_DIR}/.kube/config"

log "Checking cluster status..."

# Check kind cluster
if ! kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
    log "❌ Kind cluster '${CLUSTER_NAME}' not found"
    exit 1
fi
log "Kind cluster '${CLUSTER_NAME}' exists"

# Check nodes
log "Nodes:"
kubectl get nodes


log "ArgoCD Applications:"
kubectl get apps -A -o wide

# Check for issues
echo ""
UNKNOWN_APPS=$(kubectl get apps -A -o jsonpath='{range .items[?(@.status.sync.status=="Unknown")]}{.metadata.name}{" "}{end}' 2>/dev/null || true)
DEGRADED_APPS=$(kubectl get apps -A -o jsonpath='{range .items[?(@.status.health.status=="Degraded")]}{.metadata.name}{" "}{end}' 2>/dev/null || true)
PROGRESSING_APPS=$(kubectl get apps -A -o jsonpath='{range .items[?(@.status.health.status=="Progressing")]}{.metadata.name}{" "}{end}' 2>/dev/null || true)

if [[ -n "${UNKNOWN_APPS}" ]]; then
    log "   Apps with Unknown sync status: ${UNKNOWN_APPS}"
    log "   Check: kubectl describe application <app-name> -n argocd | grep -A 10 Conditions"
    log "   Repo-server logs: kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server --tail=20"
fi

if [[ -n "${DEGRADED_APPS}" ]]; then
    log "❌ Apps with Degraded health: ${DEGRADED_APPS}"
    log "   Check: kubectl describe application <app-name> -n argocd"
fi

if [[ -n "${PROGRESSING_APPS}" ]]; then
    log "⏳ Apps still progressing: ${PROGRESSING_APPS}"
fi

if [[ -z "${UNKNOWN_APPS}" && -z "${DEGRADED_APPS}" && -z "${PROGRESSING_APPS}" ]]; then
    log " All apps synced and healthy"
fi

# Show pods with issues
log "Pods not Running:"
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null || echo "  (none)"

log "Check complete. For credentials run: make argocd-info / make grafana-info / make postgresql-info"