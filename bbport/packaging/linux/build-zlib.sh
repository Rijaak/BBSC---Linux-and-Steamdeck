#!/usr/bin/env bash
# LINUX_FORK: the standard zlib (madler/zlib) for the launcher's Python, as out/zlib/libz.so.1.
#
# The launcher makes the co-op event files (tools/party_boss_events.py) and packs them with
# zlib.compress(..., 9). A build machine whose libz.so.1 is zlib-ng (Fedora, some containers) gives
# a frozen launcher that packs them differently from the official Windows build: the same events,
# other bytes, and so another "event files" fingerprint than the official one (teammates' logs
# then note that the event files differ). The standard zlib packs them byte for byte the same.
set -euo pipefail
cd -- "$(dirname -- "$0")/../.."
version=1.3.2
commit=da607da739fa6047df13e66a2af6b8bec7c2a498
out=$PWD/out/zlib
[[ -f $out/libz.so.1 && $(cat "$out/version.txt" 2>/dev/null) == "$version" ]] && exit 0
rm -rf -- "$out"; mkdir -p "$out"
git clone -q --depth 1 --branch "v$version" https://github.com/madler/zlib "$out/src"
[[ $(git -C "$out/src" rev-parse HEAD) == "$commit" ]] || { echo "zlib v$version is not commit $commit" >&2; exit 1; }
(cd "$out/src" && CFLAGS='-O2 -fPIC' ./configure --shared >/dev/null && make -j"$(nproc)" libz.so.$version >/dev/null)
cp -L "$out/src/libz.so.$version" "$out/libz.so.1"
strip --strip-unneeded "$out/libz.so.1"
echo "$version" > "$out/version.txt"
echo "zlib $version: $out/libz.so.1"
