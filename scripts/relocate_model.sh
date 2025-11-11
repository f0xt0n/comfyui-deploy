#!/usr/bin/env bash

# Model Relocator

local file_name=$1
local base_filename=$(basename "$1")
local dest_dir=$2

# Check if file exists in current directory or with its nested path
if [ -f "$file_name" ]; then
    # File exists with full path
    source_file="$file_name"
elif [ -f "$base_filename" ]; then
    # File exists as just the filename in current directory
    source_file="$base_filename"
else
    echo "  ✗ File not found: $file_name or in current directory"
    echo ""
    continue
fi

# Create destination directory if it doesn't exist
        if [ ! mkdir -p "$dest_dir" ]; then
            echo "  ✗ Failed to create destination directory: $dest_dir"
            echo ""
            continue
        fi
        
        # Move the file to destination
        if mv "$source_file" "$dest_dir/$base_filename"; then
            echo "  ✓ Successfully moved $base_filename to $dest_dir"
        else
            echo "  ✗ Failed to move $source_file to $dest_dir"
        fi
        
        echo ""
