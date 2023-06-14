#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 4 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
dir_name=$1
mkdir $dir_name/senx

cd $dir_name/src

make clean
export FORCE_UNSAFE_CONFIGURE=1 && CC="wllvm" CXX="wllvm++" CFLAGS="-g -O0 -static -fPIE" CXXFLAGS="$CFLAGS" ./configure
CC="wllvm" CXX="wllvm++" make CFLAGS="-g -O0 -static -fPIC -fPIE" CXXFLAGS="$CFLAGS" -j`nproc`
# do it again as some other unrelated binary fails for previous step
CC="wllvm" CXX="wllvm++" make CFLAGS="-g -O0 -static -fPIC -fPIE" CXXFLAGS="$CFLAGS" src/split

binary_dir=$dir_name/src/src
binary_name=split

extract-bc $binary_dir/$binary_name
analyze_bc $binary_dir/$binary_name.bc
cd $dir_name/senx
cp $binary_dir/$binary_name .
cp $binary_dir/$binary_name.bc .
cp $binary_dir/$binary_name.bc.talos .

llvm-dis $binary_name.bc
cat <<EOF > prepare_gdb_script.py
import os
import sys

binary_name = sys.argv[1]
llvm_ir_path = binary_name + ".ll"
gdb_script_path = "gdb_script"
struct_list = []
with open(llvm_ir_path, "r") as input_file:
    content_lines = input_file.readlines()
    for line in content_lines:
        if "@" in line:
            break
        if "struct" in line:
            struct_name = line.split(" = ")[0].split(".")[1]
            first_occ = struct_name.find(next(filter(str.isalpha, struct_name)))
            struct_list.append(struct_name[first_occ:])

with open(gdb_script_path, "w") as out_file:
    for struct_name in struct_list:
        out_file.writelines('offsets-of "{}"\n'.format(struct_name))
        out_file.writelines('printf "\\n"\n')

os.system("gdb -batch -silent -x gdb_script {} > def_file".format(binary_name))
EOF

python3 prepare_gdb_script.py $binary_name
cp def_file $binary_dir
