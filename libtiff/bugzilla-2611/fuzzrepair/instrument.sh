#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 4 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
dir_name=$1/$benchmark_name/$project_name/$bug_id

fix_file=$dir_name/src/$2

$script_dir/../config.sh $1
cd $dir_name/src
sed -i '816i if(0) return -1;\n' libtiff/tif_ojpeg.c
make clean
bear $script_dir/../build.sh $1
cd $LIBPATCH_DIR/rewriter
./rewritecond $fix_file -o $fix_file
ret=$?
if [[ ret -eq 1 ]]
then
   exit 128
fi
$script_dir/../build.sh $1





