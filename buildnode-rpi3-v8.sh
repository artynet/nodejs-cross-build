#!/bin/bash -x
## Node.js for Raspberry Pi 3 Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

clean () {

    rm -rvf node-v$1/ node-v$1-rpi3/
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
export PATH=$HOME/x-tools/armv8-rpi3-linux-gnueabihf/bin:$PATH

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

# update git repo, pull new version

if [ ! -e node-v${1}.tar.gz ]
then
    echo "Downloading node source ${VERSION}-release..."
    wget http://nodejs.org/dist/v${1}/node-v${1}.tar.gz
    tar xvf node-v${1}.tar.gz
else
    tar xvf node-v${1}.tar.gz
fi

mv node-v${1}/ node-v${1}-rpi3/

cd node-v${1}-rpi3/

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
