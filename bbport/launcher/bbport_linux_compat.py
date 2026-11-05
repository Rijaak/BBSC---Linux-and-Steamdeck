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


def install():
    if IS_WINDOWS:
        return
    if not hasattr(ctypes, 'windll'):
        ctypes.windll = _WinDll()
    if not hasattr(ctypes, 'WinError'):
        ctypes.WinError = lambda code=None, descr=None: OSError(code or 0, descr or 'Windows error')
    if not hasattr(os, 'startfile'):
        os.startfile = open_path


install()
