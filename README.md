# BBSC for Linux / Steam Deck

A native Linux build of the **BBSC (Bloodborne Seamless Co-op)** shadPS4 emulator, tested on the
Steam Deck. BBSC is by [CLS_AMG](https://github.com/CLSAMG22/BBSC); this repo packages it for Linux
with the fixes the Linux port needs. Upstream ships Windows only - this is the Linux build.

**Downloads:** [Releases](https://github.com/Rijaak/BBSC---Linux-and-Steamdeck/releases) ·
**Upstream:** [CLSAMG22/BBSC](https://github.com/CLSAMG22/BBSC) ·
**Community:** [BBSC Discord](https://discord.gg/Df7BCmfWdt) ·
**Bugs (this build):** the `#Release BBSC for Linux / Steam Deck` thread on the Discord

## Which version do I need?

Versions are `<BBSC version>.<Linux revision>`. **Everyone in a co-op session must be on the same
BBSC version** - 0.0.1 and 0.0.2 clients cannot connect to each other.

| Linux release | BBSC version | Connects to |
|---|---|---|
| **0.0.2.1** (current) | 0.0.2 | BBSC 0.0.2 players: Windows shadPS4, BBport, other 0.0.2.x Linux |
| 0.0.1.3 | 0.0.1 | BBSC 0.0.1 players only |
| 0.0.1.2 | 0.0.1 | BBSC 0.0.1 players only |

If your partner is on the current upstream (0.0.2), use **0.0.2.1**. The 0.0.1.x builds stay up only for
people still playing with 0.0.1 partners.

## What's in the package

`bbsc-linux-<version>-steamdeck.tar.gz` unpacks to a `bbsc-linux/` folder:

- `shadps4-bbsc` - the emulator with BBSC built in (no separate DLL)
- `run-bbsc.sh` - launcher; picks the bundled libstdc++ only if the system one is too old
- `bbsc-setup.py` - account / server setup (replaces the Windows launcher's Accounts tab)
- `lib/` - bundled libstdc++, libgcc, libatomic
- `README-LINUX.txt`, licenses, `NOTICE.md`

**Not included:** the Windows BBSC launcher, any game files, any PS4 firmware. You need your own
Bloodborne **CUSA03173 v01.09** dump.

## Requirements

- Linux with glibc 2.38+ (SteamOS 3.6+ is fine) and Vulkan
- Your own CUSA03173 v01.09 dump (`eboot.bin` + game folder)
- `libSceNgs2.sprx` in `~/.local/share/shadPS4/sys_modules/` if your setup needs it

The build uses the same data folder as a normal Linux shadPS4:
`~/.local/share/shadPS4/` (saves, `sys_modules`, `patches`, `log/shad_log.txt`, `config.json`).

## Install (first time)

```bash
mkdir -p ~/Applications && cd ~/Applications
tar xzf ~/Downloads/bbsc-linux-0.0.2.1-steamdeck.tar.gz
cd bbsc-linux
./run-bbsc.sh /path/to/CUSA03173/eboot.bin
```

To launch from Game Mode: add `run-bbsc.sh` as a Non-Steam Game and put the `eboot.bin` path in its
Launch Options. Do the Steam Deck settings and the online setup below before your first real session.

## Upgrade (drop-in binary swap)

Updates only replace the emulator binary. Config, saves, patches and your account are untouched.

```bash
pkill -9 -f shadps4-bbsc; sleep 1
cd ~/Downloads
sha256sum bbsc-linux-0.0.2.1-steamdeck.tar.gz        # compare with the hash on the release page
tar xzf bbsc-linux-0.0.2.1-steamdeck.tar.gz
DIR=$(dirname "$(find ~ /run/media -name shadps4-bbsc -type f 2>/dev/null | head -1)")
cp "$DIR/shadps4-bbsc" "$DIR/shadps4-bbsc.bak"       # rollback copy
cp bbsc-linux/shadps4-bbsc "$DIR/shadps4-bbsc"
chmod +x "$DIR/shadps4-bbsc"
```

Then do a **full restart** of the game (not a resume) and load your character - the BBSC item kit is
granted at character load. Rollback: `cp "$DIR/shadps4-bbsc.bak" "$DIR/shadps4-bbsc"`.

## Online / account setup

`bbsc-setup.py` creates (or attaches) your shadNet account and writes `users.json`, `config.json`
(`shadnet_*` keys) and `host_overrides.json` so the game's server list and summons go to the community
server. **Both players in a session must be on the same server.**

**SeamlessHunt (public community server):** make an account at <https://seamlesshunt.com/>, then

```bash
python3 bbsc-setup.py --server play.seamlesshunt.com:31313 --no-register --name YourName --password YourPassword
```

**A host's private server:** use the server card they give you

```bash
python3 bbsc-setup.py --card "/path/to/BBSC-card.json" --name YourName --password secret
```

Other options: `--user-id N` (attach to a specific shadPS4 local user), `--game-server host` (a
separate game-API host), `--key` (registration key). Then start the game and pick **Connect to network**.

Login errors: **6** (already logged in) is a stale session after a crash - wait a minute, make sure
no second instance is running (`pkill -9 -f shadps4-bbsc`), retry. **8** is a wrong password - rerun
the setup with the right one.

## Steam Deck settings

Tested on a Steam Deck LCD: a steady 30 FPS at 1280x800 (GPU around 75-85%) with these shadPS4 patches
on (`~/.local/share/shadPS4/patches/shadPS4/Bloodborne.xml`, `isEnabled="true"` on the patch's
`<Metadata>` line, or tick them in the shadPS4 Qt launcher):

- 30 FPS++
- Resolution Patch 1280x800 (16:10)
- 1280x800 Light Grid For SteamDeck
- Better AA
- Disable Motion Blur
- Disable Chromatic Aberration
- Disable DoF
- Disable Dynamic Light Shadows

Leave **SSAO on** (do *not* enable the "Disable SSAO" patch): it's a screen-space effect that shadPS4
renders correctly and adds contact shadows and depth for almost no cost. Disable it only if you see dark
grain or haloing.

**Keep "Disable Dynamic Light Shadows" on.** shadPS4 renders Bloodborne's dynamic light shadows
incorrectly and they cost GPU; the patch both tidies the lighting and saves about 7% GPU. (The large
triangular "wedge" artifacts some players hit on death or an area reload are a *separate* problem - GPU
vertex explosions - fixed by `GPU.readbacks_mode` below, not by this patch.)

One-liner that enables exactly those eight:

```bash
cd ~/.local/share/shadPS4/patches/shadPS4
for p in '30 FPS++' 'Resolution Patch 1280x800' '1280x800 Light Grid' 'Better AA' \
         'Disable Motion Blur' 'Disable Chromatic Aberration' 'Disable DoF' \
         'Disable Dynamic Light Shadows'; do
  N=$(grep -n "Name=\"$p" Bloodborne.xml | head -1 | cut -d: -f1)
  sed -i "${N}s/isEnabled=\"false\"/isEnabled=\"true\"/" Bloodborne.xml
done
grep -n 'isEnabled="true"' Bloodborne.xml | grep -o 'Name="[^"]*"'
```

Not recommended: **rgba8f color space** (large colored light-volume artifacts). Community graphics mods
(e.g. the BB PC Remaster texture pack) are GPU-bound on the Deck - they fall into the 17-25 FPS range and
can't hold 30 at native resolution; the patch set above is the best-looking config that stays locked at 30.

`config.json` keys (`~/.local/share/shadPS4/config.json`):

- `GPU.readbacks_mode: 1` (Relaxed) - **required for Bloodborne.** Without GPU readbacks the game throws
  "vertex explosions": huge coloured triangles across the screen, most often right after a death or an
  area reload. `1` fixes them with the least overhead; `2` (Precise) is heavier; `0` (off) brings them back.
- `GPU.vblank_frequency: 30` - the emulator's frame cap; with the default 60 the counter drifts above 30
  even with the 30 FPS++ patch.
- `GPU.full_screen: true`
- `Vulkan.pipeline_cache_enabled: true` - off by default; without it shaders recompile every launch and
  turning the camera stutters for the first minutes of every session.

Expect shader-compile hitches on the first pass through each area; they fade as the cache fills.

Steam Deck side: leave the Quick Access frame limiter **off** (two 30 FPS limiters fight and produce
drops to 15), TDP limit off.

### Frame rate in co-op

Upstream's 0.0.2 notes recommend everyone in a session run the *same* frame rate - the default
`vblank 60` with no FPS patch - or you can get elevators skipping and players floating / falling through.
The 30 FPS settings above are a solo-performance choice for the Deck; the vblank-60 default is
**noticeably more stuttery on the Deck**, so only switch if you actually see desync in a session.

Switch to the co-op default (close the game first):

```bash
pkill -9 -f shadps4-bbsc; sleep 1
sed -i 's/"vblank_frequency": *30/"vblank_frequency": 60/' ~/.local/share/shadPS4/config.json
cd ~/.local/share/shadPS4/patches/shadPS4
N=$(grep -n 'Name="30 FPS++' Bloodborne.xml | head -1 | cut -d: -f1)
sed -i "${N}s/isEnabled=\"true\"/isEnabled=\"false\"/" Bloodborne.xml
```

Back to the solo 30 FPS setup: the same commands with `60`→`30` and `"true"`→`"false"` swapped.

## Playing co-op: the bells

BBSC replaces the vanilla online items with its own kit. It's granted automatically at character load
(if it's missing, do a full quit and relaunch, not a resume). The vanilla Beckoning Bell / Small Resonant
Bell / Silencing Blank are disabled.

| Item | What it does |
|---|---|
| **Hunt Bell** | Host: call other players into your game |
| **Kin Bell** | Join another player's game |
| **Bloodlust Bell** | Invade another player's world |
| **Duel Bell** | In co-op, toggle PvP between players |
| **Parting Blank** | End the co-op session |

In 0.0.2 the bells can be rung anywhere, including the Hunter's Dream. The session is seamless: one
co-op session across areas, deaths, lamps, bosses and the Dream.

## BBSC settings

BBSC options are environment variables, the same names as the Windows build's Mods tab, e.g.
`BBSC_MOD_SEAMLESS=1 BBSC_MOD_HOOKS=1 SHADPS4_BBSC_FIVE_HUNTERS=1 ...` - all **on** by default (see
`mod.json` in the upstream package for the full list). Set one to `0` in `run-bbsc.sh`'s environment
to turn it off.

Do **not** set `SHADPS4_BLOODBORNE_RE_TRACE=0` to quiet logging - that switch installs the co-op hooks,
so turning it off disables co-op (deaths stop resetting to the lamp, the online session drops). The
reverse-engineering capture is off by default; developers can enable it with `SHADPS4_BBSC_CAPTURE=1`.

## Known issues

From upstream 0.0.2 (still a test version - **back up your saves**):

- After a full party wipe in a boss fight, the host (and the guest with them) can wake up in the Hunter's
  Dream instead of at the last lamp.
- As a guest, after a boss kill, items, NPCs or levers sometimes can't be used.
- Chalice Dungeons: no co-op inside them yet (solo works).
- Frame-rate mismatch between players: elevators skipping, floating, falling through (see above).

Linux build:

- The vblank-60 default stutters noticeably on the Deck; keep the 30 FPS settings unless you see desync.
- `BBSC relay client: cannot reach <server>:20444 - retrying` in the log is harmless if your server
  doesn't run the 0.0.2 relay; emulator-to-emulator co-op still works over the P2P signaling.
- Shader-compile hitches on the first pass through a new area.

## Reporting bugs

Post in **#Release BBSC for Linux / Steam Deck** on the [Discord](https://discord.gg/Df7BCmfWdt) with
the version, host or guest, what happened and when, and the logs: the emulator log
`~/.local/share/shadPS4/log/shad_log.txt` (or, if you use a user folder next to the executable,
`user/log/shad_log.txt`) and the `bbsc-timeline-*.txt` from the same run. For co-op problems, logs from
both players. Linux-only problems go here, not upstream's `#bug-reports`.

## Linux changes in this build

On top of upstream BBSC 0.0.2 (tag `v0.0.2`):

- **Relay client ported to Linux** (`bbsc_relay_client.cpp`). Upstream wrote it against Winsock and
  stubbed it out on non-Windows, so a naive Linux build silently shipped a dead relay. The relay is what
  lets an emulator player share scaling, world flags, boss progress and the Duel Bell with a BBport player
  in the same session.
- **Item kit fix** (`bbsc_memscan.cpp`). The guest-memory param scan had no Linux implementation (Windows
  only, returned nothing), so the kit was never granted and the vanilla bells never disabled. Added a
  `/proc/self/maps`-based scan.
- **Co-op hooks decoupled from the RE capture.** The capture (per-event disk I/O, a source of stutter)
  is now off by default behind `SHADPS4_BBSC_CAPTURE`; the hooks always install.
- `--user-id N` works on Linux (read from `/proc/self/cmdline`).
- Save-folder lookup via the emulator's user dir on non-Windows, a missing `<optional>` include, a stray
  `constexpr`, the `fdk-aac` submodule on its GitHub mirror.

Full history: `docs/CHANGELOG.md`.

## Building from source

The source is upstream `CLSAMG22/BBSC` at tag `v0.0.2` plus the Linux commits (branch `linux-0.0.2`
in this repo). Clang 18 recommended; GCC 14's libstdc++ or newer is required for `std::ranges::to`.

```bash
git clone --recursive <this repo>
cd BBSC/emulator
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
      -DENABLE_QT_GUI=OFF -DENABLE_DISCORD_RPC=OFF -DENABLE_UPDATER=OFF
ninja -C build shadps4
```

Debian/Ubuntu packages: the list in `emulator/documents/building-linux.md` plus
`libxtst-dev libwayland-dev libxkbcommon-dev libdrm-dev libgbm-dev libdecor-0-dev libusb-1.0-0-dev`.
The `mesa-kosmickrisp` submodule is macOS-only and can be skipped.

## Credits

- **CLS_AMG** - BBSC
- **Wozzardman** - shadp2p, seamless summons
- **fhody125** - No Dream For The Hunter, server format
- **framilano (fra98_)** - Bloodborne Nucleus Co-op handler; tester
- **deadinside28, Supermedo** - BBport
- **shadPS4 team** - the emulator
- **Rijaak** - Linux / Steam Deck build and testing

## License

GPL-2.0-or-later, the same as shadPS4 and BBSC. See `LICENSE-BBSC.txt`, `LICENSE-shadPS4.txt` and
`NOTICE.md` in the package. No game files or firmware are included or distributed.
