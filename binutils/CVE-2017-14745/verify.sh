#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment/$benchmark_name/$project_name/$bug_id
TEST_ID=$1

cd $dir_name/src
patch -f -p 1 < $dir_name/dev-patch/fix.patch
bash $script_dir/build.sh
bash $script_dir/test.sh $TEST_ID
ret=$?
patch -R -f -p 1 < $dir_name/dev-patch/fix.patch
bash $script_dir/build.sh
exit $ret


