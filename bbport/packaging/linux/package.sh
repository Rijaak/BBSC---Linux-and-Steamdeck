#!/usr/bin/env bash
# LINUX_FORK (Rijaak/BBSC---Linux-and-Steamdeck): the native Linux package of BBSC: Yharnam Together,
# laid out like the Windows one (packaging/windows/package.sh) so the same launcher and run.py work:
#
#   BLauncher            the launcher (bbport_launcher_win.py frozen with PyInstaller, Tk included)
#   bin/bb-probe         the game, bin/gpu/libbbgpu.so its GPU library, bin/lib/ the libraries they
#                        need that a Steam Deck or another distribution may not have
#   run.py scripts/ tools/ patches/ launcher/ backend/ fsr4_shaders/ event-reference.json ...
#
# Usage: bash packaging/linux/package.sh <windows package folder> <linux version, e.g. 1.0.0.1>
#   The co-op release is the first three numbers (what the server checks: it must be the Windows
#   release's); the fourth is the Linux revision.
#   The Windows package of the same release gives the files that are not built here (the FSR 4
#   shaders, the patch lists, the backend, the launcher art, licences and texts).
# Build first: bash build.sh (out/bb-probe, out/gpu/libbbgpu.so, out/bb-gpu-capabilities).
set -euo pipefail
cd -- "$(dirname -- "$0")/../.."
windows=$(realpath "${1:?usage: package.sh <windows package folder> <version>}")
version=${2:?usage: package.sh <windows package folder> <version>}
python=${PYTHON:-$PWD/../../pyenv/bin/python}
[[ -f out/bb-probe && -f out/gpu/libbbgpu.so && -f out/bb-gpu-capabilities ]] || { echo 'Build first: bash build.sh' >&2; exit 1; }
# A libbbgpu.so linked to the system's FFmpeg would pull in ~150 libraries (glib, cairo, codecs).
if ldd out/gpu/libbbgpu.so | grep -q libavcodec; then
    echo 'libbbgpu.so uses the shared FFmpeg: build packaging/linux/build-ffmpeg.sh first, then build.sh with its PKG_CONFIG_PATH' >&2; exit 1
fi
# SDL3 must have a real display (X11, Wayland): one built without their headers runs the game in an
# invisible window (the "dummy" and "offscreen" drivers only).
sdl=$(ldd out/bb-probe | awk '/libSDL3/{print $3}')
if [[ $(strings "$sdl" | grep -c 'libX11\.so\|libwayland-client\.so') -lt 2 ]]; then
    echo "$sdl has no X11 or Wayland support: rebuild SDL3 with their development packages" >&2; exit 1
fi
[[ -f $windows/event-reference.json ]] || { echo "$windows is not the Windows package" >&2; exit 1; }

name=YharnamTogether-$version-linux
stage=out/stage/$name
rm -rf -- out/stage out/pyi-work out/pyi-dist
mkdir -p "$stage/bin/gpu" "$stage/bin/lib"

# --- the launcher -------------------------------------------------------------------------------
hidden=()
for module in argparse base64 bisect collections contextlib hashlib json re shutil struct tempfile \
              xml.etree.ElementTree urllib.request binascii datetime http.server secrets sqlite3 uuid zlib; do
    hidden+=(--hidden-import "$module")
done
"$python" -m PyInstaller --noconfirm --clean --log-level WARN --name BLauncher \
    --distpath out/pyi-dist --workpath out/pyi-work --specpath out/pyi-work \
    --paths "$PWD/scripts" --paths "$PWD/tools" --paths "$PWD/launcher" \
    --hidden-import fetch_fsr4vk --hidden-import bbport_icons --hidden-import truststore \
    --hidden-import bbport_linux_compat --hidden-import PIL._tkinter_finder --hidden-import PIL.ImageTk \
    --hidden-import tkinter --hidden-import tkinter.ttk --hidden-import tkinter.filedialog \
    --hidden-import tkinter.messagebox "${hidden[@]}" launcher/bbport_launcher_win.py
cp -a out/pyi-dist/BLauncher/. "$stage/"
# Tk's fonts come from the system's fontconfig: a bundled older one rejects a newer system's font
# settings (SteamOS 3.7: a screenful of "Fontconfig warning" lines). Every desktop Linux has it.
rm -f "$stage"/_internal/libfontconfig.so* "$stage"/_internal/libfreetype.so*
# The launcher's zlib is the standard one, never the build machine's zlib-ng: the co-op event files
# it makes must be byte for byte the official ones (packaging/linux/build-zlib.sh says why).
bash packaging/linux/build-zlib.sh
[[ -f $stage/_internal/libz.so.1 ]] || { echo 'the frozen launcher has no _internal/libz.so.1 to replace' >&2; exit 1; }
install -m755 out/zlib/libz.so.1 "$stage/_internal/libz.so.1"
packed=$("$stage/BLauncher" --script packaging/linux/zlib-check.py)
[[ $packed == "1.3.2 ok" ]] || { echo "the packaged launcher's zlib is not the standard 1.3.2: $packed" >&2; exit 1; }

# --- the game -----------------------------------------------------------------------------------
install -m755 out/bb-probe out/bb-gpu-capabilities "$stage/bin/"
install -m755 out/gpu/libbbgpu.so "$stage/bin/gpu/"
# Libraries: everything the game and its GPU library load that is not part of every Linux system
# (glibc, the Vulkan loader, the GPU drivers, X11/Wayland, audio, OpenSSL 3, zlib). FFmpeg is
# not among them: libbbgpu.so has a minimal static copy (packaging/linux/build-ffmpeg.sh). They go in bin/lib, found
# through the binaries' RUNPATH ($ORIGIN/lib, $ORIGIN/../lib).
system='^(linux-vdso|ld-linux|libc\.|libm\.|libdl\.|librt\.|libpthread\.|libresolv\.|libutil\.|libvulkan\.|libGL|libEGL|libdrm|libgbm|libX|libxcb|libwayland|libxkbcommon|libasound|libpulse|libpipewire|libdbus|libudev|libsystemd|libbsd\.|libmd\.|libz\.so|libssl\.|libcrypto\.|libbbgpu\.|libgcc_s|libstdc\+\+)'
for elf in "$stage/bin/bb-probe" "$stage/bin/bb-gpu-capabilities" "$stage/bin/gpu/libbbgpu.so"; do
    ldd "$elf" | awk '/=> \//{print $1, $3}'
done | sort -u | while read -r soname path; do
    [[ $soname =~ $system ]] && continue
    cp -L "$path" "$stage/bin/lib/$soname"
done
# libstdc++ and libgcc_s: the system's when it is new enough (run-game.sh decides), else these.
mkdir -p "$stage/bin/lib/cxx"
cp -L "$(g++ -print-file-name=libstdc++.so.6)" "$(gcc -print-file-name=libgcc_s.so.1)" "$stage/bin/lib/cxx/"
# The libraries' own dependencies (FFmpeg's codecs, protobuf's abseil) come along the same way.
for _ in 1 2 3; do
    for lib in "$stage"/bin/lib/*.so*; do
        ldd "$lib" | awk '/=> \//{print $1, $3}'
    done | sort -u | while read -r soname path; do
        [[ $soname =~ $system || -e $stage/bin/lib/$soname ]] && continue
        cp -L "$path" "$stage/bin/lib/$soname"
    done
done
patchelf --set-rpath '$ORIGIN/lib:$ORIGIN/gpu' "$stage/bin/bb-probe" "$stage/bin/bb-gpu-capabilities"
patchelf --set-rpath '$ORIGIN/../lib' "$stage/bin/gpu/libbbgpu.so"
for lib in "$stage"/bin/lib/*.so*; do patchelf --set-rpath '$ORIGIN' "$lib"; done

# --- the release's files ------------------------------------------------------------------------
cp -a run.py "$stage/"
mkdir -p "$stage/scripts" "$stage/tools"
cp -a scripts/*.py scripts/*.bin "$stage/scripts/" 2>/dev/null || cp -a scripts/*.py "$stage/scripts/"
cp -a "$windows/scripts/build_info.json" "$stage/scripts/"
cp -a "$windows"/tools/. "$stage/tools/"
for item in patches backend fsr4_shaders licenses launcher event-reference.json CREDITS.txt LICENSE README.md; do
    cp -a "$windows/$item" "$stage/"
done
cp -a packaging/linux/README-Linux.txt packaging/linux/KNOWN_ISSUES.md packaging/linux/run-game.sh "$stage/"
chmod +x "$stage/run-game.sh"
release=$(echo "$version" | cut -d. -f1-3)
printf 'Yharnam Together: Bloodborne Seamless Co-op v%s (Linux, Bloodborne PC native port)\nLinux build %s\nBuilt: %s\nSource: https://github.com/Rijaak/BBSC---Linux-and-Steamdeck\n' \
    "$release" "$version" "$(date -u '+%Y-%m-%d %H:%M UTC')" > "$stage/VERSION.txt"
cp -a "$windows/portable.txt" "$stage/"
sed -i 's/BLauncher.exe/BLauncher/g; s/user\\/user\//g' "$stage/portable.txt"

tar -C out/stage -czf "out/$name.tar.gz" "$name"
sha256sum "out/$name.tar.gz" | sed "s#out/##" > "out/$name.tar.gz.sha256"
ls -lh "out/$name.tar.gz"
cat "out/$name.tar.gz.sha256"
