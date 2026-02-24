#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DASHBOARDS_DIR="$PROJECT_DIR/apps/monitoring/dashboards"

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

DASHBOARD_ID="${1:-}"
OUTPUT_NAME="${2:-}"

if [[ -z "${DASHBOARD_ID}" || -z "${OUTPUT_NAME}" ]]; then
    echo "Usage: $0 <dashboard_id> <output_name>"
    exit 1
fi

API_URL="https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/latest/download"
log "Downloading dashboard $DASHBOARD_ID (latest revision)"
    
TMP_FILE=$(mktemp)

curl -sL -o "$TMP_FILE" "$API_URL"

OUTPUT_FILE="$DASHBOARDS_DIR/$OUTPUT_NAME.json"

# Replace datasource variables
log "Processing datasource variables"
sed -e 's/\${DS_PROMETHEUS}/VictoriaMetrics/g' \
    -e 's/\${DS_EXPRESSION}/__expr__/g' \
    "$TMP_FILE" > "$OUTPUT_FILE"

log "New Dashboard: $OUTPUT_FILE"
