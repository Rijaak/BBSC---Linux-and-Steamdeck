# BBSC on Steam Deck - Quick Start

From nothing to Bloodborne co-op on a Steam Deck, step by step. About 20 minutes, no Linux
experience needed. Everything is copy-paste; the only typing you do is your own name, password
and file path. The full reference (every setting, cross-play with Windows players, known issues)
is the [README](README.md) - you don't need it to get playing.

**You need four things before you start:**

1. Your own Bloodborne dump, **CUSA03173 version 01.09**, as a folder with `eboot.bin` in it. (A
   base-game dump plus an update folder named `CUSA03173-UPDATE` next to it also works.) This guide
   does not cover dumping the game.
2. A free account on **<https://seamlesshunt.com/>** - the public community server everyone plays on.
   Make it in any browser now; you'll type the name and password in step 7.
3. **`libSceNgs2.sprx`** - Bloodborne's audio module, from your own PS4's firmware (it's Sony's
   file, so it isn't in the download). The emulator has a built-in stand-in, but Bloodborne wants
   the real one; this guide assumes you have it. Put it in `~/Downloads` for now.
4. The Deck in **Desktop Mode** (Steam button → Power → Switch to Desktop) with **Konsole** open
   (Application menu → System → Konsole). Every command below is pasted into Konsole. Paste with
   **Ctrl+Shift+V**.

> Wherever you see `<eboot path>` below, replace the whole thing - angle brackets included - with the
> real path to your `eboot.bin`, for example
> `/run/media/deck/SDCARD/Emulation/roms/ps4/CUSA03173/eboot.bin`. Same for `<name>` and `<password>`.

---

## 1. Download the build

Open the Deck's browser and go to the **[Releases page](https://github.com/Rijaak/BBSC---Linux-and-Steamdeck/releases)**.
Under the newest release, download the file named `bbsc-linux-<version>-steamdeck.tar.gz`. It goes to
`~/Downloads`. Nothing else from that page is needed.

(Which version? The newest one. Everyone in a session must be on the same BBSC version, and the
newest Linux build tracks the current upstream BBSC. Today that's 0.0.2.1 = BBSC 0.0.2.)

## 2. Unpack it

```bash
mkdir -p ~/Applications && cd ~/Applications
tar xzf ~/Downloads/bbsc-linux-*-steamdeck.tar.gz
ls ~/Applications/bbsc-linux
```

You should see `shadps4-bbsc`, `run-bbsc.sh`, `bbsc-setup.py`, a `lib` folder and some text files.

## 3. Find your eboot.bin

If you don't know the exact path, this prints it:

```bash
find /run/media/deck /home/deck -path '*CUSA03173*' -name eboot.bin 2>/dev/null
```

Copy that line - it's your `<eboot path>` for the rest of the guide. (If it prints two, one inside a
`CUSA03173-UPDATE` folder, use the other one - the base game's. The emulator picks up the update
folder on its own.)

## 4. First launch (creates the config)

```bash
cd ~/Applications/bbsc-linux
./run-bbsc.sh <eboot path>
```

The game should come up to the title screen. Don't play yet - **quit it** (close the window, or
Ctrl+C in Konsole). This first run writes `~/.local/share/shadPS4/config.json`, which the next step
edits.

If a dialog called **Config Migration** appears instead (you had an older shadPS4 on this Deck),
pick **Update**.

## 5. Required settings

Four config values. `readbacks_mode` is the one that matters most: without it the game draws giant
coloured triangles across the screen after every death and area load.

```bash
C=~/.local/share/shadPS4/config.json
sed -i -E 's/"readbacks_mode": *[0-9]+/"readbacks_mode": 1/; s/"vblank_frequency": *[0-9]+/"vblank_frequency": 30/; s/"full_screen": *(true|false)/"full_screen": true/; s/"pipeline_cache_enabled": *(true|false)/"pipeline_cache_enabled": true/' "$C"
grep -nE '"readbacks_mode"|"vblank_frequency"|"full_screen"|"pipeline_cache_enabled"' "$C"
```

The grep must show `"readbacks_mode": 1`, `"vblank_frequency": 30`, `"full_screen": true` and
`"pipeline_cache_enabled": true`. If any of the four lines is missing, step 4 didn't finish - launch
the game once more and quit it, then redo this step.

Now the graphics patches: this downloads the community patch file and switches on the eight that
make Bloodborne run at a steady 30 FPS on the Deck (16:10 resolution, Deck light grid, 30 FPS++,
better AA, and four effects off).

```bash
mkdir -p ~/.local/share/shadPS4/patches/shadPS4 && cd ~/.local/share/shadPS4/patches/shadPS4
curl -L -o Bloodborne.xml https://raw.githubusercontent.com/shadps4-emu/ps4_cheats/main/PATCHES/Bloodborne.xml
printf '{"Bloodborne.xml": ["CUSA03173"]}\n' > files.json
python3 - <<'EOF'
import xml.etree.ElementTree as ET, os
p = os.path.expanduser('~/.local/share/shadPS4/patches/shadPS4/Bloodborne.xml')
want = ['30 FPS++', 'Resolution Patch 1280x800', '1280x800 Light Grid', 'Better AA',
        'Disable Motion Blur', 'Disable Chromatic Aberration', 'Disable DoF',
        'Disable Dynamic Light Shadows']
t = ET.parse(p); on = []
for m in t.getroot().iter('Metadata'):
    name = m.get('Name', '')
    if any(name.startswith(w) for w in want):
        m.set('isEnabled', 'true'); on.append(name)
t.write(p, encoding='utf-8', xml_declaration=True)
print(f'{len(on)} patches enabled:'); print('\n'.join(' - ' + n for n in on))
EOF
```

You should see `8 patches enabled:` and the list. Leave SSAO alone (don't enable "Disable SSAO").

## 6. The audio module

```bash
mkdir -p ~/.local/share/shadPS4/sys_modules
cp ~/Downloads/libSceNgs2.sprx ~/.local/share/shadPS4/sys_modules/
ls -la ~/.local/share/shadPS4/sys_modules/
```

You should see `libSceNgs2.sprx` listed, a few hundred KB. The emulator picks it up automatically on
the next launch; nothing to configure. (Any other `.sprx` you were told to use goes in the same
folder.)

## 7. Your online account

You made the account on seamlesshunt.com already. This tells the emulator about it, points the game at the community server, and writes the server files. **The game must be closed** (it rewrites config.json when it exits and would undo this). Run it from the `bbsc-linux` folder, with the
password in single quotes so characters like `*`, `$` or `!` survive the shell:

```bash
cd ~/Applications/bbsc-linux
python3 bbsc-setup.py --server play.seamlesshunt.com:31313 --no-register --name '<name>' --password '<password>'
```

Use the exact name and password you registered with. Each player needs their **own** account - two
people on one account gives the second one "login error 6".

## 8. Add it to Steam (so it runs in Game Mode)

Still in Desktop Mode, in the Steam window:

1. **Games → Add a Non-Steam Game to My Library… → Browse…**
2. Set the file type dropdown to **All Files**, go to `/home/deck/Applications/bbsc-linux/`, pick
   **`run-bbsc.sh`**, then **Add Selected Programs**.
3. Find it in your Library (it's called `run-bbsc.sh`), right-click → **Properties…**
   - **Shortcut** tab: rename it (e.g. `Bloodborne BBSC`). In **Launch Options** paste your eboot path
     in double quotes: `"<eboot path>"`
   - **Compatibility** tab: leave **"Force the use of a specific Steam Play compatibility tool"
     unticked.** This is a native Linux app; Proton must not be involved.

## 9. Game Mode settings, then play

Back to Game Mode (**Return to Gaming Mode** on the desktop). Open the game's page in your Library,
press the **gear icon → Properties**, and on the first tab set **Game Resolution** to **1280x800**
and turn on **Set resolution for internal and external display**. (This is what lets the game
survive a dock or USB-C display being unplugged mid-session.)

Also worth doing: Quick Access menu (**…** button) → Performance: **frame limiter off**, **TDP limit
off** for this game. The emulator already caps at 30; two caps fight and you get drops to 15.

Now launch it.

- First launch takes longer than usual - shaders compile. Later launches are faster.
- At the title screen, when the game asks, pick **Connect to network**.
- Load your character and open your inventory. You should have the BBSC kit:
  **Hunt Bell, Kin Bell, Bloodlust Bell, Duel Bell, Parting Blank.** If you still see the vanilla
  Beckoning Bell and Small Resonant Bell instead, **quit the game completely and relaunch** (not a
  resume) - the kit is granted at character load.

That's it. You're online with BBSC.

## Co-op in one table

Every bell can be rung anywhere, including the Hunter's Dream. One session carries across areas,
lamps, deaths and bosses. Your partner must be on BBSC **0.0.2** (any platform: Windows shadPS4,
BBport, or this Linux build) and on the **same server** (SeamlessHunt).

| Item | What it does |
|---|---|
| **Hunt Bell** | Host: call other players into your world |
| **Kin Bell** | Join another player's world |
| **Bloodlust Bell** | Invade |
| **Duel Bell** | In co-op, toggle PvP between you |
| **Parting Blank** | Leave the session |

## If something goes wrong

| What you see | What it is | Do this |
|---|---|---|
| *"You are currently not signed into PlayStation Network"* at launch | The game didn't log in. Usually a typo in step 7, or Wi-Fi not up yet after a reboot. | Rerun step 7 with the right name/password; or just restart the game. |
| Still "Unable to connect" after running the setup | The game was open when you ran it (it overwrote the config on exit), or your password has a `*`, `$`, `!` or quote in it | Close the game, rerun step 7 with the password in single quotes, as shown. |
| Giant coloured triangles after a death or load | `readbacks_mode` isn't 1 | Redo step 5 and check the grep output. |
| Vanilla bells, no Hunt/Kin Bell | Kit not granted yet | Full quit, relaunch, load the character. |
| No music or sound effects | The audio module isn't in place | Redo step 6 and check the `ls` shows `libSceNgs2.sprx`. |
| Kin Bell's **Use** is greyed out | You're offline, or a hung join | Get online first; if you are, full quit and relaunch. |
| Both players stuck on "waiting to join / host" | Different servers. Nearly always the Windows/BBport player's **Game server** field. | They set *all* server fields to `play.seamlesshunt.com` - see the README's cross-play section. |
| Game freezes with no error, then closes by itself a minute or two later | An emulator crash followed by a long core dump. Being investigated. | Post it (below). It helps a lot if you turn logging on first: in `config.json`, in the `"Log"` block, set `"enable": true` and `"filter": "*:Warning"`. |

**Where to post:** the **"Release BBSC for Linux / Steam Deck"** thread on the
[BBSC Discord](https://discord.gg/Df7BCmfWdt), or a
[GitHub issue](https://github.com/Rijaak/BBSC---Linux-and-Steamdeck/issues). Say which version
you're on, whether you were host or guest, what you did right before, and attach
`~/.local/share/shadPS4/log/shad_log.txt` plus the newest `bbsc-timeline-*.txt` from the same folder.

## Updating later

New releases are a drop-in binary swap - your saves, config, patches and account are untouched.
The commands are in the README under *Upgrade*.
