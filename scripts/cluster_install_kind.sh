#!/bin/bash
# Install and configure kind cluster
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"
load_env

export KUBECONFIG="${PROJECT_DIR}/.kube/config"
mkdir -p "${PROJECT_DIR}/.kube"

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

install_kind() {
    log "Checking if kind cluster '${CLUSTER_NAME}' exists"
    if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
        log "kind cluster '${CLUSTER_NAME}' already exists"
    else
        log "Creating kind cluster '${CLUSTER_NAME}'"
        kind create cluster --name "${CLUSTER_NAME}" --config "${PROJECT_DIR}/kind-config.yaml"
    fi

    log "Exporting kubeconfig to ${KUBECONFIG}"
    kind get kubeconfig --name "${CLUSTER_NAME}" > "${KUBECONFIG}"
}

wait_for_kind() {
    log "Waiting for Kubernetes API"
    until kubectl version --request-timeout=5s >/dev/null 2>&1; do
        sleep 2
        printf "."
    done
    echo

    log "Waiting for node condition Ready timeout 2 minutes"
    kubectl wait node --all --for=condition=Ready --timeout=120s

    log "Waiting for CoreDNS"
    wait_or_debug kube-system deploy/coredns 120s
}

# Check tools
need docker
need kubectl
need kind

install_kind
wait_for_kind

log "✅ kind cluster ready"
