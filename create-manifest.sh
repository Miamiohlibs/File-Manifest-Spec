#!/bin/bash


output_delimiter=$'\t'

# join_by: Join an array by a delimiter
# Usage: join_by "," "${array[@]}"

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

# Get the directory from the first argument
dir="${1%/}"  # Remove trailing slash if present
base_depth=$(echo "$dir" | tr -cd '/' | wc -c) # Count the number of slashes

# Check if the directory exists
if [[ ! -d "$dir" ]]; then
    echo "Error: Directory '$dir' does not exist."
    exit 1
fi

#print the header
# header="Folder${output_delimiter}"
# header+="Path${output_delimiter}"
# header+="Date_created${output_delimiter}"
# header+="SizeInBytes${output_delimiter}"
# header+="Size(Human-readable)${output_delimiter}"
# header+="NumFiles${output_delimiter}"
# header+="Extension${output_delimiter}"
# header+="Depth"
# echo $header
echo "Folder${output_delimiter}Path${output_delimiter}Date_created${output_delimiter}SizeInBytes${output_delimiter}Size(Human-readable)${output_delimiter}NumFiles${output_delimiter}Extension${output_delimiter}Depth"

# Loop through each subdirectory and print its size
while IFS= read -r subdir; do
    folder_name=$(basename "$subdir")
    size_bytes=$(du -sk "$subdir" | awk '{print $1 * 1024}')  # Convert KB to Bytes
    size_human=$(du -sh "$subdir" | awk '{print $1}')         # Human-readable size
    num_files=$(find "$subdir" -type f | wc -l | awk '{$1=$1;print}') # Number of files 

    # Try to get the date created
        # Windows
        date_created=$(stat -c %y "$subdir" 2> /dev/null |  awk '{print $1, $2}' | cut -d '.' -f1) #2> /dev/null suppress error msg on mac
    # Mac
    if [ "$date_created" = "" ]; then
        date_created=$(stat -f %SB "$subdir" | xargs -I{} date -j -f "%b %d %T %Y" "{}" "+%Y-%m-%d %H:%M:%S") 
    fi

    files=$(find "$subdir" -type f)              
    extensions=$(echo "$files" | awk -F. '{print $NF}' | sort | uniq | sort -nr | tr '\n' ',')
    extensions=${extensions%,}  # Remove trailing comma
    depth=$(echo "$subdir" | tr -cd '/' | wc -c) # Count the number of slashes
    relative_depth=$((depth - base_depth)) # Calculate the relative depth
    
    # rowArray=("$folder_name" "$subdir" "$date_created" "$size_bytes" "$size_human" "$num_files" "$extensions" "$relative_depth")
    
    # Print the details joined by the delimiter
    # echo $(join_by "$output_delimiter" "${rowArray[@]}")
    echo "$folder_name$output_delimiter$subdir$output_delimiter$date_created$output_delimiter$size_bytes$output_delimiter$size_human$output_delimiter$num_files$output_delimiter$extensions$output_delimiter$relative_depth"
done < <(find "$dir" -type d)
