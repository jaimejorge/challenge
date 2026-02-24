#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"
load_env


SECRET_NAME=$(kubectl get secret -n "${GRAFANA_NAMESPACE}" -o name 2>/dev/null | grep grafana | head -1)
PASSWORD=$(kubectl get secret -n "${GRAFANA_NAMESPACE}" "${SECRET_NAME##*/}" -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d)

echo "URL:      https://${GRAFANA_HOST}"
echo "Username: admin"
echo "Password: ${PASSWORD}"
