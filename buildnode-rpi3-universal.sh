#!/bin/bash -x
## Node.js for Raspberry Pi 2 Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

CURDIR=$PWD

clean () {

    rm -rvf node-v$1 node-v$1-rpi3 node-v$1-linux
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

    mkdir -p $CURDIR/TARBALL

    local VERSION=${1}

    if [ ! -e $CURDIR/TARBALL/node-v${1}.tar.xz ]
    then
        echo "Downloading node source v${VERSION}-release..."
        curl -o $CURDIR/TARBALL/node-v${1}.tar.xz http://nodejs.org/dist/v${1}/node-v${1}.tar.xz
        tar xvf $CURDIR/TARBALL/node-v${1}.tar.xz -C $CURDIR
    else
        tar xvf $CURDIR/TARBALL/node-v${1}.tar.xz -C $CURDIR
    fi

    mv node-v${1}/ node-v${1}-${2}/

}

hostbuild () {

    cd node-v${1}-linux/
    patch -p1 < $CURDIR/patches/no-git-check-v${major}.patch

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

    cd node-v${1}-rpi3/
    patch -p1 < $CURDIR/patches/no-git-check-v${major}.patch

    # exportcross
    # clear out old builds
    echo "cleaning..."
    make clean

    # build
    echo "building..."
    export ARCH=arm DESTCPU=arm
    export CONFIG_FLAGS="--without-snapshot --with-intl=none"
    sed -i -e s/small-icu/none/g Makefile
    sed -i -e "s/-\$(ARCH)/\-armv8-rpi3/g" Makefile
    time make -j3 binary

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
    untar ${1} linux
    untar ${1} rpi3
    echo -e "\nFixing v8.gyp file...\n"
    fixv8gyp ${1} rpi3
    echo $var
    sleep 1
    # performing host build
    hostbuild ${1}
    cd $CURDIR
else
    # simply extracting tarball for cross-build
    untar ${1} rpi3
fi

# exporting compilers
export PATH=/opt/armv8-rpi3-linux-gnueabihf/bin:$PATH

# raspberry pi 3 cross-compile exports
export HOST="armv8-rpi3-linux-gnueabihf"
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
