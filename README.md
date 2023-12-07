# VulnLoc Benchmark

Security vulnerability benchmark with instrumentation support for repair tools.

## Usage

**NOTE:** Please ignore the two bugs in ffmpeg (bug id 9 and 10), since they could not be reproduced
easily.

To setup and test each of the bugs, first install the dependencies to projects in the benchmark.
`Dockerfile` contains the list of libraries to be installed. One can also use it to build a
docker image, and set up bugs in its container.

For each bug (e.g. `CVE-2016-9264`), the scripts for setting it up and building it are under
their corresponding directory:

- `setup.sh`: Set up source code version for that bug.
- `config.sh`: Configure the project with appropriate flags.
- `build.sh`: Build the binary which contains the bug, with the required sanitizer instrumentation.

Note that the scripts are assumed to run in some docker environment, where the project source code
is in some pre-defined directories (e.g. `/experiment`). Users can adjust the scripts to suit
their directory structure.

After building the binary, to reproduce each bug, run the binary against the provided exploit input.
Inputs can be found in `tests/` directory under each bug directory.
The exact command and exploit input to be used for each bug can be found in `meta-data.json` file.
In this file, for each bug, the command for bug reproduction is a combination of the `binary_path`, `crash_input`, and `exploit_file_list`.
`crash_input` specifies the command line argument to be suppied after the binary path, in which the special `$POC` string is to be replaced with path to the actual exploit input file.
For exploit input file, use any of the ones in `exploit_file_list`.

## Note

1. In `meta-data.json` file, the `build_command` entry is not intended to be used for reproducing the bug in a dynamic analysis setting.
Instead, `build_script` entry is for reproducing bugs with exploit input.
The `build_command` entry is just provided as a command to build the project, which is more commonly
used by static analysis tools.
