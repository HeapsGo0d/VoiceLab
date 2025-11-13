# VoiceLab v1 - Voice AI Experimentation Container
# Base: CUDA 12.4.1 + cuDNN + Ubuntu 22.04
# Stack: PyTorch 2.5.1 + Applio-RVC + audio-separator

FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Set workspace directory
WORKDIR /workspace

# ============================================================================
# STAGE 1: System Dependencies
# ============================================================================

RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    cmake \
    # Python
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    # Audio processing
    ffmpeg \
    sox \
    libsndfile1 \
    libsndfile1-dev \
    # Utilities
    git \
    wget \
    curl \
    vim \
    htop \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for python command
RUN ln -sf /usr/bin/python3.10 /usr/bin/python

# ============================================================================
# STAGE 2: Python Virtual Environment
# ============================================================================

# Create and activate venv (activated via ENV for subsequent RUN commands)
RUN python -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"
ENV VIRTUAL_ENV="/workspace/venv"

# Upgrade pip, setuptools, wheel
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# ============================================================================
# STAGE 3: PyTorch 2.5.1 + CUDA 12.4 (CRITICAL - Install First)
# ============================================================================

RUN pip install --no-cache-dir \
    torch==2.5.1 \
    torchvision==0.20.1 \
    torchaudio==2.5.1 \
    --index-url https://download.pytorch.org/whl/cu124

# Verify PyTorch + CUDA installation
RUN python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')"

# ============================================================================
# STAGE 4: audio-separator (Vocal Isolation Tool)
# ============================================================================

RUN pip install --no-cache-dir audio-separator

# Pre-create cache directory for models (will be populated on first run)
RUN mkdir -p /root/.cache/audio-separator

# ============================================================================
# STAGE 5: Applio-RVC (Voice Conversion Tool)
# ============================================================================

# Clone Applio at specific commit (v3.5.1)
RUN mkdir -p /workspace/tools && \
    cd /workspace/tools && \
    git clone https://github.com/IAHispano/Applio.git applio && \
    cd applio && \
    git checkout b8791412993ebc934c148bd84798782af2f0439e

# CRITICAL: Patch requirements.txt to use PyTorch 2.5.1 + CUDA 12.4
RUN cd /workspace/tools/applio && \
    sed -i 's/torch==2\.7\.1+cu128/torch==2.5.1+cu124/g' requirements.txt && \
    sed -i 's/torchvision==.*+cu128/torchvision==0.20.1+cu124/g' requirements.txt && \
    sed -i 's/torchaudio==.*+cu128/torchaudio==2.5.1+cu124/g' requirements.txt && \
    echo "✓ Patched requirements.txt:" && \
    grep -E "(torch|torchvision|torchaudio)==" requirements.txt

# Install Applio dependencies
RUN cd /workspace/tools/applio && \
    pip install --no-cache-dir -r requirements.txt

# ============================================================================
# STAGE 6: Workspace Structure Setup
# ============================================================================

# Create persistent workspace directories
RUN mkdir -p \
    /workspace/data/raw \
    /workspace/data/isolated/vocals \
    /workspace/data/isolated/instrumentals \
    /workspace/data/datasets \
    /workspace/models/applio \
    /workspace/models/uvr5 \
    /workspace/models/pretraineds \
    /workspace/outputs \
    /workspace/tools/applio/assets/datasets \
    /workspace/tools/applio/logs \
    /workspace/tools/applio/weights

# ============================================================================
# STAGE 7: Scripts, Entrypoint and Ports
# ============================================================================

# Copy scripts to /scripts (outside /workspace to avoid volume shadowing)
COPY entrypoint.sh /scripts/entrypoint.sh
COPY scripts/startup.sh /scripts/startup.sh
RUN chmod +x /scripts/*.sh

# Expose Applio Web UI port
EXPOSE 6969

# Set working directory to Applio
WORKDIR /workspace/tools/applio

# Health check - verify Gradio is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:6969/ || exit 1

# Default entrypoint (outside /workspace to prevent volume shadowing)
ENTRYPOINT ["/scripts/entrypoint.sh"]
