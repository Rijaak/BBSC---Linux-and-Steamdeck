# The build environment of the general Linux AppImage: Ubuntu 24.04 (glibc 2.39, GCC 14), so the
# AppImage runs on every current distro: glibc 2.39 and a GCC 14 C++ runtime or newer (Ubuntu 24.04,
# Debian 13, Fedora 40, SteamOS 3.7, Arch and newer). The C++ runtime is the player's system's (the GPU
# drivers loaded into the game need it too). What Ubuntu ships too old is built from source at the
# versions the port is known to build with (make.sh passes the developer PC's).
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential gcc-14 g++-14 ninja-build pkg-config git curl ca-certificates rsync xz-utils \
        file patchelf binutils nasm python3 python3-pip python3-venv \
        nlohmann-json3-dev libxxhash-dev libssl-dev zlib1g-dev libprotobuf-dev protobuf-compiler \
        libvulkan-dev libvulkan1 \
        libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev libxtst-dev libxfixes-dev \
        libxinerama-dev libxkbcommon-dev libwayland-dev libwayland-bin wayland-protocols libdecor-0-dev \
        libegl-dev libgl-dev libdbus-1-dev libudev-dev libpipewire-0.3-dev libpulse-dev libasound2-dev \
        libdrm-dev libgbm-dev libglib2.0-0 squashfs-tools \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-14 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-14 100
ENV CC=gcc-14 CXX=g++-14
RUN pip3 install --break-system-packages --no-cache-dir "cmake<4" aqtinstall
ENV PREFIX=/opt/deps
ENV PKG_CONFIG_PATH=/opt/deps/lib/pkgconfig:/opt/deps/lib/x86_64-linux-gnu/pkgconfig:/opt/deps/share/pkgconfig \
    CMAKE_PREFIX_PATH=/opt/deps \
    LD_LIBRARY_PATH=/opt/deps/lib:/opt/deps/lib/x86_64-linux-gnu \
    PATH=/opt/deps/bin:/usr/local/bin:$PATH
WORKDIR /tmp/src
# Vulkan headers: the port's (the system's are taken away so nothing picks them up).
ARG VK_HEADERS=1.4.328
RUN git clone -q --depth 1 --branch v$VK_HEADERS https://github.com/KhronosGroup/Vulkan-Headers.git \
    && cmake -S Vulkan-Headers -B vh -G Ninja -DCMAKE_INSTALL_PREFIX=$PREFIX && cmake --install vh \
    && rm -rf /usr/include/vulkan /usr/include/vk_video Vulkan-Headers vh
ARG VMA=3.3.0
RUN git clone -q --depth 1 --branch v$VMA https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git vma \
    && cmake -S vma -B vmab -G Ninja -DCMAKE_INSTALL_PREFIX=$PREFIX && cmake --install vmab && rm -rf vma vmab
ARG ROBIN_MAP=1.4.0
RUN git clone -q --depth 1 --branch v$ROBIN_MAP https://github.com/Tessil/robin-map.git \
    && cmake -S robin-map -B rmb -G Ninja -DCMAKE_INSTALL_PREFIX=$PREFIX && cmake --install rmb && rm -rf robin-map rmb
ARG FMT=11.2.0
RUN git clone -q --depth 1 --branch $FMT https://github.com/fmtlib/fmt.git \
    && cmake -S fmt -B fmtb -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
       -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DFMT_TEST=OFF -DFMT_DOC=OFF \
    && cmake --build fmtb && cmake --install fmtb && rm -rf fmt fmtb
ARG ZYDIS=4.1.1
RUN git clone -q --depth 1 --recursive --branch v$ZYDIS https://github.com/zyantific/zydis.git \
    && cmake -S zydis -B zb -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
       -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DZYDIS_BUILD_TOOLS=OFF -DZYDIS_BUILD_EXAMPLES=OFF \
       -DZYDIS_BUILD_TESTS=OFF -DZYDIS_BUILD_DOXYGEN=OFF \
    && cmake --build zb && cmake --install zb && rm -rf zydis zb
ARG GLSLANG=15.4.0
# Arch numbers glslang as the Vulkan SDK it came with (1.4.363.0): its tag is vulkan-sdk-<that>.
RUN tag=$GLSLANG; case $tag in 1.*) tag=vulkan-sdk-$tag;; esac; \
    git clone -q --depth 1 --branch $tag https://github.com/KhronosGroup/glslang.git \
    && cmake -S glslang -B gb -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
       -DENABLE_OPT=OFF -DGLSLANG_TESTS=OFF -DBUILD_EXTERNAL=OFF -DGLSLANG_ENABLE_INSTALL=ON \
    && cmake --build gb && cmake --install gb && rm -rf glslang gb
ARG SDL3=3.2.24
RUN git clone -q --depth 1 --branch release-$SDL3 https://github.com/libsdl-org/SDL.git sdl \
    && cmake -S sdl -B sb -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
       -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF \
    && cmake --build sb && cmake --install sb && rm -rf sdl sb
ARG FFMPEG=8.0
RUN git clone -q --depth 1 --branch n$FFMPEG https://github.com/FFmpeg/FFmpeg.git ffmpeg \
    && cd ffmpeg && ./configure --prefix=$PREFIX --enable-shared --disable-static --disable-programs \
       --disable-doc --disable-autodetect --disable-avdevice --disable-network \
    && make -j"$(nproc)" && make install && cd .. && rm -rf ffmpeg
ARG BOOST=1.89.0
RUN v=$(echo $BOOST | tr . _) \
    && curl -fsSL "https://archives.boost.io/release/$BOOST/source/boost_$v.tar.gz" | tar xz \
    && cp -r boost_$v/boost $PREFIX/include/ && rm -rf boost_$v
# Qt for the co-op server (6.8 or newer: its HTTP services), from Qt's own Linux build.
ARG QT=6.9.3
RUN (aqt install-qt linux desktop $QT linux_gcc_64 -m qthttpserver qtwebsockets -O /opt/qt \
     || aqt install-qt linux desktop "$(aqt list-qt linux desktop --spec "${QT%.*}" --latest-version)" linux_gcc_64 \
        -m qthttpserver qtwebsockets -O /opt/qt) \
    && ln -s "$(ls -d /opt/qt/6.*/gcc_64 | head -1)" /opt/qt/current
# A portable Python with Tk for the launcher (python-build-standalone): its zlib is the classic
# one, so the co-op event files are packed byte for byte as by the Windows launcher's Python 3.12.
ARG PYTHON=3.12
RUN url=$(curl -fsSL https://api.github.com/repos/astral-sh/python-build-standalone/releases/latest \
        | python3 -c "import json,sys; a=[x['browser_download_url'] for x in json.load(sys.stdin)['assets'] \
          if x['name'].startswith('cpython-$PYTHON.') and x['name'].endswith('-x86_64-unknown-linux-gnu-install_only.tar.gz')]; print(a[0])") \
    && curl -fsSL "$url" | tar xz -C /opt \
    && /opt/python/bin/python3 -c "import tkinter, zlib, sys; print(sys.version, zlib.ZLIB_RUNTIME_VERSION); sys.exit('ng' in zlib.ZLIB_RUNTIME_VERSION)"
# Zydis finds Zycore, its own dependency, as a package of its own: the one Zydis was built with
# (its submodule), installed beside it.
RUN git clone -q --depth 1 --recursive --branch v$ZYDIS https://github.com/zyantific/zydis.git \
    && cmake -S zydis/dependencies/zycore -B zcb -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
       -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DZYCORE_BUILD_TESTS=OFF -DZYCORE_BUILD_EXAMPLES=OFF \
    && cmake --build zcb && cmake --install zcb && rm -rf zydis zcb \
    && test -f $PREFIX/lib/cmake/zycore/zycore-config.cmake -o -f $PREFIX/lib/cmake/zycore/ZycoreConfig.cmake \
       -o -n "$(find $PREFIX -iname 'zycore*config.cmake' -print -quit)"
# protobuf with Abseil, as on the developer's PC: the GPU library gets Abseil (texture_cache.h's
# flat_hash_map) through protobuf's targets, and Ubuntu's protobuf is older than Abseil there.
ARG ABSEIL=20250512.1
ARG PROTOBUF=31.1
RUN git clone -q --depth 1 --branch $ABSEIL https://github.com/abseil/abseil-cpp.git \
    && cmake -S abseil-cpp -B ab -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
       -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=17 -DABSL_PROPAGATE_CXX_STD=ON -DABSL_BUILD_TESTING=OFF \
    && cmake --build ab && cmake --install ab && rm -rf abseil-cpp ab \
    && git clone -q --depth 1 --branch v$PROTOBUF https://github.com/protocolbuffers/protobuf.git \
    && cmake -S protobuf -B pb -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
       -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_ABSL_PROVIDER=package \
       -Dprotobuf_BUILD_SHARED_LIBS=OFF \
    && cmake --build pb && cmake --install pb && rm -rf protobuf pb
RUN curl -fsSL -o /usr/local/bin/appimagetool \
        https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage \
    && chmod +x /usr/local/bin/appimagetool
# git answers the build's revision from the developer's checkout (make.sh: YT_REVISION); the copy
# built here has no history of its own.
RUN printf '%s\n' '#!/bin/sh' \
      'if [ "$1" = rev-parse ] && [ "$2" = HEAD ] && [ -n "$YT_REVISION" ]; then echo "$YT_REVISION"; exit 0; fi' \
      'if [ "$1" = status ] && [ -n "$YT_REVISION" ]; then exit 0; fi' \
      'exec /usr/bin/git "$@"' > /usr/local/bin/git && chmod +x /usr/local/bin/git
WORKDIR /
