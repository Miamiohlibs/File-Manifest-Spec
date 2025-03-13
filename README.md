# File Manifest Generator

Creates a manifest of the files in a directory and its subdirectories,
output is a delimited file with information about each subdirectory.

This script is intended to summarize the contents of a directory and its subdirectories
for the purposes of digital preservation and archiving.

## Usage

`./create-manifest.sh [-c] [-t] <directory> > manifest.csv`

- `-c`: output in CSV format (default)
- `-t`: output in TSV (tab-separated) format, should output to manifest.tsv (not csv)
- `<directory>`: The directory to scan (required)
- `> manifest.csv`: Redirects the output to a file named manifest.csv

Note: as a bash script, this is intended to run in a Unix-like environment
(Linux, macOS, etc.). To run on Windows, use [git-bash](https://git-scm.com/downloads/win).

## Output

The output is a delimited file with the following columns:

- `Folder`: The name of the folder
- `Path`: The path to the folder, relative to the script (this could be better)
- `Date Created`: The date the folder was created in the file system
- `Size In Bytes`: The size of the folder in bytes including all files and subfolders
- `Size (Human-Readable)`: The size of the folder in a human-readable format (e.g., KB, MB, GB)
- `File Count`: The number of files in the folder & subfolders
- `Extensions`: The file extensions in the folder & subfolders, separated by commas
- `Depth`: The depth of the folder in the directory tree relative to the start folder (0 for the root folder, 1 for its immediate subfolders, etc.)

## License

This open-source script is licensed under the MIT License. See the LICENSE file for details.
The script is provided "as-is" without any warranty of any kind, either express or implied.
You are free to use, modify, and distribute this script as long as you include the original license.`

## Credits

- Author: Ken Irwin, irwinkr@miamioh.edu
- Date: 2025-03-13
