#!/bin/bash

# This script runs the create-manifest.sh script on all subdirectories
# in a given directory. It will call create-manifest.sh for each subdirectory and
# output the results to stdout. The output will be a CSV file with a header row
# followed by a row for each subdirectory.
# IMPORTANT NOTE: This script is intended for very large folders. The NOT report an entry for the
# top level folder, which may be too big to process. This script will skip the top level folder
# and process just the subdirectories.

# Usage: ./wrapper.sh <directory> > manifest.csv
#        <directory>: The directory to scan (required)  

# Capture the directory argument after options
dir=$(realpath "${1%/}")  # Remove trailing slash if present

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

#first, print the header only
./create-manifest.sh -H "$dir"

while IFS= read -r subdir; do
    folder_name=$(basename "$subdir")
    if [ "$folder_name" = "#recycle" ]; then
        : # do nothing
    else
        # echo "$folder_name"
        ./create-manifest.sh -d "$subdir"
    fi
done <<< "$all_dirs"