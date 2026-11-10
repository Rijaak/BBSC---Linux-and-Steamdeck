#!/usr/bin/env bash
# Runs in the container (make.sh): builds the port and the co-op server from /src (a clean checkout
# of the branch) in /build (kept between runs: the next build is incremental) and makes
# /out/$NAME.AppImage. Fails when anything in it needs a glibc newer than the container's.
set -euo pipefail
mkdir -p /build && exec > >(tee /build/inside.log) 2>&1  # everything also in the build folder
NAME=${NAME:-YharnamTogether-linux-test-geral-x86_64}
export HOME=/tmp CC=gcc-14 CXX=g++-14 BB_PGO=off
# The port's Vulkan headers (and the other libraries built for it) for everything compiled here,
# the DLSS bridge included (it takes "the system's"; the container's old ones are gone).
export CPATH=/opt/deps/include
QT=/opt/qt/current
PY=/opt/python
# sed reads all of ldd's output (head would stop it early: a failure under pipefail).
glibc_max=$(ldd --version 2>&1 | sed -n '1s/.* \([0-9][0-9]*\.[0-9][0-9]*\)$/\1/p')
[[ -n $glibc_max ]] || { echo "Could not read the container's glibc version" >&2; exit 1; }
echo "Container: glibc $glibc_max, $(gcc-14 --version | sed -n 1p)"

echo "== sources"
mkdir -p /build
rsync -a --delete --exclude .git --exclude /bbport/out --exclude /server/build --exclude '/*.log' /src/ /build/
cd /build/bbport

echo "== the port (build.sh)"
if [[ -d /dlss/lib/Linux_x86_64/rel ]]; then export DLSS_SDK_ROOT=/dlss; else echo "  (no DLSS SDK mounted: no DLSS)"; fi
bash build.sh 2>&1 | tee /build/port-build.log | grep -v '^\[' | tail -15

echo "== the co-op server"
cmake -S /build/server -B /build/server/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$QT \
    > /build/server-config.log 2>&1 || { tail -30 /build/server-config.log; exit 1; }
ninja -C /build/server/build shadnet > /build/server-build.log 2>&1 || { grep -v '^\[' /build/server-build.log | tail -30; exit 1; }

echo "== the AppImage"
work=$(mktemp -d)
app=$work/AppDir
share=$app/usr/share/yt
mkdir -p "$share/out/gpu" "$share/tools" "$share/server" "$share/backend" "$app/usr/lib"
cp out/bb-probe out/bb-gpu-capabilities "$share/out/"
strip --strip-debug -o "$share/out/gpu/libbbgpu.so" out/gpu/libbbgpu.so
for f in out/libbbport_dlss.so out/libnvidia-ngx-dlss.so.* out/libnvidia-ngx-dlssg.so.* out/NVIDIA-DLSS-LICENSE.txt; do
    if [[ -e $f ]]; then cp "$f" "$share/out/"; fi
done
cp -r launcher scripts patches "$share/"
if [[ -d fsr4_shaders ]]; then cp -r fsr4_shaders "$share/"; fi
cp run.py run.sh VERSION.txt event-reference.json LICENSE README.md "$share/"
cp tools/*.py "$share/tools/"
cp -L ../tools/re/party_boss_events.py "$share/tools/party_boss_events.py"
find "$share" -name __pycache__ -type d -prune -exec rm -rf {} +
cp /build/server/build/shadnet "$share/server/shadnet"
cp ../tools/release/kit/server/shadnet.cfg "$share/server/"
cp ../backend/*.py ../backend/ss_info_template.xml ../backend/README.txt "$share/backend/"
: > "$share/backend/notice.txt"
# Python (portable, with Tk) and Qt's plugins the server loads.
mkdir -p "$app/usr/python"
(cd $PY && tar cf - --exclude='test' --exclude='tests' --exclude='idlelib' --exclude='__pycache__' \
    --exclude='ensurepip' --exclude='turtledemo' --exclude='lib2to3' --exclude='include' .) | tar xf - -C "$app/usr/python"
for kind in sqldrivers tls networkinformation; do
    if [[ -d $QT/plugins/$kind ]]; then mkdir -p "$app/usr/lib/qt6/plugins/$kind"; cp $QT/plugins/$kind/*.so "$app/usr/lib/qt6/plugins/$kind/"; fi
done
# The libraries they load, but what the player's system provides and must match it: glibc (and
# libmvec), the C++ runtime (the GPU drivers loaded into the game need the system's own, never an
# older one), the Vulkan loader, the desktop's X11/Wayland/audio/GPU libraries.
skip='^(ld-linux|libc\.so|libm\.so|libmvec\.so|libdl\.so|libpthread\.so|librt\.so|libutil\.so|libresolv\.so|libanl\.so|libstdc\+\+\.so|libgcc_s\.so|libatomic\.so|libvulkan\.so|libGL|libEGL|libGLX|libGLdispatch|libOpenGL|libgbm|libdrm|libnvidia|libcuda|libX|libxcb|libxkb|libwayland|libdecor|libasound|libpulse|libpipewire|libjack|libdbus|libsystemd|libudev|libcap\.so|libz\.so)'
export LD_LIBRARY_PATH=/opt/deps/lib:/opt/deps/lib/x86_64-linux-gnu:$QT/lib:$PY/lib:$share/out/gpu
mapfile -t elves < <(printf '%s\n' "$share/out/bb-probe" "$share/out/bb-gpu-capabilities" "$share/out/gpu/libbbgpu.so" \
    "$share/server/shadnet" "$app/usr/lib/qt6/plugins/"*/*.so "$app/usr/python/bin/python3")
if [[ -f $share/out/libbbport_dlss.so ]]; then elves+=("$share/out/libbbport_dlss.so"); fi
for elf in "${elves[@]}"; do ldd "$elf" 2>/dev/null | awk '/=> \//{print $3}' || true; done | sort -u | while read -r lib; do
    name=$(basename "$lib")
    if [[ $name =~ $skip || $name == libbbgpu.so || $lib == $PY/* ]]; then continue; fi
    if [[ ! -e $app/usr/lib/$name ]]; then cp -L "$lib" "$app/usr/lib/$name"; fi
done
ldd "$share/out/bb-probe" "$share/out/gpu/libbbgpu.so" "$share/server/shadnet" | grep 'not found' && { echo "missing libraries above" >&2; exit 1; }

echo "== glibc check (the AppImage needs at most this container's glibc $glibc_max)"
bad=0
while read -r f; do
    head -c4 "$f" 2>/dev/null | grep -q ELF || continue
    v=$(objdump -T "$f" 2>/dev/null | grep -o 'GLIBC_2\.[0-9]*' | sort -t. -k2 -n -u | tail -1 || true)
    if [[ -n $v ]] && (( ${v#GLIBC_2.} > ${glibc_max#2.} )); then echo "  $v: ${f#$app/}"; bad=1; fi
done < <(find "$app" -type f \( -name '*.so*' -o -perm -u+x \))
(( bad == 0 )) || { echo "something needs a newer glibc than $glibc_max" >&2; exit 1; }
echo "  ok: nothing needs more than glibc $glibc_max"
# The C++ runtime comes from the player's system: nothing may need more than this container's (GCC 14's).
cxx_max=$(objdump -T /usr/lib/x86_64-linux-gnu/libstdc++.so.6 | grep -o 'GLIBCXX_3\.4\.[0-9]*' | sort -t. -k3 -n -u | tail -1)
while read -r f; do
    head -c4 "$f" 2>/dev/null | grep -q ELF || continue
    v=$(objdump -T "$f" 2>/dev/null | grep -o 'GLIBCXX_3\.4\.[0-9]*' | sort -t. -k3 -n -u | tail -1 || true)
    if [[ -n $v ]] && (( ${v##*.} > ${cxx_max##*.} )); then echo "  $v: ${f#$app/}"; bad=1; fi
done < <(find "$app" -type f \( -name '*.so*' -o -perm -u+x \))
(( bad == 0 )) || { echo "something needs a newer C++ runtime than $cxx_max" >&2; exit 1; }
echo "  ok: nothing needs more than $cxx_max"
echo "  libraries bundled: $(ls "$app/usr/lib" | wc -l)"

echo "$(date +%Y%m%d%H%M%S) ${YT_REVISION:0:9} geral" > "$app/BUILD_ID"
cp "$app/BUILD_ID" "$share/BUILD_ID"
cat > "$app/AppRun" <<'APPRUN'
#!/usr/bin/env bash
# Runs a copy outside the AppImage: the game and the server outlive it (an AppImage stays mounted only
# while the program that opened it runs). Installed again when the build changes.
here=$(dirname "$(readlink -f "$0")")
data=${YT_LINUX_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/yharnam-together-linux}
rt=$data/rt app=$data/app
if ! cmp -s "$here/BUILD_ID" "$rt/BUILD_ID" 2>/dev/null; then
    echo "Yharnam Together (Linux): installing this build in $data"
    mkdir -p "$data" || exit 1
    rm -rf "$rt.new" && cp -a "$here/." "$rt.new" && rm -rf "$rt" && mv "$rt.new" "$rt" || exit 1
    rm -rf "$rt/usr/share/yt"  # the payload lives in app/ (its saves, settings and server accounts stay)
    mkdir -p "$app" && cp -a "$here/usr/share/yt/." "$app/" || exit 1
fi
export LD_LIBRARY_PATH="$rt/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONHOME="$rt/usr/python" PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1
export QT_PLUGIN_PATH="$rt/usr/lib/qt6/plugins"
TCL_LIBRARY=$(ls -d "$rt"/usr/python/lib/tcl[89]* 2>/dev/null | head -1)
TK_LIBRARY=$(ls -d "$rt"/usr/python/lib/tk[89]* 2>/dev/null | head -1)
export TCL_LIBRARY TK_LIBRARY
cd "$app" || exit 1
exec "$rt/usr/python/bin/python3" "$app/launcher/bbport_launcher_win.py" "$@"
APPRUN
chmod +x "$app/AppRun"
cp launcher/bloodborne.png "$app/yharnam-together.png"
printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=BBSC: Yharnam Together (Linux)' 'Exec=AppRun' \
    'Icon=yharnam-together' 'Categories=Game;' > "$app/yharnam-together.desktop"
chmod -R a+rX "$app"
ARCH=x86_64 appimagetool --appimage-extract-and-run --no-appstream "$app" "/out/$NAME.AppImage" >/dev/null
rm -rf "$work"
ls -lh "/out/$NAME.AppImage"
