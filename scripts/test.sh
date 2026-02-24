#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# ShellCheck
shellcheck -e SC1091 scripts/*.sh && echo "ShellCheck passed"

# Helm lint
CHART_DIR="apps/http-https-echo apps/monitoring apps/bootstrap"
for chart in $CHART_DIR; do
	echo "Linting chart: $chart"
	helm lint "$chart" && echo "✅ Lint passed for $chart"
	# Helm template
	echo "Validating templates..."
	helm template test "$chart" >/dev/null && echo "Templates valid for $chart"
done

echo "All tests passed!"
