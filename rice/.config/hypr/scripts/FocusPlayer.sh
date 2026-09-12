#!/usr/bin/env bash
# Enfoca la ventana del reproductor que está sonando (click en el now-playing de waybar).
# Ojo: en la lua de CachyOS el dispatch correcto es hl.dsp.focus({ window = "class:..." }).
player="$(playerctl -a metadata --format '{{playerName}}' 2>/dev/null | head -n1)"

case "${player,,}" in
    spotify*)                          sel='class:^([Ss]potify)$' ;;
    firefox*|librewolf*|zen*)          sel='class:^(firefox|librewolf|zen)$' ;;
    chromium*|chrome*|brave*|vivaldi*) sel='class:^(chromium|google-chrome|brave-browser|vivaldi-stable)$' ;;
    mpv*)                              sel='class:^(mpv)$' ;;
    vlc*)                              sel='class:^(vlc)$' ;;
    *)                                 sel='class:^([Ss]potify)$' ;;
esac

hyprctl dispatch "hl.dsp.focus({ window = \"${sel}\" })"
