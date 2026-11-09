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
