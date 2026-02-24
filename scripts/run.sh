#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
if [[ -f .env ]]; then
    source .env
fi

if [[ ! $(command -v docker) ]]; then
    echo "ERROR: Docker is not installed. Please install Docker first: https://docs.docker.com/get-docker/" >&2
    exit 1
fi


if [[ ! $(docker info 2>/dev/null) ]]; then
    echo "ERROR: Docker daemon is not running. Please start Docker Desktop or the Docker service." >&2
    exit 1
fi

# Docker socket - use standard path on macOS with Docker Desktop
# Docker host if not set, default to standard Docker socket
DOCKER_SOCKET="${DOCKER_HOST:-/var/run/docker.sock}"

# Remove "unix://" prefix if present
DOCKER_SOCKET="${DOCKER_SOCKET#unix://}"

# Export for use in docker run
export DOCKER_SOCKET

docker run --rm -it \
    -v "${PROJECT_DIR}:/workspace" \
    -v "${DOCKER_SOCKET}:/var/run/docker.sock" \
    -e KUBECONFIG=/workspace/.kube/config \
    --network host \
    "${IMAGE_NAME}" \
    -c "$*"

