# Voice AI Stack Overview - v1

## Core Stack Configuration

**Base Environment:**
- Base image: `nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04`
- Target PyTorch: **2.5.1** with CUDA 12.4
- Python: 3.10 or 3.11

**CUDA/PyTorch Compatibility Note:** PyTorch 2.5.0 had known issues; 2.5.1 is the minimum recommended version for stability.

---

## Tool Matrix

### Primary Tools (v1 Phase 1)

| Tool | Version/Commit | Date | Status | Port | VRAM (Typical) |
|------|---------------|------|--------|------|----------------|
| **Applio-RVC** | `b879141299` (v3.5.1) | Oct 26, 2024 | ✅ **PRIMARY** | 6969 | 6-8GB inference, 8-12GB training |
| **audio-separator** | Latest (PyPI) | Active | ✅ **PRIMARY** | N/A (CLI) | 6-8GB (adjustable) |

### Fallback Tools (v2 - If Needed)

| Tool | Version/Commit | Date | Status | Port | VRAM (Typical) |
|------|---------------|------|--------|------|----------------|
| UVR5 (official GUI) | `a897c05a82` (v5.6) | Sep 2023 | ⚠️ **FALLBACK ONLY** | N/A (GUI only) | 6-8GB |

**Note:** UVR5 official GUI targets CUDA 11.7 and requires separate environment. Only use if audio-separator fails. See [integration notes](02_integration_notes.md) for setup.

### Optional Tools (Phase 3 - Separate Container)

| Tool | Version/Commit | Date | Status | Port | VRAM (Typical) |
|------|---------------|------|--------|------|----------------|
| **GPT-SoVITS v3/v4** | Latest stable | Q4 2024+ | 🚫 **DEFER TO v2** | Various | 12-16GB training, 8GB+ inference |

---

## Compatibility Matrix

### Applio-RVC

**Commit:** `b8791412993ebc934c148bd84798782af2f0439e` (v3.5.1)

**PyTorch/CUDA:**
- ⚠️ **Requires modification:** Current `requirements.txt` specifies PyTorch 2.7.1 + CUDA 12.8
- ✅ **Target-compatible:** PyTorch 2.4+ officially supported (PR #947)
- ✅ **Your target (2.5.1 + cu124):** Should work with modified requirements
- 📝 **Action:** Patch requirements to use:
  - `torch==2.5.1+cu124`
  - `torchvision==0.20.1+cu124`
  - `torchaudio==2.5.1+cu124`

**Fallback if v3.5.1 has issues:**
- **Commit:** `f17128bb3a6a` (Oct 27, 2024) - Includes explicit "fix: Torch 2.5.0" commit
- **Or:** Downgrade to PyTorch 2.4.1+cu124 (officially supported via PR #947)

**Known Issues:**
- 🔴 **Multi-GPU training broken** (#1153) - Use single GPU only
- 🟡 **Docker portaudio errors** (#1144) - Expected in headless; use file upload
- 🟡 **Training concatenation errors** (#1119) - Requires clean dataset prep
- ✅ **Memory leaks fixed** (Gradio-related, Oct 2025)

**Web UI:**
- Gradio-based, excellent for remote use
- Default port: **6969**
- Launch: `python app.py --server-name 0.0.0.0 --port 6969`
- File upload for audio (no physical mic support on RunPod)

**Directories:**
- Training data: `assets/datasets/<model_name>/`
- Model output: `logs/<experiment_name>/` (checkpoints)
- Final weights: `weights/`
- Configs: Root-level configs + per-experiment in `logs/`

---

### Vocal Isolation Tools

#### ✅ PRIMARY: audio-separator (Recommended for v1)

**Installation:** `pip install audio-separator` (PyPI)

**Why primary:**
- ✅ CLI-first design (perfect for headless RunPod)
- ✅ Compatible with PyTorch 2.5.1 + CUDA 12.4
- ✅ Uses same UVR models (MDX-Net, Demucs, VR Arch)
- ✅ Active maintenance
- ✅ Lightweight, shares environment with Applio

**VRAM:**
- Minimum: 6GB (tight)
- Comfortable: 8-12GB
- Can reduce memory via `--segment_size` parameter

**Usage:**
```bash
audio-separator input.wav \
  --model_filename model_bs_roformer_ep_317_sdr_12.9755.ckpt \
  --output_dir /workspace/data/isolated/
```

---

#### ⚠️ FALLBACK: UVR5 Official GUI (v2 - If audio-separator fails)

**Commit:** `a897c05a82b1d6bd5979911535cebe248315f5ae` (v5.6, Sep 2023)

**Why fallback only:**
- ❌ **Officially targets CUDA 11.7** - Requires separate environment with cu117 stack
- ❌ **ONNX Runtime CUDA 11 dependency** - Workarounds needed for CUDA 12
- 🔴 **Known crashes with CUDA 12.3/12.4** (#1652, #1119)
- 🟡 **GUI-only** - Requires X11 forwarding for headless use

**When to use:**
- audio-separator has CUDA/ONNX issues in your environment
- You need specific UVR5 GUI-only features
- Willing to set up separate venv with CUDA 11.7 stack

**Setup:** See [integration notes Option B](02_integration_notes.md) for isolated environment configuration.

---

### GPT-SoVITS v3/v4 (Optional TTS/Voice Cloning)

**Status:** ✅ Compatible with PyTorch 2.5.1 + CUDA 12.4, but 🚫 **NOT RECOMMENDED for v1**

**Why defer to Phase 3 / separate container:**
1. **Complexity overhead** - TTS vs voice conversion are different workflows
2. **Rapid development** - v4 still in testing phase; v2Pro is latest stable
3. **Dependency sprawl** - Adds modelscope, funasr, Chinese NLP tools
4. **Different VRAM profile** - 12-16GB training (heavier than RVC)
5. **User priority** - Voice conversion (Applio) is primary; TTS is optional

**If you add it later:**
- Can share PyTorch 2.5.1 + CUDA 12.4 environment with Applio
- Separate container cleaner for experimentation
- Requires high-quality training data (v1/v2Pro better for average audio)

---

## Environment Layout for v1

### **Single Shared Environment (Recommended)**

**Primary Environment (PyTorch 2.5.1 + CUDA 12.4):**
- Applio-RVC (with modified requirements.txt)
- audio-separator (CLI tool, shares PyTorch)
- Shared audio processing libs (librosa, scipy, soundfile, etc.)

**Why this approach:**
- ✅ Simplest to build and maintain
- ✅ audio-separator compatible with modern PyTorch/CUDA
- ✅ Avoids CUDA 11.7 vs 12.4 conflicts
- ✅ Single Python environment = easier troubleshooting
- ✅ Lower storage overhead (~5-7GB vs ~10-12GB for dual env)

**Fallback (v2 only if needed):**
- Split environment with UVR5 in separate venv (CUDA 11.7)
- See [integration notes Option B](02_integration_notes.md) for details
- Only pursue if audio-separator has blocking issues

---

## Red Flags & Mitigations

| Issue | Severity | Mitigation |
|-------|----------|------------|
| PyTorch version mismatch (Applio wants 2.7.1) | 🟡 MEDIUM | Modify requirements.txt to 2.5.1+cu124 |
| Multi-GPU training broken | 🟡 MEDIUM | Use single GPU (acceptable for hobby) |
| UVR5 CUDA 12.4 incompatibility | 🔴 HIGH | Use audio-separator instead |
| Docker audio device access | 🟢 LOW | Expected; use file upload workflow |
| Index file conversion failures (Applio #1150) | 🟡 MEDIUM | Train without index or downgrade to v3.4 |

---

## VRAM Recommendations

> **🚀 High-End Users (RTX 4090/5090 - 24GB+):**
> Skip VRAM tuning entirely. Use default settings, max batch sizes, and experiment freely. You have enough headroom for all tools simultaneously. **Jump to [Next Steps](04_next_steps.md).**

> **💰 Budget Users (8-12GB GPUs):**
> Read VRAM guidance below for tuning tips and memory management strategies.

---

### High-End GPUs (24GB+)

**RTX 4090 (24GB)** or **RTX 5090 (32GB):**
- ✅✅ Excellent for all v1 tools with default settings
- ✅✅ Comfortable multi-tasking (multiple tools running simultaneously)
- ✅✅ Large dataset training with high batch sizes (16-32+)
- ✅✅ Ready for GPT-SoVITS Phase 3 addition (12-16GB training fits easily)
- ✅✅ Can experiment with simultaneous workflows without OOM concerns
- ✅✅ Future-proof for v1, v2, v3 expansions

**Verdict:** Zero VRAM tuning needed. Focus on experimentation, not optimization.

---

### Budget GPUs (8-12GB)

**12GB GPU** (e.g., RTX 3060 12GB, RTX 4070 12GB, RTX 4060 Ti 16GB):
- ✅ Sweet spot for hobby use
- ✅ Comfortable for all v1 tools (Applio + audio-separator)
- ✅ Room for experimentation with moderate batch sizes (8-12)
- ⚠️ GPT-SoVITS Phase 3 will be tight (training requires 12-16GB)
- 💡 **Tuning tips:** Use default batch sizes, reduce if OOM occurs

**8GB GPU** (e.g., RTX 3060 Ti, RTX 2070 Super):
- ⚠️ Viable but tight for training
- ✅ Inference works comfortably
- ⚠️ Requires careful memory management for training
- 💡 **Tuning tips:** Reduce batch size to 4-6, use smaller pretrained models, lower audio-separator segment size
- ❌ GPT-SoVITS Phase 3 not recommended

**< 8GB GPU:**
- ❌ Not recommended for v1
- Training will frequently OOM
- Consider upgrading GPU or using cloud (RunPod/Vast.ai)
