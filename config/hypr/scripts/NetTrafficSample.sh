#!/usr/bin/env bash
# NetTrafficSample.sh — loop de 1s: una línea JSON por segundo con el
# throughput (bytes/seg, up y down) de la interfaz de la ruta default.
# Proceso persistente, lo lanza la isla quickshell/netmon (Quickshell.Io.Process,
# lee stdout línea a línea) mientras está abierta.
set -u

IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
[ -z "$IFACE" ] && IFACE=$(basename "$(ls -d /sys/class/net/*/ 2>/dev/null | grep -v '/lo/' | head -1)")

read_bytes() { cat "/sys/class/net/$IFACE/statistics/${1}_bytes" 2>/dev/null || echo 0; }

prev_rx=$(read_bytes rx)
prev_tx=$(read_bytes tx)

while true; do
    sleep 1
    rx=$(read_bytes rx)
    tx=$(read_bytes tx)
    down=$(( rx - prev_rx ))
    up=$(( tx - prev_tx ))
    # counters pueden resetear (interfaz que cae y vuelve) -> negativo, clamp a 0
    (( down < 0 )) && down=0
    (( up < 0 )) && up=0
    prev_rx=$rx; prev_tx=$tx
    printf '{"iface":"%s","down_bps":%d,"up_bps":%d,"rx_total":%d,"tx_total":%d}\n' \
        "$IFACE" "$down" "$up" "$rx" "$tx"
done
