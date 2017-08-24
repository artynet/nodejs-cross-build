#!/bin/bash -x
## Node.js v8 for i486 uClibc OpenWRT Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

clean () {

    rm -rvf node-v$1/ node-v$1-i486-openwrt-uclibc/

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
export STAGING_DIR=$HOME/x-tools/i486-openwrt-linux-uclibc
export PATH=$STAGING_DIR/bin:$PATH

# i486 openwrt cross-compile exports
export HOST="i486-openwrt-linux-uclibc"
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

mv node-v${1}/ node-v${1}-i486-openwrt-uclibc/

cd node-v${1}-i486-openwrt-uclibc/

for i in ../node8-uclibc-patches/*.patch
do
    patch -p1 < $i
done

# clear out old builds
echo "cleaning..."
make clean

# build
echo "building..."
export ARCH=x86 DESTCPU=x86
export CONFIG_FLAGS="--without-snapshot --with-intl=none --dest-os=linux"
sed -i -e s/small-icu/none/g Makefile
sed -i -e "s/-\$(ARCH)/\-i486-openwrt-uclibc/g" Makefile
time make -j3 binary
