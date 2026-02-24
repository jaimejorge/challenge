#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"
load_env


wait_for_apps() {
    local APPS=("bootstrap" "ingress-nginx" "http-https-echo" "cloudnative-pg-operator" "postgresql-cluster" "v-metrics")


    log "Waiting for ArgoCD apps to sync (timeout: ${ARGOCD_SYNC_TIMEOUT})..."

    log "Waiting for bootstrap Application..."
    until kubectl get application bootstrap -n argocd >/dev/null 2>&1; do
        sleep 5
        printf "."
    done
    echo

    for app in "${APPS[@]}"; do
        if ! kubectl get application "${app}" -n argocd >/dev/null 2>&1; then
            log "${app} not found, skipping..."
            continue
        fi

        log "Waiting for ${app} to sync..."
        kubectl wait application "${app}" -n argocd \
            --for=jsonpath='{.status.sync.status}'=Synced \
            --timeout="${ARGOCD_SYNC_TIMEOUT}" 2>/dev/null && log "${app} synced" || log "${app} sync timeout"

        log "Waiting for ${app} to be healthy..."
        kubectl wait application "${app}" -n argocd \
            --for=jsonpath='{.status.health.status}'=Healthy \
            --timeout="${ARGOCD_SYNC_TIMEOUT}" 2>/dev/null && log "${app} healthy" || log "${app} health timeout"
    done
}

wait_for_apps

log "All apps ready"
