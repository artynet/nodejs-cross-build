#!/bin/bash -x
## Node.js for Raspberry Pi 2 Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

WORKDIR=$PWD

clean () {

    rm -rvf node-v$1-linux-arm-openwrt/
	
}

fixv7 () {

	var=$(readlink -f ../node-v${1}-linux)"/out/Release/mkpeephole"
	sed "s#<(mkpeephole_exec)#$var#g" -i deps/v8/src/v8.gyp

}

fixv10 () {

	var1='<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)torque<(EXECUTABLE_SUFFIX)'
	var2=$(readlink -f ../node-v${1}-linux)"/out/Release/torque"
	
	sed "s#$var1#$var2#g" -i deps/v8/gypfiles/v8.gyp
	
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
export STAGING_DIR=$HOME/x-tools
export PATH=$HOME/x-tools/arm-openwrt-linux-muslgnueabi/bin:$PATH

# raspberry pi 2 cross-compile exports
export HOST="arm-openwrt-linux-muslgnueabi"
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

mv node-v${1}/ node-v${1}-linux-arm-openwrt/

cd node-v${1}-linux-arm-openwrt/

nodever=$(echo "${1}" | sed s/[.].*$//)

# applying specific patches for node v7 native tools
if [ ${nodever} = 7 ]
then
    echo "ok v7"
    fixv7 ${1}
    echo $var
    sleep 1
elif [ ${nodever} -ge 10 ]
then
    echo "ok greater than v10"
    fixv10 ${1}
    echo $var2
    sleep 1
fi

# applying openwrt patches
for t in $WORKDIR/node-openwrt-patches-v${nodever}/*.patch
do
	patch -p1 < $t
done

# clear out old builds
echo "cleaning..."
make clean

# build
echo "building..."
export ARCH=arm DESTCPU=arm
export CONFIG_FLAGS="--without-snapshot --with-arm-fpu=vfpv3" LDFLAGS="${LDFLAGS} -latomic"
sed -i -e s/small-icu/none/g Makefile
sed -i -e "s/-\$(ARCH)/\-arm-openwrt/g" Makefile
make -j3 binary
