#!/bin/bash -x
## Node.js for Mips uClibc OpenWRT Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

# setting working folder
CURDIR=$PWD

# creating tarball folder
mkdir -p $CURDIR/TARBALL

clean () {

    rm -rvf node-v$1/ node-v$1-mips-openwrt-uclibc/ node-v$1-linux/
}

fixv8gyp () {

    var=$(readlink -f $CURDIR/node-v${1}-linux)"/out/Release/mkpeephole"
    sed "s#<(mkpeephole_exec)#$var#g" -i $CURDIR/node-v${1}-${2}/deps/v8/src/v8.gyp
}

if [ -z ${1} ]; then
  echo "set the VERSION first"
  exit 1
fi

# clear out old builds
echo -e "\ncleaning...\n"
clean ${1}

sleep 1

untar () {

    if [ ! -e node-v${1}.tar.gz ]
    then
        echo "Downloading node source ${VERSION}-release..."
        wget http://nodejs.org/dist/v${1}/node-v${1}.tar.gz
        tar xvf node-v${1}.tar.gz
    else
        tar xvf node-v${1}.tar.gz
    fi

    mv node-v${1}/ node-v${1}-${2}/

}

hostbuild () {

    cd node-v${1}-linux/
    patch -p1 < $CURDIR/patches/no-git-check.patch

    # clear out old builds
    echo "cleaning..."
    make clean

    # build
    echo "building..."
    export CONFIG_FLAGS="--without-snapshot --with-intl=none"
    sed -i -e s/small-icu/none/g Makefile
    time make -j3 binary

}

crossbuild () {

    cd node-v${1}-mips-openwrt-uclibc/

    # applying general purpose use patches
    patch -p1 < $CURDIR/patches/no-git-check.patch

    # applying uClibc specific patches
    for i in ../node${major}-uclibc-patches/*.patch
    do
        patch -p1 < $i
    done

    # exportcross
    # clear out old builds
    echo "cleaning..."
    make clean

    # build
    echo "building..."
    export ARCH=mips DESTCPU=mips
    export CONFIG_FLAGS="--without-snapshot --with-intl=none --with-mips-float-abi=soft --dest-os=linux"
    sed -i -e s/small-icu/none/g Makefile
    sed -i -e "s/-\$(ARCH)/\-mips-openwrt-uclibc/g" Makefile
    time make -j3 binary

}

checkhostbuild () {

    if [ -e $CURDIR/node-v${1}-linux/out/Release/mkpeephole ]
    then
        echo -e "\nskipping host build....\n"
    else
        untar ${1} linux
        hostbuild ${1}
        mv $CURDIR/node-v${1}-linux/*.tar.* $CURDIR/TARBALL/
    fi

}

# update git repo, pull new version
nodever=$1
major=`echo $nodever | cut -d. -f1`
minor=`echo $nodever | cut -d. -f2`
revision=`echo $nodever | cut -d. -f3`

# echo "$major.$minor.$revision"

# applying specific patches for node native tools
if [[ $major == 7 || ($major == 8 && $minor -le 2) ]]
then
    # preparing sources
    untar ${1} mips-openwrt-uclibc
    echo -e "\nFixing v8.gyp file...\n"
    fixv8gyp ${1} mips-openwrt-uclibc
    echo $var
    sleep 1
    # performing host build
    checkhostbuild ${1}
    cd $CURDIR
else
    # simply extracting tarball for cross-build
    untar ${1} mips-openwrt-uclibc
fi

# exporting compilers
export STAGING_DIR=$HOME/x-tools/mips-openwrt-linux-uclibc
export PATH=$STAGING_DIR/bin:$PATH

# MIPS openwrt cross-compile exports
export HOST="mips-openwrt-linux-uclibc"
export CPP="${HOST}-gcc -E"
export STRIP="${HOST}-strip"
export OBJCOPY="${HOST}-objcopy"
export AR="${HOST}-ar"
export RANLIB="${HOST}-ranlib"
export LD="${HOST}-g++"
export OBJDUMP="${HOST}-objdump"
export CC="${HOST}-gcc"
export CXX="${HOST}-g++"
export NM="${HOST}-nm"
export AS="${HOST}-as"
export PS1="[${HOST}] \w$ "

# making actual cross build
crossbuild $1
cd $CURDIR

# moving tarballs of cross-build
mv $CURDIR/node-v${1}-mips-openwrt-uclibc/*.tar.* $CURDIR/TARBALL

# spring cleaning
echo -e "\ncleaning again...\n"
clean ${1}

echo -e "\nFinished !\n"
