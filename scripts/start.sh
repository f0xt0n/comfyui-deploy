#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

export NETWORK_VOLUME="/workspace"
export HF_DIR="$NETWORK_VOLUME/hf"
export COMFYUI_DIR="$NETWORK_VOLUME/ComfyUI"
export WORKFLOW_DIR="$NETWORK_VOLUME/ComfyUI/user/default/workflows"
export MODEL_WHITELIST_DIR="$NETWORK_VOLUME/ComfyUI/user/default/ComfyUI-Impact-Subpack/model-whitelist.txt"
export DIFFUSION_MODELS_DIR="$NETWORK_VOLUME/ComfyUI/models/diffusion_models"
export LORAS_DIR="$NETWORK_VOLUME/ComfyUI/models/loras"
export TEXT_ENCODERS_DIR="$NETWORK_VOLUME/ComfyUI/models/text_encoders"
export VAE_DIR="$NETWORK_VOLUME/ComfyUI/models/vae"
export UPSCALE_MODELS_DIR="$NETWORK_VOLUME/ComfyUI/models/upscale_models"


# Get Models to download list
source "$(dirname "$0")/declare_model.sh"


# Download HF Models
source "$(dirname "$0")/download_model.sh" huggingface


# Download LoRAs & Checkpoints
"$(dirname "$0")/download_model.sh" civitai


# Wait for all downloads to complete
sleep 3
echo "⏳ Waiting for downloads to complete..."
while pgrep -x "aria2c" > /dev/null; do
    echo "🔽 Downloads still in progress..."
    sleep 10  # Check every 10 seconds
done
echo "✅ All models downloaded successfully!"


# JupyterLab
echo "Starting JupyterLab in ${NETWORK_VOLUME}..."
jupyter-lab --ip=0.0.0.0 --allow-root --no-browser --NotebookApp.token='' --NotebookApp.password='' --ServerApp.allow_origin='*' --ServerApp.allow_credentials=True --notebook-dir=/workspace > /tmp/jupyterlab.log 2>&1 &


# Workspace as main working directory
echo "cd $NETWORK_VOLUME" >> ~/.bashrc

echo "Updating default preview method..."
CONFIG_PATH="$NETWORK_VOLUME/ComfyUI/user/default/ComfyUI-Manager"
CONFIG_FILE="$CONFIG_PATH/config.ini"

# Ensure the directory exists
mkdir -p "$CONFIG_PATH"

# Create the config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating config.ini..."
    cat <<EOL > "$CONFIG_FILE"
[default]
preview_method = auto
git_exe =
use_uv = False
channel_url = https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main
share_option = all
bypass_ssl = False
file_logging = True
component_policy = workflow
update_policy = stable-comfyui
windows_selector_event_loop_policy = False
model_download_by_agent = False
downgrade_blacklist =
security_level = normal
skip_migration_check = False
always_lazy_install = False
network_mode = public
db_mode = cache
EOL
else
    echo "config.ini already exists. Updating preview_method..."
    sed -i 's/^preview_method = .*/preview_method = auto/' "$CONFIG_FILE"
fi
echo "Config file setup complete!"
echo "Default preview method updated to 'auto'"


HOST="127.0.0.1"
PORT="8188"
echo "Starting ComfyUI"
if [[ "${USE_SAGE_ATTENTION,,}" == "true" ]]; then
    echo "Using 🐸 SageAttention2.2"
    nohup python3 "$NETWORK_VOLUME/ComfyUI/main.py" --front-end-version Comfy-Org/ComfyUI_frontend@latest --listen --use-sage-attention --disable-xformers > "$NETWORK_VOLUME/comfyui_${RUNPOD_POD_ID}_nohup.log" 2>&1 &
else
    echo "Using 🔥 PyTorchCrossAttention"
    nohup python3 "$NETWORK_VOLUME/ComfyUI/main.py" --front-end-version Comfy-Org/ComfyUI_frontend@latest --listen --use-pytorch-cross-attention --disable-xformers > "$NETWORK_VOLUME/comfyui_${RUNPOD_POD_ID}_nohup.log" 2>&1 &
fi
echo "View startup logs here: $NETWORK_VOLUME/comfyui_${RUNPOD_POD_ID}_nohup.log"
echo -n "🔄 ComfyUI Starting Up.."
until timeout 1 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; do
  echo -n "."
  sleep 5
done
echo " ✅"
echo "🚀 ComfyUI is ready!"
sleep infinity

