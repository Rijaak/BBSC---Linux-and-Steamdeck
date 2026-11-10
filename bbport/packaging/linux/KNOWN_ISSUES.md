# Known issues: Linux build (Rijaak/BBSC---Linux-and-Steamdeck)

## Add to Steam: off on Linux (since 1.4.0.1)

**Status for 1.4.0.1 (playtest pre-release):** the button stays off, so it cannot touch anyone's
shortcuts; to be resolved (tested on a Deck and switched back on) before a full release.

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

## Joining a team: not yet tested on Linux (1.4.0.1)

Global sign-in, the server connection and the co-op code start on a Steam Deck (checked: the party HUD
draws from the co-op code). Joining or hosting a team with another player has not succeeded yet in
testing. Reports welcome: user/log/console.txt and user/log/shad_log.txt (bbport.ini coop_trace=1 for
the full co-op log).

## Frame rate in co-op

On the public server co-op runs the game's fixed 60 FPS step whatever the Frame rate setting says
(30 included), so all players move at the same speed; a Steam Deck does not hold 60 everywhere.
Display & FPS: Frame rate Unlocked with Frame cap 30 keeps 30 in co-op (the launcher's experimental
unlocked co-op; not yet tested in a team).

## Upstream tests that fail on Linux

5 of tests/test_coop_launcher.py fail on Linux before and after this fork's changes: they test the
Windows firewall, Windows code pages and the Windows updater (setup .exe), which the Linux build does
not use.

## Fixed in 1.4.0.1 (for reference)

- Start-up crash (SIGSEGV in apply_patches): the GPU hooks left pages of the game read-only.
- Invisible game window: SDL3 built without X11/Wayland.
- Party HUD placeholders ("99 / 99", "test", 表示位置) when started from the Steam shortcut:
  BLauncher --play started the game without co-op (also in the Windows launcher's code).
- A grey wedge under the title screen, menus and cutscenes on 16:10 screens: black bars now.
- Output had no 1280 x 800; 3D map found 0 areas when the game files' case differed.
