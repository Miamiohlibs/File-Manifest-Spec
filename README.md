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

## Credits

- Author: Ken Irwin, irwinkr@miamioh.edu
- Date: 2025-03-13
