#!/usr/bin/env bash
killall waybar 2>/dev/null
sleep 0.3
uwsm app -- waybar >/dev/null 2>&1 &
