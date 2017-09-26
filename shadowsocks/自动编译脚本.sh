#!/bin/sh

# cross & static compile shadowsocks-libev

PCRE_VER=8.41
PCRE_FILE="http://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VER.tar.gz"

MBEDTLS_VER=2.6.0
MBEDTLS_FILE="https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz"

LIBSODIUM_VER=1.0.14
LIBSODIUM_FILE="https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz"

LIBEV_VER=4.24
LIBEV_FILE="https://fossies.org/linux/misc/libev-$LIBEV_VER.tar.gz"

CARES_FILE="https://github.com/c-ares/c-ares.git"

UDNS_FILE="https://github.com/shadowsocks/libudns"

SHADOWSOCKS_LIBEV_VER=3.1.0
SHADOWSOCKS_LIBEV_FILE="https://github.com/shadowsocks/shadowsocks-libev"

SIMPLE_OBFS_VER=0.0.3
SIMPLE_OBFS_FILE="https://github.com/shadowsocks/simple-obfs"

SHADOWSOCKSR_LIBEV_FILE="https://github.com/shadowsocksr-backup/shadowsocksr-libev.git"

cur_dir=$(pwd)

prepare() {
    rm -rf $cur_dir/build && mkdir $cur_dir/build
}

compile_pcre() {
    [ -d $prefix/pcre ] && return

    cd $cur_dir/build
    wget --no-check-certificate $PCRE_FILE
    tar xvf pcre-$PCRE_VER.tar.gz
    cd pcre-$PCRE_VER
    ./configure --prefix=$prefix/pcre --host=$host --enable-utf8 --enable-unicode-properties --disable-shared
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

compile_mbedtls() {
    [ -d $prefix/mbedtls ] && return

    cd $cur_dir/build
    wget --no-check-certificate $MBEDTLS_FILE
    tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz
    cd mbedtls-$MBEDTLS_VER
    prefix_reg=$(echo $prefix | sed "s/\//\\\\\//g")
    sed -i "s/DESTDIR=\/usr\/local/DESTDIR=$prefix_reg\/mbedtls/g" Makefile
    [ -z $host ] && make install -j$(getconf _NPROCESSORS_ONLN) || CC=$host-gcc AR=$host-ar LD=$host-ld make install -j$(getconf _NPROCESSORS_ONLN)
}

compile_libsodium() {
    [ -d $prefix/libsodium ] && return

    cd $cur_dir/build
    wget --no-check-certificate $LIBSODIUM_FILE
    tar xvf libsodium-$LIBSODIUM_VER.tar.gz
    cd libsodium-$LIBSODIUM_VER
    ./configure --prefix=$prefix/libsodium --host=$host --disable-ssp --disable-shared
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

compile_libev() {
    [ -d $prefix/libev ] && return

    cd $cur_dir/build
    wget --no-check-certificate $LIBEV_FILE
    tar xvf libev-$LIBEV_VER.tar.gz
    cd libev-$LIBEV_VER
    ./configure --prefix=$prefix/libev --host=$host --disable-shared
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

compile_libudns() {
    [ -d $prefix/libudns ] && return

    cd $cur_dir/build
    git clone --depth 1 $UDNS_FILE
    cd libudns
    ./autogen.sh
    ./configure --prefix=$prefix/libudns --host=$host
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

compile_cares() {
    [ -d $prefix/cares ] && return

    cd $cur_dir/build
    git clone --depth 1 $CARES_FILE
    cd c-ares
    ./buildconf
    autoconf configure.ac
    ./configure --prefix=$prefix/cares --host=$host --disable-shared
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

compile_shadowsocks_libev() {
    [ -f $prefix/shadowsocks-libev/bin/ss-local ] && return

    cd $cur_dir/build
    git clone --depth 1 --branch v$SHADOWSOCKS_LIBEV_VER $SHADOWSOCKS_LIBEV_FILE
    cd shadowsocks-libev
    git submodule update --init --recursive
    ./autogen.sh
    LIBS="-lpthread -lm" LDFLAGS="-Wl,-static -static -static-libgcc -L$prefix/libudns/lib -L$prefix/libev/lib" CFLAGS="-I$prefix/libudns/include -I$prefix/libev/include" ./configure --prefix=$prefix/shadowsocks-libev --host=$host --disable-ssp --disable-documentation --with-cares=$prefix/cares --with-mbedtls=$prefix/mbedtls --with-pcre=$prefix/pcre --with-sodium=$prefix/libsodium
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

compile_simple_obfs() {
    [ -f $prefix/shadowsocks-libev/bin/obfs-local ] && return

    cd $cur_dir/build
    git clone --depth 1 --branch v$SIMPLE_OBFS_VER $SIMPLE_OBFS_FILE
    cd simple-obfs
    git submodule update --init --recursive
    ./autogen.sh
    LIBS="-lpthread -lm" LDFLAGS="-Wl,-static -static -static-libgcc -L$prefix/libudns/lib -L$prefix/cares/lib -L$prefix/libev/lib -L$prefix/libsodium/lib" CFLAGS="-I$prefix/libudns/include -I$prefix/cares/include -I$prefix/libev/include -I$prefix/libsodium/include" ./configure --prefix=$prefix/shadowsocks-libev --host=$host --disable-ssp --disable-documentation
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

compile_shadowsocksr_libev() {
    [ -f $prefix/shadowsocksr-libev/bin/ss-local ] && return

    cd $cur_dir/build
    git clone --depth 1 $SHADOWSOCKSR_LIBEV_FILE
    cd shadowsocksr-libev
    ./autogen.sh
    LIBS="-lpthread -lm" LDFLAGS="-Wl,-static -static -static-libgcc -L$prefix/libudns/lib -L$prefix/libev/lib" CFLAGS="-I$prefix/libudns/include -I$prefix/libev/include" ./configure --prefix=$prefix/shadowsocksr-libev --host=$host --disable-ssp --disable-documentation --with-mbedtls=$prefix/mbedtls --with-pcre=$prefix/pcre
    make -j$(getconf _NPROCESSORS_ONLN) && make install
}

clean() {
    cd $cur_dir
    rm -rf $cur_dir/build
}

host=arm-linux

red="\033[0;31m"
green="\033[0;32m"
plain="\033[0m"

[ -z $host ] && compiler=gcc || compiler=$host-gcc
if [ -f "$(which $compiler)" ]; then
	echo -e "found cross compiler ${green}$(which ${compiler})${plain}"
else
	echo -e "${red}Error:${plain} not found cross compiler ${green}${compiler}${plain}"
	exit -1
fi

[ -z $prefix ] && prefix=$cur_dir/dists
echo -e "binaries will be installed in ${green}${prefix}${plain}"

prepare
compile_pcre
compile_mbedtls
compile_libsodium
compile_libev
compile_libudns
compile_cares
compile_shadowsocks_libev
compile_simple_obfs
compile_shadowsocksr_libev
clean
