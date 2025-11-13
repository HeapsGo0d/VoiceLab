#!/bin/bash
# VoiceLab RunPod Startup Script
# Initializes the VoiceLab container on RunPod with optional configuration

set -e

# ============================================================================
# Configuration
# ============================================================================
LOG_FILE="/tmp/voicelab_startup.log"
WORKSPACE_DIR="/workspace"
APPLIO_DIR="/opt/applio"

# ============================================================================
# Logging Setup
# ============================================================================
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================="
echo "  VoiceLab v1 - RunPod Startup"
echo "  $(date)"
echo "========================================="
echo ""

# ============================================================================
# System Information
# ============================================================================
echo "=== System Information ==="
echo ""

# GPU Info
echo "GPU Info:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || echo "⚠ nvidia-smi query failed"
else
    echo "⚠ Warning: nvidia-smi not available"
fi
echo ""

# Python Environment
echo "Python Environment:"
python --version
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'N/A')"
echo "CUDA Available: $(python -c 'import torch; print(torch.cuda.is_available())' 2>/dev/null || echo 'N/A')"
echo "CUDA Version: $(python -c 'import torch; print(torch.version.cuda if torch.cuda.is_available() else "N/A")' 2>/dev/null || echo 'N/A')"
echo ""

# ============================================================================
# Workspace Setup
# ============================================================================
echo "=== Workspace Setup ==="
echo ""

# Create workspace directories if they don't exist
echo "Creating workspace directories..."
mkdir -p \
    "$WORKSPACE_DIR/data/raw" \
    "$WORKSPACE_DIR/data/isolated/vocals" \
    "$WORKSPACE_DIR/data/isolated/instrumentals" \
    "$WORKSPACE_DIR/data/datasets" \
    "$WORKSPACE_DIR/models/applio" \
    "$WORKSPACE_DIR/models/uvr5" \
    "$WORKSPACE_DIR/models/pretraineds" \
    "$WORKSPACE_DIR/outputs" \
    "$WORKSPACE_DIR/scripts"

echo "✓ Workspace directories ready"
echo ""

# Display workspace structure
echo "Workspace structure:"
ls -lh "$WORKSPACE_DIR/" 2>/dev/null || echo "Empty workspace"
echo ""

# ============================================================================
# Applio Configuration
# ============================================================================
echo "=== Applio Configuration ==="
echo ""

# Check if password authentication is requested
AUTH_ARGS=""
if [[ -n "$APPLIO_PASSWORD" ]]; then
    echo "✓ Applio password authentication enabled"
    AUTH_ARGS="--auth admin:$APPLIO_PASSWORD"
else
    echo "⚠ Applio running without password (publicly accessible)"
    AUTH_ARGS=""
fi
echo ""

# ============================================================================
# Start Applio Web UI
# ============================================================================
echo "========================================="
echo "  Starting Applio Web UI"
echo "========================================="
echo ""
echo "🌐 Web UI will be available at:"
echo "   http://[pod-id]-6969.proxy.runpod.net"
echo ""
echo "📁 Workspace directories:"
echo "   Data:    $WORKSPACE_DIR/data/"
echo "   Models:  $WORKSPACE_DIR/models/"
echo "   Outputs: $WORKSPACE_DIR/outputs/"
echo ""

# Change to Applio directory
cd "$APPLIO_DIR" || {
    echo "❌ Error: Applio directory not found at $APPLIO_DIR"
    echo "Please check the Docker image installation"
    exit 1
}

# Start Applio Web UI
echo "🚀 Launching Applio..."
echo ""
echo "Command: python app.py --server-name 0.0.0.0 --server-port 6969 --share false $AUTH_ARGS"
echo ""

# Execute Applio (this will keep the container running)
exec python app.py \
    --server-name 0.0.0.0 \
    --server-port 6969 \
    --share false \
    $AUTH_ARGS
