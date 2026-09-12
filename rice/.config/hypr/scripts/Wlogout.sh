#!/usr/bin/env bash
pkill wlogout && exit 0
# 5 opciones -> una sola fila
wlogout -b 5 -c 10 -r 10 -m 250 -p layer-shell
