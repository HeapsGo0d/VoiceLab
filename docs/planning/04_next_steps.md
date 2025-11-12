# Next Steps - Roadmap to v1 Container

## Current Status

✅ **Phase 1: Planning & Research** - COMPLETE
- Stack selection finalized (Applio + audio-separator)
- Compatibility matrix documented
- GPU tier selected (RTX 4090/5090)
- Environment strategy decided (single shared env)
- Folder structure designed
- Smoke tests defined
- Risks identified with fallbacks

---

## Phase 2: Base Container Build

**Goal:** Create a working Dockerfile that builds the v1 container with Applio + audio-separator.

### 2.1 Create Dockerfile

**Location:** `/Dockerfile`

**Structure:**
```dockerfile
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# System deps
# Python 3.10 setup
# PyTorch 2.5.1 + cu124
# audio-separator
# Applio (with modified requirements.txt)
# Workspace setup
# Port exposure (6969)
# Entrypoint script
```

**Key tasks:**
- [ ] Write base Dockerfile
- [ ] Create entrypoint script (starts Applio Web UI)
- [ ] Add health check (verify Gradio is running)
- [ ] Document build process

**Estimated time:** 2-3 hours (including testing)

---

### 2.2 Modify Applio Requirements

**Critical step:** Before installing Applio in the Dockerfile, modify its `requirements.txt`.

**Options:**

**Option A: Patch during build (Recommended)**
```dockerfile
RUN cd /workspace/tools/applio && \
    sed -i 's/torch==2.7.1+cu128/torch==2.5.1+cu124/g' requirements.txt && \
    sed -i 's/torchvision==.*+cu128/torchvision==0.20.1+cu124/g' requirements.txt && \
    sed -i 's/torchaudio==.*+cu128/torchaudio==2.5.1+cu124/g' requirements.txt
```

**Option B: Pre-patched fork (Overkill)**
- Fork Applio repo
- Commit patched requirements.txt
- Clone your fork in Dockerfile

**Verdict:** Use Option A (simpler, no fork maintenance).

---

### 2.3 Build and Test Locally

**Pre-requisites:**
- Docker installed with NVIDIA Container Toolkit
- NVIDIA GPU with drivers (or use RunPod for testing)

**Build command:**
```bash
docker build -t voicelab:v1 .
```

**Run command:**
```bash
docker run --gpus all -p 6969:6969 \
    -v $(pwd)/workspace:/workspace \
    voicelab:v1
```

**Verify:**
- [ ] Container starts without errors
- [ ] PyTorch detects CUDA 12.4: `docker exec <container> python -c "import torch; print(torch.version.cuda)"`
- [ ] Applio Web UI accessible at `http://localhost:6969`
- [ ] audio-separator CLI available: `docker exec <container> audio-separator --help`

**Estimated time:** 1-2 hours (including build time)

---

### 2.4 Run Smoke Tests

**Use smoke tests from `02_integration_notes.md`:**

1. **Applio smoke test:**
   - Prepare 3-5 short WAV files
   - Copy to container: `docker cp test_audio/ <container>:/workspace/data/datasets/test_voice/0_gt_wavs/`
   - Train tiny model (10 epochs)
   - Run inference
   - Verify output audio exists

2. **audio-separator smoke test:**
   - Copy test audio: `docker cp test.wav <container>:/workspace/data/raw/`
   - Run isolation: `docker exec <container> audio-separator /workspace/data/raw/test.wav --model_filename <model> --output_dir /workspace/data/isolated/`
   - Verify vocals + instrumental outputs

**Pass criteria:**
- Both tests complete without CUDA errors
- Outputs are valid audio files
- No critical errors in logs

**Estimated time:** 1 hour

---

## Phase 3: RunPod Deployment

**Goal:** Deploy the working container to RunPod with persistent storage.

### 3.1 Push Image to Registry

**Options:**

**Option A: Docker Hub (Public)**
```bash
docker tag voicelab:v1 yourusername/voicelab:v1
docker push yourusername/voicelab:v1
```

**Option B: Docker Hub (Private)**
- Same as above, but create private repo on Docker Hub
- Configure RunPod with Docker Hub credentials

**Option C: GitHub Container Registry (GHCR)**
```bash
docker tag voicelab:v1 ghcr.io/yourusername/voicelab:v1
docker push ghcr.io/yourusername/voicelab:v1
```

**Recommended:** Docker Hub (public) for v1 simplicity, switch to private/GHCR for v2 if needed.

---

### 3.2 Configure RunPod Pod

**Pod settings:**
- **Template:** Custom (use your Docker image)
- **GPU:** RTX 4090 (24GB) - Community Cloud for cost savings
- **Container Image:** `yourusername/voicelab:v1`
- **Ports:** Expose 6969 (HTTP)
- **Volume:** Attach persistent network volume (50-100GB)
  - Mount point: `/workspace`
  - This survives pod restarts
- **Environment Variables:**
  - `GRADIO_SERVER_NAME=0.0.0.0`
  - `GRADIO_SERVER_PORT=6969`

**Auto-pause settings:**
- Enable auto-pause after 15 minutes idle
- Saves $ when not actively using

**Estimated time:** 30 minutes (including initial pod spin-up)

---

### 3.3 Access and Verify

**Access Applio Web UI:**
- RunPod provides a public URL (e.g., `https://12345-6969.proxy.runpod.net`)
- Open in browser, verify Web UI loads

**Connect via SSH (optional):**
```bash
ssh root@<runpod-pod-id>.runpod.io -p <port>
```

**Verify storage persistence:**
- Upload test audio via Web UI
- Train a small model
- Stop pod
- Restart pod
- Verify model still exists in `/workspace/models/`

**Estimated time:** 30 minutes

---

## Phase 4: Production Workflow & Documentation

**Goal:** Establish repeatable workflows for voice conversion experiments.

### 4.1 Create Workflow Scripts (PLANNED - Not Yet Implemented)

**Scripts to add in `/scripts/` directory:**

**Note:** These scripts are planned for Phase 4 and do not exist yet in the repository.

**`isolate_vocals.sh`** (planned) - Wrapper for audio-separator
```bash
#!/bin/bash
# Usage: ./scripts/isolate_vocals.sh input.wav output_dir/
audio-separator "$1" \
    --model_filename model_bs_roformer_ep_317_sdr_12.9755.ckpt \
    --output_dir "$2"
```

**`prepare_dataset.sh`** (planned) - Organize isolated vocals for Applio training
```bash
#!/bin/bash
# Usage: ./scripts/prepare_dataset.sh voice_name isolated_vocals_dir/
mkdir -p /workspace/data/datasets/$1/0_gt_wavs/
cp $2/*.wav /workspace/data/datasets/$1/0_gt_wavs/
```

**`backup_model.sh`** (planned) - Export trained model from container
```bash
#!/bin/bash
# Usage: ./scripts/backup_model.sh voice_name
tar -czf /workspace/outputs/backup_${1}_$(date +%Y%m%d).tar.gz \
    /workspace/tools/applio/logs/$1/ \
    /workspace/tools/applio/weights/$1.*
```

---

### 4.2 Document Common Workflows (PLANNED - Not Yet Implemented)

**Create:** `/docs/workflows/` directory

**Note:** These workflow documents are planned for Phase 4 and do not exist yet in the repository.

**`01_voice_conversion_basic.md`** (planned) - End-to-end voice conversion
1. Upload raw audio with target voice
2. Isolate vocals using audio-separator
3. Prepare dataset for Applio
4. Train RVC model (Web UI)
5. Run inference on test audio
6. Download converted results

**`02_training_tips.md`** (planned) - Best practices
- Optimal audio quality (sample rate, format)
- Dataset size recommendations (3-5 min for hobby, 10-30 min for better quality)
- Training parameters (epochs, batch size)
- Common errors and fixes

**`03_troubleshooting.md`** (planned) - Debug guide
- CUDA OOM errors (shouldn't happen with 4090)
- Audio quality issues (pitch, artifacts)
- Training instability
- Web UI connection problems

---

### 4.3 Optimize Dockerfile (Optional)

**Improvements for v1.1:**
- Multi-stage build (reduce final image size)
- Layer caching optimization (faster rebuilds)
- Pre-download common UVR models (avoid first-run downloads)
- Add Jupyter notebook support (for experimentation)

**Estimated time:** 2-3 hours

---

## Phase 5: Advanced Features (v2/v3)

**These are post-v1 enhancements. Only tackle after v1 is stable and fun to use.**

### 5.1 Add GPT-SoVITS v3 (Optional)

**Decision point:** After using v1 for a few weeks, decide if you want TTS capabilities.

**If yes:**
- Create separate container OR multi-stage Dockerfile
- Use PyTorch 2.5.1 + CUDA 12.4 (compatible)
- Test v4 branch (may be stable by then)
- Add smoke tests for TTS inference

**Estimated time:** 4-6 hours

---

### 5.2 Automation & API Integration

**Features:**
- REST API wrapper for Applio (trigger training/inference via API)
- Batch processing scripts (convert multiple files)
- Integration with Discord bot (fun experiments)
- Web dashboard (track experiments, compare models)

**Tools:**
- FastAPI for REST API
- Celery for background tasks
- SQLite for experiment tracking

**Estimated time:** 8-12 hours

---

### 5.3 Model Gallery & Sharing

**Features:**
- Organize trained models with metadata (dataset size, training time, quality notes)
- Export/import model packages
- Share models with friends (via Hugging Face Hub)

**Estimated time:** 3-4 hours

---

## Timeline Estimate

**Realistic hobby schedule (assuming 5-10 hrs/week):**

| Phase | Duration | Calendar Time |
|-------|----------|---------------|
| Phase 1: Planning | ✅ Complete | 1 day |
| Phase 2: Base Container Build | 4-6 hours | 1-2 weeks |
| Phase 3: RunPod Deployment | 1-2 hours | 1 day |
| Phase 4: Workflows & Docs | 3-5 hours | 1 week |
| **Total for stable v1** | **8-13 hours** | **3-4 weeks** |
| Phase 5: Advanced Features | 15-25 hours | 3-6 weeks |

**Aggressive schedule (full weekend sprint):**
- Phase 2-3: Saturday (8 hours)
- Phase 4: Sunday (4 hours)
- **v1 ready in 1 weekend** (12 hours focused work)

---

## Blockers & Dependencies

**Phase 2 blockers:**
- Need Docker installed locally OR RunPod account for testing
- Need test audio files (can use royalty-free samples)

**Phase 3 blockers:**
- Need RunPod account with payment method
- Need Docker registry account (Docker Hub, GHCR, etc.)

**Phase 4 blockers:**
- None (can iterate on running container)

---

## Success Metrics

**v1 is "done" when:**
- [ ] Dockerfile builds without errors
- [ ] Container runs on RunPod with 4090
- [ ] Applio Web UI accessible remotely
- [ ] Both smoke tests pass (Applio + audio-separator)
- [ ] Can complete one full voice conversion workflow end-to-end
- [ ] Models persist across pod restarts
- [ ] Basic documentation exists for common workflows

**v1 is "fun to use" when:**
- [ ] Can train a new voice in <1 hour of hands-on time
- [ ] Can convert audio without consulting docs (intuitive Web UI)
- [ ] No mysterious crashes or CUDA errors
- [ ] Storage costs are predictable and reasonable
- [ ] Can experiment with different voices without fear of breaking things

---

## Recommended Next Action

**Start here:**

1. **Create base Dockerfile** (90 minutes)
   - Copy structure from planning docs
   - Focus on getting build to succeed first (don't optimize yet)

2. **Test build locally or on RunPod GPU instance** (60 minutes)
   - If local GPU available: `docker build && docker run`
   - If no local GPU: Spin up cheap RunPod instance, SSH in, build there

3. **Run one smoke test** (30 minutes)
   - Start with audio-separator (simpler)
   - Verify CUDA works and outputs are correct

4. **Iterate on Dockerfile until both smoke tests pass** (1-2 hours)
   - Fix dependency conflicts
   - Adjust PyTorch version if needed
   - Add missing system packages

5. **Push to Docker Hub and deploy to RunPod** (30 minutes)
   - Tag and push image
   - Create RunPod template
   - Spin up persistent pod

**Total time to first working v1:** 4-6 hours of focused work.

---

## Questions to Decide Before Phase 2

1. **Docker registry preference?**
   - Docker Hub (easiest)
   - GitHub Container Registry (more integrated with repo)
   - Other (AWS ECR, Google GCR)

2. **RunPod account ready?**
   - If not, create account and add payment method
   - Community Cloud (cheaper) or Secure Cloud (guaranteed availability)

3. **Test audio sources?**
   - Have some sample audio files ready (MP3/WAV, 30-60 sec clips)
   - Can use royalty-free music from YouTube Audio Library

4. **Naming conventions?**
   - Docker image name: `voicelab`, `rvc-lab`, `voice-ai-pod`?
   - Voice model names: How will you name experiments?

---

## Resources & Links

**Official Repos:**
- Applio: https://github.com/IAHispano/Applio
- audio-separator: https://github.com/nomadkaraoke/python-audio-separator
- UVR5 (reference): https://github.com/Anjok07/ultimatevocalremovergui

**Docker & RunPod:**
- NVIDIA Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
- RunPod Docs: https://docs.runpod.io/
- RunPod Templates: https://www.runpod.io/console/gpu-cloud

**Testing Resources:**
- Royalty-free audio: https://www.youtube.com/audiolibrary
- Test voice datasets: https://commonvoice.mozilla.org/
- RVC community models: https://huggingface.co/models?search=rvc

**Useful Tutorials:**
- Applio basic usage: https://www.youtube.com/results?search_query=applio+rvc+tutorial
- RVC training tips: https://docs.google.com/document/d/13-NM18sx1HmZ3RYpf46dHjZZ09NeaoFCjNXXIfgUo9w (community guide)

---

## Final Thoughts

You're well-positioned for a smooth v1 build:
- ✅ Clear plan with specific commits
- ✅ Environment strategy decided
- ✅ 4090/5090 eliminates VRAM concerns
- ✅ Fallbacks documented for likely issues
- ✅ Smoke tests defined for validation

**Philosophy for Phase 2:**
- Get it working first, optimize later
- Don't chase perfection on v1 (it's for learning)
- If you hit a blocker, consult the fallbacks in `03_recommendations.md`
- Document weird issues as you go (future-you will thank you)

**Most important:** Have fun! This is hobby experimentation, not a production deployment. If something breaks, it's a learning opportunity, not a failure.

Ready to build? Start with the Dockerfile and iterate from there. 🚀
