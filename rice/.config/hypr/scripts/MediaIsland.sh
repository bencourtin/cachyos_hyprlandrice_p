#!/usr/bin/env bash
# Toggle de la isla de reproductores (quickshell). La llama el on-click del
# módulo custom/playerctl de waybar. Misma mecánica que ClimaIsland.sh.
set -u

if pgrep -f 'quickshell.*-c[= ]mediactl' >/dev/null 2>&1; then
    pkill -f 'quickshell.*-c[= ]mediactl'
    exit 0
fi

exec quickshell -c mediactl
