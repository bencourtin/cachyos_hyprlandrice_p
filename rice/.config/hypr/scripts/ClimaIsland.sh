#!/usr/bin/env bash
# Toggle de la isla de clima (quickshell). Lo llama el on-click del módulo
# custom/clima de waybar.
set -u

if pgrep -f 'quickshell.*-c[= ]clima' >/dev/null 2>&1; then
    pkill -f 'quickshell.*-c[= ]clima'
    exit 0
fi

# refresca state.json (respeta el TTL interno) y abre la isla
"$HOME/.config/hypr/UserScripts/ClimaClock.sh" >/dev/null 2>&1 || true
exec quickshell -c clima
