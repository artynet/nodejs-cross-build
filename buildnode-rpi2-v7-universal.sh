#!/bin/bash -x
## Node.js for Raspberry Pi 2 Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

CURDIR=$PWD

clean () {

    rm -rvf node-v$1 node-v$1-rpi2 node-v$1-linux
}

fixv7 () {

    var=$(readlink -f $CURDIR/node-v${1}-linux)"/out/Release/mkpeephole"
    sed "s#<(mkpeephole_exec)#$var#g" -i $CURDIR/node-v${1}-linux/deps/v8/src/v8.gyp
}

if [ -z ${1} ]; then
  echo "set the VERSION first"
  exit 1
fi

# clear out old builds
echo "cleaning..."
clean ${1}

sleep 1

# exporting compilers
export PATH=/opt/armv7-rpi2-linux-gnueabihf/bin:$PATH

# raspberry pi 2 cross-compile exports
export HOST="armv7-rpi2-linux-gnueabihf"
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

# update git repo, pull new version

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

    # clear out old builds
    echo "cleaning..."
    make clean

    # build
    echo "building..."
    export CONFIG_FLAGS="--without-snapshot --with-intl=none"
    sed -i -e s/small-icu/none/g Makefile
    make -j3 binary

}

crossbuild () {

    # clear out old builds
    echo "cleaning..."
    make clean

    # build
    echo "building..."
    export ARCH=arm DESTCPU=arm
    export CONFIG_FLAGS="--without-snapshot --with-intl=none"
    sed -i -e s/small-icu/none/g Makefile
    sed -i -e "s/-\$(ARCH)/\-armv7l-rpi2/g" Makefile
    make -j3 binary

}

nodever=$(echo "${1}" | sed s/[.].*$//)

# applying specific patches for node v7 native tools
if [ ${nodever} = 7 ]
then
    untar ${1} linux
    echo "ok v7"
    fixv7 ${1}
    echo $var
    sleep 1
fi


hostbuild ${1}
cd $CURDIR

crossbuild

cd $CURDIR
