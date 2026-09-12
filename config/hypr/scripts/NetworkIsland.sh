#!/usr/bin/env bash
# Toggle de la isla de tráfico de red (quickshell). La llama el on-click del
# módulo "network" de waybar (group/connections). Misma mecánica que
# ClimaIsland.sh / MediaIsland.sh / MixerIsland.sh.
set -u

if pgrep -f 'quickshell.*-c[= ]netmon' >/dev/null 2>&1; then
    pkill -f 'quickshell.*-c[= ]netmon'
    exit 0
fi

exec quickshell -c netmon
