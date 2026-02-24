#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"
load_env

log "Deleting kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME" 

log "Removing kubeconfig..."
rm -rf "${PROJECT_DIR}/.kube"

log "Cleanup complete"
