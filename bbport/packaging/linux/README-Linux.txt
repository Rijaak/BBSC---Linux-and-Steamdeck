BBSC: YHARNAM TOGETHER - LINUX / STEAM DECK BUILD
=================================================
The native Linux build of BBSC: Yharnam Together, from the same source as the Windows release.
It plays with Windows players and on the public server: everyone in a team must be on the same
co-op release (the server checks it), and this build is that release.

Unofficial: built and maintained at https://github.com/Rijaak/BBSC---Linux-and-Steamdeck.
Report problems there (Issues) or in the Linux thread on the BBSC Discord, not to the upstream team.

YOU NEED
  - A Linux PC or a Steam Deck (SteamOS 3.6 or newer), Vulkan 1.3 graphics.
  - Your own Bloodborne for PS4, version 1.09 (CUSA03173 tested): a dumped game folder with the 1.09
    update. Installing from .pkg files is Windows-only for now.

SET UP (once, in Desktop Mode on a Deck)
  1. Unpack this folder anywhere you have room (it makes a co-op copy of the game from links, no
     duplicate files on the same drive).
  2. Run ./BLauncher (double-click it, or from a terminal).
  3. Co-op setup: Global (the public server) or Local (a friend's server by address), your game
     folder ("Find it for me" or Browse), Enemies, Travel. Done.
  4. Press PLAY. The first start takes a while: the game is prepared from your copy and its shaders
     compile.

STEAM DECK GAME MODE
  Add run-game.sh as a Non-Steam Game: in Desktop Mode, Steam > Games > Add a Non-Steam Game >
  Browse, file type All Files, run-game.sh. It starts the game with the settings you made in
  BLauncher. Do NOT force a Steam Play compatibility tool on it: it is a native Linux program.
  (BLauncher's Add to Steam button is off in this build: see KNOWN_ISSUES.md.)

STEAM DECK SETTINGS
  A starting point for the Steam Deck (LCD), from the shadPS4 builds' tested set (a steady 30 FPS at
  1280x800) carried over to this port. Settings in BLauncher; the game reads them at start.

  General
    Output              1280 x 800 (16:10)   The Deck's own screen: nothing is scaled twice, and the
                                             HUD sits at the screen's edges.
    Frame rate          30 FPS (as on PS4)   What the Deck holds steadily; 60 is recommended in co-op
                                             but the Deck rarely keeps it. Mixed frame rates in a
                                             team work (the game sends its state at each one's rate).
    Upscaler            FSR 3.1              FSR 4 is slow on the Deck's GPU (no INT8 dot products).
    Preset              Native AA (x1.0)     Draws at 1280x800, as the shadPS4 setup did; FSR 3.1
                                             only smooths edges. Not holding 30: Quality (x1.5,
                                             ~854x534), then Balanced.
    Window              Borderless (full screen)
    Map > 3D map        Prerendered; press Prepare the 3D map once (a few minutes, ~140 MB).

  Graphics
    Live resolution changes   Off (faster)   The output is set by a patch at start; the Deck never
                                             changes it in the game, so "On" would only cost FPS.
    Light grid                Auto           The community 1280x800 "Light Grid For SteamDeck" patch
                                             at that output (fewer light-grid draw calls, faster);
                                             the game's own grid at any other. Lights missing or cut
                                             off near the screen's edges: choose "The game's own".
    Sharpening                On, 0.50       Lower it if Native AA looks too crisp.
    Object motion vectors     as it is       Off by itself on AMD graphics (the Deck's): it cost
                                             frame rate there.
    Frame generation          Off            Needs 60 FPS or more to look right.
    Model detail (LOD)        As in the game Lower (1) is a cheap gain if 30 is not held.
    Show the FPS counter      On while tuning, off after.

  Display & FPS
    Frames ahead of the GPU   1 (default)    Even frame pacing; 2 can add FPS when the GPU is the
                                             limit, with a little more input lag.
    Presentation              FIFO (VSync)   30 FPS on a 60 Hz screen: each frame shown for exactly
                                             two refreshes, the most even 30. (Mailbox is for high
                                             frame rates; Game Mode's gamescope may use FIFO anyway.)
    HDR output                Off            The LCD Deck has no HDR.

  Game & effects
    Motion blur, Depth of field, Chromatic aberration, Dynamic light shadows: off. The expensive
    effects, as in the shadPS4 set ("Disable ..." patches); dynamic light shadows off also tidies
    the lighting. SSAO: on (cheap, adds contact shadows).

  Advanced
    Experimental features     Off            FSR 4.1.1 and AMD motion vectors are not for the Deck.
    Two-stage GPU pipeline    Auto (8+ threads)  On with the Deck's 8 threads: 20-30% faster;
                                             switch it off only if the game is unstable.
    GPU readbacks             Relaxed (default)
    Fast shader math          Off            A spare: a little more FPS, a slightly different
                                             picture, shaders compiled again once.

  Not needed from the shadPS4 builds: the "Resolution Patch 1280x800" (Output sets the size), "30
  FPS++" (the Frame rate setting manages the frame-rate patches), "Better AA" (the Upscaler), and
  shadPS4's own config (readbacks_mode, buffer cache budget, logging): another emulator core.

  Play from Game Mode (run-game.sh added to Steam, above): in Desktop Mode, Steam's
  desktop controller layout also turns the Deck's buttons into keys the game reads (phantom key
  presses), and the desktop's compositor costs frame rate. Controller layout: Gamepad. The first
  visit to each area compiles shaders (stutter): judge the frame rate on a second pass.

STEAM DECK MEMORY (UMA frame buffer)
  If you set the BIOS UMA Frame Buffer Size to 4 GB: when the battery runs completely flat the
  Deck can boot with it back at 1 GB, and long sessions can then hang while loading an area. Check
  with: cat /sys/class/drm/card*/device/mem_info_vram_total  (4294967296 is 4 GB). If it shows
  1 GB, set it again in the BIOS (hold Volume Up and press Power, Setup Utility > Advanced).

HOSTING
  Hosting the co-op server from Linux is not in this build yet. Join the public server
  (play.seamlesshunt.com) or a Windows host.

WHERE THINGS ARE
  Saves, settings and logs: user/ in this folder. The game's log: user/log/.
  Saves: user/savedata/1/CUSA03173/ (the game backs them up to user/save-backups/ every 10 min).

USING YOUR OLD SAVE FOLDER (shadPS4, the 0.0.x Linux builds, another install)
  This build keeps its own saves in user/savedata/1. To play from the saves you already have,
  either copy them (BLauncher: Import saves) or make user/savedata/1 a link to your old folder,
  so both installs use the same saves. The link works with the game's backups and with
  BLauncher's Restore. In Konsole, with the game and BLauncher closed:

  1. Find the folder that holds your CUSA03173 folder. For shadPS4 it is usually one of:
       ls ~/.local/share/shadPS4/savedata/1/
       ls ~/.local/share/shadPS4/home/1000/savedata/
     (on the SD card, an EmuDeck install may keep it under Emulation/saves/ instead).
  2. Back up both first:
       cp -a ~/.local/share/shadPS4/savedata ~/savedata-backup-$(date +%Y%m%d)
  3. Go to this folder and replace user/savedata/1 with a link to the old folder (change the path
     after "ln -s" to the folder from step 1, the one that holds CUSA03173):
       cd "/path/to/Yharnam Together"
       mkdir -p user/savedata
       [ -e user/savedata/1 ] && mv user/savedata/1 user/savedata/1.before-link
       ln -s ~/.local/share/shadPS4/savedata/1 user/savedata/1
       ls user/savedata/1/      (should list CUSA03173)
  To undo: rm user/savedata/1 (removes only the link) and mv user/savedata/1.before-link user/savedata/1.

  Notes: use one install at a time on the same saves, never both running together. This build also
  writes small SPRJ*.sce_sys folders beside the saves (their names and icons): leave them.
