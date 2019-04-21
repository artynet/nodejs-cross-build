#!/bin/bash -x
## Node.js for Raspberry Pi armhf Packaging Script
## =========================================
## Use like this:
## ./buildnode.sh <node_tarball_version>

WORKDIR=$PWD

nodever=$(echo "${1}" | sed s/[.].*$//)

clean () {

    rm -rvf node-v$1-armhf/ node-v$1-linux/
	
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

native_build () {
	
	[[ -d node-v${1}-linux ]] && return 0

	# unpacking for native build
	tar xvf node-v${1}.tar.gz
	mv node-v${1} node-v${1}-linux
	cd node-v${1}-linux/

	# native build
	echo "native building..."
	export CONFIG_FLAGS="--with-intl=none"
	sed -i -e s/small-icu/none/g Makefile
	make -j3 binary

	cd $WORKDIR
	
}

# sets the version
if [ -z ${1} ]; then
  echo "set the VERSION first"
  exit 1
fi

# clear out old builds
echo "cleaning..."
clean ${1}

sleep 1

# update git repo, pull new version
if [ ! -e node-v${1}.tar.gz ]
then
    echo "Downloading node source ${VERSION}-release..."
    wget http://nodejs.org/dist/v${1}/node-v${1}.tar.gz
fi

if [ ${nodever} -ge 10 ]
then
    native_build ${1}
fi

##### CROSS COMPILING ####

# exporting compilers
# export PATH=/opt/armv7-armhf-linux-gnueabihf/bin:$PATH

# raspberry pi armhf cross-compile exports
export HOST="arm-linux-gnueabihf"
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

tar xvf node-v${1}.tar.gz

mv node-v${1}/ node-v${1}-armhf/

cd node-v${1}-armhf/

# applying specific patches for node v7 native tools
nodever=$(echo "${1}" | sed s/[.].*$//)

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

# clear out old builds
echo "cleaning..."
make clean

# build
echo "building..."
export ARCH=arm DESTCPU=arm
export CONFIG_FLAGS="--without-snapshot --with-intl=none"
sed -i -e s/small-icu/none/g Makefile
sed -i -e "s/-\$(ARCH)/\-armv7l-armhf/g" Makefile
make -j3 binary
