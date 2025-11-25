#!/usr/bin/env bash

# Model Declarer

# Define repository arrays for each model
# Format: "repo_name|file_name|dest_dir"
declare -A MODEL_REPOS

MODEL_REPOS[qwen]="
    lightx2v/Qwen-Image-Lightning|Qwen-Image-Edit-2509/qwen_image_edit_2509_fp8_e4m3fn_scaled.safetensors|$DIFFUSION_MODELS_DIR
    Comfy-Org/Qwen-Image_ComfyUI|split_files/vae/qwen_image_vae.safetensors|$VAE_DIR
    Comfy-Org/Qwen-Image_ComfyUI|split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors|$TEXT_ENCODERS_DIR
    lightx2v/Qwen-Image-Lightning|Qwen-Image-Lightning-8steps-V2.0.safetensors|$LORAS_DIR
"
# nunchaku-tech/nunchaku-qwen-image-edit-2509|svdq-int4_r128-qwen-image-edit-2509-lightningv2.0-8steps.safetensors|$DIFFUSION_MODELS_DIR
# Comfy-Org/Qwen-Image-Edit_ComfyUI|split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors|$DIFFUSION_MODELS_DIR


MODEL_REPOS[wan22]="
    Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors|$DIFFUSION_MODELS_DIR
    Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/vae/wan2.2_vae.safetensors|$VAE_DIR
    Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors|$TEXT_ENCODERS_DIR
    lightx2v/Wan2.2-Lightning|Wan2.2-T2V-A14B-4steps-lora-rank64-Seko-V2.0/low_noise_model.safetensors|$LORAS_DIR
    lightx2v/Wan2.2-Distill-Loras|wan2.2_i2v_A14b_low_noise_lora_rank64_lightx2v_4step_1022.safetensors|$LORAS_DIR
"


export MODEL_REPOS


echo "Available Models:"
echo "================="    
for model in "${!MODEL_REPOS[@]}"; do
    echo "  - $model"
done    
echo ""

