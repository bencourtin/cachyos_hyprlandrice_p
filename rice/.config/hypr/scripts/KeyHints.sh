#!/usr/bin/env bash
# Toggle del cheatsheet de atajos (quickshell). Bind: SUPER + K.
# Mismo idiom que ClimaIsland.sh / MediaIsland.sh.
set -u

if pgrep -f 'quickshell.*-c[= ]keyhints' >/dev/null 2>&1; then
    pkill -f 'quickshell.*-c[= ]keyhints'
    exit 0
fi

exec quickshell -c keyhints
