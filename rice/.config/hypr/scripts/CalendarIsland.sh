#!/usr/bin/env bash
# Toggle de la isla de calendario (quickshell). La llama el bind SUPER+SHIFT+C.
# Misma mecánica que ClimaIsland.sh / MediaIsland.sh.
set -u

if pgrep -f 'quickshell.*-c[= ]calendario' >/dev/null 2>&1; then
    pkill -f 'quickshell.*-c[= ]calendario'
    exit 0
fi

exec quickshell -c calendario
