#!/usr/bin/env bash
case "$1" in
  status)
    if pgrep -x hypridle >/dev/null; then
      echo '{"text":"","tooltip":"hypridle activo","class":"active","alt":"active"}'
    else
      echo '{"text":"","tooltip":"hypridle detenido","class":"notactive","alt":"notactive"}'
    fi ;;
  toggle)
    if pgrep -x hypridle >/dev/null; then
      pkill -x hypridle; notify-send -a hypridle "Idle" "desactivado"
    else
      uwsm app -- hypridle >/dev/null 2>&1 & notify-send -a hypridle "Idle" "activado"
    fi ;;
esac
