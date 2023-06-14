#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 4 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
dir_name=$1
setup_dir_path=/setup/$benchmark_name/$project_name/$bug_id
crash_file="libtiff/tif_ojpeg.c"
gold_file=$2

apt-get install -y gcc-multilib libtool automake valgrind
echo " --klee-solver-timeout 100 --klee-timeout 120 --klee-search dfs --klee-max-forks 100 " > /tmp/ANGELIX_ARGS


clean-source () {
    local directory="$1"
    pushd "$directory" &> /dev/null
    find . -name .svn -exec rm -rf {} \; &> /dev/null || true
    find . -name .git -exec rm -rf {} \; &> /dev/null || true
    find . -name .hg -exec rm -rf {} \; &> /dev/null || true
    ./configure &> /dev/null || true
    make clean &> /dev/null || true
    make distclean &> /dev/null || true
    popd &> /dev/null
}
# Common functions -------------------------------------------------------------

# replaces within "$3" lines starting from the only occurrence of symbol "$2" in file "$1"
replace-in-range () {
    local file="$1"
    local symbol="$2"
    local length="$3"
    local original="$4"
    local replacement="$5"

    local begin=$(grep -n "$symbol" "$file" | cut -d : -f 1)
    local end=$(( begin + length ))

    sed -i "$begin,$end{s/$original/$replacement/;}" "$file"
}

replace-all-in-range () {
    local file="$1"
    local symbol="$2"
    local length="$3"
    local original="$4"
    local replacement="$5"

    local begin=$(grep -n "$symbol" "$file" | cut -d : -f 1)
    local end=$(( begin + length ))

    sed -i "$begin,$end{s/$original/$replacement/g;}" "$file"
}

add-header () {
    local file="$1"
    sed -i '1s/^/#ifndef ANGELIX_OUTPUT\n/' "$file"
    sed -i '2s/^/#define ANGELIX_OUTPUT(type, expr, id) expr\n/' "$file"
    sed -i '3s/^/#define ANGELIX_REACHABLE(id)\n/' "$file"
    sed -i '4s/^/#endif\n/' "$file"
}

restore_original () {
    local src="$1"
    if [ -e $src.org ]; then
        # restore the original
        cp $src.org $src
    else
        # prepare the org file
        cp $src $src.org
    fi
}

# Libtiff ----------------------------------------------------------------------

add-angelix-runner () {
    local script="$1"
    local call="$2"
    local occurrence="$3"
    local lines=$(grep -n "$call" "$script" | cut -d : -f 1)
    read -a arr <<<$lines #convert list into array
    local line=${arr[$occurrence]}
    sed -i "$line"'s/^/export MEMCHECK=${ANGELIX_RUN:-eval}; /' "$script"
    sed -i "$line"'s/$/&; unset MEMCHECK/' "$script"
}



instrument () {
    local directory="$1"
    local buggy_source="$1/$crash_file"
    restore_original $buggy_source
    sed -i '816i ANGELIX_OUTPUT(int, sp->bytes_per_line, "sp->bytes_per_line");' "$buggy_source"
    add-header "$buggy_source"
}

instrument_gold () {
    local directory="$1"
    local buggy_source="$1/$crash_file"
    restore_original $buggy_source
    sed -i '825i ANGELIX_OUTPUT(int, sp->bytes_per_line, "sp->bytes_per_line");' "$buggy_source"
    add-header "$buggy_source"
}



root_directory=$1
buggy_directory="$root_directory/src"
golden_directory="$root_directory/src-gold"

if [ ! -d golden_directory ]; then
  cp -rf $buggy_directory $golden_directory
  cd $golden_directory
  patch -f -p 1 < $dir_name/dev-patch/fix.patch
fi

if [ ! -d "$root_directory/angelix" ]; then
  mkdir $root_directory/angelix
fi

clean-source $buggy_directory
clean-source $golden_directory


instrument $buggy_directory
instrument_gold $golden_directory

cat <<EOF > $root_directory/angelix/oracle
#!/bin/bash
setup_dir_path=$setup_dir_path
binary_path="./tools/tiffmedian"
case "\$1" in
    1)
        POC=\$setup_dir_path/tests/1.tif
        \${ANGELIX_RUN:-eval} \$binary_path \$POC foo > \$binary_path.log 2>&1
esac
EOF
chmod u+x $root_directory/angelix/oracle

cat <<EOF > $root_directory/angelix/config
#!/bin/bash
./configure --enable-static --disable-shared
EOF
chmod +x $root_directory/angelix/config

cat <<EOF > $root_directory/angelix/build
#!/bin/bash
make -e
EOF
chmod u+x $root_directory/angelix/build
