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
  In BLauncher press Add to Steam (close Steam first: in Desktop Mode, Steam > Exit). It adds
  run-game.sh as a Non-Steam Game called Bloodborne, which starts the game with the settings you
  made in BLauncher. Or add it by hand: Steam > Games > Add a Non-Steam Game > Browse, file type
  All Files, run-game.sh. Do NOT force a Steam Play compatibility tool on it: it is a native Linux
  program.

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
