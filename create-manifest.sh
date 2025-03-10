#!/bin/bash

# Get the directory from the first argument
dir=$1
output_delimiter=$'\t'
base_depth=$(echo "$dir" | tr -cd '/' | wc -c) # Count the number of slashes

# Check if the directory exists
if [[ ! -d "$dir" ]]; then
    echo "Error: Directory '$dir' does not exist."
    exit 1
fi

#print the header
echo "Path${output_delimiter}Date_created$output_delimiterSizeInBytes${output_delimiter}Size(Human-readable)${output_delimiter}NumFiles${output_delimiter}Extension${output_delimiter}Depth"

# Loop through each subdirectory and print its size
while IFS= read -r subdir; do
    size_bytes=$(du -sk "$subdir" | awk '{print $1 * 1024}')  # Convert KB to Bytes
    size_human=$(du -sh "$subdir" | awk '{print $1}')         # Human-readable size
    num_files=$(find "$subdir" -type f | wc -l | awk '{$1=$1;print}') # Number of files 
    # date_created=$(stat -c %y "$subdir" | awk '{print $1}') # Date created
    date_created=$(stat -f %SB "$subdir" ) # Date created
    files=$(find "$subdir" -type f)              
    extensions=$(echo "$files" | awk -F. '{print $NF}' | sort | uniq | sort -nr | tr '\n' ',')
    extensions=${extensions%,}  # Remove trailing comma
    depth=$(echo "$subdir" | tr -cd '/' | wc -c) # Count the number of slashes
    relative_depth=$((depth - base_depth)) # Calculate the relative depth
    # rowArray+=("$subdir,$size_bytes,$size_human,$num_files")
    # Print the details joined by the delimiter
    echo "$subdir$output_delimiter$date_created$output_delimiter$size_bytes$output_delimiter$size_human$output_delimiter$num_files$output_delimiter$extensions$output_delimiter$relative_depth"
    # echo "Path: $subdir | SizeInBytes: $size_bytes | Human-readable: $size_human | NumFiles: $num_files"
done < <(find "$dir" -type d)
