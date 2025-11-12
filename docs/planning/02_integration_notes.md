# Integration Notes - v1 Container

## Recommended Folder Structure

```
/workspace/
├── tools/
│   ├── applio/                    # Applio-RVC installation
│   │   ├── assets/
│   │   │   ├── datasets/          # Training data staging
│   │   │   └── audios/            # Applio output default
│   │   ├── logs/                  # Training checkpoints
│   │   ├── weights/               # Inference models
│   │   └── app.py
│   └── audio-separator/           # (if installed separately)
│
├── data/
│   ├── raw/                       # Original audio files
│   │   └── <date_or_source>/
│   ├── isolated/                  # UVR5/audio-separator outputs
│   │   ├── vocals/
│   │   └── instrumentals/
│   └── datasets/                  # Prepared training datasets
│       └── <voice_name>/
│           ├── 0_gt_wavs/         # Ground truth WAVs (Applio format)
│           └── metadata.csv       # (if needed)
│
├── models/
│   ├── applio/
│   │   └── <voice_name>/
│   │       ├── <experiment>.pth   # Final trained model
│   │       └── <experiment>.index # Index file
│   ├── uvr5/                      # UVR model weights
│   │   └── <model_name>.pth
│   └── pretraineds/               # Base pretrained models
│       └── <architecture>/
│
└── outputs/
    └── <YYYYMMDD_experiment_name>/
        ├── converted/              # Voice conversion results
        ├── isolated/               # Isolated vocals from this run
        └── README.txt              # Experiment notes
```

**Design rationale:**
- `tools/` - Immutable app installations
- `data/` - User content, survives container rebuilds
- `models/` - Heavy model weights, organized by tool
- `outputs/` - Timestamped experiments, easy to archive

---

## Environment Layout: Shared Primary + audio-separator

### Installation Order (Minimizes Conflicts)

1. **Base system packages:**
   ```bash
   apt-get update && apt-get install -y \
       git wget curl ffmpeg sox libsndfile1 \
       build-essential
   ```

2. **Python environment:**
   ```bash
   python3.10 -m venv /workspace/venv
   source /workspace/venv/bin/activate
   ```

3. **PyTorch 2.5.1 + CUDA 12.4 (FIRST):**
   ```bash
   pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
       --index-url https://download.pytorch.org/whl/cu124
   ```

   **Verify installation:**
   ```bash
   python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}')"
   # Expected output: PyTorch: 2.5.1+cu124, CUDA: 12.4
   ```

4. **audio-separator (lightweight, fewer conflicts):**
   ```bash
   pip install audio-separator
   ```
   - Downloads models on first run to `~/.cache/audio-separator/`
   - Link to `/workspace/models/uvr5/` for shared volume

5. **Applio-RVC (LAST, after modifying requirements.txt):**
   ```bash
   cd /workspace/tools
   git clone https://github.com/IAHispano/Applio.git applio
   cd applio
   git checkout b8791412993ebc934c148bd84798782af2f0439e

   # CRITICAL: Patch requirements.txt to use PyTorch 2.5.1 + cu124
   sed -i 's/torch==2\.7\.1+cu128/torch==2.5.1+cu124/g' requirements.txt
   sed -i 's/torchvision==.*+cu128/torchvision==0.20.1+cu124/g' requirements.txt
   sed -i 's/torchaudio==.*+cu128/torchaudio==2.5.1+cu124/g' requirements.txt

   # Verify patch applied correctly
   grep -E "(torch|torchvision|torchaudio)==" requirements.txt

   pip install -r requirements.txt
   ```

   **Fallback if v3.5.1 has issues:**
   - Try commit `f17128bb3a6a` (includes "fix: Torch 2.5.0")
   - Or downgrade to PyTorch 2.4.1+cu124 (officially supported)

**Why this order:**
- PyTorch first ensures correct CUDA variant
- Lightweight tools next (fewer pins)
- Applio last (most opinionated requirements)

---

## Environment Strategy for v1

### ✅ Single Environment (v1 Default)

**This is the recommended approach for v1. Options B/C below are fallbacks only if this fails.**

**Setup:**
- One Python venv: `/workspace/venv`
- PyTorch 2.5.1 + CUDA 12.4
- Applio + audio-separator in same env

**Pros:**
- ✅ Simplest to build and maintain
- ✅ Lowest storage overhead
- ✅ audio-separator designed for modern PyTorch
- ✅ Shared audio libs (librosa, scipy) no duplication

**Cons:**
- ⚠️ If audio-separator has PyTorch conflicts, affects Applio too
- ⚠️ Dependency resolution must satisfy both tools

**Decision:** Use this for v1. Only consider fallbacks below if you encounter blocking issues.

---

## Fallback Environment Strategies (v2 - Only If Needed)

### ⚠️ Option B: Split Environment (If audio-separator conflicts with Applio)

**Setup:**
- Primary venv: `/workspace/venv` (Applio)
- Secondary venv: `/workspace/venv-uvr5` (official UVR5 GUI with CUDA 11.7)

**Pros:**
- ✅ Complete isolation (zero conflicts)
- ✅ Can use official UVR5 with its preferred CUDA 11.7
- ✅ Easier to troubleshoot tool-specific issues

**Cons:**
- ❌ More complex Dockerfile (multiple envs)
- ❌ Higher storage (~2-3GB extra for duplicate PyTorch)
- ❌ Need wrapper scripts to switch envs
- ❌ Official UVR5 is GUI-only (poor for headless)

**When to use:** Only if audio-separator has CUDA/dependency conflicts in shared env.

---

### ⚠️ Option C: Multi-Stage Docker (Advanced users / Phase 3 GPT-SoVITS)

**Setup:**
- Stage 1: Base CUDA image + shared deps
- Stage 2: Applio build (PyTorch 2.5.1 + cu124)
- Stage 3: UVR5 build (PyTorch + cu117, separate /)

**Pros:**
- ✅ Cleanest isolation
- ✅ Can optimize each stage separately
- ✅ Easy to swap out tools

**Cons:**
- ❌ Overkill for hobby v1
- ❌ More Dockerfile complexity
- ❌ Harder to experiment/modify

**Verdict:** Not for v1. Consider if you containerize GPT-SoVITS later.

---

## Simple Smoke Tests

### Applio-RVC Smoke Test

**Goal:** Confirm training and inference work on your GPU.

**Steps:**
1. **Prepare tiny dataset:**
   - 3-5 short WAV files (10-30 sec each, 16kHz or 48kHz mono)
   - Place in `/workspace/data/datasets/test_voice/0_gt_wavs/`

2. **Run minimal training via Web UI:**
   - Navigate to browser on port 6969
   - Training tab → Select dataset → Set epochs to 10 (fast)
   - Train for ~5 minutes (just to test, not real model)

3. **Run inference:**
   - Inference tab → Load trained .pth from `logs/test_voice/`
   - Upload a short test audio
   - Convert and download result

**Pass criteria:**
- ✅ Training completes without OOM or CUDA errors
- ✅ Inference produces audio output (quality doesn't matter for smoke test)
- ✅ No port access issues (can reach Web UI)

**Expected issues:**
- ⚠️ Warnings about deprecated PyTorch features (acceptable)
- ⚠️ "unsafe .pth file loading" warnings (acceptable for v1)

---

### audio-separator Smoke Test

**Goal:** Confirm vocal isolation works without VRAM exhaustion.

**Steps:**
1. **Download a test model:**
   ```bash
   audio-separator --list_models
   # Pick a light model like: model_bs_roformer_ep_317_sdr_12.9755.ckpt
   ```

2. **Run isolation on 60-sec clip:**
   ```bash
   audio-separator /workspace/data/raw/test.wav \
       --model_filename model_bs_roformer_ep_317_sdr_12.9755.ckpt \
       --output_dir /workspace/data/isolated/
   ```

3. **Check outputs:**
   - Should produce: `test_Vocals.wav` + `test_Instrumental.wav`

**Pass criteria:**
- ✅ Completes without CUDA OOM
- ✅ Outputs exist and are playable
- ✅ No ONNX Runtime CUDA errors

**If fails:**
- Try different model (MDX-Net models use less VRAM)
- Lower segment size: `--segment_size 128` (default 256)

---

### ⚠️ UVR5 Official GUI Smoke Test (REFERENCE ONLY - Likely to Fail)

**Note:** This test is included only for reference if you're using Option B (split env with official UVR5). **Expect this to fail in headless Docker containers.** This is why audio-separator is the primary recommendation.

**Goal:** Confirm GUI launches and processes audio (if using split env setup).

**Steps:**
1. Activate UVR5 venv: `source /workspace/venv-uvr5/bin/activate`
2. Launch GUI: `python UVR.py` (or main script)
3. Select model via GUI, load test audio, process
4. Check output folder

**Pass criteria (unlikely in Docker):**
- ✅ GUI launches without Tkinter errors
- ✅ Processing completes
- ✅ Outputs valid audio files

**Expected failures:**
- ❌ X11 forwarding errors (no display available)
- ❌ Tkinter initialization fails
- ❌ GUI widgets don't render

**Workaround:** Use CLI wrapper scripts or audio-separator instead of GUI.

---

## Configuration Checklist

**Before first run:**

- [ ] PyTorch 2.5.1 + cu124 confirmed: `python -c "import torch; print(torch.__version__, torch.version.cuda)"`
- [ ] Applio requirements.txt modified (torch 2.7.1→2.5.1, cu128→cu124)
- [ ] Folder structure created under `/workspace/`
- [ ] Applio Web UI accessible on port 6969
- [ ] audio-separator models downloaded or cached
- [ ] Sample test audio files prepared (raw + isolated vocals)
- [ ] GPU visible in container: `nvidia-smi`

**Post-smoke-test:**

- [ ] Applio training completed without OOM
- [ ] Applio inference produced output
- [ ] audio-separator isolated vocals from test clip
- [ ] No CUDA 11.7 vs 12.4 errors in logs
- [ ] Outputs saved to persistent `/workspace/` volume
