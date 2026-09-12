#!/usr/bin/env bash
# Uso de GPU NVIDIA para waybar (módulo custom/gpu). Salida JSON.
set -u

q="$(nvidia-smi --query-gpu=name,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw \
      --format=csv,noheader,nounits 2>/dev/null)" || { echo '{"text":"","tooltip":"nvidia-smi no disponible"}'; exit 0; }

IFS=',' read -r name gpu memu vram vramtot temp power <<<"$q"
name="$(echo "$name" | sed 's/^ *//;s/ *$//')"
gpu="$(echo "$gpu" | tr -d ' ')"
memu="$(echo "$memu" | tr -d ' ')"
vram="$(echo "$vram" | tr -d ' ')"
vramtot="$(echo "$vramtot" | tr -d ' ')"
temp="$(echo "$temp" | tr -d ' ')"
power="$(echo "$power" | tr -d ' ')"; power="${power%.*}"

cls="normal"; [ "${gpu:-0}" -ge 80 ] 2>/dev/null && cls="high"

printf '{"text":"%s%%","class":"%s","tooltip":"%s\\n%s%% carga · VRAM %s/%s MiB (%s%%) · %s°C · %sW"}\n' \
    "${gpu:-0}" "$cls" "$name" "${gpu:-0}" "${vram:-?}" "${vramtot:-?}" "${memu:-?}" "${temp:-?}" "${power:-?}"
