#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 4 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
dir_name=$1/$benchmark_name/$project_name/$bug_id

fix_file=$dir_name/src/$2

$script_dir/../config.sh $1
cd $dir_name/src
sed -i '2470i if(0) return;' tools/tiff2ps.c
sed -i '2441i if(0) return;' tools/tiff2ps.c
make clean

bear $script_dir/../build.sh $1
cd $LIBPATCH_DIR/rewriter
./rewritecond $fix_file -o $fix_file
ret=$?
if [[ ret -eq 1 ]]
then
   exit 128
fi

# build with AFL instrumentation
cd $dir_name/src/
make clean
make distclean
CC="afl-clang-fast" CXX="afl-clang-fast++" R_CFLAGS="-g -O0" R_CPPFLAGS="-g -O0" R_LDFLAGS="-pie" $script_dir/../config.sh $1
R_CFLAGS="-fsanitize=address -g -O0 -fPIE" R_CPPFLAGS="-fsanitize=address -g -O0 -fPIE" R_LDFLAGS="-pie" $script_dir/../build.sh $1
