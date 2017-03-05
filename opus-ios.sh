#! /bin/bash
#Created by 郑丰 on 2017/2/22.
#Copyright © 2017年 zhengfeng. All rights reserved.

cd `dirname $0`
set -e

#自定义选项
MINIOSVERSION="8.0"
OPUS_DIR="opus-1.2-alpha"
#build
ALL_ARCHS_IOS8_SDK="armv7 arm64 i386 x86_64"
BUILD_ROOT="`pwd`/build"
mkdir -p ${BUILD_ROOT};

ARCHS=${ALL_ARCHS_IOS8_SDK}

DEVELOPER=`xcode-select -print-path`
XCRUN_OSVERSION="-miphoneos-version-min=${MINIOSVERSION}"
#config
OPUS_COMMON_CONFIG=
OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --enable-float-approx"
OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --disable-shared"
OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --enable-static"
OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --with-pic"
OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --disable-doc"
#Method
echo_check() {
    echo "===================="
    echo "[*] check xcode version"
    echo "====$ARCHS===="
    echo "github:https://github.com/SnowMango"
    echo "===================="
}

build_arch()
{
    ARCH=$1
    if [ -z "$ARCH" ]; then
        echo "You must specific an architecture 'armv7, armv7s, arm64, i386, x86_64, ...'.\n"
        exit 1
    fi
    ARCH_ROOT="${BUILD_ROOT}/opus-${ARCH}"
    ARCH_LIB="${ARCH_ROOT}/lib"
    ARCH_INCLUDE="${ARCH_ROOT}/include"
    mkdir -p ${ARCH_ROOT}
    mkdir -p ${ARCH_LIB}
    mkdir -p ${ARCH_INCLUDE}

    if [ "${ARCH}" == "i386" -o "${ARCH}" == "x86_64" ]
    then
        PLATFORM="iphonesimulator"
        EXTRA_CONFIG="--host=x86_64-apple-darwin"
    else
        PLATFORM="iphoneos"
        EXTRA_CONFIG="--host=arm-apple-darwin"
    fi
    SYSROOT=eval xcrun -sdk ${PLATFORM} --show-sdk-path
    OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --with-sysroot=${SYSROOT}"
    OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --libdir=${ARCH_LIB}"
    OPUS_COMMON_CONFIG="${OPUS_COMMON_CONFIG} --includedir=${ARCH_INCLUDE}"

export CC="xcrun -sdk ${PLATFORM} clang -arch ${ARCH} ${XCRUN_OSVERSION}"
export CCAS="xcrun -sdk ${PLATFORM} clang -arch ${ARCH} ${XCRUN_OSVERSION} -no-integrated-as"
    cd ${OPUS_DIR}
    ./configure ${OPUS_COMMON_CONFIG} \
        ${EXTRA_CONFIG}

    make
    make install
    make clean
    cd `dirname $0`
}

build_all()
{
    for ARCH in ${ARCHS}
    do
        build_arch $ARCH
    done
}

build_lipo()
{
    LIPO_ROOT="${BUILD_ROOT}/opus-lipo"
    LIPO_LIB_DIR="${LIPO_ROOT}/lib"
    mkdir -p ${LIPO_ROOT}
    mkdir -p ${LIPO_LIB_DIR}
    LIPO_OS="libopus-iphoneos.a"
    LIPO_SIM="libopus-iphonesimulator.a"
    LIPO_All="libopus.a"

    LIPO_TARGET=$1

case "$LIPO_TARGET" in
    os)
        LIPO_OUTFILE=${LIPO_OS}
        LIPO_SOURCE_ARCH="armv7 arm64"
    ;;
    simulator)
        LIPO_OUTFILE=${LIPO_SIM}
        LIPO_SOURCE_ARCH="i386 x86_64"
    ;;
    all)
        LIPO_OUTFILE=${LIPO_All}
        LIPO_SOURCE_ARCH=${ARCHS}
    ;;
    *)
    echo "  opus-ios.sh lipo [all|os|simulator]"
    exit 1
    ;;
esac

    LIPO_FLAGS=
    for ARCH in $LIPO_SOURCE_ARCH
    do
        SOURCE_DIR="${BUILD_ROOT}/opus-${ARCH}"
        SOURCE_LIB_FILE="${SOURCE_DIR}/lib/libopus.a"
        if [ -f "$SOURCE_LIB_FILE" ]; then
            LIPO_FLAGS="$LIPO_FLAGS $SOURCE_LIB_FILE"
        else
            echo "skip $SOURCE_LIB_FILE of $ARCH";
        fi
    done
    cd $LIPO_LIB_DIR
    xcrun lipo -create $LIPO_FLAGS -output $LIPO_LIB_DIR/$LIPO_OUTFILE
    xcrun lipo -info $LIPO_LIB_DIR/$LIPO_OUTFILE
    du -h $LIPO_LIB_DIR/$LIPO_OUTFILE
    cd `dirname $0`
    if [ -f "$LIPO_LIB_DIR/$LIPO_OUTFILE" ]; then
        cp -R "${SOURCE_DIR}/include" "${LIPO_ROOT}"
    fi
}

build_clean()
{
    echo "clean build"
    echo "================="
    rm -rf ${BUILD_ROOT}
    echo "clean success"
}
# main
main()
{
    TARGET=$1
    if [ "$TARGET" = "armv7" -o "$TARGET" = "arm64" ]; then
        build_arch $TARGET
    elif [ "$TARGET" = "i386" -o "$TARGET" = "x86_64" ]; then
        build_arch $TARGET
    elif [ "$TARGET" = "lipo" ]; then
        build_lipo $2
    elif [ "$TARGET" = "all" ]; then
        build_all
    elif [ "$TARGET" = "check" ]; then
        echo_check
    elif [ "$TARGET" = "clean" ]; then
        build_clean
    else
        echo "Usage:"
        echo "  opus-ios.sh armv7|arm64|i386|x86_64"
        echo "  opus-ios.sh lipo all[os|simulator]"
        echo "  opus-ios.sh all"
        echo "  opus-ios.sh clean"
        echo "  opus-ios.sh check"
        exit 1
    fi
}

echo "============================="
echo "[*] opus-ios.sh xecute start"
echo "============================="
main $1 $2
echo "=============================="
echo "[*] opus-ios.sh xecute finish"
echo "=============================="

