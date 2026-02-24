#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"
load_env

echo "Building Docker image: ${IMAGE_NAME}"
DOCKER_BUILDKIT=1 docker build -t "${IMAGE_NAME}" -f Dockerfile .
echo "Done: ${IMAGE_NAME}"
