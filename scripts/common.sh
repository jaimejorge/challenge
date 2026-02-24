#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

load_env() {
	# Load default .env
	if [[ -f "${PROJECT_DIR}/.env" ]]; then
		# shellcheck disable=SC1091
		source "${PROJECT_DIR}/.env"
	fi
}

setup_kubeconfig() {
	if [[ ! -f "${PROJECT_DIR}/.kube/config" ]]; then
		mkdir -p "${PROJECT_DIR}/.kube"
		kind get kubeconfig --name "$CLUSTER_NAME" > "${PROJECT_DIR}/.kube/config"
		log "Kubeconfig set up at ${PROJECT_DIR}/.kube/config"
	fi
}

# Logging function with timestamp
log() {
	echo "[$(date +'%H:%M:%S')] $*"
}

# Check if command exists
need() {
	if  [[ ! $(command -v "$1") ]]; then
		echo "ERROR: $1 is required but not installed." >&2
		exit 1
	fi
}



