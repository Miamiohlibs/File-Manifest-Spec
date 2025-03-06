#!/bin/bash

# Get the directory from the first argument
dir=$1

# Check if the directory exists
if [[ ! -d "$dir" ]]; then
    echo "Error: Directory '$dir' does not exist."
    exit 1
fi

# Loop through each subdirectory and print its size
while IFS= read -r subdir; do
    size_bytes=$(du -sk "$subdir" | awk '{print $1 * 1024}')  # Convert KB to Bytes
    size_human=$(du -sh "$subdir" | awk '{print $1}')         # Human-readable size
    num_files=$(find "$subdir" -type f | wc -l)                # Number of files
    echo "Path: $subdir | SizeInBytes: $size_bytes | Human-readable: $size_human | NumFiles: $num_files"
done < <(find "$dir" -type d)
