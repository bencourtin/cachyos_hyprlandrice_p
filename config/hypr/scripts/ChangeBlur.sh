#!/usr/bin/env bash
cur=$(hyprctl -j getoption decoration:blur:passes | grep -oP '"int":\s*\K[0-9]+')
case "$cur" in
  2) n=4 ;; 4) n=6 ;; 6) n=0 ;; *) n=2 ;;
esac
if [ "$n" -eq 0 ]; then
  hyprctl keyword decoration:blur:enabled false
  notify-send -a waybar "Blur" "desactivado"
else
  hyprctl keyword decoration:blur:enabled true
  hyprctl keyword decoration:blur:passes "$n"
  notify-send -a waybar "Blur" "$n pases"
fi
