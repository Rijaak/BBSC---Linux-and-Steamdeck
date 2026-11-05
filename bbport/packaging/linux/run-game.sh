#!/usr/bin/env bash
# Starts the game with the launcher's saved settings, without its window: the Steam shortcut for
# Game Mode (set everything up once with ./BLauncher in Desktop Mode first).
# No arguments needed; without a set-up game folder the launcher opens instead.
cd -- "$(dirname -- "$(readlink -f -- "$0")")"
exec ./BLauncher --play "$@"
