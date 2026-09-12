local mainMod = "SUPER"
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))

-- Change focus
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab",           hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + Tab",   hl.dsp.exec_cmd("rofi -show window"))

-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + SHIFT + Up",                   hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Right",                hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + Left",                 hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Down",                 hl.dsp.window.move({ direction = "d" }))
-- SUPER + SHIFT + 1/2/3 = mover ventana entre monitores (deshabilitado: setup de 1 monitor;
-- esas teclas ahora mueven la ventana activa a ese escritorio, ver el loop de abajo).
-- hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ monitor = MONITOR1 }))
-- hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ monitor = MONITOR2 }))
-- hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ monitor = MONITOR3 }))
hl.bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.window.move({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))
-- Mover ventana activa a un escritorio: SUPER + SHIFT + número (1..10; el 0 = escritorio 10).
-- Crea el escritorio si no existe.
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { repeating = true})
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))            -- toggle barra
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd("swaync-client -t -sw"))             -- centro de control
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd("rofi -show drun"))                  -- launcher
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd("rofi -show emoji"))                 -- emojis
hl.bind(mainMod .. " + K",          hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/KeyHints.sh")) -- cheatsheet de atajos (toggle)
hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd("loginctl lock-session"))            -- lock
hl.bind(mainMod .. " + ALT + C",    hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Wlogout.sh"))  -- menú de sesión (toggle)
hl.bind("ALT + SHIFT + Space",      hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/KeyboardLayout.sh cycle"))  -- teclado: EN -> ES latam -> 中文 (pinyin)

-- Waybar: switchers de layout / estilo / restart
hl.bind(mainMod .. " + CONTROL + B", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/WaybarStyles.sh"))
hl.bind(mainMod .. " + ALT + B",     hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/WaybarLayout.sh"))
hl.bind(mainMod .. " + SHIFT + R",   hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/wbrestart.sh"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })

-- Night light: alterna el filtro de luz azul con horario solar automático
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/DarkLight.sh toggle"))

-- Calendario (isla quickshell): grilla del mes + clima de hoy
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/CalendarIsland.sh"))

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + P",     hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind("Print",               hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grim - | satty -f -"))

-- Theming and Wallpaper
-- Selector visual (quickshell / hyprquickpaper): dock horizontal con miniaturas.
-- Aplica vía commands.sh -> wallpaper.sh (awww + matugen). Space/click = elegir, W/Esc = salir.
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("quickshell -n -c hyprquickpaper"))
-- Fallback rofi (grilla de iconos): mismo backend wallpaper.sh
hl.bind(mainMod .. " + ALT + W",   hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/wallpaper.sh"))

-- Shaders de pantalla (ShaderCycle.sh): ciclar perfiles ; SUPER+ALT+S = menú (ver/crear/editar)
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ShaderCycle.sh next"))
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ShaderCycle.sh prev"))
hl.bind(mainMod .. " + SHIFT + backslash",    hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ShaderCycle.sh off"))
hl.bind(mainMod .. " + ALT + S",              hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ShaderMenu.sh"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd('cliphist list | rofi -dmenu -i -p "Clipboard" | cliphist decode | wl-copy'))

-- Notifications
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("swaync-client -d -sw")) -- toggle no molestar

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on monitors: deshabilitado (setup de 1 monitor; SUPER + número ahora
-- cambia de escritorio, ver abajo). Backup por si algún día hay 2+ monitores:
-- hl.bind(mainMod .. " + 1", hl.dsp.focus({ monitor = MONITOR1 }))
-- hl.bind(mainMod .. " + 2", hl.dsp.focus({ monitor = MONITOR2 }))
-- hl.bind(mainMod .. " + 3", hl.dsp.focus({ monitor = MONITOR3 }))

-- Cambiar de escritorio: SOLO con SUPER + número (1..9, 0 = escritorio 10).
-- Si el escritorio no existe todavía (6..10) Hyprland lo crea al vuelo y waybar
-- le pone el hanzi correspondiente. (Antes vivía en SUPER+SHIFT+número, que
-- ahora mueve la ventana activa; ver el loop en la sección de arriba.)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end

-- (Se sacaron los duplicados ALT+número = ir a escritorio absoluto y
-- CONTROL+número = ir a escritorio relativo del monitor: quedó todo unificado
-- en SUPER + número arriba.)
-- for i = 1, NUM_WPM do
--     local key = i % 10
--     hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.focus({ workspace = i }))
-- end
-- for i = 1, NUM_WPM do
--     local key = i % 10
--     hl.bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }))
-- end

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Right",       hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + Left",        hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())
