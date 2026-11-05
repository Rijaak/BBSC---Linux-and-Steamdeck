#!/usr/bin/env bash
# LINUX_FORK (Rijaak/BBSC---Linux-and-Steamdeck): builds the Linux release the way it is published.
#   bash packaging/linux/build-release.sh <windows package folder> <linux version, e.g. 1.0.0.1>
# Steps: the minimal static FFmpeg (build-ffmpeg.sh), the GPU library with clang (Release, no PGO
# or LTO, production), bb-probe and bb-gpu-capabilities with clang (build.sh's Linux commands;
# the upstream C code is warning-clean under clang, as the Windows build uses), then package.sh.
# Needs (Ubuntu 24.04 names): clang ninja-build cmake pkg-config nasm patchelf libvulkan-dev
#   glslang-tools libx11-dev libfmt-dev libzydis-dev libssl-dev libprotobuf-dev protobuf-compiler
#   libxxhash-dev libabsl-dev libboost-dev, SDL3 3.2 and Vulkan-Headers 1.4 (from source into
#   /usr/local), and for the launcher a Python 3.12 venv with tkinter, pyinstaller, pillow,
#   truststore (PYTHON=<its python>, default ../../pyenv/bin/python).
set -euo pipefail
cd -- "$(dirname -- "$0")/../.."
windows=${1:?usage: build-release.sh <windows package folder> <version>}
version=${2:?usage: build-release.sh <windows package folder> <version>}
[[ -f out/ffmpeg/lib/libavcodec.a ]] || bash packaging/linux/build-ffmpeg.sh out/ffmpeg
export PKG_CONFIG_PATH=$PWD/out/ffmpeg/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}
for patch in gpu/patches/fsr-vulkan/*.patch; do
    if ! git -C gpu/third_party/fsr-vulkan apply --reverse --check "$PWD/$patch" 2>/dev/null; then
        git -C gpu/third_party/fsr-vulkan apply "$PWD/$patch"
    fi
done
CC=clang CXX=clang++ cmake -S gpu -B out/gpu -G Ninja -DCMAKE_BUILD_TYPE=Release -DBB_PGO=off -DBB_LTO=OFF \
    -DBB_PGO_DIR="$PWD/pgo" -DBB_PRODUCTION=ON -DVulkan_INCLUDE_DIR=/usr/local/include >/dev/null
ninja -C out/gpu bbgpu > out/gpu-build.log 2>&1 || { tail -40 out/gpu-build.log >&2; exit 1; }
read -r -a includes <<< "$(pkg-config --cflags vulkan sdl3)"
read -r -a libraries <<< "$(pkg-config --libs vulkan sdl3)"
gpu=(-Lout/gpu -lbbgpu -Wl,-rpath,'$ORIGIN/gpu' -rdynamic)
rm -rf out/atrac9 && mkdir -p out/atrac9
for source in third_party/LibAtrac9/C/src/*.c; do
    clang -std=c99 -O2 -g -w -c "$source" -o "out/atrac9/$(basename "${source%.c}").o"
done
ar rcs out/libatrac9.a out/atrac9/*.o
clang -std=c11 -O2 -g -Wall -Wextra -Werror -pthread -no-pie "${includes[@]}" -I. -Isrc src/probe.c src/runtime*.c \
    src/vulkan_smoke.c out/libatrac9.a -lm "${gpu[@]}" "${libraries[@]}" -o out/bb-probe
clang -std=c11 -O2 -Wall -Wextra -Werror "${includes[@]}" tools/gpu_capabilities.c "${libraries[@]}" -o out/bb-gpu-capabilities
echo production > out/build-mode.txt
bash packaging/linux/package.sh "$windows" "$version"
