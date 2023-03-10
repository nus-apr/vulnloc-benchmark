#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 4 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
dir_name=$1/$benchmark_name/$project_name/$bug_id


cd $dir_name/src
make clean
FORCE_UNSAFE_CONFIGURE=1 CC=wllvm CXX=wllvm++ ./configure CFLAGS='-g -O0 -static -fPIE' CXXFLAGS="$CFLAGS"
make CFLAGS="-fPIC -fPIE -L/klee/build/lib  -lkleeRuntest" CXXFLAGS=$CFLAGS src/make-prime-list -j32


cat <<EOF > $script_dir/repair.conf
dir_exp:$dir_name
tag_id:$bug_id
src_directory:$dir_name/src
binary_path:$dir_name/src/src/pr
config_command:skip
build_command:make CC=crepair-cc CXX=crepair-cxx CFLAGS="-ggdb -fPIC -fPIE -g -O0 -Wno-error" CXXFLAGS="-ggdb -fPIC -fPIE -g -O0 -Wno-error" LDFLAGS="-static" src/pr
test_input_list:"-S\$(printf "\t\t\t")" a -m \$POC
poc_list:$script_dir/../tests/1.txt
klee_flags:--link-llvm-lib=/CrashRepair/lib/libcrepair_proxy.bca
mask_arg:0,1,2
EOF


cat <<EOF > $dir_name/bug.json
{
  "project": {
    "name": "$project_name"
  },
  "name": "$bug_id",
  "binary": "$dir_name/src/src/pr",
  "crash": {
    "command": "\"-S\$(printf \"\\\\t\\\\t\\\\t\")\" a -m \$POC",
    "input": "$script_dir/../tests/1.txt",
    "extra-klee-flags": "",
    "expected-exit-code": 1
  },
  "source-directory": "src",
  "build": {
    "directory": "src",
    "binary": "$dir_name/src/src/pr",
    "commands": {
      "prebuild": "exit 0",
      "clean": "make clean  > /dev/null 2>&1",
      "build": "make CC=crepair-cc CXX=crepair-cxx CFLAGS='-ggdb -fPIC -fPIE -g -O0 -Wno-error' CXXFLAGS='-ggdb -fPIC -fPIE -g -O0 -Wno-error' LDFLAGS='-static' src/pr > /dev/null 2>&1 "
    }
  }
}
EOF
