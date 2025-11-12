#!/bin/bash
# VoiceLab - Smoke Test Script
# Quick validation that the container is working

set -e

CONTAINER_NAME="${CONTAINER_NAME:-voicelab-v1}"

echo "========================================="
echo "  VoiceLab v1 Smoke Test"
echo "========================================="
echo ""

# Check container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: Container '$CONTAINER_NAME' is not running"
    echo "   Start it with: ./scripts/run.sh"
    exit 1
fi

echo "✓ Container is running"
echo ""

# Test 1: PyTorch + CUDA
echo "Test 1: PyTorch + CUDA availability"
docker exec "$CONTAINER_NAME" python -c "
import torch
print(f'  PyTorch: {torch.__version__}')
print(f'  CUDA Available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  CUDA Version: {torch.version.cuda}')
    print(f'  GPU: {torch.cuda.get_device_name(0)}')
    print(f'  VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB')
else:
    print('  ⚠ Warning: CUDA not available')
"
echo ""

# Test 2: audio-separator
echo "Test 2: audio-separator installation"
docker exec "$CONTAINER_NAME" python -c "
import audio_separator
print('  ✓ audio-separator is installed')
"
echo ""

# Test 3: Applio directory structure
echo "Test 3: Applio installation"
docker exec "$CONTAINER_NAME" bash -c "
if [ -d /workspace/tools/applio ]; then
    echo '  ✓ Applio directory exists'
    if [ -f /workspace/tools/applio/app.py ]; then
        echo '  ✓ app.py found'
    fi
    if [ -f /workspace/tools/applio/requirements.txt ]; then
        echo '  ✓ requirements.txt patched:'
        grep 'torch==' /workspace/tools/applio/requirements.txt | head -1
    fi
fi
"
echo ""

# Test 4: Workspace structure
echo "Test 4: Workspace structure"
docker exec "$CONTAINER_NAME" bash -c "
for dir in data/raw data/isolated data/datasets models/applio models/uvr5 outputs; do
    if [ -d /workspace/\$dir ]; then
        echo \"  ✓ /workspace/\$dir\"
    else
        echo \"  ❌ Missing: /workspace/\$dir\"
    fi
done
"
echo ""

# Test 5: Web UI accessibility
echo "Test 5: Web UI accessibility"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:6969/ | grep -q "200"; then
    echo "  ✓ Web UI is accessible at http://localhost:6969"
else
    echo "  ⚠ Web UI may not be ready yet (wait 30-60 seconds after start)"
fi
echo ""

echo "========================================="
echo "  Smoke Test Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "  • Open Web UI: http://localhost:6969"
echo "  • Run full test: Follow docs/planning/02_integration_notes.md smoke tests"
echo ""
