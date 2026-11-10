#!/usr/bin/env bash
# The general Linux AppImage of BBSC: Yharnam Together (the linux-port-1.5.0 branch), built in an
# Ubuntu 24.04 container (glibc 2.39, GCC 14) so it runs on every current distro: Ubuntu 24.04,
# Debian 13, Fedora 40, SteamOS 3.7, Bazzite, Arch, CachyOS, Gentoo and newer. Needs Docker.
# The libraries Ubuntu has too old are built at the versions this PC has (pacman), the ones the port
# is known to build with. Output: bbport/dist/YharnamTogether-linux-test-geral-x86_64.AppImage
# The first run builds the container (20-40 min); later runs reuse it and build incrementally.
set -euo pipefail
branch=${BRANCH:-linux-port-1.5.0}
repo=$(cd -- "$(dirname -- "$0")/../../../.." && pwd)
here=$repo/bbport/packaging/linux/appimage-geral
cache=${XDG_CACHE_HOME:-$HOME/.cache}/yt-appimage-geral
dlss=${DLSS_SDK_ROOT:-$HOME/DLSS}
command -v docker >/dev/null || { echo "Docker is not installed: sudo pacman -S docker && sudo systemctl enable --now docker" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker does not answer: start it (sudo systemctl start docker) and let your user use it (sudo usermod -aG docker \$USER, then log out and in)" >&2; exit 1; }
for f in VERSION.txt event-reference.json; do
    [[ -f $repo/bbport/$f ]] || { echo "Missing bbport/$f" >&2; exit 1; }
done

ver() { pacman -Q "$1" 2>/dev/null | awk '{print $2}' | sed 's/^[0-9]*://; s/-[0-9][0-9.]*$//'; }
vk_h=/usr/include/vulkan/vulkan_core.h
args=()
if [[ -f $vk_h ]]; then
    patch=$(awk '$2=="VK_HEADER_VERSION"{print $3; exit}' $vk_h)
    mm=$(sed -n 's/.*VK_HEADER_VERSION_COMPLETE VK_MAKE_API_VERSION(0, *\([0-9]*\), *\([0-9]*\),.*/\1.\2/p' $vk_h)
    [[ -n $patch && -n $mm ]] && args+=(--build-arg "VK_HEADERS=$mm.$patch")
fi
for pair in VMA:vulkan-memory-allocator ROBIN_MAP:robin-map FMT:fmt ZYDIS:zydis ABSEIL:abseil-cpp PROTOBUF:protobuf \
            GLSLANG:glslang SDL3:sdl3 FFMPEG:ffmpeg BOOST:boost QT:qt6-base; do
    v=$(ver "${pair#*:}")
    [[ -n $v ]] && args+=(--build-arg "${pair%%:*}=$v")
done
echo "== the container (versions from this PC):"
printf '   %s\n' "${args[@]}" | grep -v -- --build-arg || true
mkdir -p "$cache"
docker build -t yt-appimage-geral "${args[@]}" "$here" 2>&1 | tee "$cache/docker-build.log" ||
    { echo "The container did not build: see $cache/docker-build.log" >&2; exit 1; }

echo "== a clean copy of $branch"
src=$cache/src
mkdir -p "$cache/build"
git -C "$repo" worktree remove --force "$src" 2>/dev/null || rm -rf "$src"
git -C "$repo" worktree prune
git -C "$repo" worktree add -q --detach "$src" "$branch"
git -C "$src" submodule update -q --init bbport/gpu/third_party/fsr-vulkan bbport/gpu/third_party/imgui \
    bbport/gpu/third_party/magic_enum bbport/gpu/third_party/miniz bbport/gpu/third_party/xbyak bbport/third_party/LibAtrac9 \
    server/externals/protobuf
cp "$repo/bbport/VERSION.txt" "$repo/bbport/event-reference.json" "$src/bbport/"
revision=$(git -C "$src" rev-parse HEAD)

echo "== building (the log of each part: $cache/build/*.log)"
mkdir -p "$repo/bbport/dist"
mounts=(-v "$src:/src:ro" -v "$cache/build:/build" -v "$repo/bbport/dist:/out" -v "$here/inside.sh:/inside.sh:ro")
if [[ -d $dlss/lib/Linux_x86_64/rel ]]; then mounts+=(-v "$dlss:/dlss:ro"); else echo "   (no DLSS SDK in $dlss: no DLSS)"; fi
docker run --rm --user "$(id -u):$(id -g)" -e YT_REVISION="$revision" "${mounts[@]}" yt-appimage-geral bash /inside.sh ||
    { code=$?; echo "The build stopped (exit $code): see the lines above and $cache/build/*.log" >&2; exit $code; }
git -C "$repo" worktree remove --force "$src"
