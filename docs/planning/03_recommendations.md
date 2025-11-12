# Recommendations - v1 Container

## Go / Cautious / No-Go Decisions

### ✅ Applio-RVC as Primary Voice Conversion: **GO**

**Decision:** Use as primary RVC tool for v1.

**Commit:** `b8791412993ebc934c148bd84798782af2f0439e` (v3.5.1, Oct 26, 2024)

**Justification:**
- Mature, stable release with active bug fixes
- Excellent Gradio Web UI (perfect for RunPod remote use)
- Community consensus: best RVC fork for ease of use
- Well-documented directory structure
- PyTorch 2.4+ officially supported (your 2.5.1 is compatible with modification)

**Caveats:**
- Requires modifying `requirements.txt` to downgrade PyTorch from 2.7.1→2.5.1 and CUDA cu128→cu124
- Multi-GPU training is broken (use single GPU)
- Expect deprecation warnings (safe to ignore for hobby use)

**Alternative commit if v3.5.1 is flaky:** `f17128bb` (Oct 27, 2024, includes "fix: Torch 2.5.0")

---

### ✅ audio-separator for Vocal Isolation: **GO**

**Decision:** Use `audio-separator` package as PRIMARY vocal isolation tool for v1.

**Commit/Version:** Latest from PyPI (`pip install audio-separator`)

**Justification:**
- ✅ CLI-first design (perfect for headless RunPod automation)
- ✅ Compatible with PyTorch 2.5.1 + CUDA 12.4 (shares env with Applio)
- ✅ Uses same UVR models (MDX-Net, Demucs, VR Arch) as official UVR5
- ✅ Active maintenance, modern PyTorch support
- ✅ Lightweight, easier to integrate than GUI tools

**VRAM:** 6-8GB comfortable, can tune down to 4-6GB with `--segment_size` parameter.

---

### ⚠️ UVR5 Official GUI: **FALLBACK ONLY** (v2 - If audio-separator fails)

**Decision:** Keep UVR5 GUI documented as fallback, do NOT use in v1.

**Why fallback only:**
- ❌ **Officially targets CUDA 11.7** - known crashes with CUDA 12.3/12.4
- ❌ GUI-only design (Tkinter) - requires X11 forwarding for headless use
- ❌ ONNX Runtime CUDA 11 dependency - messy workarounds for CUDA 12
- ❌ Minimal maintenance since Sep 2023

**When to use:**
- audio-separator has blocking CUDA/ONNX issues
- You need specific UVR5 GUI-only features
- Willing to set up separate venv with CUDA 11.7 stack

**Fallback setup:** See [integration notes Option B](02_integration_notes.md) for split environment configuration.

---

### 🚫 GPT-SoVITS v3 as v1 Integration: **NO-GO - Defer to Phase 3**

**Decision:** Do NOT include GPT-SoVITS in v1 container. Treat as separate, later add-on.

**Justification:**
1. **Different use case:** TTS/voice cloning vs voice conversion (you want RVC first)
2. **Maturity concerns:** v3/v4 still in testing; v2Pro is latest stable (June 2025)
3. **Complexity overhead:** Adds modelscope, funasr, Chinese NLP dependencies
4. **Higher VRAM requirements:** 12-16GB training (heavier than RVC 8-12GB)
5. **Rapid development:** Breaking changes between versions
6. **User priority:** Voice conversion is primary; TTS is optional "nice-to-have"

**When to revisit:**
- After v1 container is stable and fun to use
- When you have a specific TTS use case (not just "exploration")
- When v4 becomes officially stable
- Consider separate container (cleaner isolation)

**Technical note:** GPT-SoVITS *can* share PyTorch 2.5.1 + CUDA 12.4 environment with Applio, but adds unnecessary complexity for v1.

---

## RunPod GPU Tier Recommendations

> **🚀 High-End Users (RTX 4090/5090 - 24GB+):**
> You can skip detailed VRAM analysis below. Use default settings everywhere. Jump to [Recommended Configuration](#recommended-configuration-for-your-setup).

> **💰 Budget Users (8-12GB GPUs):**
> Read the comparison table below for your GPU tier's capabilities and limitations.

---

### Your Available Hardware: RTX 4090 (24GB) / RTX 5090 (32GB)

**EXCELLENT CHOICE** - This completely changes the game.

**With 4090/5090, you have:**
- ✅✅ **Zero VRAM concerns** for v1, v2, or v3
- ✅✅ **Massive batch sizes** for faster training
- ✅✅ **Multi-tool workflows** (run Applio + audio-separator simultaneously)
- ✅✅ **Large dataset training** (10-30 min voice samples, no problem)
- ✅✅ **Future-proof for GPT-SoVITS** (12-16GB training comfortably fits)
- ✅✅ **Experimentation freedom** (try different models, architectures, settings)

**Compared to budget tiers:**

| GPU | VRAM | Applio Training | audio-separator | GPT-SoVITS v3 | Multi-tasking |
|-----|------|-----------------|-----------------|---------------|---------------|
| RTX 3060 Ti | 8GB | ⚠️ Tight | ✅ OK | ❌ No | ❌ No |
| RTX 3060 12GB | 12GB | ✅ OK | ✅ OK | ⚠️ Tight | ⚠️ Maybe |
| RTX 4070 | 12GB | ✅ OK | ✅ OK | ⚠️ Tight | ⚠️ Maybe |
| **RTX 4090** | **24GB** | ✅✅ **Excellent** | ✅✅ **Excellent** | ✅✅ **Yes** | ✅✅ **Yes** |
| **RTX 5090** | **32GB** | ✅✅ **Overkill** | ✅✅ **Excellent** | ✅✅ **Yes** | ✅✅ **Yes** |

**Verdict:** You can safely ignore all VRAM tuning advice. Focus on fun and experimentation, not memory management.

---

## RunPod Cost Considerations

**RTX 4090 on RunPod:**
- Community Cloud: ~$0.40-0.60/hr (variable availability)
- Secure Cloud: ~$0.79-1.00/hr (guaranteed availability)

**RTX 5090 on RunPod:**
- Availability: Limited (check RunPod marketplace)
- Cost: Likely $1.00-1.50/hr when available

**Budget estimate for hobby use:**
- **10 hrs/month experimentation**: $4-15/month (Community Cloud 4090)
- **20 hrs/month heavy training**: $8-30/month
- **On-demand usage**: Spin up only when actively working

**Tip:** Use RunPod Pods (not Serverless) with persistent volume (~$0.10/GB/month storage) so you don't lose models between sessions.

---

## Recommended Configuration for Your Setup

**GPU:** RTX 4090 (sweet spot for cost/performance) or RTX 5090 (if available and budget allows)

**Environment:**
- Single venv with PyTorch 2.5.1 + CUDA 12.4
- Applio + audio-separator in same environment
- No need for memory optimization tricks

**Storage:**
- 50-100GB persistent volume for `/workspace/`
- Models: ~10-20GB (pretrained + your trained voices)
- Datasets: 5-10GB per voice (depends on sample length)
- Outputs: 10-20GB (experiments, converted audio)

**RunPod Settings:**
- Pod Type: GPU Pod (not Serverless)
- Volume: Attach persistent network volume
- Port: Expose 6969 for Applio Web UI
- Auto-pause: Enable (saves $ when idle >15 min)

---

## v1 Risks & Fallbacks

### Risk 1: Applio PyTorch 2.5.1 Compatibility

**Symptoms:**
- Import errors on torch/CUDA
- Training fails with tensor device mismatches
- Inference produces silence or crashes

**Fallbacks:**
1. Use commit `f17128bb` (has "fix: Torch 2.5.0" mention)
2. Downgrade to PyTorch 2.4.1 + cu124 (officially supported via PR #947)
3. Upgrade to PyTorch 2.7.1 + cu128 (Applio's latest target, but requires CUDA 12.8 base image)

---

### Risk 2: audio-separator CUDA/ONNX Issues

**Symptoms:**
- ONNX Runtime fails to find CUDA libraries
- Crashes with "no CUDA provider available"
- Slower than expected (running on CPU)

**Fallbacks:**
1. Install `ort-nightly-gpu` for CUDA 12 support:
   ```bash
   pip install ort-nightly-gpu --index-url=https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/ort-cuda-12-nightly/pypi/simple/
   ```
2. Fall back to official UVR5 in separate venv with CUDA 11.7 stack (see integration_notes.md Option B)
3. Skip vocal isolation in v1, use external tool (audacity, online UVR)

---

### Risk 3: Multi-GPU Training Fails (Applio #1153)

**Symptoms:**
- Training crashes when multiple GPUs detected
- Error: "Expected all tensors to be on the same device"

**Fallback:**
- Force single GPU: `CUDA_VISIBLE_DEVICES=0 python app.py`
- Not a concern for your single 4090/5090 setup

---

### Risk 4: Index File Conversion Failures (Applio #1150)

**Symptoms:**
- Inference works without index file
- With index file: crashes or produces corrupted audio

**Fallbacks:**
1. Train and infer without index files (slight quality drop, but functional)
2. Downgrade to Applio v3.4.0 (last version before index regression)
3. Wait for fix in next stable release

---

### Risk 5: Docker Audio Device Access (Applio #1144)

**Symptoms:**
- Portaudio errors on startup
- "No audio devices found" warnings

**Mitigation:**
- Expected behavior in headless RunPod
- Use Web UI file upload (not real-time microphone)
- Errors are non-fatal, tool still works

---

### Risk 6: VRAM Exhaustion (NOT APPLICABLE TO YOU)

**With 4090/5090:**
- You won't hit OOM errors unless you intentionally max out settings
- Feel free to use default batch sizes, large models, and high-quality settings
- Can run multiple processes simultaneously if needed

---

## Summary: Is This Stack "Good Enough for v1"?

**YES**, with minor modifications.

**What works:**
- ✅ Applio is mature, stable, and fun to use
- ✅ Web UI perfect for RunPod remote experimentation
- ✅ audio-separator solves UVR5 CUDA 12 problem elegantly
- ✅ Single environment simple to build and maintain
- ✅✅ **4090/5090 gives you massive headroom** - zero VRAM concerns

**What requires attention:**
- ⚠️ Modify Applio requirements.txt (5-minute task)
- ⚠️ Use single GPU only (multi-GPU broken) - not an issue for your setup
- ⚠️ Expect some PyTorch deprecation warnings (cosmetic)

**What to skip for now:**
- 🚫 GPT-SoVITS (defer to Phase 3)
- 🚫 Multi-GPU training (broken anyway)
- 🚫 Real-time microphone input (impossible on RunPod)

**Confidence level:** 85% this will work smoothly for your described hobby use case. The 15% risk is mostly PyTorch version tuning, which has clear fallbacks.

**Your advantages with 4090/5090:**
- 🎉 Can experiment freely without worrying about VRAM
- 🎉 Faster iteration (larger batch sizes = faster training)
- 🎉 Can explore GPT-SoVITS in Phase 3 without hardware concerns
- 🎉 Can run multiple voices/experiments simultaneously

**Next step:** Build Phase 2 Dockerfile with confidence. You have specific commits, a clear env strategy, and smoke tests defined.
