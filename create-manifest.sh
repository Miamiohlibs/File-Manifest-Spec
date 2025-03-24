#!/bin/bash

# Creates a manifest of the files in a directory and its subdirectories,
# output is a delimited file with information about each subdirectory.
#
# Usage: ./create-manifest.sh [-c | -t] [-D | --data | -H | --header] 
#                             [--debug] [-h | --help]
#                             [-s [-p | --preview]]
#                             [{[--num-folders=<number>] [--offset=<number>]} | 
#                              {[--alpha-start=<string>] [--alpha-end=<string>]}]
#                             <directory> > manifest.csv
#        -c: Use comma as the delimiter (default is comma)
#        -D, --data: Data only, do not include the header
#        --debug: Enable debug output
#        -h, --help: Help, print usage information
#        -H, --header: Header only, do not include the data
#        -p, --preview: Preview which files would be processed but do not process them
#        -s: Skip top level folder in output (saves a lot of time for large folders)
#        -t: Use tab as the delimiter (default is comma), should output to tsv not csv
#        <directory>: The directory to scan (required)
#        > manifest.csv: Redirects the output to a file named manifest.csv
#
#        These flags are only available if -s is set:
#        --num-folders=<number>: Limit the number of folders to process (default is all)
#        --offset=<number>: Start processing folders from this offset (default is 0)
#        --alpha-start=<string>: Start processing folders from this string 
#        --alpha-end=<string>: Stop processing folders at this string 

#
# Note: as a bash script, this is intended to run in a Unix-like environment
# (Linux, macOS, etc.). To run on Windows, use git-bash.
#
# Author: Ken Irwin, irwinkr@miamioh.edu
# Date: 2025-03-24

# Default values for optional flags
flag_c=false #csv output 
flag_data=false #data only
flag_debug=false #debug 
flag_h=false #help
flag_H=false #header only
flag_p=false #preview (show which folders will be processed but do not process them)
flag_s=false #skip top level folder
flag_t=false #tsv output
num_folders=""
offset=""
alpha_start=""
alpha_end=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c)
            flag_c=true #csv output
            shift
            ;;
        -D | --data)
            flag_data=true #data only
            shift
            ;;
        -d | --debug)
            flag_debug=true #debug
            shift
            ;;
        -h | --help)
            flag_h=true #help
            shift
            ;;
        -H | --header)
            flag_H=true #header only
            shift
            ;;
        -p | --preview)
            flag_p=true #preview which files would be processed but do not process them
            shift
            ;;
        -s)
            flag_s=true #skip top level folder
            shift
            ;;
        -t)
            flag_t=true #tsv output
            shift
            ;;
        --num-folders=*)
            num_folders="${1#*=}"
            shift
            ;;
        --offset=*)
            offset="${1#*=}"
            shift
            ;;
        --alpha-start=*)
            alpha_start="${1#*=}"
            shift
            ;;
        --alpha-end=*)
            alpha_end="${1#*=}"
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            dir=$(realpath "${1%/}")  # Remove trailing slash if present
            # file_path="$1"
            shift
            ;;
    esac
done

# if flag_h is set, print help message
if $flag_h; then
    echo "Usage: ./create-manifest.sh [-c | -t] [-D | --data | -H | --header] "
    echo "                             [--debug] [-h | --help]"
    echo "                             [-s [-p | --preview]]"
    echo "                             [{[--num-folders=<number>] [--offset=<number>]} | "
    echo "                              {[--alpha-start=<string>] [--alpha-end=<string>]}]"
    echo "                             <directory> > manifest.csv"
    exit 0
fi

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

# Set the output delimiter based on flags
output_delimiter=',' # Default to tab
if $flag_c; then
    output_delimiter=','  # Comma if -c is set
fi
if $flag_t; then
    output_delimiter=$'\t'  # Tab if -t is set
fi

if [[ "$flag_c" = true && "$flag_t" = true ]]; then
    echo "Error: -c and -t cannot be used together." >&2
    exit 1
fi

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

# validate flags for limiting the number of folders to process
# if any of the flags are set, check for conflicts

if [ "$offset$num_folders$alpha_start$alpha_end" != "" ]; then
    if ! $flag_s; then
        echo "Error: -s flag must be set when using --offset, --num-folders, --alpha-start, or --alpha-end flags." >&2
        exit 1
    fi
    if [ "$offset$num_folders" != "" ] && [ "$alpha_start$alpha_end" != "" ]; then
        echo "Error: --offset and --num-folders flags cannot be with --alpha-start or --alpha-end." >&2
        exit 1
    fi
fi  

# Debug output 
if [ "$flag_debug" = true ]; then
    echo "Debug mode is enabled."
    echo "Flags:"
    echo "Flag -c: $flag_c"
    echo "Flag -D/--data: $flag_data"
    echo "Flag -d/--debug: $flag_debug"
    echo "Flag -h/--help: $flag_h"
    echo "Flag -H: $flag_H"
    echo "Flag -p: $flag_p"
    echo "Flag -s: $flag_s"
    echo "Flag -t: $flag_t"
    echo "Num Folders: ${num_folders:-not set}"
    echo "Offset: ${offset:-not set}"
    echo "Alpha Start: ${alpha_start:-not set}"
    echo "Alpha End: ${alpha_end:-not set}"
    echo "Dir: $dir"
fi

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

# Print the header if -d (data-only) and -p (preview folders) flags are not set 
if ! $flag_data && ! $flag_p; then
    echo "$header" # using quotes preserves tab delimiters
fi

# Note: folder iterating logic is BELOW the following function

#############################################
# filter folders based on inputs

FilterFolders () { 
    if [ -n "$alpha_start$alpha_end" ]; then
        # If alpha_start and alpha_end are set, filter alphabetically
        if [ "$flag_debug" = true ] ; then
            echo "Filtering by alpha_start and/or alpha_end"
        fi
        # Ensure alpha_start and alpha_end are set to default values if empty
        if [ "$alpha_start" == "" ]; then
            alpha_start=" "
        fi
        if [ "$alpha_end" == "" ]; then
            alpha_end="~~~~~~~~~~~~~~~"
        fi
        # Filter folders by basename in a case-insensitive way
        filtered_folders=()
        for folder in "${folders_to_process[@]}"; do
            basename=$(basename "$folder" | tr '[:upper:]' '[:lower:]')  # Get basename & convert to lowercase
            if [[ "$basename" > "$alpha_start" && "$basename" < "$alpha_end" ]]; then
                filtered_folders+=("$folder")
            fi
        done
    elif [ -n "$num_folders$offset" ]; then
    # If num_folders and offset are set, filter numerically
        if [ "$flag_debug" = true ]; then
            echo "Filtering by num_folders and/or offset"
        fi
        # Filter folders by num_folders and offset
        if [ -z "$offset" ]; then
            offset=0
        fi
        if [ -z "$num_folders" ]; then
            num_folders=${#folders_to_process[@]}  # Default to all folders if num_folders is not set
        fi
        filtered_folders=("${folders_to_process[@]:$offset:$num_folders}")

    else
        # No filtering applied, use all folders
        filtered_folders=("${folders_to_process[@]}")
    fi
    folders_to_process=("${filtered_folders[@]}") # Update the global folders_to_process array
}

#############################################
# Loop through each subdirectory and print its size

function print_subdir_info() {
    start_dir=$1
    while IFS= read -r subdir; do
        folder_name=$(basename "$subdir")
        subdir=$(realpath "$subdir")  # Get the absolute path of the subdirectory
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
    done < <(find "$start_dir" -type d)
}
#############################################

# Print the data if -H is not set
if ! $flag_H; then
# If -s is set, skip the top level folder
    if $flag_s; then
        # Initialize an empty array
        folders_to_process=()

        # Read folder names safely into the array (handling spaces)
        while IFS= read -r folder; do
            # Skip the folder if it is "#recycle"
            if [ "$(basename "$folder")" != "#recycle" ]; then
                folders_to_process+=("$folder")
            fi
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d |sort )

        FilterFolders # Filter the folders based on the provided flags

        # If Preview, just list the folders to print and then exit
        if $flag_p; then
            # Print the folders to process
            echo "Folders to process:"
            for folder in "${folders_to_process[@]}"; do
                echo "$(basename "$folder")"
            done
            echo
            echo "Number of folders to process: ${#folders_to_process[@]}"
            exit 0
        fi
        # If not preview, process the folders
        # Loop through folders_to_process and print its info
        if [ "$flag_debug" = true ]; then
            echo "Folders to process: ${folders_to_process[@]}"
        fi
        for topsubdir in "${folders_to_process[@]}"; do
            folder_name=$(basename "$topsubdir")   
            if [ "$flag_debug" = true ]; then
                echo "Processing folder: $topsubdir"
            fi
            print_subdir_info "$topsubdir"
        done
    else
        print_subdir_info "$dir"
    fi
fi
