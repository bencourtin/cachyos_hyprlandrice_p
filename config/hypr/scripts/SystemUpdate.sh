#!/usr/bin/env bash
# SystemUpdate.sh status|apply
# Widget de actualizaciones pendientes de waybar (custom/updates, ModulesCustom).
# status: JSON para waybar (return-type json) — texto vacío = al día, así
# waybar colapsa el módulo solo. apply: abre una terminal y actualiza
# repos (pacman) + AUR (paru, si está).
set -u

count_pacman() { checkupdates 2>/dev/null | wc -l; }
count_aur() {
    if command -v paru >/dev/null 2>&1; then
        paru -Qua 2>/dev/null | wc -l
    else
        echo 0
    fi
}

case "${1:-status}" in
    status)
        p=$(count_pacman)
        a=$(count_aur)
        total=$((p + a))
        if [ "$total" -eq 0 ]; then
            echo '{"text":"", "tooltip":"Sistema al día", "class":"none"}'
        else
            echo "{\"text\":\"󰚰 $total\", \"tooltip\":\"$p de repos + $a de AUR pendientes\\nClick para actualizar\", \"class\":\"pending\"}"
        fi
        ;;
    apply)
        uwsm app -- kitty --title system-update -e bash -c '
            sudo pacman -Syu
            if command -v paru >/dev/null 2>&1; then paru -Sua; fi
            echo; echo "Listo. Enter para cerrar."; read -r
        '
        ;;
    *)
        echo "uso: SystemUpdate.sh status|apply" >&2
        exit 1
        ;;
esac
