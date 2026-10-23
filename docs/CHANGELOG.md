# Changelog - BBSC Linux / Steam Deck build

Changes made in this Linux fork, newest first. Versions are `<BBSC version>.<Linux revision>`.
Upstream BBSC's own changelog is in the upstream repo: https://github.com/CLSAMG22/BBSC

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
- Audited the rest of 0.0.2's `#ifdef _WIN32` ad
