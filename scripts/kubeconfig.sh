#!/bin/bash
set -euo pipefail

[[ "${DEBUG:-false}" == "true" ]] && set -x

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# shellcheck source=/dev/null
if [[ -f "$DIR/../.env" ]]; then
    source "$DIR/../.env"
fi

mkdir -p .kube

kind get kubeconfig --name "$CLUSTER_NAME" > .kube/config 

echo "Kubeconfig exported to .kube/config"
echo "  export KUBECONFIG=\$PWD/.kube/config"
echo "  kubectl get pods -A"
