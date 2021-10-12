#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment/$benchmark_name/$project_name/$bug_id
cd $dir_name/src
make CFLAGS="-fsanitize=address -ggdb -fPIC -fPIE -g -O0" CXXFLAGS=$CFLAGS  LDFLAGS="-fsanitize=address" src/make-prime-list -j`nproc`

