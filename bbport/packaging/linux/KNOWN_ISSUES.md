# Known issues: Linux build (Rijaak/BBSC---Linux-and-Steamdeck)

## Add to Steam: off on Linux (since 1.4.0.1)

**Status for 1.5.0.5, as since 1.4.0.1:** the button stays off, so it cannot touch anyone's shortcuts; to be
resolved (tested on a Deck and switched back on) later.

**Status:** the launcher's Add to Steam button is disabled on Linux. Players add `run-game.sh` by hand
(Steam > Games > Add a Non-Steam Game, file type All Files). README-Linux.txt says so.

**What happened (2026-11-09, Steam Deck, SteamOS):** after Add to Steam, a Deck's 40 non-Steam shortcuts
went down to 2, and later to 1 (only NonSteamLaunchers' "Moonlight Game Streaming" survived). Restored from
the launcher's backup (`shortcuts.vdf.bak` / `shortcuts.vdf.<date-time>.yt.bak`).

**Cause found:** [NonSteamLaunchers](https://github.com/moraroy/NonSteamLaunchers-On-Steam-Deck)' background
scanner (`~/.config/systemd/user/NSLGameScanner.py`, lines 279-282 at commit 5403e8d) empties
`shortcuts.vdf` when the file is **not executable**, then writes back only its own entries. NonSteamLaunchers
keeps the file at mode 755; the launcher wrote its new file (a temp file, then `os.replace`) as 644. The
launcher's own write was correct: run on that Deck's real file it kept all 40 entries and changed only its
own (checked 2026-11-09).

**Already in the code (bbport_steam.py), not yet tested on a Deck:**
- the new file keeps the old file's permissions (the fix for the above);
- the list about to be written is read back and must keep every entry (one more when adding), or nothing
  is written;
- every write keeps the old file as `shortcuts.vdf.<date-time>.yt.bak`;
- an entry of the same name ("Bloodborne BBSC~Yarnham Together" on Linux) is updated in place, keeping its
  appid (artwork), play time and launch options;
- Steam counts as running by any of its processes or a live steam.pid.

**To switch the button back on:** test on a Deck with NonSteamLaunchers installed and its scanner running:
Add to Steam with Steam closed, wait a few minutes (the scanner's loop), check `shortcuts.vdf` still holds
every entry and is still `-rwxr-xr-x`, then start Steam and check the library. Then remove the
`steam_button.configure(state='disabled')` block in `bbport_launcher_win.py` (Saves and shortcuts card) and
the README note.

## 1.5.0.5: one game at a time, the standard zlib, Tutuzaooo's texture budget

On top of 1.5.0.4:
- **One game at a time.** 2026-11-16/17 on a Steam Deck two copies of the game ran from one install
  (two starts three seconds apart; why is not known). Both signed in as the same player and knocked
  each other off the co-op server: team buttons that did nothing, "can't reach the co-op server", an
  exit that hung. The launcher now refuses a start while a copy from the same folder is starting,
  running or still closing (user/play.lock and the running bin/bb-probe), with a message.
- **The launcher's zlib is the standard one (1.3.2), built from source.** 1.5.0.3 and 1.5.0.4 shipped
  the build machine's zlib-ng. On a Steam Deck the co-op event files those launchers made held the
  same events but not the same bytes as the tested ones (event-reference.json), so the log's "event
  files" fingerprint was 3281e92710cd5e06 where the official build's is 5027cc81d409f91b, and
  teammates' logs noted the difference. The Deck's own Python with zlib 1.3.2 made all 18 files byte
  for byte the tested ones. The launcher also makes the event files again once when another zlib
  packed them (event-patch/packed-with.txt). Not reproduced on the build machine (zlib-ng packed
  every test input like the standard zlib there), so the check is the Deck's log after updating.
- Tutuzaooo's texture hotfix: texture memory from the driver's live budget on desktop graphics cards
  (BB_GC_LIVE_BUDGET=0 for the old limits). A Steam Deck already worked this way.

**Open: as a guest, enemies that will not die for up to a minute** (2026-11-17, 1.5.0.3 and 1.5.0.4,
one partner on the official 1.5.0 build at 60 FPS). The session dropped about every 60 seconds
("CSMultiPlayMan StopRequest from the game", leave, rejoin 2 to 3 seconds later); in between the
host's damage and deaths stopped arriving for about 30 seconds while positions still came, and the
kills were applied at the rejoin. Normal again after a few minutes, and after the partner left. Not
caused by the event files (above). Cause unknown: it needs the partner's logs or a session with
another partner. No fix in this build.

**Open: one crash in the Hunter's Dream** at the Doll (channel blood echoes), outside a session,
1.5.0.4: "Guest fault (signal 11) at guest offset 0xd3fa05, address 0x1", thread "FMOD nonblockin".
Seen once. To tell whether 1.5.1's crash fixes are involved: BB_GAME_CRASH_FIXES=0 ./BLauncher --play.

## 1.5.0.4: 1.5.0 with official 1.5.1's fixes that work beside 1.5.0 players

The public server runs 1.5.0 and refuses a 1.5.1 game, so this build stays 1.5.0. On top of 1.5.0.3:
waking in the Hunter's Dream after a host's world ahead of yours (BB_DREAM_AFTER_GUEST=0 switches it
off), a teammate not yet placed never hidden, and from 1.5.1 (main 5cef8e0c): the guest stuck
"loading", a guest's own progress kept (merged with this fork's own-world fixes as in 1.5.1.1), the
Supermedo 1.9.8.5 crash fixes, GOTY 01.00 copies patched, zeroed vertex buffers, the travel lock fix,
boss tempo, spectating a boss death beside a teammate, the not-signed-in note, the launcher's fixes,
Thai. Left out: 1.5.1's shop stock flags (each player's own), since every game of a team must agree.
1.5.0 teammates' logs note that this build differs (its patches): a note, not a refusal.

Untested in play: the cloth fix at 30 FPS, waking in the Hunter's Dream, the unplaced teammate.
Reports welcome: user/log/console.txt and user/log/shad_log.txt (bbport.ini coop_trace=1 for the
full co-op log).

## Launcher Output in Desktop Mode

Under the Deck's desktop at 90% scaling the launcher can offer 1422 x 888 (the scaled desktop). Choose
1280 x 800 (Steam Deck): the game then draws the Deck's own pixels and Light grid Auto applies.

## Frame rate in co-op

Since 1.5.0 choosing Frame rate 30 FPS stays 30 FPS in co-op (the README's Steam Deck setting). The
other choices run co-op at the game's fixed 60 FPS step, which a Steam Deck does not hold
everywhere, unless Frame rate is Unlocked (the launcher's experimental unlocked co-op; its Frame cap
list has 30 FPS since 1.5.0.1).

## Hosting a server: not in this package

The launcher's Start server and Stop server work on Linux (Tutuzaooo's port, merged in 1.5.0.1), and
show when the package holds the co-op server (server/shadnet). This tarball is built without it (it
needs Qt 6.8 or newer, which the build machine did not have): play on the public server (Global), or
join a host on Windows or on Tutuzaooo's AppImage.

## Upstream tests on Linux

tests/ pass on Linux but one, tests/test_mods.py (icons overlay), which fails the same way on the
unchanged 1.5.0 source.

## 1.5.0.1: built on 1.5.0, with Tutuzaooo's Linux port merged

The public server moved to 1.5.0 (2026-11-12): a 1.4.0 game is refused. 1.5.0.1 is this fork's port
carried onto the 1.5.0 source, with the work of Tutuzaooo's linux-port-1.5.0
(github.com/Tutuzaooo/BBSC-Yharnam-Together) merged: the launcher's game session (stop and restart),
Start/Stop server, the mouse camera, the menu's mouse focus (stray presses), the fault report, DLSS
on Linux, GCC 14 fixes, and the AppImage recipe (packaging/linux/appimage-geral, not used for this
tarball). Not yet run on a Steam Deck as of its build.

## Fixed in 1.4.0.1 (for reference)

- Start-up crash (SIGSEGV in apply_patches): the GPU hooks left pages of the game read-only.
- Invisible game window: SDL3 built without X11/Wayland.
- Party HUD placeholders ("99 / 99", "test", 表示位置) when started from the Steam shortcut:
  BLauncher --play started the game without co-op (also in the Windows launcher's code).
- A grey wedge under the title screen, menus and cutscenes on 16:10 screens: black bars now.
- Output had no 1280 x 800; 3D map found 0 areas when the game files' case differed.
