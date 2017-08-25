#!/bin/bash -x
## Node.js for Mips MUSL OpenWRT Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

CURDIR=$PWD

clean () {

    rm -rvf node-v$1/ node-v$1-mips-openwrt-musl/ node-v$1-linux/
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
echo "cleaning..."
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

    cd node-v${1}-mips-openwrt-musl/

    # applying general purpose use patches
    patch -p1 < $CURDIR/patches/no-git-check.patch

    # applying musl specific patches
    for i in ../node${major}-musl-patches/*.patch
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
    sed -i -e "s/-\$(ARCH)/\-mips-openwrt-musl/g" Makefile
    time make -j3 binary

}

# update git repo, pull new version
nodever=$1
major=`echo $nodever | cut -d. -f1`
minor=`echo $nodever | cut -d. -f2`
revision=`echo $nodever | cut -d. -f3`

# echo "$major.$minor.$revision"

applying specific patches for node native tools
if [[ $major == 7 || ($major == 8 && $minor -le 2) ]]
then
    # preparing sources
    untar ${1} linux
    untar ${1} mips-openwrt-musl
    echo -e "\nFixing v8.gyp file...\n"
    fixv8gyp ${1} mips-openwrt-musl
    echo $var
    sleep 1
    # performing host build
    hostbuild ${1}
    cd $CURDIR
else
    # simply extracting tarball for cross-build
    untar ${1} mips-openwrt-musl
fi

# exporting compilers
export STAGING_DIR=/opt/toolchain-540-musl-ctng
export PATH=$STAGING_DIR/bin:$PATH

# MIPS openwrt cross-compile exports
export HOST="mips-openwrt-linux-musl"
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

crossbuild $1
cd $CURDIR

echo -e "\nFinished !\n"
