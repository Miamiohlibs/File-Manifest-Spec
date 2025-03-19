#!/bin/bash

# Creates a manifest of the files in a directory and its subdirectories,
# output is a delimited file with information about each subdirectory.
#
# Usage: ./create-manifest.sh [-c] [-t] <directory> > manifest.csv
#        -c: Use comma as the delimiter (default is comma)
#        -d: Data only, do not include the header
#        -H: Header only, do not include the data
#        -t: Use tab as the delimiter (default is comma), should output to tsv not csv
#        <directory>: The directory to scan (required)
#        > manifest.csv: Redirects the output to a file named manifest.csv
#
# Note: as a bash script, this is intended to run in a Unix-like environment
# (Linux, macOS, etc.). To run on Windows, use git-bash.
#
# Author: Ken Irwin, irwinkr@miamioh.edu
# Date: 2025-03-13

# join_by: Join an array by a delimiter
# Usage: join_by "," "${array[@]}"

# Default values for optional flags
flag_c=false #csv output 
flag_d=false #data only
flag_h=false #help
flag_H=false #header only
flag_t=false #tsv output

# Parse options
while [[ "$1" =~ ^- ]]; do
    case "$1" in
        -c) flag_c=true ;;  # Set flag_c to true if -c is provided #csv output
        -d) flag_d=true ;;  # Set flag_d to true if -d is provided #data only
        -h) flag_h=true ;;  # Set flag_h to true if -h is provided #help
        -H) flag_H=true ;;  # Set flag_h to true if -h is provided #header only
        -t) flag_t=true ;;  # Set flag_t to true if -t is provided #tsv output
        --) shift; break ;;  # Stop processing flags if '--' is encountered
        *) echo "Unknown option: $1" >&2; exit 1 ;;  # Handle unknown flags
    esac
    shift  # Move to the next argument
done

# if flag_h is set, print help message
if $flag_h; then
    echo "Usage: ./create-manifest.sh [-c] [-t] <directory> > manifest.csv"
    echo "       -c: Use comma as the delimiter (default is comma)"
    echo "       -d: Data only, do not include the header"
    echo "       -H: Header only, do not include the data"
    echo "       -t: Use tab as the delimiter (default is comma)"
    echo "       <directory>: The directory to scan (required)"
    echo "       > manifest.csv: Redirects the output to a file named manifest.csv"
    exit 0
fi

# Set the output delimiter based on flags
output_delimiter=',' # Default to tab
if $flag_c; then
    output_delimiter=','  # Comma if -c is set
fi
if $flag_t; then
    output_delimiter=$'\t'  # Tab if -t is set
fi

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

# Debug output (optional)
# echo "Flag -c: $flag_c"
# echo "Flag -t: $flag_t"
# echo "Directory: $dir"

# get the base directory depth in the filesystem
base_depth=$(echo "$dir" | tr -cd '/' | wc -c) # Count the number of slashes

#print the header
header="Folder${output_delimiter}"
header+="Path${output_delimiter}"
header+="Date Created${output_delimiter}"
header+="Size In Bytes${output_delimiter}"
header+="Size (Human-readable)${output_delimiter}"
header+="File Count${output_delimiter}"
header+="Extensions${output_delimiter}"
header+="Depth"

# Print the header if -d is not set 
if ! $flag_d; then
    echo "$header" # using quotes preserves tab delimiters
fi

# Print the data if -H is not set
if ! $flag_H; then
    # Loop through each subdirectory and print its size
    while IFS= read -r subdir; do
        folder_name=$(basename "$subdir")
        size_bytes=$(du -sk "$subdir" | awk '{print $1 * 1024}')  # Convert KB to Bytes
        size_human=$(du -sh "$subdir" | awk '{print $1}')         # Human-readable size
        file_count=$(find "$subdir" -type f | wc -l | awk '{$1=$1;print}') # Number of files 

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
            "$date_created" #Date Created
            "$size_bytes" #Size In Bytes
            "$size_human" #Size(Human-readable)
            "$file_count" #File Count
            "$extensions" #Extensions
            "$relative_depth" #Depth
            )

        # Print the details joined by the delimiter
        join_by() {
            local delimiter="$1"
            #if first element contains a comma, wrap it in quotes

            shift
            #if first element contains a comma, wrap it in quotes
            if [[ "$1" == *","* ]]; then
                local joined="\"$1\""
            else
                local joined="$1"
            fi
            # local joined="$1"
            shift
            for element in "$@"; do
                #if delimiter is comma and element contains a comma, add quotes
                if [[ "$delimiter" == "," && "$element" == *","* ]]; then
                    element="\"$element\""
                fi
                joined+="$delimiter$element"
            done
            echo "$joined"
        }
        echo "$(join_by "$output_delimiter" "${rowArray[@]}")"
    done < <(find "$dir" -type d)
fi
