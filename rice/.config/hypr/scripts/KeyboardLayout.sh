#!/usr/bin/env bash
# KeyboardLayout.sh — ciclo de 3 idiomas de teclado con un solo atajo
# (ALT+SHIFT+Space, ver binds.lua).
#
# Estados: en (English/US) -> latam (Español Latam) -> zh (中文, pinyin) -> en...
# El chino NO es un layout xkb (xkb no compone caracteres): se resuelve con el
# IME fcitx5 (motor pinyin) montado sobre el layout base "us". En es/en el IME
# se deja en "keyboard-us" (passthrough) para que las teclas lleguen directo al
# layout xkb activo (us o latam).
#
# Layouts xkb declarados en inputs.lua: kb_layout = "us,latam" (índice 0 = us,
# 1 = latam). Se cambia en runtime con `hyprctl switchxkblayout` (dispatcher,
# no `hyprctl keyword` -> no pisa el gotcha del parser Lua de CachyOS).
#
# Uso:
#   KeyboardLayout.sh cycle     siguiente estado (default si no hay args)
#   KeyboardLayout.sh en|latam|zh   ir directo a un estado
#   KeyboardLayout.sh status    imprime el estado actual
set -u

STATE_DIR="$HOME/.cache/rice-keyboard"
STATE_FILE="$STATE_DIR/state"
mkdir -p "$STATE_DIR"

ORDER=(en latam zh)

current() {
    [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "en"
}

next_state() {
    local cur="$1" i
    for i in "${!ORDER[@]}"; do
        if [ "${ORDER[$i]}" = "$cur" ]; then
            echo "${ORDER[$(( (i + 1) % ${#ORDER[@]} ))]}"
            return
        fi
    done
    echo "en"
}

osd() {
    swayosd-client --custom-message "$1" --custom-icon input-keyboard-symbolic >/dev/null 2>&1 \
        || notify-send -a "Teclado" "$1" 2>/dev/null || true
}

apply() {
    case "$1" in
        en)
            hyprctl switchxkblayout all 0 >/dev/null 2>&1
            fcitx5-remote -s keyboard-us >/dev/null 2>&1
            osd "⌨ English (US)"
            ;;
        latam)
            hyprctl switchxkblayout all 1 >/dev/null 2>&1
            fcitx5-remote -s keyboard-us >/dev/null 2>&1
            osd "⌨ Español (Latam)"
            ;;
        zh)
            hyprctl switchxkblayout all 0 >/dev/null 2>&1
            fcitx5-remote -s pinyin >/dev/null 2>&1
            osd "⌨ 中文 (Pinyin)"
            ;;
        *)
            echo "estado desconocido: $1" >&2
            return 1
            ;;
    esac
    echo "$1" > "$STATE_FILE"
    pkill -RTMIN+9 waybar 2>/dev/null || true
}

case "${1:-cycle}" in
    cycle)      apply "$(next_state "$(current)")" ;;
    en|latam|zh) apply "$1" ;;
    status)     current ;;
    label)
        # etiqueta corta para el indicador de waybar (custom/kblayout,
        # ModulesCustom) — más simple que format-icons: waybar sólo mapea
        # por texto en módulos custom con return-type json + campo "alt",
        # así que el label ya viene armado desde acá.
        case "$(current)" in
            en)    echo "EN" ;;
            latam) echo "ES" ;;
            zh)    echo "中" ;;
        esac
        ;;
    *)          echo "uso: KeyboardLayout.sh cycle|en|latam|zh|status|label" >&2; exit 1 ;;
esac
