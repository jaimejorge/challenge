#!/bin/bash
#
# Download Grafana dashboards from grafana.com
#
# Usage: ./download-dashboard.sh <dashboard-id> [revision] [output-name]
#
# Examples:
#   ./download-dashboard.sh 20417                    # CloudNativePG
#   ./download-dashboard.sh 1860 latest node         # Node Exporter

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../../scripts/common.sh
source "${SCRIPT_DIR}/../../../scripts/common.sh"

DASHBOARD_ID="${1:-}"
REVISION="${2:-latest}"
OUTPUT_NAME="${3:-}"

if [[ -z "$DASHBOARD_ID" ]]; then
    echo "Usage: $0 <dashboard-id> [revision] [output-name]"
    echo ""
    echo "Popular dashboards:"
    echo "  1860   - Node Exporter Full"
    echo "  12740  - Kubernetes Pods"
    echo "  20417  - CloudNativePG"
    echo "  11074  - Traefik 2"
    exit 1
fi

# Get latest revision if needed
if [[ "$REVISION" == "latest" ]]; then
    log "Fetching latest revision for dashboard $DASHBOARD_ID"
    REVISION=$(curl -sL "https://grafana.com/api/dashboards/$DASHBOARD_ID" | \
        grep -o '"revision":[0-9]*' | head -1 | cut -d: -f2)
    log "Latest revision: $REVISION"
fi

# Download
API_URL="https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/$REVISION/download"
log "Downloading dashboard $DASHBOARD_ID (revision $REVISION)"

TMP_FILE=$(mktemp)
trap "rm -f $TMP_FILE" EXIT

curl -sL -o "$TMP_FILE" "$API_URL"

# Get title for filename
if [[ -z "$OUTPUT_NAME" ]]; then
    TITLE=$(jq -r '.title // empty' "$TMP_FILE")
    OUTPUT_NAME=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g')
    [[ -z "$OUTPUT_NAME" ]] && OUTPUT_NAME="dashboard-$DASHBOARD_ID"
fi

OUTPUT_FILE="$SCRIPT_DIR/$OUTPUT_NAME.json"

# Replace datasource variables
log "Processing datasource variables"
sed -e 's/\${DS_PROMETHEUS}/VictoriaMetrics/g' \
    -e 's/\${DS_EXPRESSION}/__expr__/g' \
    "$TMP_FILE" > "$OUTPUT_FILE"

log "Saved: $OUTPUT_FILE ($(wc -l < "$OUTPUT_FILE" | tr -d ' ') lines)"

