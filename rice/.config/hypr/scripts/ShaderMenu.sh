#!/usr/bin/env bash
# ShaderMenu.sh — menú rofi de shaders de pantalla: ver / aplicar / crear / editar.
# Bind: SUPER + ALT + S.  Backend: ShaderCycle.sh (decoration:screen_shader vía
# `hyprctl eval hl.config{...}`; ver notas en ese script).
IFS=$'\n\t'

SHADER_DIR="$HOME/.config/hypr/shaders"
CYCLE="$HOME/.config/hypr/scripts/ShaderCycle.sh"
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
mkdir -p "$SHADER_DIR"

SEP="───────────────────────────"
ACT_NEW="Crear shader nuevo…"
ACT_RELOAD="Recargar shader activo"
ACT_OFF="Quitar shader (off)"
ACT_FOLDER="Abrir carpeta de shaders"

rofi_menu() { rofi -i -dmenu -config "$ROFI_CONFIG" "$@"; }

editor_open() { # $1 = archivo
    if command -v uwsm >/dev/null 2>&1; then
        setsid uwsm app -- gnome-text-editor --new-window "$1" >/dev/null 2>&1 &
    elif command -v gnome-text-editor >/dev/null 2>&1; then
        setsid gnome-text-editor --new-window "$1" >/dev/null 2>&1 &
    else
        setsid xdg-open "$1" >/dev/null 2>&1 &
    fi
}

open_folder() {
    if command -v uwsm >/dev/null 2>&1; then
        setsid uwsm app -- xdg-open "$SHADER_DIR" >/dev/null 2>&1 &
    else
        setsid xdg-open "$SHADER_DIR" >/dev/null 2>&1 &
    fi
}

skeleton() { # $1 = nombre
cat <<EOF
// $1 — (describí acá el efecto)
// Shader de pantalla de Hyprland (decoration:screen_shader). Ajustá las
// constantes y guardá; recargalo con SUPER+ALT+S -> "$1" o con "Recargar
// shader activo". Con los valores por defecto no hace nada.
precision highp float;

varying vec2 v_texcoord;
uniform sampler2D tex;

const vec3  LUMA       = vec3(0.2126, 0.7152, 0.0722);
const float BRIGHTNESS = 1.00;                   // <1 oscurece, >1 aclara
const float CONTRAST   = 1.00;                   // contraste alrededor del gris medio
const float SATURATION = 1.00;                   // 0 = gris, 1 = normal, >1 más color
const float GAMMA      = 1.00;                   // >1 aclara los medios tonos
const vec3  TINT       = vec3(1.00, 1.00, 1.00); // multiplicador RGB (calidez / frío)

void main() {
    vec3 c = texture2D(tex, v_texcoord).rgb;

    c *= BRIGHTNESS;
    c  = (c - 0.5) * CONTRAST + 0.5;
    c  = mix(vec3(dot(c, LUMA)), c, SATURATION);
    c  = pow(clamp(c, 0.0, 1.0), vec3(1.0 / GAMMA));
    c *= TINT;

    gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
EOF
}

# ---- toggle: si ya hay un rofi abierto, cerrarlo y salir ----
if pgrep -x rofi >/dev/null; then pkill rofi; exit 0; fi

current="$("$CYCLE" current)"

build_menu() {
    local name mark
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        [ "$name" = "$current" ] && mark="●" || mark="○"
        printf '%s %s\n' "$mark" "$name"
    done < <("$CYCLE" list)
    [ "$current" = off ] && printf '● (ninguno)\n' || printf '○ (ninguno)\n'
    printf '%s\n%s\n%s\n%s\n%s\n' "$SEP" "$ACT_NEW" "$ACT_RELOAD" "$ACT_OFF" "$ACT_FOLDER"
}

choice="$(build_menu | rofi_menu -mesg "Shaders de pantalla — ● = activo" -p "Shader")"
[ -n "$choice" ] || exit 0

case "$choice" in
    "$SEP")        exit 0 ;;
    "$ACT_FOLDER") open_folder ;;
    "$ACT_OFF")    "$CYCLE" off ;;
    "$ACT_RELOAD") "$CYCLE" reload ;;
    "$ACT_NEW")
        name="$(: | rofi_menu -p "Nombre" -mesg "Se crea ~/.config/hypr/shaders/&lt;nombre&gt;.glsl (a-z 0-9 -)")"
        name="$(printf '%s' "$name" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')"
        [ -n "$name" ] || exit 0
        f="$SHADER_DIR/$name.glsl"
        [ -e "$f" ] || skeleton "$name" > "$f"
        editor_open "$f"
        "$CYCLE" "$name"
        ;;
    "● (ninguno)"|"○ (ninguno)")
        "$CYCLE" off ;;
    *)
        name="${choice#* }"   # saca el "● " / "○ "
        if [ "$name" = "$current" ]; then
            "$CYCLE" reload
        else
            "$CYCLE" "$name"
        fi
        ;;
esac
