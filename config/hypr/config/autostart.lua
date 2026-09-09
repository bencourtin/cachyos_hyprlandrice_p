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

    -- Applets de red / bluetooth (tray)
    hl.exec_cmd("uwsm app -- nm-applet --indicator")
    hl.exec_cmd("uwsm app -- blueman-applet")

    -- Historial de portapapeles
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Daemon de inactividad
    hl.exec_cmd("uwsm app -- hypridle")
end)
