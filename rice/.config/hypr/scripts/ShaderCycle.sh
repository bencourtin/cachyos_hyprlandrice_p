#!/usr/bin/env bash
# ShaderCycle.sh — perfiles de shader de pantalla de Hyprland (decoration:screen_shader).
#
#   ShaderCycle.sh next        siguiente perfil   (bind SUPER + SHIFT + ])
#   ShaderCycle.sh prev        perfil anterior    (bind SUPER + SHIFT + [)
#   ShaderCycle.sh off         quita el shader    (bind SUPER + SHIFT + \)
#   ShaderCycle.sh <nombre>    aplica ese perfil directo
#   ShaderCycle.sh current     imprime el perfil activo ("off" si no hay)
#   ShaderCycle.sh list        lista los perfiles disponibles (orden del ciclo)
#   ShaderCycle.sh reload      re-aplica el perfil activo forzando relectura del .glsl
#   ShaderCycle.sh restore     re-aplica el último perfil, sin notificar (post_hook matugen)
#
# El ciclo (]/[) recorre solo los shaders; "off" queda fuera del ciclo y se
# alcanza únicamente con SUPER+SHIFT+\ . El orden es PREFERRED y luego cualquier
# .glsl extra en SHADER_DIR (alfabético), así los shaders nuevos entran solos.
#
# Este rice usa config Lua => el cambio en caliente va por
# `hyprctl eval hl.config{...}` (`hyprctl keyword` está deshabilitado con el
# parser Lua; por eso no sirve hyprshade). Además `hyprctl reload` (lo dispara
# matugen al cambiar wallpaper) borra el screen_shader => el post_hook de matugen
# llama a `ShaderCycle.sh restore`. Filtro de luz azul nocturno = aparte
# (DarkLight.sh / hyprsunset), se apila.
set -u

SHADER_DIR="$HOME/.config/hypr/shaders"
STATE_F="${XDG_CACHE_HOME:-$HOME/.cache}/rice-shadercycle/current"
PREFERRED=(vibrant cinema reading grayscale)
mkdir -p "$(dirname "$STATE_F")" "$SHADER_DIR"

# ---- orden del ciclo: PREFERRED existentes + resto de .glsl (alfabético) ----
build_order() {
    local all=() f name
    for f in "$SHADER_DIR"/*.glsl; do
        [ -e "$f" ] || continue
        name="$(basename "$f" .glsl)"
        case "$name" in .*) continue ;; esac
        all+=("$name")
    done
    ORDER=()
    local p a o skip
    for p in "${PREFERRED[@]}"; do
        for a in "${all[@]}"; do [ "$a" = "$p" ] && { ORDER+=("$p"); break; }; done
    done
    for a in $(printf '%s\n' "${all[@]}" | sort); do
        skip=0
        for o in "${ORDER[@]}"; do [ "$o" = "$a" ] && { skip=1; break; }; done
        [ "$skip" = 0 ] && ORDER+=("$a")
    done
}

set_shader() { # $1 = path del .glsl, o "" para quitar
    hyprctl eval "hl.config({ [\"decoration.screen_shader\"] = \"$1\" })" >/dev/null
}

path_of() { # $1 = nombre -> imprime el path del .glsl ("" para off / inexistente)
    [ "$1" = off ] && return 0
    [ -f "$SHADER_DIR/$1.glsl" ] && printf '%s\n' "$SHADER_DIR/$1.glsl"
}

live_current() { # estado real de Hyprland
    local p
    p="$(hyprctl getoption decoration:screen_shader 2>/dev/null | sed -n 's/^str: //p')"
    p="${p##*/}"; p="${p%.*}"
    case "$p" in ""|"[[EMPTY]]") echo off ;; *) echo "$p" ;; esac
}

saved_current() {
    local s; s="$(cat "$STATE_F" 2>/dev/null || true)"
    [ -n "$s" ] || s=off
    printf '%s\n' "$s"
}

notify() {
    command -v notify-send >/dev/null || return 0
    notify-send -a shader -t 1400 \
        -h "string:x-canonical-private-synchronous:shadercycle" \
        "Shader de pantalla" "$1"
}

apply() { # $1 = "off" o nombre de un .glsl ; $2 = "quiet" para no notificar
    local name="$1"
    if [ "$name" != off ] && [ ! -f "$SHADER_DIR/$name.glsl" ]; then
        notify-send -a shader "Shader '$name' no existe" "Mirá $SHADER_DIR/"
        exit 1
    fi
    set_shader "$(path_of "$name")"
    printf '%s\n' "$name" > "$STATE_F"
    [ "${2:-}" = quiet ] || notify "$name"
}

arg="${1:-next}"
case "$arg" in
    current)
        live_current
        ;;
    list)
        build_order
        printf '%s\n' "${ORDER[@]}"
        ;;
    reload)
        cur="$(live_current)"
        if [ "$cur" = off ]; then
            notify "off"
        else
            set_shader ""
            set_shader "$(path_of "$cur")"
            notify "$cur (recargado)"
        fi
        ;;
    restore)
        apply "$(saved_current)" quiet
        ;;
    next|prev)
        build_order
        cur="$(live_current)"
        n=${#ORDER[@]}
        [ "$n" -gt 0 ] || { notify "sin shaders en $SHADER_DIR"; exit 1; }
        found=-1
        for i in "${!ORDER[@]}"; do
            [ "${ORDER[$i]}" = "$cur" ] && { found=$i; break; }
        done
        if [ "$found" -lt 0 ]; then
            # veníamos de "off" o de un shader borrado: entrar por los extremos
            [ "$arg" = prev ] && target="${ORDER[$((n - 1))]}" || target="${ORDER[0]}"
        elif [ "$arg" = prev ]; then
            target="${ORDER[$(( (found - 1 + n) % n ))]}"
        else
            target="${ORDER[$(( (found + 1) % n ))]}"
        fi
        apply "$target"
        ;;
    *)
        apply "$arg"
        ;;
esac
