# LINUX_FORK: run by package.sh inside the packaged launcher (BLauncher --script): the zlib it loads,
# and that it packs and unpacks.
import zlib

data = bytes(range(256)) * 400
print(zlib.ZLIB_RUNTIME_VERSION, 'ok' if zlib.decompress(zlib.compress(data, 9)) == data else 'broken')
