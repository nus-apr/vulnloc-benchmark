#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 4 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
dir_name=/experiment/$benchmark_name/$project_name/$bug_id

fix_file=$dir_name/src/$2

$script_dir/../config.sh $1
cd $dir_name/src
sed -i '789i if(0) return 0;\n' libtiff/tif_ojpeg.c
make clean
bear $script_dir/../build.sh
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
CC="afl-clang-fast" CXX="afl-clang-fast++" $script_dir/../config.sh $1
R_CFLAGS="-g -O0 -fPIE -fsanitize=address" R_LDFLAGS="-pie -fsanitize=address" $script_dir/../build.sh
