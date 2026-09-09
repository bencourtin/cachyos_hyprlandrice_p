#!/usr/bin/env bash
case "$1" in
  --btop)  uwsm app -- kitty --title btop -e btop ;;
  --term)  uwsm app -- kitty ;;
  --nmtui) uwsm app -- kitty --title nmtui -e nmtui ;;
  --nvtop) uwsm app -- kitty --title nvtop -e nvtop 2>/dev/null || uwsm app -- kitty -e btop ;;
  *) uwsm app -- kitty ;;
esac
