#!/bin/bash
# VoiceLab - Run Script
# Runs the VoiceLab container locally with GPU access

set -e

echo "========================================="
echo "  Running VoiceLab v1 Container"
echo "========================================="
echo ""

# Run options
IMAGE_NAME="${IMAGE_NAME:-voicelab}"
IMAGE_TAG="${IMAGE_TAG:-v1}"
CONTAINER_NAME="${CONTAINER_NAME:-voicelab-v1}"
PORT="${PORT:-6969}"

echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "Container: $CONTAINER_NAME"
echo "Port: $PORT"
echo ""

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "⚠ Container '$CONTAINER_NAME' already exists"
    read -p "Remove and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rm -f "$CONTAINER_NAME"
    else
        echo "Aborted."
        exit 1
    fi
fi

# Check GPU availability
if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
    echo "✓ GPU detected, starting with GPU support"
    GPU_FLAG="--gpus all"
else
    echo "⚠ No GPU detected, starting in CPU mode"
    echo "   Note: Voice AI tasks require GPU for reasonable performance"
    GPU_FLAG=""
fi

echo ""
echo "Starting container..."
echo ""

# Run container
docker run -d \
    --name "$CONTAINER_NAME" \
    $GPU_FLAG \
    -p "$PORT:6969" \
    -v "$(pwd)/workspace:/workspace" \
    -e GRADIO_SERVER_NAME=0.0.0.0 \
    -e GRADIO_SERVER_PORT=6969 \
    --restart unless-stopped \
    "$IMAGE_NAME:$IMAGE_TAG"

echo "========================================="
echo "  ✓ Container Started"
echo "========================================="
echo ""
echo "Container: $CONTAINER_NAME"
echo "Status: $(docker ps --filter name=$CONTAINER_NAME --format '{{.Status}}')"
echo ""
echo "🌐 Applio Web UI: http://localhost:$PORT"
echo ""
echo "Useful commands:"
echo "  • View logs:      docker logs -f $CONTAINER_NAME"
echo "  • Shell access:   docker exec -it $CONTAINER_NAME bash"
echo "  • Stop:           docker stop $CONTAINER_NAME"
echo "  • Remove:         docker rm -f $CONTAINER_NAME"
echo ""
echo "Waiting for Web UI to start (this may take 30-60 seconds)..."

# Wait for health check
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null | grep -q "healthy"; then
        echo "✓ Web UI is ready!"
        break
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    echo -n "."
done

echo ""
echo "Open http://localhost:$PORT in your browser"
echo ""
