# SPDX-License-Identifier: GPL-2.0-or-later
"""Linux build of BBSC: Yharnam Together (Rijaak/BBSC---Linux-and-Steamdeck): lets the Windows
launcher (bbport_launcher_win.py, bbport_coop.py) run unchanged where it only asks Windows for
optional things (DPI, the work area, the display's modes, the console window).

Imported first by the launcher. On Windows it does nothing.

- ctypes.windll: a stand-in whose every function returns 0, which the launcher already reads as
  "not available" (no monitor list from Windows, no console, no DPI awareness). Calls whose
  answer matters on Linux are replaced in the launcher itself (see LINUX_FORK comments).
- os.startfile: xdg-open, as Explorer on Windows.
"""
import ctypes
import os
import subprocess
import sys

IS_WINDOWS = sys.platform == 'win32'
EXE = '.exe' if IS_WINDOWS else ''


class _WinFunction:
    """A Windows API function that is not there: callable, returns 0, takes argtypes/restype."""
    argtypes = None
    restype = None

    def __call__(self, *args, **kwargs):
        return 0


class _WinLibrary:
    def __getattr__(self, name):
        if name.startswith('__'):
            raise AttributeError(name)
        function = _WinFunction()
        setattr(self, name, function)
        return function


class _WinDll:
    def __getattr__(self, name):
        if name.startswith('__'):
            raise AttributeError(name)
        library = _WinLibrary()
        setattr(self, name, library)
        return library


def open_path(path, operation=None):
    """os.startfile for Linux: the desktop's default program (a folder opens in the file manager)."""
    try:
        subprocess.Popen(['xdg-open', str(path)], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL, start_new_session=True)
    except OSError as error:
        raise OSError(f'Could not open {path}: {error}') from error


CA_FILES = ('/etc/ssl/certs/ca-certificates.crt',  # SteamOS, Arch, Debian, Ubuntu
            '/etc/pki/tls/certs/ca-bundle.crt',     # Fedora, Bazzite
            '/etc/ssl/ca-bundle.pem',               # openSUSE
            '/etc/ssl/cert.pem')


def use_system_certificates():
    """The frozen launcher's OpenSSL (built on Ubuntu) looks for the trusted certificates in /usr/lib/ssl,
    which SteamOS and most other systems do not have: no certificate is trusted and Global's sign-in
    (HTTPS) fails. Point it at the system's bundle, unless the player set one."""
    import ssl
    paths = ssl.get_default_verify_paths()
    if os.environ.get('SSL_CERT_FILE') or (paths.cafile and os.path.exists(paths.cafile)):
        return
    for path in CA_FILES:
        if os.path.exists(path):
            os.environ['SSL_CERT_FILE'] = path
            break
    if not os.environ.get('SSL_CERT_DIR') and os.path.isdir('/etc/ssl/certs'):
        os.environ['SSL_CERT_DIR'] = '/etc/ssl/certs'


# One game at a time (Rijaak 2026-11-17). Two games of one install sign in as the same player, and
# the server keeps one session a player: each knocks the other off the server link every few
# seconds (team buttons do nothing, "can't reach the co-op server", an exit that hangs). Seen on a
# Steam Deck: two starts 3 s apart, each through its whole preparation, so a check for a running
# game alone would miss it. The launcher that plays holds a lock for as long as it lives (the
# kernel drops it when the process ends, however it ends), and a game still running or still
# closing is looked for as well.
_play_lock = None


def take_play_lock(data_dir):
    """True when this launcher now holds the install's play lock (or cannot tell); False when
    another launcher of this install is starting or playing the game."""
    global _play_lock
    if IS_WINDOWS or _play_lock is not None:
        return True
    import fcntl
    try:
        folder = os.path.join(str(data_dir), 'user')
        os.makedirs(folder, exist_ok=True)
        handle = open(os.path.join(folder, 'play.lock'), 'w')
    except OSError:
        return True  # nowhere to keep the lock: never a reason not to play
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        handle.close()
        return False
    _play_lock = handle
    return True


def release_play_lock():
    global _play_lock
    if _play_lock is not None:
        try:
            _play_lock.close()
        except OSError:
            pass
        _play_lock = None


def running_games(install, proc='/proc'):
    """The pids of this install's game (bin/bb-probe) that are running or still closing."""
    game = os.path.join(os.path.realpath(str(install)), 'bin', 'bb-probe')
    pids = []
    try:
        entries = os.listdir(proc)
    except OSError:
        return pids
    for entry in entries:
        if not entry.isdigit():
            continue
        try:
            path = os.readlink(os.path.join(proc, entry, 'exe')).removesuffix(' (deleted)')
        except OSError:
            continue  # gone, or another user's
        if os.path.realpath(path) == game:
            pids.append(int(entry))
    return pids


def play_blocked(install, data_dir):
    """'' when the game may start (this launcher holds the play lock from now on); else why not:
    'starting' (another launcher is starting or playing it) or 'running' (a game is still there)."""
    if IS_WINDOWS:
        return ''
    if not take_play_lock(data_dir):
        return 'starting'
    if running_games(install):
        release_play_lock()
        return 'running'
    return ''


def message_window(title, text, seconds=15):
    """A small window with `text` that closes by itself: a start without a window (Steam's
    shortcut) has nowhere else to say it. Never raises."""
    try:
        import tkinter as tk
        root = tk.Tk()
        root.title(title)
        root.configure(bg='#14110f')
        tk.Label(root, text=text, wraplength=560, justify='left', fg='#e6dcc8', bg='#14110f',
                 font=('TkDefaultFont', 13), padx=28, pady=22).pack()
        tk.Button(root, text='OK', command=root.destroy, padx=18, pady=4).pack(pady=(0, 18))
        root.after(int(seconds * 1000), root.destroy)
        root.mainloop()
    except Exception:  # no display, no Tk: the log has the line
        pass


def install():
    if IS_WINDOWS:
        return
    use_system_certificates()
    if not hasattr(ctypes, 'windll'):
        ctypes.windll = _WinDll()
    if not hasattr(ctypes, 'WinError'):
        ctypes.WinError = lambda code=None, descr=None: OSError(code or 0, descr or 'Windows error')
    if not hasattr(os, 'startfile'):
        os.startfile = open_path


install()
