#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 4 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
dir_name=$1/$benchmark_name/$project_name/$bug_id
exp_dir_path=/experiment/$benchmark_name/$project_name/$bug_id
setup_dir_path=/setup/$benchmark_name/$project_name/$bug_id
fix_file=$2
IFS='/' read -r -a array <<< "$fix_file"
file_name=${array[-1]}

cd $dir_name
ln -s src project
mkdir result
cp $setup_dir_path/extractfix/driver ./
cp $setup_dir_path/extractfix/klee-driver ./
cp -r $setup_dir_path/tests ./

cp $setup_dir_path/extractfix/project_*.sh ./

cp -r $setup_dir_path/extractfix/project_specific_lib ./

ln -s $exp_dir_path /coreutils-25003


chmod +x project_*.sh
chmod +x driver
chmod +x klee-driver


cd ./project_specific_lib
gcc -c hook.c
ar cr libhook.a hook.o
cd ..

cd src
make distclean
exit 0