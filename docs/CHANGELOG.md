# Changelog - BBSC Linux / Steam Deck build

Changes made in this Linux fork, newest first. Versions are `<BBSC version>.<Linux revision>`.
Upstream BBSC's own changelog is in the upstream repo: https://github.com/CLSAMG22/BBSC

## 2026-10-25 - Linux fork 0.0.2.2: fix the ~1 hour "freeze" in heavy areas (GPU memory exhaustion); crash logs survive

- Symptom: on the Steam Deck the game froze with no error after roughly 45-60 minutes in Central
  Yharnam (walking, solo or online), then closed by itself two minutes later. `coredumpctl` showed
  SIGTRAP; with synchronous logging the last log line was
  `buffer.cpp:90 Create: Assertion Failed! Failed allocating buffer with error ErrorOutOfDeviceMemory`
  on the GPU command-processor thread. The "freeze" was systemd-coredump draining a 6 GB core of the
  dying process.
- Root cause 1 (`src/video_core/buffer_cache/buffer_cache.cpp`, `RunGarbageCollector`): the buffer
  cache's collector computed its thresholds and defined its clean-up step but never swept the LRU -
  cached GPU buffers were never freed. Bloodborne's streaming grew the GPU footprint until the whole
  Vulkan memory budget was used. On a Deck that budget is VRAM plus system memory (the UMA Frame
  Buffer size only moves the split, which is why 4 GB UMA changed nothing; VRAM read 3930/4096 MB at
  the crash with ~1.3 GB of system RAM left). Fixed: the sweep now runs like the texture cache's -
  buffers unused for 160 submissions (80 when over the critical line) are freed, up to 32 (64) per
  pass. Only buffers with no GPU-written data are evicted (writing dirty ones back needs a GPU
  round trip inside the submit path; the first attempt, a synchronous download, was dropped) - the
  over-budget retry below covers them. An evicted range is handed back to the CPU
  (`MarkRegionAsCpuModified`) before the buffer goes: the tracker otherwise keeps the pages
  write-protected and the fault handler returns early for an unregistered range, so the first
  CPU write after eviction faulted forever (one game thread at 100%, everything else waiting - the
  first 0.0.2.2 build hung within seconds on the Central Yharnam bridge), and a recreated buffer
  would have come back without an upload. `SynchronizeBuffer` now touches the LRU on every use,
  not only on uploads, so buffers the game reads every frame without rewriting are not churned.
- Root cause 2 (`buffer.cpp`, `image.cpp`): an allocation failure was a fatal assertion. The
  VK_EXT_memory_budget budget is advisory - the driver pages between VRAM and system memory itself -
  so `vmaCreateBuffer`/`vmaCreateImage` now retry without `VMA_ALLOCATION_CREATE_WITHIN_BUDGET_BIT`,
  then with any memory type, and only assert if all three fail. First eight occurrences are logged
  as warnings (`GPU memory budget exhausted ... retrying over budget`).
- Crash diagnostics (`src/common/logging/log.cpp`): with `Log.sync=false` the assertion message that
  explains a crash sat in spdlog's background queue while the process died - `Common::Log::Flush()`
  flushed the file sink, which never sees a queued message. Flush now drains the async sink
  (`wait_all`, bounded to 2 s) first, so `assert_fail_impl` -> `Emulator::Shutdown` -> `Flush`
  gets the line onto disk before `int3`. Three days of empty crash logs were this.
- `run-bbsc.sh`: `ulimit -c 0`. A crash now closes the game in about a second instead of sitting
  frozen for two minutes while a 6 GB core is written that SteamOS then discards anyway.
- README: the UMA 4 GB section no longer claims to fix freezes (it is still the standard Deck tweak);
  Known issues describes the real cause and fix; swappiness advice corrected for SteamOS with zram
  (keep 60). QUICKSTART.md added (Deck from zero to co-op in 9 steps, incl. `libSceNgs2.sprx`,
  the patch file download and enabling, and the "run setup with the game closed, quote the
  password" gotchas found by the first outside users).

## 2026-10-21 - Linux fork 0.0.2.1: rebased onto BBSC 0.0.2; relay client and --user-id ported to Linux

- Versioning: the Linux releases are now `<BBSC version>.<Linux revision>`. 0.0.1.2 and 0.0.1.3
  (formerly 0.0.2 / 0.0.3) are Linux revisions of BBSC 0.0.1; this is the first Linux build of
  BBSC 0.0.2. Upstream 0.0.2 is a hard version break - everyone in a session (host and guests) needs
  0.0.2, mixed 0.0.1/0.0.2 sessions do not connect - so a 0.0.1.x Linux build cannot play with any
  0.0.2 client. Upstream ships no Linux game build for 0.0.2; this is it.
- All Linux-fork commits were rebased onto upstream tag v0.0.2 (`4f11faf`). 14 of 15 applied
  clean, including the item-kit fix (`bbsc_memscan.cpp` is unchanged in 0.0.2, so the Linux
  `FindInMemory` gap is still present upstream and the fix still applies) and the capture decouple.
  The only conflict was the param-scan diagnostic log, which now sits next to 0.0.2's new
  `stable_cache` in `FindBbscParamTables` (upstream caches the goods/sp-effect scans and added a
  direct param-repository fast path, so the kit should appear sooner and the log line fires far
  less often).
- New in 0.0.2 and Windows-only, now ported (`src/core/bbsc_relay_client.cpp`): the BBSC relay
  client. Upstream wrote it against Winsock with the entire implementation under `#ifdef _WIN32` and
  empty stubs for everything else, so a naive Linux build compiled fine and silently shipped a dead
  relay. The relay is what lets an emulator player share scaling, world flags, boss progress and the
  Duel Bell with a BBport/mod player in the same session (per the file's own header, without it the
  mod player "takes a stranger as its host by position"). Ported to one implementation on both
  platforms behind a small shim (`socket_t`, `InvalidSocket`, `ShutdownBoth`, `CloseSocket`;
  WSAStartup Windows-only; `SO_SNDTIMEO` as `struct timeval` on POSIX; `getpid()` for the own-id
  seed). No Windows behavior change.
- New in 0.0.2 and Windows-only, now ported (`bloodborne_re.cpp`, `BbscProcessUserId`): the
  `--user-id N` flag was read with `GetCommandLineW` and silently ignored on Linux. Linux now reads
  `/proc/self/cmdline` and runs the identical parse.
- Audited the rest of 0.0.2's `#ifdef _WIN32` additions: `localtime_s`, `_getpid`, `<process.h>`
  all have `#else` fallbacks; the `%APPDATA%` save-dir fallbacks are correctly skipped on Linux
  because the existing "resolve save folder via the emulator user dir" commit handles the Linux path;
  the F8 / `GetAsyncKeyState` code is gated to the DLL build (`_WIN32 && BBSC_MOD`) and excluded
  from the built-in build. Nothing else needed porting; the build links with no Winsock references.

## 2026-10-21 - Linux fork 0.0.1.3: implement the guest-memory param scan on Linux (fixes the item kit) (released as "0.0.3")

- Symptom: on the Linux build the BBSC item kit was never granted - no Hunt Bell, Kin Bell, Duel Bell
  or Bloodlust Bell in the inventory, and the vanilla bells (Beckoning Bell, Small Resonant Bell,
  Silencing Blank) were left active but relabeled "no longer used." A diagnostic build showed the param
  scan returning `0 raw hit(s)` for every param type (`EQUIP_PARAM_GOODS_ST`, `SP_EFFECT_PARAM_ST`,
  `NPC_PARAM_ST`), identically on every call regardless of `scan_low`/`image_base`.
- Root cause (`src/core/bbsc_memscan.cpp`, `Core::Bbsc::FindInMemory`): the entire function body was
  wrapped in `#ifdef _WIN32` with no `#else`. On Linux it compiled to `return {};` - an empty result -
  so `FindBbscParamTables` found no tables, `PrepareBbscKitRows` never ran, and the kit grant and the
  vanilla-bell disable in `PrepareBbscDuelBell` never fired. `BbscScanLow()`/`image_base` were red
  herrings: the loop that consumes them only existed in the Windows branch.
- Fix: added the Linux implementation - enumerate mapped regions from `/proc/self/maps`, scan the
  readable ones overlapping `[lo, hi)` with the same `memchr`/`memcmp` search the Windows path uses
  (`SearchRegion`, now compiled on both platforms; the Windows SEH guard is replaced on Linux by the
  fact that only maps-readable regions are scanned and shadPS4's own SIGSEGV handler backstops its
  GPU-tracked pages). No behavior change on Windows.

## 2026-10-20 - Linux fork 0.0.1.2: co-op hooks decoupled from the RE capture (SHADPS4_BBSC_CAPTURE) (released as "0.0.2")

- `SHADPS4_BLOODBORNE_RE_TRACE` was effectively a hidden master switch. In the built-in build
  (`BBSC_VANILLA` OFF, `BuiltIn` true) it installs the whole BBSC co-op hook set - death/respawn,
  summon reload, cross-map handoff, healing-fountain, the bell/area memory patches - AND the per-event
  JSONL reverse-engineering capture, both welded together in `InstallReverseEngineeringTrace`. Turning it
  off to quiet the logging (a reasonable "it's just a trace" assumption) silently tears out co-op:
  deaths stop resetting to the lamp (you stare at your corpse) and the game drops its network session.
- That capture writes and `flush()`es a record for every traced co-op event. On a Steam Deck the
  per-event disk flush is a real source of in-play stutter and load-time hitching. It is a developer
  instrument, not something a player needs running.
- Fix (`src/core/bloodborne_re.cpp`, `InstallReverseEngineeringTrace`): the co-op hooks now always
  install (still gated only by `RE_TRACE`, default on). The capture directory creation, file open and
  header write are gated behind a new `SHADPS4_BBSC_CAPTURE` switch - **default off** - and a failed
  open is now non-fatal instead of aborting the whole install. `TraceEntry` already returns before any
  write when `capture_file` is closed, so with capture off there is zero capture disk I/O and the hooks
  behave exactly as before. Set `SHADPS4_BBSC_CAPTURE=1` to record captures for RE work.
- Net effect on the Deck build: co-op, death/respawn and the online session work out of the box with no
  per-event capture flushing, and the `captures/bloodborne-re` -> `/dev/shm` RAM-disk symlink used as a
  stopgap is no longer needed. Do **not** set `SHADPS4_BLOODBORNE_RE_TRACE=0` to reduce logging - it
  disables co-op; use `SHADPS4_BBSC_CAPTURE` (off by default) to control the capture instead.

## 2026-10-17 - Steam Deck settings established (Linux 0.0.1.1)

- Tested on a Steam Deck LCD and documented in the README: a steady 30 FPS at 1280x800 with the
  eight-patch set (30 FPS++, Resolution Patch 1280x800, 1280x800 Light Grid, Better AA, Disable
  Motion Blur, Disable Chromatic Aberration, Disable DoF, Disable Dynamic Light Shadows), SSAO left
  on, `GPU.vblank_frequency: 30`, `GPU.full_screen: true`, `Vulkan.pipeline_cache_enabled: true`.
  Quick Access frame limiter and TDP limit off on the Deck side (two 30 FPS limiters fight).
- 2026-10-18: corrected to shadows-off / SSAO-on. shadPS4 renders Bloodborne's dynamic light
  shadows incorrectly and they cost ~7% GPU; SSAO is a screen-space effect it renders correctly and
  adds depth for almost no cost.
- 2026-10-21: `GPU.readbacks_mode: 1` found to be **required**. Without GPU readbacks the game throws
  vertex explosions - huge coloured triangles across the screen, most often right after a death or an
  area reload. These had been wrongly attributed to the shadow/SSAO patches; the README now says so.

## 2026-10-16 - Linux fork 0.0.1.1: first native Linux / Steam Deck build (released as "0.0.1")

- Built the BBSC emulator (shadPS4 v0.17.1 base, BBSC built in, `BBSC_VANILLA` off) natively on
  Linux. Upstream ships Windows only. Packaged as `bbsc-linux-<ver>-steamdeck.tar.gz` with
  `run-bbsc.sh` (uses the bundled libstdc++ only if the system one lacks GLIBCXX_3.4.32) and the
  bundled `lib/` (libstdc++, libgcc_s, libatomic). Uses the normal Linux shadPS4 data folder
  `~/.local/share/shadPS4/`. No game files or firmware included.
- Build fixes for Linux/Clang: a missing `<optional>` include in `notifications_layer.cpp`; a
  meaningless `constexpr` on `LayoutWord::data()`; the `fdk-aac` submodule pointed at the GitHub
  mirror of the Android AAC decoder (same code, `cpp/` layout). The macOS-only `mesa-kosmickrisp`
  submodule is skipped.
- `src/core/bloodborne_re.cpp`: the BBSC save-folder lookup assumed a Windows path; on non-Windows
  it now resolves through the emulator's user dir.
- `bbsc-setup.py`: the Linux replacement for the Windows launcher's Accounts tab. Creates (or
  attaches, `--no-register`) the shadNet account, writes it into `users.json`, sets the `shadnet_*` /
  `shad_net_enabled` / `connected_to_network` keys in `config.json`, and writes `host_overrides.json`
  so the game's server list and summons go to the community server (the launcher did this on
  Windows). Supports a host's server card (`--card`) or a direct `--server host:31313`.
- README: Linux / Steam Deck build and run notes - shared data folder, the 16:10 resolution patch,
  the launch crash, manual online setup.
