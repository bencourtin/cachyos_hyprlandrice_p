#!/usr/bin/env bash
# NetPorts.sh — dump de una vez, una línea JSON por puerto TCP/UDP en escucha
# (con el proceso dueño si se puede resolver sin sudo). Lo llama la isla
# quickshell/netmon (Quickshell.Io.Process, one-shot) cada tanto mientras está
# abierta.
set -u

declare -A seen
ss -tulnHp 2>/dev/null | while read -r proto state recvq sendq laddr paddr rest; do
    [ -z "${laddr:-}" ] && continue
    port="${laddr##*:}"
    proto_up="${proto^^}"
    key="${proto_up}:${port}"
    [ -n "${seen[$key]:-}" ] && continue
    seen[$key]=1
    proc=$(grep -oP '(?<=\(\(")[^"]+' <<< "$rest")
    [ -z "$proc" ] && proc="-"
    printf '{"proto":"%s","port":"%s","proc":"%s"}\n' "$proto_up" "$port" "$proc"
done
