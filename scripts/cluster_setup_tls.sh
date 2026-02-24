#!/bin/bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=/dev/null
if [[ -f .env ]]; then
    source .env
fi



export CAROOT="$PWD/.mkcert"

mkdir -p "$CAROOT" certs

# Setup CA
if [ -f "$CAROOT/rootCA.pem" ]; then
    echo "CA already exists."
else
    mkcert -install 2>/dev/null || true
fi

# Generate certs if missing
if [[ ! -f certs/tls.crt ]]; then
    echo "Generating wildcard cert for *.${TLS_DOMAIN}..."
    cd certs && mkcert -cert-file tls.crt -key-file tls.key "*.${TLS_DOMAIN}" "${TLS_DOMAIN}" localhost 127.0.0.1 && cd ..
fi

# Create K8s secrets
echo "Creating TLS secrets..."
APPS="default argocd monitoring ingress-nginx postgresql"

for ns in ${APPS}; do
    kubectl create ns "$ns" --dry-run=client -o yaml | 
        kubectl apply -f - 2>/dev/null || true
    
    kubectl create secret tls "${TLS_SECRET_NAME}" --cert=certs/tls.crt --key=certs/tls.key -n "$ns" --dry-run=client -o yaml | 
        kubectl apply -f -
done

echo "Done! Run './scripts/trust-ca.sh' to trust CA on host."
