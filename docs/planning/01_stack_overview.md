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
| **Applio-RVC** | `b879141299` (v3.5.1) | Oct 26, 2024 | **PRIMARY** | 6969 | 6-8GB inference, 8-12GB training |
| **UVR5** (alt) | Use `audio-separator` package | Active | **RECOMMENDED ALT** | N/A (CLI) | 6-8GB (adjustable) |
| UVR5 (official) | `a897c05a82` (v5.6) | Sep 2023 | ⚠️ PROBLEMATIC | N/A (GUI only) | 6-8GB |

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
- 📝 **Action:** Downgrade requirements from `torch==2.7.1+cu128` to `torch==2.5.1+cu124`

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

### UVR5 (Vocal Isolation)

**Official GUI Commit:** `a897c05a82b1d6bd5979911535cebe248315f5ae` (v5.6, Sep 2023)

**PyTorch/CUDA:**
- ❌ **Officially targets CUDA 11.7** - Not designed for CUDA 12.x
- ❌ **ONNX Runtime CUDA 11 dependency** - Requires workarounds for CUDA 12
- 🔴 **Known crashes with CUDA 12.3/12.4** (#1652, #1119)
- 🟡 **GUI-only** - No official CLI support

**RECOMMENDED ALTERNATIVE: audio-separator package**
- CLI-first design (perfect for headless RunPod)
- Uses same UVR models (MDX-Net, Demucs, VR Arch)
- More flexible with PyTorch/CUDA versions
- Active maintenance
- Installation: `pip install audio-separator`

**VRAM:**
- Minimum: 6GB (tight)
- Comfortable: 8-12GB
- Can reduce memory via "Segment Size" or "Chunk Size" settings

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

## Environment Layout Recommendation

### **OPTION B: Shared primary env + audio-separator CLI**

**Primary Environment (PyTorch 2.5.1 + CUDA 12.4):**
- Applio-RVC (modified requirements)
- audio-separator (lightweight CLI alternative to UVR5)
- Shared audio processing libs (librosa, scipy, etc.)

**Why this layout:**
- ✅ Simplest for v1 hobby use
- ✅ audio-separator more headless-friendly than UVR5 GUI
- ✅ Avoids CUDA 11.7 vs 12.4 conflicts
- ✅ Single Python environment = easier maintenance
- ⚠️ If audio-separator has issues, fallback to separate UVR5 venv in v2

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

**RTX 4090 (24GB)** or **RTX 5090 (32GB):**
- ✅✅ Excellent for all v1 tools
- ✅✅ Comfortable multi-tasking (multiple tools running)
- ✅✅ Large dataset training with high batch sizes
- ✅✅ Ready for GPT-SoVITS Phase 3 addition
- ✅✅ Can experiment with simultaneous workflows

**12GB GPU** (e.g., RTX 3060 12GB, RTX 4070):
- ✅ Sweet spot for hobby use
- ✅ Comfortable for all v1 tools
- ✅ Room for experimentation

**8GB GPU** (e.g., RTX 3060 Ti):
- ⚠️ Viable but tight
- ⚠️ Requires careful memory management

**Verdict:** With 4090/5090 available, you have zero VRAM concerns for v1-v3. Future-proof for any voice AI experimentation.
