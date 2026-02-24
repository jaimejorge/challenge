#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"
load_env


USER=$(kubectl -n "${POSTGRESQL_NAMESPACE}" get secret "${POSTGRESQL_SECRET}" -o jsonpath="{.data.username}" 2>/dev/null | base64 -d)
PASS=$(kubectl -n "${POSTGRESQL_NAMESPACE}" get secret "${POSTGRESQL_SECRET}" -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
DB=$(kubectl -n "${POSTGRESQL_NAMESPACE}" get secret "${POSTGRESQL_SECRET}" -o jsonpath="{.data.dbname}" 2>/dev/null | base64 -d)

echo "Host:     localhost"
echo "Port:     ${POSTGRESQL_HOST_PORT}"
echo "Database: ${DB}"
echo "Username: ${USER}"
echo "Password: ${PASS}"
echo ""
echo "psql -h localhost -p ${POSTGRESQL_HOST_PORT} -U ${USER} -d ${DB}"
