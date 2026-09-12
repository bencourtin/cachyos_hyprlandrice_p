#!/usr/bin/env bash
# DarkLight.sh — night-light / blue-light filter with an automatic sunrise→sunset
# schedule.
#
# Backend: hyprsunset (Hyprland's blue-light filter). In `auto` mode a small
# background loop recomputes the target every few minutes from the sun's altitude
# at your location: from a few degrees above the horizon down to civil dusk it
# eases (smoothstep) between DAY_TEMP and NIGHT_TEMP, so the shift is gradual and
# follows the season. The temperature is pushed with `hyprctl hyprsunset`.
#
# Location is reused from the weather module's cache
# (~/.cache/waybar-clima/geo.json, written by ClimaClock.sh). If that is missing
# it does one IP-geolocation lookup of its own, cached for a day. With no
# location at all it falls back to a plain 07:00/19:00 clock schedule.
#
# Solar-schedule approach ported from serpantinum
# (https://github.com/ilyamiro/serpantinum, AGPL-3.0). The astronomy below is the
# standard low-precision sun-position model, reimplemented here.
#
# Usage:
#   DarkLight.sh auto            start / refresh the automatic solar schedule
#   DarkLight.sh on [KELVIN]     fixed manual temperature (default $NIGHT_TEMP)
#   DarkLight.sh off             stop the schedule, drop the filter (identity)
#   DarkLight.sh toggle          off <-> auto
#   DarkLight.sh status          print  "auto <K>" | "manual <K>" | "off"
#
# Deps: hyprsunset, hyprctl, awk. Optional: jq + curl (location).
set -u

# --------------------------- CONFIG ---------------------------
DAY_TEMP=6500            # neutral daytime white point (K)
NIGHT_TEMP=4000          # warmest point at full night (K)
UPDATE_INTERVAL=300      # seconds between recomputes in auto mode
GEO_CACHE_TTL=86400      # seconds to trust our own IP-geolocation fallback
FIXED_LAT=""             # set both to pin a location and skip geolocation
FIXED_LON=""
# ------------------------------------------------------------

TEMP_MIN=1000
TEMP_MAX=10000

RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/rice-darklight"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rice-darklight"
STATE_F="$CACHE_DIR/state"
TEMP_F="$CACHE_DIR/temp"
PID_F="$RUN_DIR/loop.pid"
CLIMA_GEO="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-clima/geo.json"
OWN_GEO="$CACHE_DIR/geo.json"
mkdir -p "$RUN_DIR" "$CACHE_DIR"

have() { command -v "$1" >/dev/null 2>&1; }
for b in hyprctl awk; do
    have "$b" || { echo "DarkLight: missing '$b'" >&2; exit 1; }
done

# ---------------------- hyprsunset ----------------------
hs_running() { pgrep -x hyprsunset >/dev/null 2>&1; }

hs_ensure() {
    hs_running && return 0
    have hyprsunset || { echo "DarkLight: hyprsunset not installed" >&2; return 1; }
    if ! hyprctl dispatch exec -- hyprsunset >/dev/null 2>&1; then
        nohup hyprsunset >/dev/null 2>&1 &
        disown 2>/dev/null || true
    fi
    for _ in $(seq 1 60); do hs_running && break; sleep 0.05; done
    hs_running
}

hs_set() { # $1 = kelvin
    hyprctl hyprsunset temperature "$1" >/dev/null 2>&1 && printf '%s\n' "$1" > "$TEMP_F"
}

hs_off() {
    hs_running || return 0
    hyprctl hyprsunset identity >/dev/null 2>&1 || true
    pkill -x hyprsunset 2>/dev/null || true
    rm -f "$TEMP_F"
}

# ---------------------- background loop ----------------------
loop_stop() {
    [ -f "$PID_F" ] || return 0
    local p; p="$(cat "$PID_F" 2>/dev/null || true)"
    if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then
        pkill -P "$p" 2>/dev/null || true   # wake the sleep
        kill "$p" 2>/dev/null || true
    fi
    rm -f "$PID_F"
}

run_loop() {
    trap 'exit 0' TERM INT
    while :; do
        local t; t="$(compute_target)"
        if [ -n "$t" ] && [ "$t" -ge "$TEMP_MIN" ] 2>/dev/null && [ "$t" -le "$TEMP_MAX" ] 2>/dev/null; then
            hs_ensure && hs_set "$t"
        fi
        sleep "$UPDATE_INTERVAL" &
        wait $!
    done
}

# ---------------------- location ----------------------
read_latlon() { # echoes "LAT LON", non-zero exit if unknown
    if [ -n "$FIXED_LAT" ] && [ -n "$FIXED_LON" ]; then
        printf '%s %s\n' "$FIXED_LAT" "$FIXED_LON"; return 0
    fi
    if have jq && [ -f "$CLIMA_GEO" ]; then
        local r; r="$(jq -r 'select(.lat and .lon) | "\(.lat) \(.lon)"' "$CLIMA_GEO" 2>/dev/null)"
        [ -n "$r" ] && { printf '%s\n' "$r"; return 0; }
    fi
    if ! { [ -f "$OWN_GEO" ] && [ $(( $(date +%s) - $(stat -c %Y "$OWN_GEO") )) -lt "$GEO_CACHE_TTL" ]; }; then
        if have curl; then
            local j
            j="$(curl -sf --max-time 5 https://ipapi.co/json/ 2>/dev/null)" \
              || j="$(curl -sf --max-time 5 'http://ip-api.com/json/?fields=status,lat,lon' 2>/dev/null)" \
              || j=""
            [ -n "$j" ] && printf '%s' "$j" > "$OWN_GEO"
        fi
    fi
    if have jq && [ -f "$OWN_GEO" ]; then
        local r; r="$(jq -r '(.latitude // .lat) as $a | (.longitude // .lon) as $o
                              | if ($a != null and $o != null) then "\($a) \($o)" else empty end' \
                     "$OWN_GEO" 2>/dev/null)"
        [ -n "$r" ] && { printf '%s\n' "$r"; return 0; }
    fi
    return 1
}

# ---------------------- target temperature ----------------------
# Sun altitude -> colour temperature, eased across a band around the horizon.
solar_temp() { # $1 lat  $2 lon
    awk -v lat="$1" -v lon="$2" -v day="$DAY_TEMP" -v night="$NIGHT_TEMP" -v now="$(date -u +%s)" '
        function rad(d){ return d*0.017453292519943295 }
        function deg(r){ return r*57.29577951308232 }
        function norm(x){ x=x%360; return x<0 ? x+360 : x }
        function asin_s(x){ if(x>1)x=1; if(x<-1)x=-1; return atan2(x, sqrt(1-x*x)) }
        BEGIN{
            d   = (now - 946728000) / 86400.0          # days since J2000.0
            g   = rad(norm(357.529 + 0.98560028*d))    # sun mean anomaly
            q   = norm(280.459 + 0.98564736*d)         # sun mean longitude
            L   = rad(norm(q + 1.915*sin(g) + 0.020*sin(2*g)))  # ecliptic longitude
            e   = rad(23.439 - 0.00000036*d)           # obliquity of the ecliptic
            sinL= sin(L)
            dec = atan2(sin(e)*sinL, sqrt(1 - sin(e)*sin(e)*sinL*sinL))  # declination
            ra  = deg(atan2(cos(e)*sinL, cos(L)))
            gmst= norm(280.46061837 + 360.98564736629*d)
            H   = rad(norm(gmst + lon - ra))           # local hour angle
            alt = deg(asin_s( sin(rad(lat))*sin(dec) + cos(rad(lat))*cos(dec)*cos(H) ))
            lo=-6.0; hi=3.0                            # ease band, degrees of altitude
            if      (alt <= lo) t = night
            else if (alt >= hi) t = day
            else { x=(alt-lo)/(hi-lo); s=x*x*(3-2*x); t = night + (day-night)*s }
            printf "%d\n", t + 0.5
        }'
}

# No location: plain clock schedule (day 07-19, dusk ramp 19-21, dawn ramp 06-07).
clock_temp() {
    awk -v day="$DAY_TEMP" -v night="$NIGHT_TEMP" -v h="$(date +%-H)" -v m="$(date +%-M)" '
        BEGIN{
            t = h + m/60.0
            if      (t>=7 && t<19)  x = day
            else if (t>=19 && t<21) { f=(t-19)/2; s=f*f*(3-2*f); x = day  + (night-day)*s }
            else if (t>=6 && t<7)   { f=(t-6);    s=f*f*(3-2*f); x = night + (day-night)*s }
            else                    x = night
            printf "%d\n", x + 0.5
        }'
}

compute_target() {
    local ll
    if ll="$(read_latlon)"; then
        solar_temp "${ll% *}" "${ll#* }"
    else
        clock_temp
    fi
}

# ---------------------- commands ----------------------
cmd="${1:-toggle}"; shift 2>/dev/null || true

case "$cmd" in
    __loop) run_loop ;;   # internal: the detached auto-mode loop

    auto)
        loop_stop
        hs_ensure || exit 1
        hs_set "$(compute_target)"
        nohup "$0" __loop >/dev/null 2>&1 &
        echo $! > "$PID_F"
        disown 2>/dev/null || true
        echo auto > "$STATE_F"
        ;;

    on)
        loop_stop
        k="${1:-$NIGHT_TEMP}"
        case "$k" in
            ''|*[!0-9]*) echo "DarkLight: bad temperature '$k'" >&2; exit 1 ;;
        esac
        { [ "$k" -ge "$TEMP_MIN" ] && [ "$k" -le "$TEMP_MAX" ]; } \
            || { echo "DarkLight: temperature out of range ($TEMP_MIN-$TEMP_MAX)" >&2; exit 1; }
        hs_ensure || exit 1
        hs_set "$k"
        echo manual > "$STATE_F"
        ;;

    off|reset)
        loop_stop
        hs_off
        echo off > "$STATE_F"
        ;;

    toggle)
        if [ "$(cat "$STATE_F" 2>/dev/null || echo off)" = off ]; then
            exec "$0" auto
        else
            exec "$0" off
        fi
        ;;

    status)
        state="$(cat "$STATE_F" 2>/dev/null || echo off)"
        if [ "$state" = off ] || ! hs_running; then
            echo off
        else
            echo "$state $(cat "$TEMP_F" 2>/dev/null || echo '?')"
        fi
        ;;

    *)
        echo "usage: DarkLight.sh {auto|on [KELVIN]|off|toggle|status}" >&2
        exit 1
        ;;
esac
