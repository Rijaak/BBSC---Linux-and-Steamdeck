Bloodborne Seamless Co-op - Linux / Steam Deck (BBSC)

Play the whole of Bloodborne together. BBSC is a mod for the shadPS4 emulator that keeps a co-op session alive through deaths, lamps, area changes, bosses and the Hunter's Dream - up to five hunters, each keeping their own character.

This is the native Linux / Steam Deck build: BBSC compiled into the shadPS4 emulator and run from the command line. (The upstream Windows distribution - launcher, BBport, Nucleus split-screen - is separate and not part of this build; the Windows package does not work under Proton/Wine, which is why this native build exists. See Linux / Steam Deck below.)

Downloads: Releases · Community: Discord

Early public tests. Back up your saves before playing. Discord Thread is under General>Release BBSC for Linux / Steam Deck,  https://discord.gg/Df7BCmfWdt

Features
One co-op session that lasts through deaths, lamps, area changes, bosses and the Hunter's Dream
Up to 5 hunters: the host and 4 guests
Guests follow the host between areas and lamps and respawn with the group
Everyone keeps their own levels, echoes and items
Shared progress (optional): the host's boss kills and shortcuts are added to the guest's world
Guests get boss rewards and enemy drops; items already picked up do not come back
Enemy scaling by the number of hunters
A co-op kit with no Insight cost: Hunt Bell, Kin Bell, Bloodlust Bell, Parting Blank, Duel Bell (PvP toggle)
Clear co-op messages in place of the vanilla "beckoner / resonance" lines
Public server or self-hosted servers (Radmin VPN, Tailscale, LAN, VPS)
Runs as a native Linux / Steam Deck shadPS4 build - no Proton/Wine
Requirements
Your own Bloodborne CUSA03173, version 01.09 - no game files are included
Linux with glibc 2.38+ (SteamOS 3.6+ / Steam Deck is fine) and Vulkan. libstdc++ is bundled in the tarball.
Downloads

Get these from the Releases page:

File	For
bbsc-linux-<version>-steamdeck.tar.gz	New installs. The full Linux / Steam Deck build: the BBSC emulator, run-bbsc.sh, bbsc-setup.py and bundled libs.
bbsc-linux-0.0.1-hotfix1.tar.gz	Existing 0.0.1 installs. In-place binary update (keeps your config, saves, patches and shortcut): extract and run ./apply-hotfix.sh.

Hosting your own server is Python-only and cross-platform - see server/ (bbsc_gameserver.py).

Quick start
Extract bbsc-linux-<version>-steamdeck.tar.gz and keep its files together.
Make your account on the community server first (Seamless Hunt: https://seamlesshunt.com/), then wire it up once:
bash
   python3 bbsc-setup.py --server play.seamlesshunt.com:31313 --no-register --name YourName --password YourPassword
Launch and pick Connect to network:
bash
   ./run-bbsc.sh /path/to/CUSA03173/eboot.bin
Host rings the Hunt Bell, guests ring the Kin Bell.

On a Steam Deck, add run-bbsc.sh as a non-Steam game so it launches from Game Mode, and apply the graphics config under Steam Deck settings below.

Repository layout

The Linux build is produced entirely from emulator/. The other folders are part of the wider BBSC project (Windows launcher, etc.) and are not used by this build.

Folder	Contents
emulator/	The shadPS4 fork with BBSC built in. BBSC game code: src/core/bloodborne_re.cpp
server/	Host package scripts and the BBSC game server (bbsc_gameserver.py) - cross-platform
tools/	Game data readers and helper tools
docs/	Architecture, world sync, networking, known limitations, changelog
launcher/, mod/	The Windows launcher and mod DLL - not used by the Linux build
Linux / Steam Deck (this fork)

This fork builds a native Linux version of the BBSC emulator (emulator/, shadPS4 v0.17.1 base with BBSC built in). The Windows package does not work under Proton/Wine: the game stalls in a loading loop before the first logo, and the plain shadPS4 v0.17.0 Windows build does the same, so it is a Wine issue rather than BBSC. The same code compiled natively runs fine.

What you get is the emulator only. The Windows launcher is not ported; the game is started from the command line and BBSC's options are set with environment variables (same names as in mod.json).

Run (release tarball, or your own build):

bash
./run-bbsc.sh /path/to/CUSA03173/eboot.bin

It uses the normal shadPS4 data folder (~/.local/share/shadPS4: saves, sys_modules, patches, config.json), so an existing shadPS4 setup is used as it is. To keep BBSC separate, create a user folder next to the executable and it will be used instead.

Going online. The Windows launcher's Accounts tab and the first-start / join-host scripts are not ported; bbsc-setup.py (in the tarball) does the same from a terminal:

bash
# 1. create your account on the community server (Seamless Hunt: https://seamlesshunt.com/),
#    or let the script create it on a server that allows it (drop --no-register, add --card or --key)
# 2. write account + server into the emulator's files
python3 bbsc-setup.py --server play.seamlesshunt.com:31313 --no-register --name YourName --password YourPassword
# 3. start the game and pick "Connect to network"

What it writes, if you would rather do it by hand (all in the data folder):

File	Change
users.json	in Users.user, on the entry with player_index: 1 (user 1000): shadnet_enabled: true, shadnet_npid, shadnet_password, shadnet_email
config.json	in General: shadnet_server: "host:31313", shadnet_webapi_server: "http://host:31315", shad_net_enabled: true, connected_to_network: true
host_overrides.json	{"https://ss4.scej-network.jp:20443": "http://host:20443", "http://thehuntersdream.com:18671/summon_messenger": "http://host:31315"} - without this the game asks Sony's dead server for its server list and reports "Failed to acquire network server information"

Replace host with the community server (play.seamlesshunt.com for Seamless Hunt, or your own host's address). A server card (*.json with shadnet and registration_key) can be passed with --card instead of --server.

BBSC's own options (five hunters, scaling, no fog walls, ...) are environment variables with the names from mod.json (BBSC_MOD_SEAMLESS, BBSC_MOD_HOOKS, SHADPS4_BBSC_*); all default to on. Do not set SHADPS4_BLOODBORNE_RE_TRACE=0 to quiet logging - that switch installs the co-op hooks, so turning it off disables co-op (deaths stop resetting, the online session drops). The developer reverse-engineering capture is off by default; set SHADPS4_BBSC_CAPTURE=1 only if you need it.

Notes:

Running another shadPS4 build (e.g. the EmuDeck one) on the same data folder resets connected_to_network / shad_net_enabled / shadnet_server on exit. Run bbsc-setup.py again afterwards (it is idempotent), or keep BBSC on its own user folder.
The 1280x800 (16:10) resolution patch fills the screen in gameplay; the title screen and other full-screen 2D art stay 16:9 with grey bars by design.
An occasional std::bad_alloc on launch is known; relaunching works.

To check the connection: grep -a -i -E 'shadnet|login|ss.info' ~/.local/share/shadPS4/log/shad_log.txt. A working run logs the shadNet login for your account and a 200 reply for /bb-eu/ss.info.

No game files or PS4 firmware are included, here or in the release tarball: you need your own Bloodborne CUSA03173 v01.09 dump, and libSceNgs2.sprx in sys_modules if your setup needs it, as with any shadPS4 install.

Steam Deck settings

Tested on a Steam Deck LCD: a steady 30 FPS at 1280x800 (GPU around 75-85%) with these shadPS4 patches on (~/.local/share/shadPS4/patches/shadPS4/Bloodborne.xml, isEnabled="true" on the patch's <Metadata> line, or tick them in the shadPS4 Qt launcher):

30 FPS++
Resolution Patch 1280x800 (16:10)
1280x800 Light Grid For SteamDeck
Better AA
Disable Motion Blur
Disable Chromatic Aberration
Disable DoF
Disable Dynamic Light Shadows

Leave SSAO on (do not enable the "Disable SSAO" patch): it is a screen-space effect that shadPS4 renders correctly and it adds contact shadows and depth for almost no cost. Disable it only if you ever see dark grain or haloing.

Keep "Disable Dynamic Light Shadows" on. shadPS4 renders Bloodborne's dynamic light shadows incorrectly and they also cost GPU, so the patch both tidies the lighting and saves about 7% GPU. (The large triangular "wedge" artifacts some players hit on death or an area reload are a separate problem - GPU vertex explosions - fixed by GPU.readbacks_mode below, not by this patch.)

One-liner that enables exactly those eight:

bash
cd ~/.local/share/shadPS4/patches/shadPS4
for p in '30 FPS++' 'Resolution Patch 1280x800' '1280x800 Light Grid' 'Better AA' \
         'Disable Motion Blur' 'Disable Chromatic Aberration' 'Disable DoF' \
         'Disable Dynamic Light Shadows'; do
  N=$(grep -n "Name=\"$p" Bloodborne.xml | head -1 | cut -d: -f1)
  sed -i "${N}s/isEnabled=\"false\"/isEnabled=\"true\"/" Bloodborne.xml
done
grep -n 'isEnabled="true"' Bloodborne.xml | grep -o 'Name="[^"]*"'

Not recommended: rgba8f color space (large colored light-volume artifacts). Community graphics mods (e.g. the BB PC Remaster texture pack) are GPU-bound on the Deck - they fall into the 17-25 FPS range and cannot hold 30 at native resolution, so they are not worth running here; the patch set above is the best-looking config that stays locked at 30.

config.json keys:

GPU.readbacks_mode: 1 (Relaxed) - required for Bloodborne. Without GPU readbacks the game throws "vertex explosions": huge coloured triangles across the screen, most often right after a death or an area reload. 1 fixes them with the least overhead; 2 (Precise) is heavier; 0 (off) brings them back.
GPU.vblank_frequency: 30 - the emulator's frame cap; with the default 60 the counter drifts above 30 even with the 30 FPS++ patch.
GPU.full_screen: true
Vulkan.pipeline_cache_enabled: true - off by default; without it shaders recompile every launch and turning the camera stutters for the first minutes of every session.

Expect shader-compile hitches on the first pass through each area; they fade as the cache fills.

Steam Deck side: leave the Quick Access frame limiter off (two 30 FPS limiters fight and produce drops to 15), TDP limit off.

Build (Linux)

Clang 18 recommended; GCC 14's libstdc++ or newer is required for std::ranges::to.

bash
git clone --recursive https://github.com/Classmg22/bbsc
cd bbsc/emulator
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
      -DENABLE_QT_GUI=OFF -DENABLE_DISCORD_RPC=OFF -DENABLE_UPDATER=OFF
ninja -C build shadps4

Debian/Ubuntu packages: the list in emulator/documents/building-linux.md plus libxtst-dev libwayland-dev libxkbcommon-dev libdrm-dev libgbm-dev libdecor-0-dev libusb-1.0-0-dev. The mesa-kosmickrisp submodule is macOS-only and can be skipped. The fdk-aac submodule points at the GitHub mirror of the Android AAC decoder (same code; cpp/ layout).

Linux changes in this fork: BBSC save-folder lookup uses the emulator's user dir on non-Windows (src/core/bloodborne_re.cpp), a missing <optional> include, a stray constexpr, the fdk-aac paths, and the co-op hooks decoupled from the reverse-engineering capture (see docs/CHANGELOG.md).

Reporting bugs

Post in #Release BBSC for Linux / Steam Deck on the Discord with the version, host or guest, what happened and when, and the logs: the emulator log ~/.local/share/shadPS4/log/shad_log.txt (or, if you use a user folder next to the executable, user/log/shad_log.txt) and the bbsc-timeline-*.txt from the same run. For co-op problems, logs from both players.

Credits
CLS_AMG - BBSC
framilano (fra98_) - Bloodborne Nucleus Co-op Handler; tester
Wozzardman - shadp2p and shadnet-p2p, the online fork BBSC is built on
Fahad (fhody125) - No Dream For The Hunter, the game server groundwork (MIT)
shadPS4 team and contributors - the emulator; shadNet team - shadNet
The Hunter's Dream team
deadinside28 (bbport) and Supermedo (its Windows build)
Testers - Hardwater, Onesadeye, aboood888848, Fahad, Mob, lelial, J2mF, Kukar3x
Supporters: see SUPPORTERS.txt
Support

BBSC is free for everyone. If you want to support the time that goes into it: Patreon or Buy Me a Coffee.

License

GPL-2.0-or-later, like shadPS4. See LICENSE and NOTICE.md. Third-party parts keep their own licenses.

Bloodborne is developed by FromSoftware and published by Sony Interactive Entertainment. BBSC is a free fan project and is not affiliated with or endorsed by either.
