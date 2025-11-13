#!/usr/bin/env bash

# Model Declarer

# Define repository arrays for each model
# Format: "repo_name|file_name|dest_dir"
declare -A MODEL_REPOS

MODEL_REPOS[Qwen]="
    Comfy-Org/Qwen-Image_ComfyUI|split_files/vae/qwen_image_vae.safetensors|$VAE_DIR
    nunchaku-tech/nunchaku-qwen-image-edit-2509|svdq-int4_r128-qwen-image-edit-2509-lightningv2.0-8steps.safetensors|$DIFFUSION_MODELS_DIR
    Comfy-Org/Qwen-Image_ComfyUI|split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors|$TEXT_ENCODERS_DIR
"

#MODEL_REPOS[Llama]="
    meta-llama/Llama-2-7b|config.json
    meta-llama/Llama-2-13b|pytorch_model.bin
#"

#MODEL_REPOS[Mistral]="
    mistralai/Mistral-7B-v0.1|config.json
    mistralai/Mixtral-8x7B-v0.1|pytorch_model.bin
#"


export MODEL_REPOS

