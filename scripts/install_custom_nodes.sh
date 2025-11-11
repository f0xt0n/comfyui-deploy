#!/usr/bin/env bash

# Install ComfyUI Custom Nodes

CN_DIR="$COMFYUI_DIR/custom_nodes"
INIT_MARKER="$CN_DIR/.custom_nodes_initialized"

declare -A REPOS=(
  ["ComfyUI-Manager"]="https://github.com/ltdrdata/ComfyUI-Manager.git"
  ["ComfyUI_essentials"]="https://github.com/cubiq/ComfyUI_essentials.git"
  ["ComfyUI_Comfyroll_CustomNodes"]="https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
  ["comfyui-impact-pack"]="https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
  ["comfyui-impact-subpack"]="https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"
  ["comfyui-custom-scripts"]="https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
  ["comfyui-easy-use"]="https://github.com/yolain/ComfyUI-Easy-Use.git"
  ["rgthree-comfy"]="https://github.com/rgthree/rgthree-comfy.git"
  ["cg-use-everywhere"]="https://github.com/chrisgoringe/cg-use-everywhere.git"
  ["was-ns"]="https://github.com/ltdrdata/was-node-suite-comfyui.git"
  ["comfyui_image_metadata_extension"]="https://github.com/edelvarden/comfyui_image_metadata_extension.git"
  ["ComfyUI-KJNodes"]="https://github.com/kijai/ComfyUI-KJNodes.git"
  ["ComfyUI-GGUF"]="https://github.com/city96/ComfyUI-GGUF.git"
  ["ComfyUI-QwenImageWanBridge"]="https://github.com/fblissjr/ComfyUI-QwenImageWanBridge.git"
  ["ComfyUI_UltimateSDUpscale"]="https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
)

if [ ! -f "$INIT_MARKER" ]; then
  echo "↳ First run: initializing custom_nodes…"
  mkdir -p "$CN_DIR"
  for name in "${!REPOS[@]}"; do
    url="${REPOS[$name]}"
    target="$CN_DIR/$name"
    if [ -d "$target" ]; then
      echo "  ↳ $name already exists, skipping clone"
    else
      echo "  ↳ Cloning $name"
      git clone --depth 1 "$url" "$target"
    fi
  done

  echo "↳ Installing/upgrading dependencies…"
  for dir in "$CN_DIR"/*/; do
    req="$dir/requirements.txt"
    if [ -f "$req" ]; then
      echo "  ↳ pip install --upgrade -r $req"
      python -m pip install --no-cache-dir --upgrade -r "$req"
    fi
  done

  # Create marker file
  touch "$INIT_MARKER"
else
  echo "↳ Custom nodes already initialized, skipping clone and dependency installation."
fi

