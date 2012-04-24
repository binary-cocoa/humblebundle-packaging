#!/bin/bash

dohelp() {
    echo "Extracts all content from a nixstaller archive"
    echo "Usage: $0 [-h] [-d DESTDIR] package.sh DESTDIR"
    exit 1
}

progress() {
    while read a; do
        printf .
    done
}

extract_subarch() {
    target="$1"
    pushd $target/installer >/dev/null
    echo "Extracting Archives "
    arch=`get_arch`
    ./bin/linux/$arch/libc.so.6/lzma d subarch - 2>/dev/null | tar -xvf - 2>&1 | progress
    echo
    popd >/dev/null
}

extract_files() {
    target="$1"
    pushd $target >/dev/null
    echo "Extracting Files"
    arch=`get_arch`
    lzma_dec=$PWD/installer/bin/linux/$arch/libc.so.6/lzma
    for archive in $PWD/installer/instarchive_*.sizes; do
        filename=`basename $archive .sizes`
        archname=`dirname $archive`/$filename
        dirname=${filename/#instarchive/files}
        printf "Extracting $filename "
        mkdir $dirname
        pushd $dirname >/dev/null
        $lzma_dec d $archname - 2>/dev/null | tar -xvf - 2>&1 | progress
        echo
        popd >/dev/null
    done
    popd >/dev/null
}

extract_deps() {
    target="$1"
    pushd $target >/dev/null
    echo "Extracting Dependencies"
    arch=`get_arch`
    lzma_dec=$PWD/installer/bin/linux/$arch/libc.so.6/lzma
    for archive in $PWD/installer/deps/*/*.sizes; do
        filename=`basename $archive .sizes`
        archname=`dirname $archive`/$filename
        dirname=$filename
        printf "Extracting $filename "
        mkdir $dirname
        pushd $dirname >/dev/null
        $lzma_dec d $archname - 2>/dev/null | tar -xvf - 2>&1 | progress
        echo
        popd >/dev/null
    done
    popd >/dev/null
}



get_arch() {
    arch=`uname -m`
    if [ "$arch" != "x86_64" ]; then
        arch=x86
    fi
    echo $arch
}

### Main Program
target=

while getopts "hd:" flag
do
    case $flag in
        d)
            target=$OPTARG
            ;;
        ? | h)
            dohelp
            ;;
    esac
done

shift $(($OPTIND - 1))

if [ -z "$1" ]; then
    dohelp
fi

installer="$1"

if [ -z "$target" ]; then
    target=`basename $installer .sh`
fi

echo "This will extract $installer to $target"

if [ -e $target ]; then
    echo "ERROR: Target directory already exists"
    exit 2
fi

echo "Press Enter to Proceed.  (CTRL-C to Abort)"
read

sh $installer --target $target/installer --noexec --keep

extract_subarch $target
extract_files $target
extract_deps $target

