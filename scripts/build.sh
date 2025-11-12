#!/bin/bash
# VoiceLab - Build Script
# Builds the VoiceLab Docker image

set -e

echo "========================================="
echo "  Building VoiceLab v1 Container"
echo "========================================="
echo ""

# Build options
IMAGE_NAME="${IMAGE_NAME:-voicelab}"
IMAGE_TAG="${IMAGE_TAG:-v1}"
BUILD_ARGS="${BUILD_ARGS:-}"

echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running or not installed"
    echo "   Please start Docker and try again"
    exit 1
fi

# Check NVIDIA Docker runtime (optional but recommended)
if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
    echo "✓ NVIDIA Docker runtime detected"
else
    echo "⚠ Warning: NVIDIA Docker runtime not available"
    echo "   Container will build but won't have GPU access"
    echo "   Install: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
fi

echo ""
echo "Building Docker image..."
echo "This will take 10-20 minutes on first build (downloads ~8GB)"
echo ""

# Build with BuildKit for better performance
export DOCKER_BUILDKIT=1

docker build \
    -t "$IMAGE_NAME:$IMAGE_TAG" \
    -t "$IMAGE_NAME:latest" \
    $BUILD_ARGS \
    .

echo ""
echo "========================================="
echo "  ✓ Build Complete"
echo "========================================="
echo ""
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "Size: $(docker images $IMAGE_NAME:$IMAGE_TAG --format '{{.Size}}')"
echo ""
echo "Next steps:"
echo "  • Test locally: ./scripts/run.sh"
echo "  • Or use docker-compose: docker-compose up"
echo "  • Push to registry: docker push $IMAGE_NAME:$IMAGE_TAG"
echo ""
