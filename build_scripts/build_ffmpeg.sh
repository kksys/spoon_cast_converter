#!/bin/bash

FREETYPE_VERSION="2.11.0"
FREETYPE_REPOSITORY="https://github.com/freetype/freetype.git"
FRIBIDI_VERSION="1.0.10"
FRIBIDI_REPOSITORY="https://github.com/fribidi/fribidi.git"
ASS_VERSION="0.15.1"
ASS_REPOSITORY="https://github.com/libass/libass.git"
AOM_VERSION="3.1.1"
AOM_REPOSITORY="https://aomedia.googlesource.com/aom"
DAV1D_VERSION="0.9.1"
DAV1D_REPOSITORY="https://code.videolan.org/videolan/dav1d.git"
MP3LAME_VERSION="3.100"
MP3LAME_PACKAGE="https://jaist.dl.sourceforge.net/project/lame/lame/${MP3LAME_VERSION}/lame-${MP3LAME_VERSION}.tar.gz"
OPUS_VERSION="1.3.1"
OPUS_REPOSITORY="https://github.com/xiph/opus.git"
SNAPPY_VERSION="1.1.8"
SNAPPY_REPOSITORY="https://github.com/google/snappy.git"
OGG_VERSION="1.3.5"
OGG_REPOSITORY="https://github.com/xiph/ogg.git"
THEORA_VERSION="1.1.1"
THEORA_REPOSITORY="https://github.com/xiph/theora.git"
VORBIS_VERSION="1.3.7"
VORBIS_REPOSITORY="https://github.com/xiph/vorbis.git"
VPX_VERSION="1.10.0"
VPX_REPOSITORY="https://chromium.googlesource.com/webm/libvpx"
LZMA_VERSION="5.2.5"
LZMA_REPOSITORY="https://git.tukaani.org/xz.git"
FFMPEG_VERSION="n5.0.1"
FFMPEG_PACKAGE="https://github.com/FFmpeg/FFmpeg/archive/refs/tags/${FFMPEG_VERSION}.tar.gz"

#                             +------------------------------------------------+-----------------------------------------+
#                             | License                                        | Note                                    |
#                             +------------------------------------------------+-----------------------------------------+
FFMPEG_ENABLE_FREETYPE=0    # | GPL                                            | this is for video, not audio            |
FFMPEG_ENABLE_ASS=0         # | non GPL, but this library requires libfreetype | this is for video, not audio            |
FFMPEG_ENABLE_AOM=1         # | non GPL                                        |                                         |
# FFMPEG_ENABLE_AOM=0
FFMPEG_ENABLE_DAV1D=1       # | non GPL                                        |                                         |
# FFMPEG_ENABLE_DAV1D=0
FFMPEG_ENABLE_MP3LAME=1     # | non GPL                                        |                                         |
# FFMPEG_ENABLE_MP3LAME=0
FFMPEG_ENABLE_OPUS=1        # | non GPL                                        |                                         |
# FFMPEG_ENABLE_OPUS=0
FFMPEG_ENABLE_SNAPPY=1      # | ?                                              |                                         |
# FFMPEG_ENABLE_SNAPPY=0
FFMPEG_ENABLE_THEORA=1      # | ?                                              |                                         |
# FFMPEG_ENABLE_THEORA=0
FFMPEG_ENABLE_VORBIS=1      # | BSD                                            |                                         |
# FFMPEG_ENABLE_VORBIS=0
FFMPEG_ENABLE_VPX=1         # | BSD                                            |                                         |
FFMPEG_ENABLE_FDK_AAC=0     # | non GPL, but this library requires license fee |                                         |
FFMPEG_ENABLE_FONTCONFIG=0  # |                                                | this is for video, not audio            |
FFMPEG_ENABLE_FFMPEG=1      # | multiple lisence                               |                                         |
# FFMPEG_ENABLE_FFMPEG=0
#                             +------------------------------------------------+-----------------------------------------+

OSX_VERSION=11.0

RAMDISK_FILENAME=$(hdid -nomount ram://1024000)
VOLUME_NAME="ffmpeg_build"

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

INSTALL_PATH="/Volumes/${VOLUME_NAME}"
DIST_PATH=$(realpath modules/ffmpeg/dist)

prepare_freetype_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "freetype" ]]; then
        git clone ${FREETYPE_REPOSITORY} freetype
    fi
    cd freetype
    git fetch --all
    git checkout refs/tags/VER-$(echo ${FREETYPE_VERSION/./-})

    popd
}

prepare_fribidi_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "fribidi" ]]; then
        git clone ${FRIBIDI_REPOSITORY} fribidi
    fi
    cd fribidi
    git fetch --all
    git checkout refs/tags/v${FRIBIDI_VERSION}

    popd
}

prepare_ass_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "ass" ]]; then
        git clone ${ASS_REPOSITORY} ass
    fi
    cd ass
    git fetch --all
    git checkout refs/tags/${ASS_VERSION}

    popd
}

prepare_aom_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "aom" ]]; then
        git clone ${AOM_REPOSITORY} aom
    fi
    cd aom
    git fetch --all
    git checkout refs/tags/v${AOM_VERSION}

    local TOOLCHAIN_PATH="build/cmake/toolchains/arm64-macos.cmake"
    if [[ ! -e ${TOOLCHAIN_PATH} ]]; then
        echo "set(CMAKE_SYSTEM_PROCESSOR \"arm64\")" > ${TOOLCHAIN_PATH}
        echo "set(CMAKE_SYSTEM_NAME \"Darwin\")" >> ${TOOLCHAIN_PATH}
        echo "set(CMAKE_OSX_ARCHITECTURES \"arm64\")" >> ${TOOLCHAIN_PATH}
        echo "set(CMAKE_C_COMPILER_ARG1 \"-mmacosx-version-min=$OSX_VERSION -arch arm64 -target aarch64-apple-darwin\")" >> ${TOOLCHAIN_PATH}
        echo "set(CMAKE_CXX_COMPILER_ARG1 \"-arch arm64 -target aarch64-apple-darwin\")" >> ${TOOLCHAIN_PATH}
        echo "# Apple tools always complain in 32 bit mode without PIC." >> ${TOOLCHAIN_PATH}
        echo "set(CONFIG_PIC 1 CACHE STRING \"\")" >> ${TOOLCHAIN_PATH}
        echo "# No runtime cpu detect for arm*-ios targets." >> ${TOOLCHAIN_PATH}
        echo "set(CONFIG_RUNTIME_CPU_DETECT 0 CACHE STRING \"\")" >> ${TOOLCHAIN_PATH}
    fi

    local TOOLCHAIN_PATH="build/cmake/toolchains/x86_64-macos.cmake"
    if [[ ! -e ${TOOLCHAIN_PATH} ]]; then
        echo "set(CMAKE_SYSTEM_PROCESSOR \"x86_64\")" > ${TOOLCHAIN_PATH}
        echo "set(CMAKE_SYSTEM_NAME \"Darwin\")" >> ${TOOLCHAIN_PATH}
        echo "set(CMAKE_OSX_ARCHITECTURES \"x86_64\")" >> ${TOOLCHAIN_PATH}
        echo "set(CMAKE_C_COMPILER_ARG1 \"-mmacosx-version-min=$OSX_VERSION -arch x86_64 -target x86_64-apple-darwin\")" >> ${TOOLCHAIN_PATH}
        echo "set(CMAKE_CXX_COMPILER_ARG1 \"-arch x86_64 -target x86_64-apple-darwin\")" >> ${TOOLCHAIN_PATH}
        echo "# Apple tools always complain in 32 bit mode without PIC." >> ${TOOLCHAIN_PATH}
        echo "set(CONFIG_PIC 1 CACHE STRING \"\")" >> ${TOOLCHAIN_PATH}
        echo "# No runtime cpu detect for arm*-ios targets." >> ${TOOLCHAIN_PATH}
        echo "set(CONFIG_RUNTIME_CPU_DETECT 0 CACHE STRING \"\")" >> ${TOOLCHAIN_PATH}
    fi

    popd
}

prepare_dav1d_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "dav1d" ]]; then
        git clone ${DAV1D_REPOSITORY} dav1d
    fi
    cd dav1d
    git fetch --all
    git checkout refs/tags/${DAV1D_VERSION}

    local TOOLCHAIN_PATH="package/crossfiles/arm64-macos.meson"
    if [[ ! -e ${TOOLCHAIN_PATH} ]]; then
        echo "[binaries]" > ${TOOLCHAIN_PATH}
        echo "c = 'clang'" >> ${TOOLCHAIN_PATH}
        echo "cpp = 'clang++'" >> ${TOOLCHAIN_PATH}
        echo "ar = 'ar'" >> ${TOOLCHAIN_PATH}
        echo "strip = 'strip'" >> ${TOOLCHAIN_PATH}
        echo "pkgconfig = 'pkg-config'" >> ${TOOLCHAIN_PATH}
        echo "windres = 'windres'" >> ${TOOLCHAIN_PATH}
        echo "" >> ${TOOLCHAIN_PATH}
        echo "[properties]" >> ${TOOLCHAIN_PATH}
        echo "needs_exe_wrapper = true" >> ${TOOLCHAIN_PATH}
        echo "" >> ${TOOLCHAIN_PATH}
        echo "[host_machine]" >> ${TOOLCHAIN_PATH}
        echo "system = 'darwin'" >> ${TOOLCHAIN_PATH}
        echo "cpu_family = 'aarch64'" >> ${TOOLCHAIN_PATH}
        echo "endian = 'little'" >> ${TOOLCHAIN_PATH}
        echo "cpu = 'aarch64'" >> ${TOOLCHAIN_PATH}
    fi

    local TOOLCHAIN_PATH="package/crossfiles/x86_64-macos.meson"
    if [[ ! -e ${TOOLCHAIN_PATH} ]]; then
        echo "[binaries]" > ${TOOLCHAIN_PATH}
        echo "c = 'clang'" >> ${TOOLCHAIN_PATH}
        echo "cpp = 'clang++'" >> ${TOOLCHAIN_PATH}
        echo "ar = 'ar'" >> ${TOOLCHAIN_PATH}
        echo "strip = 'strip'" >> ${TOOLCHAIN_PATH}
        echo "pkgconfig = 'pkg-config'" >> ${TOOLCHAIN_PATH}
        echo "windres = 'windres'" >> ${TOOLCHAIN_PATH}
        echo "" >> ${TOOLCHAIN_PATH}
        echo "[properties]" >> ${TOOLCHAIN_PATH}
        echo "needs_exe_wrapper = true" >> ${TOOLCHAIN_PATH}
        echo "" >> ${TOOLCHAIN_PATH}
        echo "[host_machine]" >> ${TOOLCHAIN_PATH}
        echo "system = 'darwin'" >> ${TOOLCHAIN_PATH}
        echo "cpu_family = 'x86_64'" >> ${TOOLCHAIN_PATH}
        echo "endian = 'little'" >> ${TOOLCHAIN_PATH}
        echo "cpu = 'x86_64'" >> ${TOOLCHAIN_PATH}
    fi

    popd
}

prepare_mp3lame_sources() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/package/mp3lame
    cd modules/ffmpeg/package/mp3lame
    if [[ ! -e "lame-${MP3LAME_VERSION}.tar.gz" ]]; then
        wget ${MP3LAME_PACKAGE}
    fi

    cd ../../source
    if [[ ! -e "mp3lame" ]]; then
        tar zxvf ../package/mp3lame/lame-${MP3LAME_VERSION}.tar.gz
        mv ./lame-${MP3LAME_VERSION} ./mp3lame
    fi

    popd
}

prepare_opus_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "opus" ]]; then
        git clone ${OPUS_REPOSITORY} opus
    fi
    cd opus
    git fetch --all
    git checkout refs/tags/v${OPUS_VERSION}

    popd
}

prepare_snappy_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "snappy" ]]; then
        git clone ${SNAPPY_REPOSITORY} snappy
    fi
    cd snappy
    git fetch --all
    git checkout refs/tags/${SNAPPY_VERSION}

    popd
}

prepare_ogg_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "ogg" ]]; then
        git clone ${OGG_REPOSITORY} ogg
    fi
    cd ogg
    git fetch --all
    git checkout refs/tags/v${OGG_VERSION}

    popd
}

prepare_theora_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "theora" ]]; then
        git clone ${THEORA_REPOSITORY} theora
    fi
    cd theora
    git fetch --all
    git checkout refs/tags/v${THEORA_VERSION}

    popd
}

prepare_vorbis_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "vorbis" ]]; then
        git clone ${VORBIS_REPOSITORY} vorbis
    fi
    cd vorbis
    git fetch --all
    git checkout refs/tags/v${VORBIS_VERSION}

    popd
}

prepare_vpx_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "vpx" ]]; then
        git clone ${VPX_REPOSITORY} vpx
    fi
    cd vpx
    git fetch --all
    git checkout refs/tags/v${VPX_VERSION}

    popd
}

prepare_lzma_sources() {
    pushd $(pwd)

    cd modules/ffmpeg/source
    if [[ ! -e "lzma" ]]; then
        git clone ${LZMA_REPOSITORY} lzma
    fi
    cd lzma
    git fetch --all
    git checkout refs/tags/v${LZMA_VERSION}

    popd
}
prepare_ffmpeg_sources() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/package/ffmpeg
    cd modules/ffmpeg/package/ffmpeg
    if [[ ! -e "${FFMPEG_VERSION}.tar.gz" ]]; then
        wget ${FFMPEG_PACKAGE}
    fi

    cd ../../source
    if [[ ! -e "ffmpeg" ]]; then
        tar zxvf ../package/ffmpeg/${FFMPEG_VERSION}.tar.gz
        mv ./FFmpeg-${FFMPEG_VERSION} ./ffmpeg
    fi

    popd
}

build_freetype() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/source/freetype
    cd modules/ffmpeg/source/freetype

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libfreetype.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        autoreconf -i
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            CC=clang \
            --disable-fontconfig \
            --enable-shared \
            --disable-static

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_fribidi() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/source/fribidi
    cd modules/ffmpeg/source/fribidi

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libfribidi.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        autoreconf -i
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            CC=clang \
            --disable-fontconfig \
            --enable-shared \
            --disable-static

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_ass() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/source/ass
    cd modules/ffmpeg/source/ass

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libaom.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        autoreconf -i
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            CC=clang \
            --disable-fontconfig \
            --enable-shared \
            --disable-static

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_aom() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/build/aom
    cd modules/ffmpeg/build/aom

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libaom.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        rm -rf ./*
        cmake \
            ../../source/aom \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE=../../source/aom/build/cmake/toolchains/${ARCH}-macos.cmake \
            -DENABLE_TESTS=0 \
            -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
            -DBUILD_SHARED_LIBS=1

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_dav1d() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/build/dav1d
    cd modules/ffmpeg/build/dav1d

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libdav1d.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        rm -rf ./*
        LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        meson \
            --prefix=${PREFIX} \
            --cross-file=../../source/dav1d/package/crossfiles/${ARCH}-macos.meson \
            --buildtype=release \
            ../../source/dav1d

        ninja -j 4
        meson install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_mp3lame() {
    pushd $(pwd)

    cd modules/ffmpeg/source/mp3lame

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libmp3lame.dylib" ]]; then
        mkdir -p "${PREFIX}"

        gsed -i -z -e "s/lame_init_old\n//" include/libmp3lame.sym

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        CC=clang \
        CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            --disable-debug \
            --disable-static \
            --enable-shared \
            --enable-nasm

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_opus() {
    pushd $(pwd)

    cd modules/ffmpeg/source/opus

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libopus.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        ./autogen.sh
        CC=clang \
        CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            --disable-debug \
            --disable-static \
            --enable-shared

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_snappy() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/build/snappy
    cd modules/ffmpeg/build/snappy

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libsnappy.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        rm -rf ./*
        cmake \
            ../../source/snappy \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_SYSTEM_NAME=Darwin \
            -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
            -DCMAKE_OSX_ARCHITECTURES=${ARCH} \
            -DCMAKE_C_COMPILER_ARG1="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            -DCMAKE_CXX_COMPILER_ARG1="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            -DCONFIG_RUNTIME_CPU_DETECT=0 \
            -DSNAPPY_BUILD_TESTS=OFF \
            -DSNAPPY_BUILD_BENCHMARKS=OFF \
            -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
            -DBUILD_SHARED_LIBS=ON

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_ogg() {
    pushd $(pwd)

    cd modules/ffmpeg/source/ogg

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libogg.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        ./autogen.sh
        CC=clang \
        CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            --disable-static \
            --enable-shared

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_theora() {
    pushd $(pwd)

    cd modules/ffmpeg/source/theora

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libtheora.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        ./autogen.sh
        CC=clang \
        CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            --disable-oggtest \
            --disable-vorbistest \
            --disable-examples \
            --disable-static \
            --enable-shared

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_vorbis() {
    pushd $(pwd)

    mkdir -p modules/ffmpeg/build/vorbis
    cd modules/ffmpeg/build/vorbis

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libvorbis.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        rm -rf ./*
        cmake \
            ../../source/vorbis \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_SYSTEM_NAME=Darwin \
            -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
            -DCMAKE_OSX_ARCHITECTURES=${ARCH} \
            -DCMAKE_C_COMPILER_ARG1="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            -DCMAKE_CXX_COMPILER_ARG1="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            -DCONFIG_RUNTIME_CPU_DETECT=0 \
            -DSNAPPY_BUILD_TESTS=OFF \
            -DSNAPPY_BUILD_BENCHMARKS=OFF \
            -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
            -DBUILD_SHARED_LIBS=ON

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_vpx() {
    pushd $(pwd)

    cd modules/ffmpeg/source/vpx

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libvpx.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        local VPX_TARGET=""
        if [ "a${TARGET}z" == "aaarch64-apple-darwinz" ]; then
            VPX_TARGET="arm64-darwin20-gcc"
        elif [ "a${TARGET}z" == "ax86_64-apple-darwinz" ]; then
            VPX_TARGET="x86_64-darwin20-gcc"
        fi

        CC=clang \
        CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        ./configure \
            --prefix=${PREFIX} \
            --target=${VPX_TARGET} \
            --disable-examples \
            --disable-unit-tests \
            --enable-pic \
            --enable-vp9-highbitdepth \
            --disable-debug \
            --disable-static \
            --enable-shared

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_lzma() {
    pushd $(pwd)

    cd modules/ffmpeg/source/lzma

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/liblzma.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        ./autogen.sh

        CC=clang \
        CFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        LDFLAGS="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
        ./configure \
            --prefix=${PREFIX} \
            --host=${TARGET} \
            --disable-debug \
            --disable-dependency-tracking \
            --disable-silent-rules \
            --disable-static \
            --enable-shared

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

build_ffmpeg() {
    pushd $(pwd)

    cd modules/ffmpeg/source/ffmpeg

    local ARCH=$1
    local TARGET=$2

    make clean >/dev/null 2>&1
    make distclean >/dev/null 2>&1

    local PREFIX="${INSTALL_PATH}/mac-${ARCH}"
    if [[ ! -e "${PREFIX}/lib/libavcodec.dylib" ]]; then
        mkdir -p "${PREFIX}"

        local OLD_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}

        local LIBRARY_OPTION=""

        if [ ${FFMPEG_ENABLE_FREETYPE} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libfreetype"
        fi
        if [ ${FFMPEG_ENABLE_ASS} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libass"
        fi
        if [ ${FFMPEG_ENABLE_AOM} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libaom"
        fi
        if [ ${FFMPEG_ENABLE_DAV1D} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libdav1d"
        fi
        if [ ${FFMPEG_ENABLE_MP3LAME} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libmp3lame"
        fi
        if [ ${FFMPEG_ENABLE_OPUS} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libopus"
        fi
        if [ ${FFMPEG_ENABLE_SNAPPY} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libsnappy"
        fi
        if [ ${FFMPEG_ENABLE_THEORA} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libtheora"
        fi
        if [ ${FFMPEG_ENABLE_VORBIS} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libvorbis"
        fi
        if [ ${FFMPEG_ENABLE_VPX} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libvpx"
        fi
        if [ ${FFMPEG_ENABLE_FONTCONFIG} -eq 1 ]; then
            LIBRARY_OPTION="${LIBRARY_OPTION} --enable-libfontconfig"
        fi

        ./configure \
            --prefix=${PREFIX} \
            --enable-cross-compile \
            --target-os=darwin \
            --arch=${ARCH} \
            --extra-ldflags="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET -L${PREFIX}/lib" \
            --extra-cflags="-mmacosx-version-min=$OSX_VERSION -arch $ARCH -target $TARGET" \
            --cc=clang \
            --disable-programs \
            --disable-static \
            --enable-shared \
            ${LIBRARY_OPTION} \
            --enable-demuxer=dash \
            --disable-libjack \
            --disable-indev=jack \
            --enable-opencl \
            --enable-videotoolbox \
            --disable-libxcb \
            --disable-libxcb_shape \
            --disable-libxcb_shm \
            --disable-libxcb_xfixes \
            --disable-xlib \
            --disable-sdl2 \
            --disable-htmlpages

        make -j4 VERBOSE=1
        make install

        export PKG_CONFIG_PATH=${OLD_PKG_CONFIG_PATH}
    fi

    popd
}

generate_fat_binary() {
    pushd $(pwd)

    cd modules/ffmpeg/dist

    if [ ! -e "mac" ]; then
        local DIST="mac"
        mkdir -p ${DIST}/lib ${DIST}/include
        cp -R ${DIST}-arm64/include ${DIST}/

        local TARGET_LIB_NAME=""
        for lib_name in $(ls ${DIST}-x86_64/lib | grep "\.dylib$"); do
            if [ ! -L "${DIST}-x86_64/lib/${lib_name}" ]; then
                TARGET_LIB_NAME="${TARGET_LIB_NAME} ${lib_name}"
            fi
        done

        for lib_name in $(echo "${TARGET_LIB_NAME}"); do
            lipo -create -output ${DIST}/lib/${lib_name} \
                -arch arm64 ${DIST}-arm64/lib/${lib_name} \
                -arch x86_64 ${DIST}-x86_64/lib/${lib_name}
        done
    fi

    cd mac/lib

    install_name_tool -id "@rpath/libaom.3.1.1.dylib" libaom.3.1.1.dylib

    install_name_tool -id "@rpath/libavcodec.59.18.100.dylib" libavcodec.59.18.100.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libswresample.4.dylib" "@rpath/libswresample.4.3.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavutil.57.dylib" "@rpath/libavutil.57.17.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libdav1d.5.dylib" "@rpath/libdav1d.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/liblzma.5.dylib" "@rpath/liblzma.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libmp3lame.0.dylib" "@rpath/libmp3lame.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libopus.0.dylib" "@rpath/libopus.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoraenc.1.dylib" "@rpath/libtheoraenc.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoradec.1.dylib" "@rpath/libtheoradec.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" \
            libavcodec.59.18.100.dylib
    done
    install_name_tool \
        -change "libvpx.6.dylib" "@rpath/libvpx.6.dylib" \
        -change "@rpath/libsnappy.1.dylib" "@rpath/libsnappy.1.1.8.dylib" \
        -change "@rpath/libaom.3.dylib" "@rpath/libaom.3.1.1.dylib" \
        -change "libvorbis.0.4.9.dylib" "@rpath/libvorbis.0.4.9.dylib" \
        -change "libvorbisenc.2.0.12.dylib" "@rpath/libvorbisenc.2.0.12.dylib" \
        libavcodec.59.18.100.dylib

    install_name_tool -id "@rpath/libavdevice.59.4.100.dylib" libavdevice.59.4.100.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavfilter.8.dylib" "@rpath/libavfilter.8.24.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libswscale.6.dylib" "@rpath/libswscale.6.4.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavformat.59.dylib" "@rpath/libavformat.59.16.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavcodec.59.dylib" "@rpath/libavcodec.59.18.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libswresample.4.dylib" "@rpath/libswresample.4.3.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavutil.57.dylib" "@rpath/libavutil.57.17.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libdav1d.5.dylib" "@rpath/libdav1d.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/liblzma.5.dylib" "@rpath/liblzma.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libmp3lame.0.dylib" "@rpath/libmp3lame.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libopus.0.dylib" "@rpath/libopus.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoraenc.1.dylib" "@rpath/libtheoraenc.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoradec.1.dylib" "@rpath/libtheoradec.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" \
            libavdevice.59.4.100.dylib
    done
    install_name_tool \
        -change "libvpx.6.dylib" "@rpath/libvpx.6.dylib" \
        -change "@rpath/libsnappy.1.dylib" "@rpath/libsnappy.1.1.8.dylib" \
        -change "@rpath/libaom.3.dylib" "@rpath/libaom.3.1.1.dylib" \
        -change "libvorbis.0.4.9.dylib" "@rpath/libvorbis.0.4.9.dylib" \
        -change "libvorbisenc.2.0.12.dylib" "@rpath/libvorbisenc.2.0.12.dylib" \
        libavdevice.59.4.100.dylib

    install_name_tool -id "@rpath/libavfilter.8.24.100.dylib" libavfilter.8.24.100.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libswscale.6.dylib" "@rpath/libswscale.6.4.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavformat.59.dylib" "@rpath/libavformat.59.16.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavcodec.59.dylib" "@rpath/libavcodec.59.18.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libswresample.4.dylib" "@rpath/libswresample.4.3.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavutil.57.dylib" "@rpath/libavutil.57.17.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libdav1d.5.dylib" "@rpath/libdav1d.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/liblzma.5.dylib" "@rpath/liblzma.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libmp3lame.0.dylib" "@rpath/libmp3lame.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libopus.0.dylib" "@rpath/libopus.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoraenc.1.dylib" "@rpath/libtheoraenc.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoradec.1.dylib" "@rpath/libtheoradec.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" \
            libavfilter.8.24.100.dylib
    done
    install_name_tool \
        -change "libvpx.6.dylib" "@rpath/libvpx.6.dylib" \
        -change "@rpath/libsnappy.1.dylib" "@rpath/libsnappy.1.1.8.dylib" \
        -change "@rpath/libaom.3.dylib" "@rpath/libaom.3.1.1.dylib" \
        -change "libvorbis.0.4.9.dylib" "@rpath/libvorbis.0.4.9.dylib" \
        -change "libvorbisenc.2.0.12.dylib" "@rpath/libvorbisenc.2.0.12.dylib" \
        libavfilter.8.24.100.dylib

    install_name_tool -id "@rpath/libavformat.59.16.100.dylib" libavformat.59.16.100.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavcodec.59.dylib" "@rpath/libavcodec.59.18.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libswresample.4.dylib" "@rpath/libswresample.4.3.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavutil.57.dylib" "@rpath/libavutil.57.17.100.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libdav1d.5.dylib" "@rpath/libdav1d.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/liblzma.5.dylib" "@rpath/liblzma.5.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libmp3lame.0.dylib" "@rpath/libmp3lame.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libopus.0.dylib" "@rpath/libopus.0.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoraenc.1.dylib" "@rpath/libtheoraenc.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libtheoradec.1.dylib" "@rpath/libtheoradec.1.dylib" \
            -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" \
            libavformat.59.16.100.dylib
    done
    install_name_tool \
        -change "libvpx.6.dylib" "@rpath/libvpx.6.dylib" \
        -change "@rpath/libsnappy.1.dylib" "@rpath/libsnappy.1.1.8.dylib" \
        -change "@rpath/libaom.3.dylib" "@rpath/libaom.3.1.1.dylib" \
        -change "libvorbis.0.4.9.dylib" "@rpath/libvorbis.0.4.9.dylib" \
        -change "libvorbisenc.2.0.12.dylib" "@rpath/libvorbisenc.2.0.12.dylib" \
        libavformat.59.16.100.dylib

    install_name_tool -id "@rpath/libavutil.57.17.100.dylib" libavutil.57.17.100.dylib

    install_name_tool -id "@rpath/libswresample.4.3.100.dylib" libswresample.4.3.100.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavutil.57.dylib" "@rpath/libavutil.57.17.100.dylib" libswresample.4.3.100.dylib
    done

    install_name_tool -id "@rpath/libswscale.6.4.100.dylib" libswscale.6.4.100.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool -change "${INSTALL_PATH}/mac-${ARCH}/lib/libavutil.57.dylib" "@rpath/libavutil.57.17.100.dylib" libswscale.6.4.100.dylib
    done

    install_name_tool -id "@rpath/libdav1d.5.dylib" libdav1d.5.dylib

    install_name_tool -id "@rpath/liblzma.5.dylib" liblzma.5.dylib

    install_name_tool -id "@rpath/libmp3lame.0.dylib" libmp3lame.0.dylib

    install_name_tool -id "@rpath/libogg.0.dylib" libogg.0.dylib

    install_name_tool -id "@rpath/libopus.0.dylib" libopus.0.dylib

    install_name_tool -id "@rpath/libsnappy.1.1.8.dylib" libsnappy.1.1.8.dylib

    install_name_tool -id "@rpath/libtheora.0.dylib" libtheora.0.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" libtheora.0.dylib
    done

    install_name_tool -id "@rpath/libtheoradec.1.dylib" libtheoradec.1.dylib

    install_name_tool -id "@rpath/libtheoraenc.1.dylib" libtheoraenc.1.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" libtheoraenc.1.dylib
    done

    install_name_tool -id "@rpath/libvorbis.0.4.9.dylib" libvorbis.0.4.9.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" libvorbis.0.4.9.dylib
    done

    install_name_tool -id "@rpath/libvorbisenc.2.0.12.dylib" libvorbisenc.2.0.12.dylib
    install_name_tool -change "libvorbis.0.4.9.dylib" "@rpath/libvorbis.0.4.9.dylib" libvorbisenc.2.0.12.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" libvorbisenc.2.0.12.dylib
    done

    install_name_tool -id "@rpath/libvorbisfile.3.3.8.dylib" libvorbisfile.3.3.8.dylib
    install_name_tool -change "libvorbis.0.4.9.dylib" "@rpath/libvorbis.0.4.9.dylib" libvorbisfile.3.3.8.dylib
    for ARCH in $(echo "x86_64" "arm64"); do
        install_name_tool -change "${INSTALL_PATH}/mac-${ARCH}/lib/libogg.0.dylib" "@rpath/libogg.0.dylib" libvorbisfile.3.3.8.dylib
    done

    install_name_tool -id "@rpath/libvpx.6.dylib" libvpx.6.dylib

    popd
}

clean() {
    pushd $(pwd)

    cd modules/ffmpeg/dist

    for dir in $(echo "mac" "mac-arm64" "mac-x86_64"); do
        rm -rf ./${dir}
    done

    cd ../source
    rm -rf ./*

    cd ..
    rm -rf ./build

    popd
}

prepare_sources() {
    if [ ${FFMPEG_ENABLE_FREETYPE} -eq 1 -o ${FFMPEG_ENABLE_ASS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing freetype sources...                                                                            ="
        echo "============================================================================================================"
        # prepare freetype sources
        prepare_freetype_sources
    fi
    if [ ${FFMPEG_ENABLE_ASS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing fribidi sources...                                                                             ="
        echo "============================================================================================================"
        # prepare fribidi sources
        prepare_fribidi_sources

        echo "============================================================================================================"
        echo "= preparing ass sources...                                                                                 ="
        echo "============================================================================================================"
        # prepare ass sources
        prepare_ass_sources
    fi
    if [ ${FFMPEG_ENABLE_AOM} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing aom sources...                                                                                 ="
        echo "============================================================================================================"
        # prepare aom sources
        prepare_aom_sources
    fi
    if [ ${FFMPEG_ENABLE_DAV1D} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing dav1d sources...                                                                               ="
        echo "============================================================================================================"
        # prepare dav1d sources
        prepare_dav1d_sources
    fi
    if [ ${FFMPEG_ENABLE_MP3LAME} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing mp3lame sources...                                                                             ="
        echo "============================================================================================================"
        # prepare mp3lame sources
        prepare_mp3lame_sources
    fi
    if [ ${FFMPEG_ENABLE_OPUS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing opus sources...                                                                                ="
        echo "============================================================================================================"
        # prepare opus sources
        prepare_opus_sources
    fi
    if [ ${FFMPEG_ENABLE_SNAPPY} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing snappy sources...                                                                              ="
        echo "============================================================================================================"
        # prepare snappy sources
        prepare_snappy_sources
    fi
    if [ ${FFMPEG_ENABLE_THEORA} -eq 1 -o ${FFMPEG_ENABLE_VORBIS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing ogg sources...                                                                                 ="
        echo "============================================================================================================"
        # prepare ogg sources
        prepare_ogg_sources
    fi
    if [ ${FFMPEG_ENABLE_THEORA} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing theora sources...                                                                              ="
        echo "============================================================================================================"
        # prepare theora sources
        prepare_theora_sources
    fi
    if [ ${FFMPEG_ENABLE_VORBIS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing vorbis sources...                                                                              ="
        echo "============================================================================================================"
        # prepare vorbis sources
        prepare_vorbis_sources
    fi
    if [ ${FFMPEG_ENABLE_VPX} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing vpx sources...                                                                                 ="
        echo "============================================================================================================"
        # prepare vpx sources
        prepare_vpx_sources
    fi
    if [ ${FFMPEG_ENABLE_FFMPEG} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= preparing lzma sources...                                                                                ="
        echo "============================================================================================================"
        # prepare lzma sources
        prepare_lzma_sources

        echo "============================================================================================================"
        echo "= preparing ffmpeg sources...                                                                              ="
        echo "============================================================================================================"
        # prepare ffmpeg sources
        prepare_ffmpeg_sources
    fi
}

build() {
    if [ ${FFMPEG_ENABLE_FREETYPE} -eq 1 -o ${FFMPEG_ENABLE_ASS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building freetype sources...                                                                             ="
        echo "============================================================================================================"
        # freetype build
        build_freetype "x86_64" "x86_64-apple-darwin"
        build_freetype "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_ASS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building fribidi sources...                                                                              ="
        echo "============================================================================================================"
        # fribidi build
        build_fribidi "x86_64" "x86_64-apple-darwin"
        build_fribidi "arm64" "aarch64-apple-darwin"

        echo "============================================================================================================"
        echo "= building ass sources...                                                                                  ="
        echo "============================================================================================================"
        # ass build
        build_ass "x86_64" "x86_64-apple-darwin"
        build_ass "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_AOM} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building aom sources...                                                                                  ="
        echo "============================================================================================================"
        # aom build
        build_aom "x86_64" "x86_64-apple-darwin"
        build_aom "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_DAV1D} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building dav1d sources...                                                                                ="
        echo "============================================================================================================"
        # dav1d build
        build_dav1d "x86_64" "x86_64-apple-darwin"
        build_dav1d "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_MP3LAME} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building mp3lame sources...                                                                              ="
        echo "============================================================================================================"
        # mp3lame build
        build_mp3lame "x86_64" "x86_64-apple-darwin"
        build_mp3lame "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_OPUS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building opus sources...                                                                                 ="
        echo "============================================================================================================"
        # opus build
        build_opus "x86_64" "x86_64-apple-darwin"
        build_opus "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_SNAPPY} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building snappy sources...                                                                               ="
        echo "============================================================================================================"
        # snappy build
        build_snappy "x86_64" "x86_64-apple-darwin"
        build_snappy "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_THEORA} -eq 1 -o ${FFMPEG_ENABLE_VORBIS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building ogg sources...                                                                                  ="
        echo "============================================================================================================"
        # ogg build
        build_ogg "x86_64" "x86_64-apple-darwin"
        build_ogg "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_THEORA} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building theora sources...                                                                               ="
        echo "============================================================================================================"
        # theora build
        build_theora "x86_64" "x86_64-apple-darwin"
        build_theora "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_VORBIS} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building vorbis sources...                                                                               ="
        echo "============================================================================================================"
        # vorbis build
        build_vorbis "x86_64" "x86_64-apple-darwin"
        build_vorbis "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_VPX} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building vpx sources...                                                                                  ="
        echo "============================================================================================================"
        # vpx build
        build_vpx "x86_64" "x86_64-apple-darwin"
        build_vpx "arm64" "aarch64-apple-darwin"
    fi
    if [ ${FFMPEG_ENABLE_FFMPEG} -eq 1 ]; then
        echo "============================================================================================================"
        echo "= building lzma sources...                                                                                 ="
        echo "============================================================================================================"
        # lzma build
        build_lzma "x86_64" "x86_64-apple-darwin"
        build_lzma "arm64" "aarch64-apple-darwin"

        echo "============================================================================================================"
        echo "= building ffmpeg sources...                                                                               ="
        echo "============================================================================================================"
        # ffmpeg build
        build_ffmpeg "x86_64" "x86_64-apple-darwin"
        build_ffmpeg "arm64" "aarch64-apple-darwin"
    fi
}

copy_package_to_dist() {
    for DIR in $(ls ${INSTALL_PATH}); do
        cp -R ${INSTALL_PATH}/${DIR} ${DIST_PATH}/${DIR}
    done
}

collect_license_files() {
    pushd $(pwd)

    cd modules/ffmpeg

    if [ ${FFMPEG_ENABLE_FREETYPE} -eq 1 -o ${FFMPEG_ENABLE_ASS} -eq 1 ]; then
        mkdir -p dist/mac/license/freetype
        cp ./source/freetype/LICENSE.TXT ./dist/mac/license/freetype/LICENSE
        echo "${FREETYPE_VERSION}" > ./dist/mac/license/freetype/VERSION
    fi
    if [ ${FFMPEG_ENABLE_ASS} -eq 1 ]; then
        # fribidi build
        mkdir -p dist/mac/license/fribidi
        cp ./source/fribidi/COPYING ./dist/mac/license/fribidi/LICENSE
        echo "${FRIBIDI_VERSION}" > ./dist/mac/license/fribidi/VERSION

        # ass build
        mkdir -p dist/mac/license/ass
        cp ./source/ass/COPYING ./dist/mac/license/ass/LICENSE
        echo "${ASS_VERSION}" > ./dist/mac/license/ass/VERSION
    fi
    if [ ${FFMPEG_ENABLE_AOM} -eq 1 ]; then
        # aom build
        mkdir -p dist/mac/license/aom
        cp ./source/aom/LICENSE ./dist/mac/license/aom/LICENSE
        echo "${AOM_VERSION}" > ./dist/mac/license/aom/VERSION
    fi
    if [ ${FFMPEG_ENABLE_DAV1D} -eq 1 ]; then
        # dav1d build
        mkdir -p dist/mac/license/dav1d
        cp ./source/dav1d/COPYING ./dist/mac/license/dav1d/LICENSE
        echo "${DAV1D_VERSION}" > ./dist/mac/license/dav1d/VERSION
    fi
    if [ ${FFMPEG_ENABLE_MP3LAME} -eq 1 ]; then
        # mp3lame build
        mkdir -p dist/mac/license/mp3lame
        cp ./source/mp3lame/COPYING ./dist/mac/license/mp3lame/LICENSE
        echo "${MP3LAME_VERSION}" > ./dist/mac/license/mp3lame/VERSION
    fi
    if [ ${FFMPEG_ENABLE_OPUS} -eq 1 ]; then
        # opus build
        mkdir -p dist/mac/license/opus
        cp ./source/opus/COPYING ./dist/mac/license/opus/LICENSE
        echo "${OPUS_VERSION}" > ./dist/mac/license/opus/VERSION
    fi
    if [ ${FFMPEG_ENABLE_SNAPPY} -eq 1 ]; then
        # snappy build
        mkdir -p dist/mac/license/snappy
        cp ./source/snappy/COPYING ./dist/mac/license/snappy/LICENSE
        echo "${SNAPPY_VERSION}" > ./dist/mac/license/snappy/VERSION
    fi
    if [ ${FFMPEG_ENABLE_THEORA} -eq 1 -o ${FFMPEG_ENABLE_VORBIS} -eq 1 ]; then
        # ogg build
        mkdir -p dist/mac/license/ogg
        cp ./source/ogg/COPYING ./dist/mac/license/ogg/LICENSE
        echo "${OGG_VERSION}" > ./dist/mac/license/ogg/VERSION
    fi
    if [ ${FFMPEG_ENABLE_THEORA} -eq 1 ]; then
        # theora build
        mkdir -p dist/mac/license/theora
        cp ./source/theora/COPYING ./dist/mac/license/theora/LICENSE
        cat ./source/theora/LICENSE >> ./dist/mac/license/theora/LICENSE
        echo "${THEORA_VERSION}" > ./dist/mac/license/theora/VERSION
    fi
    if [ ${FFMPEG_ENABLE_VORBIS} -eq 1 ]; then
        # vorbis build
        mkdir -p dist/mac/license/vorbis
        cp ./source/vorbis/COPYING ./dist/mac/license/vorbis/LICENSE
        echo "${VORBIS_VERSION}" > ./dist/mac/license/vorbis/VERSION
    fi
    if [ ${FFMPEG_ENABLE_VPX} -eq 1 ]; then
        # vpx build
        mkdir -p dist/mac/license/vpx
        cp ./source/vpx/LICENSE ./dist/mac/license/vpx/LICENSE
        echo "${VPX_VERSION}" > ./dist/mac/license/vpx/VERSION
    fi
    if [ ${FFMPEG_ENABLE_FFMPEG} -eq 1 ]; then
        # lzma build
        mkdir -p dist/mac/license/lzma
        cp ./source/lzma/COPYING.LGPLv2.1 ./dist/mac/license/lzma/LICENSE
        echo "${LZMA_VERSION}" > ./dist/mac/license/lzma/VERSION

        # ffmpeg build
        mkdir -p dist/mac/license/ffmpeg
        cp ./source/ffmpeg/COPYING.LGPLv2.1 ./dist/mac/license/ffmpeg/LICENSE
        echo "${FFMPEG_VERSION}" > ./dist/mac/license/ffmpeg/VERSION
    fi

    popd
}

mount_ramdisk() {
    diskutil eraseDisk HFS+ ${VOLUME_NAME} ${RAMDISK_FILENAME}
}

unmount_ramdisk() {
    diskutil unmountDisk ${RAMDISK_FILENAME}
    diskutil eject ${RAMDISK_FILENAME}
}

trap_function() {
    status=$?
    unmount_ramdisk
    exit $status
}

main() {
    local args=("$@")
    echo ${args[@]}

    brew install autoconf automake gnu-sed

    mount_ramdisk

    trap 'trap_function' 1 2 3 15

    if [ "a${args[0]}z" == "acleanz" -o "a${args[0]}z" == "arebuildz" ]; then
        clean
    fi

    if [ "a${args[0]}z" == "abuildz" -o "a${args[0]}z" == "arebuildz" ]; then
        prepare_sources
        build
        copy_package_to_dist
    fi

    if [ "a${args[0]}z" == "abuildz" -o "a${args[0]}z" == "arebuildz" -o "a${args[0]}z" == "aframeworkz" ]; then
        generate_fat_binary
    fi

    if [ "a${args[0]}z" == "abuildz" -o "a${args[0]}z" == "arebuildz" -o "a${args[0]}z" == "acollect_licensez" ]; then
        collect_license_files
    fi

    unmount_ramdisk
}

main "$@" 2>&1 | tee ./modules/ffmpeg/ffmpeg.log
