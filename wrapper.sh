#!/bin/bash

# Capture the directory argument after options
dir="${1%/}"  # Remove trailing slash if present

# Check if directory is missing
if [[ -z "$dir" ]]; then
    echo "Error: No directory specified." >&2
    exit 1
fi

# Check if the directory exists
if [[ ! -d "$dir" ]]; then
    echo "Error: Directory '$dir' does not exist." >&2
    exit 1
fi

all_dirs=$(ls -d "$dir"/*/)

while IFS= read -r subdir; do
    folder_name=$(basename "$subdir")
    # echo "$folder_name"
    ./create-manifest.sh "$subdir"
done <<< "$all_dirs"