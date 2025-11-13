#!/bin/bash
# VoiceLab RunPod Template Creator
# Creates a RunPod template for deploying VoiceLab voice AI container
# Usage:
#   ./template.sh           # Generate local template.json
#   ./template.sh --deploy  # Deploy directly via RunPod API

set -e

# ============================================================================
# Color Variables
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ============================================================================
# Configuration Defaults
# ============================================================================
DOCKER_IMAGE="heapsgo0d/voicelab"
VERSION_TAG="v0.0.2"
TEMPLATE_NAME="VoiceLab - Voice AI Experimentation"
CONTAINER_DISK_GB=${CONTAINER_DISK_GB:-50}
VOLUME_GB=${VOLUME_GB:-100}
DEPLOY_MODE=false

# ============================================================================
# Parse Command Line Arguments
# ============================================================================
for arg in "$@"; do
    case $arg in
        --deploy)
            DEPLOY_MODE=true
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--deploy]"
            exit 1
            ;;
    esac
done

# ============================================================================
# Helper Functions
# ============================================================================

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╦  ╦┌─┐┬┌─┐┌─┐╦  ┌─┐┌┐
╚╗╔╝│ │││  ├┤ ║  ├─┤├┴┐
 ╚╝ └─┘┴└─┘└─┘╩═╝┴ ┴└─┘

RunPod Template Creator
EOF
    echo -e "${NC}"
}

print_usage() {
    echo -e "${WHITE}This script creates a RunPod template for VoiceLab${NC}"
    echo ""
    echo -e "${YELLOW}Two modes available:${NC}"
    echo -e "  1. ${GREEN}Local mode${NC} (default): Generates template.json for manual upload"
    echo -e "  2. ${GREEN}API mode${NC} (--deploy): Deploys directly via RunPod API"
    echo ""
    echo -e "${CYAN}You'll be prompted for:${NC}"
    echo "  • Applio Web UI password (optional)"
    echo "  • Container disk size (default: ${CONTAINER_DISK_GB}GB)"
    echo "  • Persistent volume size (default: ${VOLUME_GB}GB)"
    echo ""
}

check_api_requirements() {
    if [[ -z "$RUNPOD_API_KEY" ]]; then
        echo -e "${RED}Error: RUNPOD_API_KEY environment variable not set${NC}"
        echo ""
        echo "To deploy via API, first set your API key:"
        echo "  export RUNPOD_API_KEY='your-api-key-here'"
        echo ""
        echo "Get your API key from: https://www.runpod.io/console/user/settings"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl command not found${NC}"
        echo "Please install curl to use API deployment"
        exit 1
    fi
}

get_configuration() {
    echo -e "${YELLOW}=== Configuration ===${NC}"
    echo ""

    # Applio password
    echo -e "${CYAN}Applio Web UI Password (optional, press Enter to skip):${NC}"
    read -r -p "> " APPLIO_PASSWORD

    # Container disk size
    echo ""
    echo -e "${CYAN}Container disk size in GB (default: ${CONTAINER_DISK_GB}):${NC}"
    read -r -p "> " input_container_disk
    if [[ -n "$input_container_disk" ]]; then
        CONTAINER_DISK_GB="$input_container_disk"
    fi

    # Volume size
    echo ""
    echo -e "${CYAN}Persistent volume size in GB (default: ${VOLUME_GB}, 0 for ephemeral):${NC}"
    read -r -p "> " input_volume
    if [[ -n "$input_volume" ]]; then
        VOLUME_GB="$input_volume"
    fi

    echo ""
}

generate_template() {
    local output_file="voicelab-template.json"

    echo -e "${YELLOW}=== Generating Template ===${NC}"

    # Build environment variables array
    local env_vars=""

    if [[ -n "$APPLIO_PASSWORD" ]]; then
        env_vars="${env_vars}{\"key\": \"APPLIO_PASSWORD\", \"value\": \"$APPLIO_PASSWORD\"},"
    fi

    # Remove trailing comma if present
    env_vars="${env_vars%,}"

    # If no env vars, use empty array
    if [[ -z "$env_vars" ]]; then
        env_vars=""
    fi

    # Create storage note
    local storage_note=$(make_storage_note)

    # Generate JSON
    cat > "$output_file" << EOF
{
  "name": "$TEMPLATE_NAME",
  "imageName": "$DOCKER_IMAGE:$VERSION_TAG",
  "dockerArgs": "",
  "startScript": "/scripts/startup.sh",
  "env": [${env_vars}],
  "ports": [
    {
      "privatePort": 6969,
      "publicPort": 6969,
      "type": "http",
      "description": "Applio Web UI"
    }
  ],
  "volumeMounts": [
    {
      "containerPath": "/workspace",
      "name": "workspace"
    }
  ],
  "containerDiskInGb": $CONTAINER_DISK_GB,
  "volumeInGb": $VOLUME_GB,
  "volumeMountPath": "/workspace",
  "readme": "$storage_note\n\n## VoiceLab - Voice AI Experimentation\n\nDocker-based platform for voice conversion and vocal isolation with RTX 4090/5090 GPUs.\n\n### Features:\n- Applio-RVC v3.5.1 for voice conversion\n- audio-separator for vocal isolation\n- PyTorch 2.5.1 + CUDA 12.4\n- Web UI on port 6969\n\n### Access:\nOnce the pod starts, access Applio Web UI at:\nhttp://[pod-id]-6969.proxy.runpod.net\n\n### Workspace:\n- /workspace/data/raw - Upload audio files\n- /workspace/data/isolated - Vocal isolation outputs\n- /workspace/data/datasets - Training datasets\n- /workspace/models - Trained RVC models\n- /workspace/outputs - Experiment results\n\n### Documentation:\nhttps://github.com/HeapsGo0d/VoiceLab"
}
EOF

    echo -e "${GREEN}✓ Template saved to: $output_file${NC}"
    return 0
}

make_storage_note() {
    if [[ "$VOLUME_GB" -eq 0 ]]; then
        echo "**Storage:** ${CONTAINER_DISK_GB}GB ephemeral (no persistence)"
    else
        echo "**Storage:** ${CONTAINER_DISK_GB}GB ephemeral + ${VOLUME_GB}GB persistent"
    fi
}

print_summary() {
    echo ""
    echo -e "${YELLOW}=== Configuration Summary ===${NC}"
    echo -e "${WHITE}Docker Image:${NC} $DOCKER_IMAGE:$VERSION_TAG"
    echo -e "${WHITE}Template Name:${NC} $TEMPLATE_NAME"
    echo -e "${WHITE}Container Disk:${NC} ${CONTAINER_DISK_GB}GB"
    echo -e "${WHITE}Persistent Volume:${NC} ${VOLUME_GB}GB"
    if [[ -n "$APPLIO_PASSWORD" ]]; then
        echo -e "${WHITE}Applio Password:${NC} ********"
    else
        echo -e "${WHITE}Applio Password:${NC} (not set)"
    fi
    echo ""
}

generate_instructions() {
    cat > RUNPOD_USAGE.md << 'EOF'
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
EOF

    echo -e "${GREEN}✓ Usage guide saved to: RUNPOD_USAGE.md${NC}"
}

deploy_template() {
    echo -e "${YELLOW}=== Deploying via RunPod API ===${NC}"

    # Build environment variables for API (different format)
    local env_json="[]"
    if [[ -n "$APPLIO_PASSWORD" ]]; then
        env_json="[{\"key\": \"APPLIO_PASSWORD\", \"value\": \"$APPLIO_PASSWORD\"}]"
    fi

    # Build the GraphQL mutation
    local mutation_json=$(cat <<EOF
{
  "query": "mutation saveTemplate(\$input: SaveTemplateInput!) { saveTemplate(input: \$input) { id name imageName } }",
  "variables": {
    "input": {
      "name": "$TEMPLATE_NAME",
      "imageName": "$DOCKER_IMAGE:$VERSION_TAG",
      "dockerArgs": "",
      "startScript": "/scripts/startup.sh",
      "env": $env_json,
      "ports": "6969/http",
      "containerDiskInGb": $CONTAINER_DISK_GB,
      "volumeInGb": $VOLUME_GB,
      "volumeMountPath": "/workspace"
    }
  }
}
EOF
)

    # Make API call
    echo -e "${CYAN}Sending request to RunPod API...${NC}"
    local response=$(curl -s -X POST \
        "https://api.runpod.io/graphql" \
        -H "Authorization: Bearer $RUNPOD_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$mutation_json")

    # Check for errors
    if echo "$response" | grep -q '"errors"'; then
        echo -e "${RED}✗ API Error:${NC}"

        # Try to extract error message (works with or without jq)
        if command -v jq &> /dev/null; then
            echo "$response" | jq -r '.errors[0].message'
        else
            echo "$response"
        fi
        return 1
    fi

    # Extract template ID
    local template_id
    if command -v jq &> /dev/null; then
        template_id=$(echo "$response" | jq -r '.data.saveTemplate.id')
    else
        template_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi

    echo -e "${GREEN}✓ Template deployed successfully!${NC}"
    echo ""
    echo -e "${WHITE}Template ID:${NC} $template_id"
    echo -e "${WHITE}Template URL:${NC} https://www.runpod.io/console/user/templates"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Go to RunPod console"
    echo "  2. Find '$TEMPLATE_NAME' in your templates"
    echo "  3. Deploy a pod with GPU (RTX 4090/5090 recommended)"
    echo "  4. Access Applio at http://[pod-id]-6969.proxy.runpod.net"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    print_banner
    print_usage

    # Check requirements if deploying via API
    if [[ "$DEPLOY_MODE" == true ]]; then
        check_api_requirements
    fi

    # Get user configuration
    get_configuration

    # Show summary
    print_summary

    # Confirm before proceeding
    echo -e "${YELLOW}Proceed with template creation? (y/n)${NC}"
    read -r -p "> " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    echo ""

    # Generate template file (always create local copy)
    generate_template

    # Generate usage instructions
    generate_instructions

    # Deploy if requested
    if [[ "$DEPLOY_MODE" == true ]]; then
        echo ""
        deploy_template
    else
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo "  1. Upload voicelab-template.json to RunPod"
        echo "  2. Or run: ./template.sh --deploy"
        echo ""
    fi

    echo -e "${GREEN}Done!${NC}"
}

# Run main function
main
