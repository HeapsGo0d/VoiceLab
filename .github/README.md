# GitHub Actions Workflows

This directory contains automated workflows for VoiceLab.

## Workflows

### `build-and-push.yml` - Automated Docker Build & Push

**Triggers:** On version tags (`v*` pattern, e.g., `v1.0.0`, `v1.0.1`)

**What it does:**
1. Frees up ~30GB disk space (Android SDK, .NET, Haskell, etc.)
2. Builds VoiceLab Docker image (~12-15GB)
3. Pushes to Docker Hub with version tag + `latest`
4. Uses GitHub Actions cache for faster rebuilds
5. Cleans up old tags (keeps latest 3 versions)

**Build time:** ~20-30 minutes on GitHub runners

---

## Setup Instructions

### 1. Create Docker Hub Access Token

1. Go to https://hub.docker.com/settings/security
2. Click **New Access Token**
3. Name: `github-actions-voicelab`
4. Permissions: **Read & Write**
5. Click **Generate**
6. **Copy the token** (you won't see it again!)

### 2. Add GitHub Secrets

1. Go to your repo: https://github.com/HeapsGo0d/VoiceLab/settings/secrets/actions
2. Click **New repository secret**
3. Add two secrets:

**Secret 1: DOCKER_USERNAME**
- Name: `DOCKER_USERNAME`
- Value: Your Docker Hub username (e.g., `heapsg00d`)

**Secret 2: DOCKER_PASSWORD**
- Name: `DOCKER_PASSWORD`
- Value: The access token you just created

---

## Usage

### Trigger a Build

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

This will automatically:
- Build the Docker image
- Tag as `yourusername/voicelab:v1.0.0`
- Tag as `yourusername/voicelab:latest`
- Push to Docker Hub
- Clean up old versions

### View Build Progress

1. Go to: https://github.com/HeapsGo0d/VoiceLab/actions
2. Click on the latest workflow run
3. Watch live build logs

### Use the Built Image

Once the workflow succeeds, anyone can pull your image:

```bash
# Pull specific version
docker pull yourusername/voicelab:v1.0.0

# Pull latest
docker pull yourusername/voicelab:latest

# Run on RunPod
# Use: yourusername/voicelab:latest as the container image
```

---

## Troubleshooting

### Build Fails: "Authentication required"

**Problem:** Docker Hub secrets not configured

**Fix:**
1. Check secrets exist: https://github.com/HeapsGo0d/VoiceLab/settings/secrets/actions
2. Verify `DOCKER_USERNAME` matches your Docker Hub username (case-sensitive)
3. Verify `DOCKER_PASSWORD` is a valid access token (not your password)
4. Regenerate token if needed

### Build Fails: "No space left on device"

**Problem:** GitHub runner ran out of disk space

**Fix:**
- Already handled by `free-disk-space` action
- If still failing, the image may be too large (>12-15GB)
- Consider optimizing Dockerfile with multi-stage build

### Cleanup Fails: "Failed to authenticate with Docker Hub"

**Problem:** Token expired or invalid

**Fix:**
1. Regenerate Docker Hub token
2. Update `DOCKER_PASSWORD` secret in GitHub

### Tag Already Exists

**Problem:** Pushed same tag twice

**Fix:**
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Recreate with new commit
git tag v1.0.0
git push origin v1.0.0
```

---

## Workflow Details

### Disk Space Management

VoiceLab's Docker image is large (~12-15GB). The workflow frees up ~30GB before building:
- Tool cache: ~15GB
- Android SDK: ~11GB
- .NET: ~2GB
- Haskell: ~2.7GB

### Cache Strategy

Uses GitHub Actions cache to speed up rebuilds:
- `cache-from: type=gha` - Reuses layers from previous builds
- `cache-to: type=gha,mode=max` - Saves all layers for next build

**First build:** ~25-30 minutes
**Cached builds:** ~10-15 minutes (if Dockerfile unchanged)

### Tag Retention

Keeps latest 3 version tags + current tag:
- Prevents Docker Hub storage bloat
- Retains recent history for rollbacks
- Automatically deletes older versions

**Example:**
- Tags: `v1.0.0`, `v1.0.1`, `v1.0.2`, `v1.0.3`, `v1.0.4`
- After `v1.0.4` build: Keeps `v1.0.2`, `v1.0.3`, `v1.0.4` + `latest`
- Deletes: `v1.0.0`, `v1.0.1`

---

## Manual Build (Without Workflow)

If you need to build/push manually:

```bash
# Build locally
./scripts/build.sh

# Tag for Docker Hub
docker tag voicelab:v1 yourusername/voicelab:v1.0.0
docker tag voicelab:v1 yourusername/voicelab:latest

# Login to Docker Hub
docker login

# Push
docker push yourusername/voicelab:v1.0.0
docker push yourusername/voicelab:latest
```

---

## Cost Considerations

**GitHub Actions:**
- Public repos: Free unlimited minutes
- Private repos: 2,000 free minutes/month (VoiceLab uses ~25-30 min per build)

**Docker Hub:**
- Free tier: Unlimited public repos
- Rate limits: 200 pulls/6hr for anonymous, unlimited for authenticated
- Storage: No explicit limit for free tier (reasonable use)

---

## Next Steps After Setup

1. **Test the workflow:**
   ```bash
   git tag v0.1.0-test
   git push origin v0.1.0-test
   ```

2. **Monitor first build:** https://github.com/HeapsGo0d/VoiceLab/actions

3. **Verify on Docker Hub:** https://hub.docker.com/r/yourusername/voicelab/tags

4. **Test pulling image:**
   ```bash
   docker pull yourusername/voicelab:latest
   docker run --gpus all -p 6969:6969 yourusername/voicelab:latest
   ```

5. **Update RunPod template** with your Docker Hub image

---

## Resources

- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Docker Hub:** https://hub.docker.com/
- **Workflow syntax:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- **Docker build-push action:** https://github.com/docker/build-push-action
