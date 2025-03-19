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


flag_h=false #help
flag_H=false #header only
flag_t=false #tsv output

# Parse options
while [[ "$1" =~ ^- ]]; do
    case "$1" in
        -h) flag_h=true ;;  # Set flag_h to true if -h is provided #help
        -t) flag_t=true ;;  # Set flag_t to true if -t is provided #tsv output
        --) shift; break ;;  # Stop processing flags if '--' is encountered
        *) echo "Unknown option: $1" >&2; exit 1 ;;  # Handle unknown flags
    esac
    shift  # Move to the next argument
done

if ($flag_h); then
    echo "Usage: ./wrapper.sh <directory> > manifest.csv"
    echo "       <directory>: The directory to scan (required)"
    exit 0
fi

if ($flag_t); then
    flags_to_pass = "-t"
else
    flags_to_pass = "-c"
fi

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
        ./create-manifest.sh -d $flags_to_pass "$subdir"
    fi
done <<< "$all_dirs"