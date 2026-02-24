#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

CA_FILE=".mkcert/rootCA.pem"

if [[ ! -f "$CA_FILE" ]]; then
    echo "CA not found. Run 'make tls' first."
    exit 1
fi

case "$(uname -s)" in
    Darwin)
        echo "Installing CA to macOS keychain..."
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CA_FILE"
        ;;
    Linux)
        echo "Installing CA to Linux trust store..."
        if command -v update-ca-certificates &>/dev/null; then
            sudo cp "$CA_FILE" /usr/local/share/ca-certificates/mkcert-ca.crt
            sudo update-ca-certificates
        elif command -v update-ca-trust &>/dev/null; then
            sudo cp "$CA_FILE" /etc/pki/ca-trust/source/anchors/mkcert-ca.pem
            sudo update-ca-trust
        else
            echo "Unknown cert tool. Install CA manually: $CA_FILE"; exit 1
        fi
        ;;
    *)
        echo "Unsupported OS. Install CA manually: $CA_FILE"; exit 1
        ;;
esac

echo "Done! Restart browser for HTTPS to work on *.localtest.me"
