#!/usr/bin/env bash
# Toggle de la isla de mezcla de volumen (quickshell). La llama el on-click del
# módulo pulseaudio de waybar (group/audio). Misma mecánica que ClimaIsland.sh
# / MediaIsland.sh.
set -u

if pgrep -f 'quickshell.*-c[= ]mixerctl' >/dev/null 2>&1; then
    pkill -f 'quickshell.*-c[= ]mixerctl'
    exit 0
fi

exec quickshell -c mixerctl
