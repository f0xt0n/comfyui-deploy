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


# ComfyUI Custom Nodes
echo "Installing custom nodes.."
"$(dirname "$0")/install_custom_nodes.sh" "$@" > /tmp/custom_nodes.log 2>&1
CUSTOMNODES_PID=$!
#wait "$CUSTOMNODES_PID"


# SageAttention 2++
"$(dirname "$0")/install_sageattention.sh" "$@" > /tmp/sage_build.log 2>&1
SAGE_PID=$!
#echo "SageAttention build started in background (PID: $SAGE_PID)"


# CivitAI Downloader
"$(dirname "$0")/install_civitai_downloader.sh" "$@"
ARIA_PID=$!
wait "$ARIA_PID"


# Get Models to download list
"$(dirname "$0")/declare_model.sh" "$@"
MODELS_PID=$!
wait "$MODELS_PID"


# Download HF Models
"$(dirname "$0")/download_model.sh" huggingface
HF_PID=$!
wait "$HF_PID"


# Download LoRAs & Checkpoints
"$(dirname "$0")/download_model.sh" civitai &
CIVITAI_PID=$!


# Wait for all downloads to complete
sleep 3
echo "⏳ Waiting for downloads to complete..."
while pgrep -x "aria2c" > /dev/null; do
    echo "🔽 Downloads still in progress..."
    sleep 10  # Check every 10 seconds
done
echo "✅ All models downloaded successfully!"


# Model Relocator
#"$(dirname "$0")/model_relocator.sh" qwen_image_edit_2509
#RELOCATOR_PID=$!
#wait "$RELOCATOR_PID"


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


# Wait for SageAttention build to complete and check status
#while kill -0 "$SAGE_PID" 2>/dev/null; do
#    echo "🛠️ SageAttention is currently installing... (this can take around 5 minutes)"
#    sleep 10
#done
# Check if build completed successfully
#SAGE_ATTENTION_AVAILABLE=false
#if [ -f "/tmp/sage_build_done" ]; then
#    SAGE_ATTENTION_AVAILABLE=true
#    echo "✅ SageAttention build completed successfully"
#else
#    echo "⚠️ SageAttention build failed. Launching ComfyUI without --use-sage-attention flag"
#    echo "Build log available at /tmp/sage_build.log"
#fi
wait "$SAGE_PID"
if [ kill -0 "$SAGE_PID" 2>/dev/null ]; then
    SAGE_ATTENTION_AVAILABLE=true
    echo "✅ SageAttention installed successfully"
fi


local HOST="127.0.0.1"
local PORT="8188"
echo "Starting ComfyUI"
if [ "$SAGE_ATTENTION_AVAILABLE" == "true" ]; then
  nohup python3 "$NETWORK_VOLUME/ComfyUI/main.py" --front-end-version Comfy-Org/ComfyUI_frontend@latest --listen --use-sage-attention --disable-xformers > "$NETWORK_VOLUME/comfyui_${RUNPOD_POD_ID}_nohup.log" 2>&1 &
else
  nohup python3 "$NETWORK_VOLUME/ComfyUI/main.py" --front-end-version Comfy-Org/ComfyUI_frontend@latest --listen --use-pytorch-cross-attention --disable-xformers > "$NETWORK_VOLUME/comfyui_${RUNPOD_POD_ID}_nohup.log" 2>&1 &
fi
echo "View startup logs here: $NETWORK_VOLUME/comfyui_${RUNPOD_POD_ID}_nohup.log"
echo "🔄 ComfyUI Starting Up."
until timeout 1 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; do
  echo -n "."
  sleep 5
done
echo " ✅"
echo "🚀 ComfyUI is ready!"
sleep infinity

