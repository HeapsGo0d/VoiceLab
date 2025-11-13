#!/bin/bash
set -e

echo "========================================="
echo "  VoiceLab v1 - Voice AI Container"
echo "========================================="
echo ""

# Display environment info
echo "GPU Info:"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || echo "⚠ Warning: nvidia-smi not available (GPU may not be accessible)"
echo ""

echo "Python Environment:"
python --version
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA Available: $(python -c 'import torch; print(torch.cuda.is_available())')"
echo "CUDA Version: $(python -c 'import torch; print(torch.version.cuda if torch.cuda.is_available() else "N/A")')"
echo ""

echo "Workspace Structure:"
ls -lh /workspace/
echo ""

# Check if custom command is provided
if [ $# -gt 0 ]; then
    echo "Running custom command: $@"
    exec "$@"
else
    echo "========================================="
    echo "  Starting Applio Web UI"
    echo "========================================="
    echo ""
    echo "🌐 Web UI will be available at:"
    echo "   http://localhost:6969"
    echo ""
    echo "📁 Workspace directories:"
    echo "   Data:    /workspace/data/"
    echo "   Models:  /workspace/models/"
    echo "   Outputs: /workspace/outputs/"
    echo ""
    echo "🚀 Launching Applio..."
    echo ""

    # Start Applio Web UI (now at /opt instead of /workspace)
    cd /opt/applio
    exec python app.py \
        --server-name 0.0.0.0 \
        --server-port 6969 \
        --share false
fi
