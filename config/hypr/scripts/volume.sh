#!/usr/bin/env bash
case "$1" in
  --inc)       swayosd-client --output-volume raise ;;
  --dec)       swayosd-client --output-volume lower ;;
  --toggle)    swayosd-client --output-volume mute-toggle ;;
  --toggle-mic)swayosd-client --input-volume mute-toggle ;;
  --mic-inc)   swayosd-client --input-volume raise ;;
  --mic-dec)   swayosd-client --input-volume lower ;;
  *) echo "uso: volume.sh --inc|--dec|--toggle|--toggle-mic|--mic-inc|--mic-dec" ;;
esac
