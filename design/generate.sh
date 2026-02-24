#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="mjdk/diagrams"

# Default to all python files if no argument provided
if [ -n "$1" ]; then
    DIAGRAMS=("$1.py")
else
    DIAGRAMS=(*.py)
fi

echo "Generating diagrams using Docker..."

for diagram in "${DIAGRAMS[@]}"; do
    if [ -f "$SCRIPT_DIR/$diagram" ]; then
        echo "  Processing: $diagram"
        docker run -it --rm \
            -v "$SCRIPT_DIR:/diagrams/scripts/" \
            -w /diagrams/scripts/ \
            "$DOCKER_IMAGE" \
            "$diagram"
    else
        echo "  Warning: $diagram not found, skipping"
    fi
done

echo "Done! Generated files:"
ls -la "$SCRIPT_DIR"/*.png 2>/dev/null || echo "  No PNG files generated"
