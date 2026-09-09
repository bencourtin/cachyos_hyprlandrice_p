#!/usr/bin/env bash
DIR="$HOME/Pictures/wallpapers"
img=$(find "$DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | shuf -n1)
[ -n "$img" ] && exec "$HOME/.config/hypr/scripts/wallpaper.sh" "$img"
