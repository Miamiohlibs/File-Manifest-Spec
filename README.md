# File Manifest Generator

Creates a manifest of the files in a directory and its subdirectories,
output is a delimited file with information about each subdirectory.

This script is intended to summarize the contents of a directory and its subdirectories
for the purposes of digital preservation and archiving.

## Usage

```
Usage: ./create-manifest.sh [-c | -t] [-D | --data | -H | --header]
                            [--debug] [-h | --help]
                            [-s [-p | --preview]]
                            [{[--num-folders=<number>] [--offset=<number>]} |
                             {[--alpha-start=<string>] [--alpha-end=<string>]}]
                            <directory> > manifest.csv
```

### Options

#### Output format (optional)

- `-c`, `--csv`: Output in CSV format (default)
- `-t`, `--tsv`: Output in TSV format
- `-D`, `--data`: Output only the data (no header)
- `-H`, `--header`: Output only the header (no data)

#### Handling large directories (optional)

- `-s`: Skip the top-level directory. Without this flag, the top-level directory is included in the output. This can be very slow for large directories. The `-s` flag omits this and allows you to restrict the output to only a subset of the subdirectories, making it easier to process in smaller chunks.

##### Limiting output numerically (only in combination with `-s`)

- `--num-folders=<number>`: Limit the output to `<number>` subdirectories. By default it will start with first subdirectory, but you can modify this with the `--offset` flag.
- `--offset=<number>`: Start the output at the `<number>`th subdirectory. This is useful for resuming a previous run or skipping over a large number of subdirectories.
- `-p`, `--preview`: Preview the output without writing to a file. This is useful for testing the script with the `-s` flag to see how many subdirectories will be included in the output.

##### Limiting output alphabetically (only in combination with `-s`)

- `--alpha-start=<string>`: Start the output at the first subdirectory that comes after `<string>` alphabetically. This is useful for resuming a previous run or skipping over a large number of subdirectories. Default is the first subdirectory.
- `--alpha-end=<string>`: End the output at the last subdirectory that comes before `<string>` alphabetically. This is useful for limiting the output to a subset of subdirectories. Default is the last subdirectory.

##### Previewing which subdirectories will be included in the output

- `-p`, `--preview`: Preview which subdirectories will be included . This is useful for testing the script with the `-s` and the alphabetical or numerical limiter flag to see how which subdirectories will be included in the output if you run it without the `-p` flag.

#### Debugging/helpers (optional)

- `-d`, `--debug`: Print debugging information
- `-h`, `--help`: Print help message

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
