#!/usr/bin/env bash
# LINUX_FORK (Rijaak/BBSC---Linux-and-Steamdeck): the FFmpeg the Linux release links into
# libbbgpu.so: static, position independent, and only what the game's movie player uses
# (MP4/MPEG-TS, H.264/HEVC video, AAC audio, file reading). A distribution's shared FFmpeg brings
# ~150 libraries with it (glib, cairo, Kerberos, every codec), which a Steam Deck may not have or
# may have in other versions; this one brings none.
#
# Usage: bash packaging/linux/build-ffmpeg.sh [prefix]   (default: out/ffmpeg; needs clang, nasm)
# Then:  PKG_CONFIG_PATH=<prefix>/lib/pkgconfig:$PKG_CONFIG_PATH bash build.sh
set -euo pipefail
cd -- "$(dirname -- "$0")/../.."
prefix=$(realpath -m "${1:-out/ffmpeg}")
source=out/ffmpeg-src
[[ -d $source ]] || git clone -q --depth 1 -b n6.1.2 https://github.com/FFmpeg/FFmpeg.git "$source"
cd "$source"
./configure --prefix="$prefix" --cc="${CC:-clang}" --enable-pic --enable-static --disable-shared \
    --disable-programs --disable-doc --disable-everything --disable-autodetect --disable-network \
    --disable-avdevice --disable-avfilter --disable-postproc \
    --enable-avformat --enable-avcodec --enable-swscale --enable-swresample \
    --enable-demuxer=mov,mpegts,h264,hevc,aac --enable-decoder=h264,hevc,aac,aac_fixed \
    --enable-parser=h264,hevc,aac --enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,aac_adtstoasc \
    --enable-protocol=file >/dev/null
make -j"$(nproc)" >/dev/null
make install >/dev/null
echo "FFmpeg (minimal, static) in $prefix"
