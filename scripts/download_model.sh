#!/usr/bin/env bash

# Model Downloader

download_huggingface() {
    # Check if MODELS_TO_DOWNLOAD environment variable is set
    if [ -z "$MODELS_TO_DOWNLOAD" ]; then
        echo "🚨 MODELS_TO_DOWNLOAD environment variable is not set"
        echo "Usage: MODELS_TO_DOWNLOAD='Qwen' $0"
        echo "       MODELS_TO_DOWNLOAD='Qwen,Llama' $0"
        exit 1
    fi
    # Convert MODELS_TO_DOWNLOAD to array (supports both comma and space separated)
    IFS=', ' read -ra MODELS_ARRAY <<< "$MODELS_TO_DOWNLOAD"
    # Process each model
    for model in "${MODELS_ARRAY[@]}"; do
        # Trim whitespace
        model=$(echo "$model" | xargs)    
        echo "Processing model: $model"    
        # Check if model exists in our repository list
        if [ -z "${MODEL_REPOS[$model]}" ]; then
            echo "⚠️ Model '$model' not found in repository list. Skipping..."
            continue
        fi    
        # Get repositories for this model
        repos="${MODEL_REPOS[$model]}"    
        # Process each repository
        for repo_entry in $repos; do
            # Split repo_name, file_name, dest_dir
            IFS='|' read -r repo_name file_name dest_dir <<< "$repo_entry"        
            echo "📥 Downloading: $file_name from $repo_name"        
            
            HF_XET_HIGH_PERFORMANCE=1 hf download --local-dir="$HF_DIR" "$repo_name" "$file_name"

            if [[ $? -eq 0 ]]; then
                echo "  ✓ Successfully downloaded $file_name"
                # Move model to correct destination
                mv "$HF_DIR/$file_name" "$dest_dir"
                #"$(dirname "$0")/relocate_model.sh" "$file_name" "$dest_dir"
            else
                echo "  ✗ Failed to download $file_name from $repo_name"
            fi        
            echo "---"
        done
    done
    echo "Models downloaded!"
}


download_civitai() {
    # Get LoRAs & Checkpoints
    declare -A MODEL_CATEGORIES=(
        ["$NETWORK_VOLUME/ComfyUI/models/loras"]="$LORAS_IDS_TO_DOWNLOAD"
        ["$NETWORK_VOLUME/ComfyUI/models/checkpoints"]="$CHECKPOINTS_IDS_TO_DOWNLOAD"
    )
    # Counter to track background jobs
    download_count=0
    # Ensure directories exist and schedule downloads in background
    for TARGET_DIR in "${!MODEL_CATEGORIES[@]}"; do
        mkdir -p "$TARGET_DIR"
        IFS=',' read -ra MODEL_IDS <<< "${MODEL_CATEGORIES[$TARGET_DIR]}"

        for MODEL_ID in "${MODEL_IDS[@]}"; do
            sleep 6
            echo "✒️ Scheduling download: $MODEL_ID to $TARGET_DIR"
            (cd "$TARGET_DIR" && download_with_aria.py -m "$MODEL_ID") &
            ((download_count++))
        done
    done
    echo "📋 Scheduled $download_count downloads in background"
}


download_aria2() {
    local url="$1"
    local full_path="$2"

    local destination_dir=$(dirname "$full_path")
    local destination_file=$(basename "$full_path")

    mkdir -p "$destination_dir"

    # Simple corruption check: file < 10MB or .aria2 files
    if [ -f "$full_path" ]; then
        local size_bytes=$(stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path" 2>/dev/null || echo 0)
        local size_mb=$((size_bytes / 1024 / 1024))

        if [ "$size_bytes" -lt 10485760 ]; then  # Less than 10MB
            echo "🗑️  Deleting corrupted file (${size_mb}MB < 10MB): $full_path"
            rm -f "$full_path"
        else
            echo "✅ $destination_file already exists (${size_mb}MB), skipping download."
            return 0
        fi
    fi

    # Check for and remove .aria2 control files
    if [ -f "${full_path}.aria2" ]; then
        echo "🗑️  Deleting .aria2 control file: ${full_path}.aria2"
        rm -f "${full_path}.aria2"
        rm -f "$full_path"  # Also remove any partial file
    fi

    echo "📥 Downloading $destination_file to $destination_dir..."
    aria2c -x 16 -s 16 -k 1M --continue=true -d "$destination_dir" -o "$destination_file" "$url" &

    echo "Download started in background for $destination_file"
}


# Run function from input parameter
case "$1" in
    huggingface)
        echo "[*] Downloading from HuggingFace.."
        download_huggingface
        ;;
    civitai)
        echo "[*] Downloading from CivitAI.."
        download_civitai
        ;;
    aria2)
        echo "[*] Downloading using Aria2.."
        download_aria2
        ;;
    *)
        echo "Usage: $0 {download_model}"
        echo "  huggingface - Download HF models from MODELS_TO_DOWNLOAD environment variable."
        echo "  civitai - Download CivitAI from LORAS_IDS_TO_DOWNLOAD & CHECKPOINTS_IDS_TO_DOWNLOAD environment variable."
        echo "  aria2 - General Aria2 downloader from input URL & FULL-PATH."
        exit 1
        ;;
esac

