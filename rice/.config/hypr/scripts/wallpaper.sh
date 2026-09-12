#!/usr/bin/env bash
# Wallpaper + Material You (matugen) — rice
# Uso:
#   wallpaper.sh                 -> selector rofi desde ~/Pictures/wallpapers
#   wallpaper.sh /ruta/img.png   -> fija ese wallpaper
#   wallpaper.sh --restore       -> re-aplica el wallpaper actual (autostart)
set -uo pipefail

WALL_DIR="${WALL_DIR:-$HOME/Pictures/wallpapers}"
LINK="$HOME/.config/hypr/current_wallpaper"
CACHE="$HOME/.cache/current_wallpaper"

_notify() { command -v notify-send >/dev/null && notify-send -a "wallpaper" "$@" || true; }

set_wall() {
    local img="$1"
    if [ ! -f "$img" ]; then
        _notify "No existe: $img"
        exit 1
    fi

    # 1) referencia estable para hyprlock / rofi / etc.
    ln -sf "$img" "$LINK"
    mkdir -p "$(dirname "$CACHE")"
    printf '%s\n' "$img" > "$CACHE"

    # 2) daemon awww (fork de swww en CachyOS)
    if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon >/dev/null 2>&1 &
        sleep 0.4
    fi
    awww img "$img" \
        --transition-type grow --transition-pos center \
        --transition-fps 60 --transition-duration 1 2>/dev/null \
        || awww img "$img" 2>/dev/null || true

    # 3) colores Material You (matugen)
    if command -v matugen >/dev/null; then
        matugen image "$img" -m dark --source-color-index 0 >/dev/null 2>&1 || true
    fi
}

case "${1:-}" in
    --restore)
        target="$(readlink -f "$LINK" 2>/dev/null || true)"
        if [ -z "$target" ] || [ ! -f "$target" ]; then
            target="$(find "$WALL_DIR" -maxdepth 1 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) \
                | sort | head -1)"
        fi
        [ -n "$target" ] && set_wall "$target"
        ;;
    "")
        cd "$WALL_DIR" 2>/dev/null || { _notify "No existe $WALL_DIR"; exit 1; }
        pick="$(find . -maxdepth 1 -type f \
                    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) \
                    -printf '%f\n' | sort \
                | while IFS= read -r f; do
                    printf '%s\0icon\x1f%s\n' "$f" "$WALL_DIR/$f"
                  done \
                | rofi -dmenu -i -p "Wallpaper" \
                    -theme-str 'listview {columns: 3;} element-icon {size: 7.5em;}')"
        [ -n "$pick" ] && set_wall "$WALL_DIR/$pick"
        ;;
    *)
        set_wall "$1"
        ;;
esac
