#!/bin/bash

# creates a manifest of the files in a directory and its subdirectories
# Usage: ./create-manifest.sh <directory> > manifest.tsv
# This script generates a single tab-separated file
#
# Note: as a bash script, this is intended to run in a Unix-like environment
# (Linux, macOS, etc.). To run on Windows, use git-bash.
#
# Author: Ken Irwin, irwinkr@miamioh.edu
# Date: 2025-03-13

output_delimiter=$'\t'

# join_by: Join an array by a delimiter
# Usage: join_by "," "${array[@]}"

# Get the directory from the first argument
dir="${1%/}"  # Remove trailing slash if present

# Check if the directory exists
if [[ ! -d "$dir" ]]; then
    echo "Error: Directory '$dir' does not exist."
    exit 1
fi

# get the base directory depth in the filesystem
base_depth=$(echo "$dir" | tr -cd '/' | wc -c) # Count the number of slashes

#print the header
header="Folder${output_delimiter}"
header+="Path${output_delimiter}"
header+="Date_created${output_delimiter}"
header+="SizeInBytes${output_delimiter}"
header+="Size(Human-readable)${output_delimiter}"
header+="NumFiles${output_delimiter}"
header+="Extension${output_delimiter}"
header+="Depth"
echo "$header" # using quotes preserves tab delimiters

# Loop through each subdirectory and print its size
while IFS= read -r subdir; do
    folder_name=$(basename "$subdir")
    size_bytes=$(du -sk "$subdir" | awk '{print $1 * 1024}')  # Convert KB to Bytes
    size_human=$(du -sh "$subdir" | awk '{print $1}')         # Human-readable size
    num_files=$(find "$subdir" -type f | wc -l | awk '{$1=$1;print}') # Number of files 

    # Get the date created
    # Windows
    date_created=$(stat -c %y "$subdir" 2> /dev/null |  awk '{print $1, $2}' | cut -d '.' -f1) #2> /dev/null suppress error msg on mac
    # Mac
    if [ "$date_created" = "" ]; then
        date_created=$(stat -f %SB "$subdir" | xargs -I{} date -j -f "%b %d %T %Y" "{}" "+%Y-%m-%d %H:%M:%S") 
    fi

    # get all the file extensions in the subdirectory and its decendants
    files=$(find "$subdir" -type f)              
    extensions=$(echo "$files" | awk -F. '{print $NF}' | sort | uniq | sort -nr | tr '\n' ',')
    extensions=${extensions%,}  # Remove trailing comma

    # get the depth of the subdirectory relative to the starting directory
    depth=$(echo "$subdir" | tr -cd '/' | wc -c) # Count the number of slashes
    relative_depth=$((depth - base_depth)) # Calculate the relative depth
    
    # Create an array to hold the values
    rowArray=(
        "$folder_name" #Folder 
        "$subdir" #Path
        "$date_created" #Date_created
        "$size_bytes" #SizeInBytes
        "$size_human" #Size(Human-readable)
        "$num_files" #NumFiles
        "$extensions" #Extension
        "$relative_depth" #Depth
        )

    # Print the details joined by the delimiter
    join_by() {
        local delimiter="$1"
        shift
        local joined="$1"
        shift
        for element in "$@"; do
            joined+="$delimiter$element"
        done
        echo "$joined"
    }
    echo "$(join_by "$output_delimiter" "${rowArray[@]}")"
done < <(find "$dir" -type d)
