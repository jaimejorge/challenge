#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"
load_env

ARGOCD_PASSWORD="$(kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo "URL:      https://${ARGOCD_DOMAIN}"
echo "Username: admin"
echo "Password: ${ARGOCD_PASSWORD}"

