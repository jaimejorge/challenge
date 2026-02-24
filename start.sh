#!/bin/bash

set -euo pipefail

# Check dependencies
if [[ ! $(command -v docker) ]]; then
    echo "ERROR: Docker is required. Install from https://docs.docker.com/get-docker/"
    echo "Also make sure to install docker-buildx: sudo apt install docker-buildx."
    exit 1
fi

if [[ ! $(command -v make) ]]; then
    echo "ERROR: make is required."
    echo ""
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt install make"
    echo "  RHEL/Fedora:   sudo dnf install make"
    echo "  Alpine:        apk add make"
    echo "  macOS:         xcode-select --install"
    exit 1
fi

make docker-build
make install
