#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment/$benchmark_name/$project_name/$bug_id

current_dir=$PWD
mkdir -p $dir_name
cd $dir_name
mkdir dev-patch

project_url=https://github.com/vadz/libtiff.git
fix_commit_id=43bc256d8ae44b92d2734a3c5bc73957a4d7c1ec
bug_commit_id=9a72a69

cd $dir_name
git clone $project_url src
cd src
git checkout $bug_commit_id
git format-patch -1 $fix_commit_id
cp *.patch $dir_name/dev-patch/fix.patch

./autogen.sh

cd $dir_name/src
seed_dir=$script_dir/seed-dir
# Copy Seed Files
mkdir $seed_dir
cp $script_dir/tests/*  $seed_dir
find . -type f -iname '*.tiff' -exec cp  {} $seed_dir \;
find . -type f -iname '*.bmp' -exec cp  {} $seed_dir \;
find . -type f -iname '*.gif' -exec cp  {} $seed_dir \;
find . -type f -iname '*.pgm' -exec cp  {} $seed_dir \;
find . -type f -iname '*.ppm' -exec cp  {} $seed_dir \;
find . -type f -iname '*.pbm' -exec cp  {} $seed_dir \;
find . -type f -iname '*.j2k' -exec cp  {} $seed_dir \;
find . -type f -iname '*.jpg' -exec cp  {} $seed_dir \;
find . -type f -iname '*.jp2' -exec cp  {} $seed_dir \;
