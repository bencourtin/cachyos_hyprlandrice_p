#!/usr/bin/env bash
case "$1" in
  --inc) swayosd-client --brightness raise ;;
  --dec) swayosd-client --brightness lower ;;
  *) echo "uso: Brightness.sh --inc|--dec" ;;
esac
