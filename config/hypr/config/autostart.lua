-- Auto-start — stack modular sin Noctalia
-- Backup del original (con noctalia): ~/rice-backup-2026-09-08/config-plain/hypr/
-- Para volver a Noctalia: restaurar ese autostart.lua y binds.lua.

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("xhost +SI:localuser:root")

    -- Agente polkit
    hl.exec_cmd("uwsm app -- /usr/lib/polkit-kde-authentication-agent-1")

    -- Wallpaper: daemon awww (fork de swww en CachyOS) + restaurar fondo/colores
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("$HOME/.config/hypr/scripts/wallpaper.sh --restore")

    -- Barra
    hl.exec_cmd("uwsm app -- waybar")

    -- Notificaciones + centro de control
    hl.exec_cmd("uwsm app -- swaync")

    -- OSD de volumen / brillo
    hl.exec_cmd("swayosd-server")

    -- Red / bluetooth: apagados los applets de bandeja (2026-09-12), se
    -- reemplazaron por los módulos nativos de waybar (group/connections) en
    -- modules-right, junto al audio. Revertir: descomentar estas 2 líneas y
    -- sacar "group/connections" de modules-right en el config activo.
    -- hl.exec_cmd("uwsm app -- nm-applet --indicator")
    -- hl.exec_cmd("uwsm app -- blueman-applet")

    -- Historial de portapapeles
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Daemon de inactividad
    hl.exec_cmd("uwsm app -- hypridle")

    -- IME (fcitx5): teclado ES latam / EN / chino pinyin, ver KeyboardLayout.sh (ALT+SHIFT+Space)
    hl.exec_cmd("uwsm app -- fcitx5 -d --replace")

    -- Filtro de luz azul con horario solar automático (wl-gammarelay-rs).
    -- Toggle manual: SUPER+SHIFT+N. Ubicación reutilizada del módulo de clima.
    hl.exec_cmd("$HOME/.config/hypr/scripts/DarkLight.sh auto")

    -- Shader de pantalla: perfil por defecto al iniciar (vibrant = realce sutil).
    -- Ciclar: SUPER+SHIFT+] / [ ; quitar: SUPER+SHIFT+\ (ver ShaderCycle.sh).
    hl.exec_cmd("$HOME/.config/hypr/scripts/ShaderCycle.sh vibrant")

    -- Apps de uso diario (arrancan a la bandeja / minimizadas donde se puede)
    hl.exec_cmd("uwsm app -- steam -silent")            -- a la bandeja, sin ventana
    hl.exec_cmd("uwsm app -- discord --start-minimized") -- minimizado a la bandeja
    hl.exec_cmd("uwsm app -- spotify")                   -- sin flag de minimizar en Linux
end)
