# Bloodborne Seamless Co-op (BBSC)

Play the whole of Bloodborne together. BBSC is a mod for the [shadPS4](https://github.com/shadps4-emu/shadPS4)
emulator that keeps a co-op session alive through deaths, lamps, area changes, bosses and the Hunter's
Dream - up to five hunters, each keeping their own character.

**Downloads:** Nexus Mods (link coming with the release) · **Community:** [Discord](https://discord.gg/Df7BCmfWdt)

> 0.0.1 is the first public test. Back up your saves before playing.

## Features

- One co-op session that lasts through deaths, lamps, area changes, bosses and the Hunter's Dream
- Up to 5 hunters: the host and 4 guests
- Guests follow the host between areas and lamps and respawn with the group
- Everyone keeps their own levels, echoes and items
- Shared progress (optional): the host's boss kills and shortcuts are added to the guest's world
- Guests get boss rewards and enemy drops; items already picked up do not come back
- Enemy scaling by the number of hunters
- A co-op kit with no Insight cost: Hunt Bell, Kin Bell, Bloodlust Bell, Parting Blank, Duel Bell (PvP toggle)
- Clear co-op messages in place of the vanilla "beckoner / resonance" lines
- Public server, self-hosted servers (Radmin VPN, Tailscale, LAN, VPS) and split screen (Nucleus Co-op)
- Runs in shadPS4 and in the BBport Windows build

## Requirements

- Your own Bloodborne **CUSA03173, version 01.09** - no game files are included
- Windows, or Linux / Steam Deck with the native emulator build from this fork (see **Linux** below; the server also runs on Linux)

## Downloads

| File | For |
|---|---|
| `BBSC-<version>-Play.zip` | Players: launcher + emulator + BBSC, connects to the public server |
| `BBSC-<version>-Server.zip` | Hosting your own server (Windows) |
| `BBSC-<version>-Nucleus.zip` | Split screen with the [Bloodborne Nucleus Co-op Handler](https://github.com/framilano/BloodborneNucleusCoopHandler) |
| `BBSC-<version>-BBport.zip` | Test build for the [BBport Windows build](https://github.com/Supermedo/bloodborne_pc) - same server as shadPS4 players |

## Quick start

1. Unzip the Play package and keep its files together.
2. Run `PLAY BBSC.cmd`. Your shadPS4 settings, patches and saves are used as they are.
3. Launcher > Settings > Accounts > Create Account on Server.
4. Host rings the Hunt Bell, guests ring the Kin Bell.

## Repository layout

| Folder | Contents |
|---|---|
| `emulator/` | The shadPS4 fork (shadp2p based). BBSC game code: `src/core/bloodborne_re.cpp`; the mod DLL: `mod/` |
| `launcher/` | The Qt launcher fork (Mods and Accounts tabs) |
| `server/` | Host package scripts and the BBSC game server (`bbsc_gameserver.py`) |
| `tools/` | Game data readers and helper tools |
| `docs/` | Architecture, world sync, networking, known limitations, changelog |

## Linux / Steam Deck (this fork)

This fork adds a native Linux build of the BBSC emulator (`emulator/`, shadPS4 v0.17.1 base with
BBSC built in). The Windows package does not work under Proton/Wine: the game stalls in a loading loop
before the first logo, and the plain shadPS4 v0.17.0 Windows build does the same, so it is a Wine
issue rather than BBSC. The same code compiled natively runs fine.

What you get is the emulator only. The Windows launcher is not ported; the game is started from the
command line and BBSC's options are set with environment variables (same names as in `mod.json`).

**Run** (release tarball, or your own build):

```bash
./run-bbsc.sh /path/to/CUSA03173/eboot.bin
```

It uses the normal shadPS4 data folder (`~/.local/share/shadPS4`: saves, `sys_modules`, `patches`,
`config.json`), so an existing shadPS4 setup is used as it is. To keep BBSC separate, create a `user`
folder next to the executable and it will be used instead.

**Going online.** The Windows launcher's Accounts tab and the `first-start` / `join-host` scripts are
not ported; `emulator/scripts/bbsc-setup.py` (also in the tarball) does the same from a terminal:

```bash
# 1. create your account on the community server (Seamless Hunt: https://seamlesshunt.com/),
#    or let the script create it on a server that allows it (drop --no-register, add --card or --key)
# 2. write account + server into the emulator's files
python3 bbsc-setup.py --server play.seamlesshunt.com:31313 --no-register --name YourName --password YourPassword
# 3. start the game and pick "Connect to network"
```

What it writes, if you would rather do it by hand (all in the data folder):

| File | Change |
|---|---|
| `users.json` | in `Users.user`, on the entry with `player_index: 1` (user 1000): `shadnet_enabled: true`, `shadnet_npid`, `shadnet_password`, `shadnet_email` |
| `config.json` | in `General`: `shadnet_server: "host:31313"`, `shadnet_webapi_server: "http://host:31315"`, `shad_net_enabled: true`, `connected_to_network: true` |
| `host_overrides.json` | `{"https://ss4.scej-network.jp:20443": "http://host:20443", "http://thehuntersdream.com:18671/summon_messenger": "http://host:31315"}` — without this the game asks Sony's dead server for its server list and reports "Failed to acquire network server information" |

Replace `host` with the community server (`play.seamlesshunt.com` for Seamless Hunt, or your own
host's address). A server card (`*.json` with `shadnet` and `registration_key`) can be passed with
`--card` instead of `--server`.

BBSC's own options (five hunters, scaling, no fog walls, ...) are environment variables with the
names from `mod.json` (`BBSC_MOD_SEAMLESS`, `BBSC_MOD_HOOKS`, `SHADPS4_BBSC_*`); all default to on.

To check the connection: `grep -a -i -E 'shadnet|login|ss.info' ~/.local/share/shadPS4/log/shad_log.txt`.
A working run logs the shadNet login for your account and a `200` reply for `/bb-eu/ss.info`.

Needs glibc 2.38+ (SteamOS 3.6+ is fine) and Vulkan. `libstdc++` is bundled in the tarball.

**Build** (Clang 18 recommended; GCC 14's libstdc++ or newer is required for `std::ranges::to`):

```bash
git clone --recursive https://github.com/<you>/BBSC
cd BBSC/emulator
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
      -DENABLE_QT_GUI=OFF -DENABLE_DISCORD_RPC=OFF -DENABLE_UPDATER=OFF
ninja -C build shadps4
```

Debian/Ubuntu packages: the list in `emulator/documents/building-linux.md` plus
`libxtst-dev libwayland-dev libxkbcommon-dev libdrm-dev libgbm-dev libdecor-0-dev libusb-1.0-0-dev`.
The `mesa-kosmickrisp` submodule is macOS-only and can be skipped. The `fdk-aac` submodule points at
the GitHub mirror of the Android AAC decoder (same code; `cpp/` layout).

Linux changes in this fork: BBSC save-folder lookup uses the emulator's user dir on non-Windows
(`src/core/bloodborne_re.cpp`), a missing `<optional>` include, a stray `constexpr`, and the
`fdk-aac` paths. Everything else is upstream BBSC 0.0.1.

## Building

- Emulator: `build/build-shadp2p.cmd` (Windows, Visual Studio 2022, CMake, Ninja)
- Mod DLL: `emulator/mod/build-mod.cmd`
- Game server: Python 3, no extra packages (`server/gameserver/bbsc_gameserver.py --shadnet <address>`)

## Reporting bugs

Post in `#bug-reports` on the [Discord](https://discord.gg/Df7BCmfWdt) with the version, host or guest,
what happened and when, and both logs: the BBSC log (`mods/CUSA03173/bbsc/logs/`) and the emulator log
(`user/log/shad_log.txt` or `%APPDATA%\shadPS4\log\`).

## Credits

- **CLS_AMG** - BBSC
- **framilano (fra98_)** - Bloodborne Nucleus Co-op Handler; tester
- **Wozzardman** - [shadp2p](https://github.com/Wozzardman/shadp2p) and shadnet-p2p, the online fork BBSC is built on
- **Fahad (fhody125)** - No Dream For The Hunter, the game server groundwork (MIT)
- **shadPS4 team and contributors** - the emulator; **shadNet team** - shadNet
- **The Hunter's Dream team**
- **deadinside28** (bbport) and **Supermedo** (its Windows build)
- **Testers** - Hardwater, Onesadeye, aboood888848, Fahad, Mob, lelial, J2mF, Kukar3x
- Supporters: see `SUPPORTERS.txt`

## Support

BBSC is free for everyone. If you want to support the time that goes into it:
[Patreon](https://www.patreon.com/c/CLS_AMG) or [Buy Me a Coffee](https://buymeacoffee.com/j2mf).

## License

GPL-2.0-or-later, like shadPS4. See `LICENSE` and `NOTICE.md`. Third-party parts keep their own licenses.

Bloodborne is developed by FromSoftware and published by Sony Interactive Entertainment. BBSC is a free
fan project and is not affiliated with or endorsed by either.
