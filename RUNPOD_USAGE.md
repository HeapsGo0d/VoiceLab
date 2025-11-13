# VoiceLab RunPod Usage Guide

## Deploying Your Pod

### Option 1: Via RunPod Web Console
1. Go to [RunPod Templates](https://www.runpod.io/console/user/templates)
2. Click "New Template"
3. Upload the generated `voicelab-template.json`
4. Deploy a pod using your template

### Option 2: Via API (if you used --deploy)
Your template is already deployed! Find it in your RunPod templates list.

## Accessing Your Pod

Once your pod is running, you'll get a URL like:
```
http://[pod-id]-6969.proxy.runpod.net
```

This is your Applio Web UI interface.

## Workspace Structure

Your `/workspace` volume contains:
- `data/raw/` - Upload original audio files here
- `data/isolated/` - Vocal isolation outputs
- `data/datasets/` - Training datasets organized by voice
- `models/applio/` - Your trained RVC models
- `models/uvr5/` - UVR5 vocal removal model weights
- `outputs/` - Timestamped experiment results

## Common Workflows

### 1. Vocal Isolation (audio-separator)
```bash
# SSH into your pod or use terminal in RunPod
cd /workspace
audio-separator /workspace/data/raw/song.mp3 \
  --output_dir /workspace/data/isolated \
  --model_name UVR-MDX-NET-Inst_HQ_3
```

### 2. Voice Conversion (Applio Web UI)
1. Access Web UI at your pod URL
2. Go to "Train" tab
3. Upload audio samples to `/workspace/data/datasets/[voice-name]/`
4. Configure training parameters
5. Start training
6. Once complete, use "Inference" tab to convert voices

### 3. Model Management
- Trained models are saved to `/workspace/models/applio/`
- Models persist across pod restarts if you have a network volume
- Download models via the Web UI "Download" section

## Logs & Troubleshooting

### View startup logs:
```bash
docker exec -it [container-name] cat /tmp/voicelab_startup.log
```

### Check GPU:
```bash
nvidia-smi
```

### Restart Applio:
```bash
docker restart [container-name]
```

## Storage Notes

- **Ephemeral storage** (container disk): Lost when pod is terminated
- **Network volume** (persistent): Survives pod termination, costs more
- Store important models and datasets on network volume (`/workspace`)

## Authentication

If you set an Applio password during template creation:
- Username: `admin`
- Password: (whatever you configured)

## Support

- Documentation: https://github.com/HeapsGo0d/VoiceLab
- Issues: https://github.com/HeapsGo0d/VoiceLab/issues
- Applio Docs: https://docs.applio.org/

---

**Happy voice experimenting!** 🎤
