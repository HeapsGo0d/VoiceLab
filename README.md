# VoiceLab 🎤

**Voice AI Experimentation Container for RunPod**

A stability-first, reproducible Docker environment for voice conversion and vocal isolation experiments using modern AI tools. Built for hobby use with RTX 4090/5090 GPUs on RunPod.

---

## What is this?

VoiceLab is a containerized voice AI playground featuring:
- **Applio-RVC** - Modern voice conversion (RVC) with an excellent Web UI
- **audio-separator** - CLI-based vocal isolation using UVR5 models
- **PyTorch 2.5.1 + CUDA 12.4** - Stable, modern ML stack
- **RunPod-optimized** - Designed for remote GPU experimentation

**Use case:** Personal voice conversion experiments for rap/singing, including celeb-style voices for private tinkering (non-commercial, hobby use).

---

## Current Status

**Phase 1: Planning & Research** ✅ COMPLETE
- Stack selection finalized
- Compatibility research done
- Environment strategy decided
- Documentation written

**Phase 2: Base Container Build** 🚧 IN PROGRESS
- Dockerfile implementation next
- See [Next Steps](docs/planning/04_next_steps.md)

---

## Quick Links

### Planning Documentation
- **[Stack Overview](docs/planning/01_stack_overview.md)** - Tool versions, compatibility matrix, VRAM requirements
- **[Integration Notes](docs/planning/02_integration_notes.md)** - Folder structure, installation order, smoke tests
- **[Recommendations](docs/planning/03_recommendations.md)** - Go/no-go decisions, GPU tiers, risk fallbacks
- **[Next Steps](docs/planning/04_next_steps.md)** - Phase 2-5 roadmap, timeline, action items

---

## Tech Stack

### Core Tools (v1)
| Tool | Purpose | Version/Commit | Status |
|------|---------|---------------|--------|
| **Applio-RVC** | Voice conversion | [`b879141`](https://github.com/IAHispano/Applio/commit/b8791412993ebc934c148bd84798782af2f0439e) (v3.5.1) | ✅ Primary |
| **audio-separator** | Vocal isolation | Latest (PyPI) | ✅ Primary |
| **GPT-SoVITS v3** | TTS/voice cloning | Latest stable | 🚫 Deferred to Phase 3 |

### Base Stack
- **Base Image:** `nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04`
- **PyTorch:** 2.5.1 with CUDA 12.4
- **Python:** 3.10 or 3.11

---

## Key Decisions

### ✅ What We're Using
- **Applio-RVC** as primary voice conversion tool (best RVC fork for ease of use)
- **audio-separator** instead of official UVR5 GUI (CLI-friendly, CUDA 12 compatible)
- **Single shared environment** (PyTorch 2.5.1 + CUDA 12.4)
- **RTX 4090 (24GB) or 5090 (32GB)** - Zero VRAM concerns, future-proof

### 🚫 What We're NOT Using (Yet)
- Official UVR5 GUI (CUDA 11.7 conflicts, GUI-only design)
- GPT-SoVITS v3 in v1 (deferred to Phase 3 / separate container)
- Multi-GPU training (broken in Applio #1153)

---

## Hardware Requirements

### Recommended (Your Setup)
- **GPU:** RTX 4090 (24GB) or RTX 5090 (32GB)
- **VRAM:** 24GB+ (excellent for all tools, future-proof)
- **Storage:** 50-100GB persistent volume

### Minimum (Budget Tier)
- **GPU:** RTX 3060 12GB or RTX 4070 12GB
- **VRAM:** 12GB (comfortable for v1 tools)
- **Storage:** 30GB persistent volume

### Not Recommended
- GPUs with <8GB VRAM (too tight for training)
- Non-NVIDIA GPUs (no CUDA support)

---

## Project Structure

```
/workspace/                     # Persistent storage (survives container restarts)
├── tools/
│   ├── applio/                # Applio-RVC installation
│   └── audio-separator/       # (if installed separately)
│
├── data/
│   ├── raw/                   # Original audio files
│   ├── isolated/              # Vocal isolation outputs
│   └── datasets/              # Training datasets (by voice name)
│
├── models/
│   ├── applio/                # Trained RVC models
│   ├── uvr5/                  # UVR model weights
│   └── pretraineds/           # Base pretrained models
│
└── outputs/                   # Experiment results (timestamped)
```

---

## Getting Started

### Phase 2: Build the Container (Next Steps)

1. **Review planning docs** (see [docs/planning/](docs/planning/))
2. **Create Dockerfile** (see [04_next_steps.md](docs/planning/04_next_steps.md))
3. **Build and test locally or on RunPod**
4. **Run smoke tests** (see [02_integration_notes.md](docs/planning/02_integration_notes.md))
5. **Deploy to RunPod with persistent storage**

**Estimated time:** 4-6 hours focused work → working v1 container

**Detailed roadmap:** See [Next Steps](docs/planning/04_next_steps.md)

---

## Features (Planned)

### v1 (Stability First)
- ✅ Applio Web UI (port 6969)
- ✅ audio-separator CLI
- ✅ Persistent storage for models and datasets
- ✅ Smoke tests for validation
- ✅ RunPod-optimized deployment

### v2 (Polish)
- 🔄 Workflow automation scripts
- 🔄 Common workflow documentation
- 🔄 Troubleshooting guide
- 🔄 Dockerfile optimization

### v3 (Advanced)
- 📅 GPT-SoVITS v3 integration (optional TTS)
- 📅 REST API for automation
- 📅 Batch processing tools
- 📅 Model gallery and sharing

---

## Key Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Applio PyTorch 2.5.1 compatibility | 🟡 MEDIUM | Modify requirements.txt, fallback commits documented |
| audio-separator CUDA/ONNX issues | 🟡 MEDIUM | ort-nightly-gpu fallback, or separate UVR5 env |
| Multi-GPU training broken | 🟢 LOW | Use single GPU (not an issue for 4090/5090) |
| Index file conversion failures | 🟡 MEDIUM | Train without index, or downgrade to v3.4 |

**Full risk analysis:** See [Recommendations](docs/planning/03_recommendations.md)

---

## Design Philosophy

### Priorities
1. **Stability over bleeding edge** - Use proven, stable releases
2. **Reproducibility** - Pin commits, document versions
3. **Simplicity** - Single environment when possible
4. **Fun over perfection** - Good enough for v1, iterate later

### Non-Priorities
- Production-grade reliability
- Multi-tenancy or security hardening
- Micro-optimizations (with 24GB VRAM, not needed)
- Real-time voice conversion (not feasible on RunPod)

---

## Contributing

This is a personal hobby project, but feel free to:
- Open issues for bugs or suggestions
- Share your own forks or improvements
- Document your experiments (PRs welcome for workflow docs)

**Note:** This repo is for learning and experimentation. Don't expect production support or rapid responses.

---

## License

This project is for personal, non-commercial use. Individual tools have their own licenses:
- **Applio:** MIT License (check repo)
- **audio-separator:** MIT License (check repo)
- **UVR5:** Varies by model (check licenses)

**Usage note:** Voice conversion/cloning should respect copyright and personality rights. Use responsibly and ethically.

---

## Acknowledgments

**Tools:**
- [Applio-RVC](https://github.com/IAHispano/Applio) by IAHispano - Excellent RVC implementation
- [audio-separator](https://github.com/nomadkaraoke/python-audio-separator) - CLI vocal isolation
- [Ultimate Vocal Remover (UVR5)](https://github.com/Anjok07/ultimatevocalremovergui) - Original vocal removal models

**Research:**
- RVC (Retrieval-based Voice Conversion) community
- PyTorch and NVIDIA CUDA teams
- RunPod for accessible GPU compute

---

## Support & Resources

- **Documentation:** See [docs/planning/](docs/planning/)
- **Issues:** Use GitHub Issues for bugs/questions
- **Discussions:** Use GitHub Discussions for general chat

**External Resources:**
- [RunPod Docs](https://docs.runpod.io/)
- [Applio Documentation](https://docs.applio.org/)
- [RVC Community Discord](https://discord.gg/rvc) (unofficial)

---

## Roadmap

- [x] Phase 1: Planning & Research (Nov 2024)
- [ ] Phase 2: Base Container Build (Target: Dec 2024)
- [ ] Phase 3: RunPod Deployment (Target: Dec 2024)
- [ ] Phase 4: Workflows & Documentation (Target: Jan 2025)
- [ ] Phase 5: Advanced Features (Target: Feb 2025+)

**Status:** Currently in Phase 2 kickoff. See [Next Steps](docs/planning/04_next_steps.md) for detailed timeline.

---

**Built with 🎵 for voice AI experimentation**
