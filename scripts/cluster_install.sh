#!/bin/bash
# Main installer - orchestrates kind, argocd, and verification
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

# Run individual install scripts
"${SCRIPT_DIR}/cluster_install_kind.sh"
"${SCRIPT_DIR}/cluster_install_argocd.sh"
"${SCRIPT_DIR}/cluster_waits.sh"
"${SCRIPT_DIR}/cluster_check.sh"

# Show credentials
echo ""
log "=== Credentials ==="
"${SCRIPT_DIR}/info_argocd.sh"
echo ""
"${SCRIPT_DIR}/info_grafana.sh"
echo ""
"${SCRIPT_DIR}/info_postgresql.sh"
