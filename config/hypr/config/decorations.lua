-- Look and feel configuration

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = {
                colors = { CACHYLGREEN, CACHYDGREEN },
                angle = 45,
            },
            inactive_border = CACHYGRAY,
        },
    },
    group = {
        col = {
            border_active = CACHYLBLUE,
            border_inactive = CACHYGRAY,
            border_locked_active = CACHYDBLUE,
            border_locked_inactive = CACHYGRAY,
        },
        groupbar = {
            col = {
                active = CACHYLGREEN,
                inactive = CACHYGRAY,
                locked_active = CACHYDBLUE,
                locked_inactive = CACHYGRAY,
            },
        },
    },
    decoration = {
        dim_special = 0.3,
        rounding = 10,
        active_opacity = 0.92,
        inactive_opacity = 0.80,
        fullscreen_opacity = 1,
        blur = {
            enabled = true,
            size = 6,
            passes = 4,
            ignore_opacity = true,   -- blur también detrás de píxeles opacos -> vidrio más marcado
            new_optimizations = true,
            xray = false,            -- true = difumina solo el wallpaper (ignora ventanas de atrás)
            noise = 0.012,
            contrast = 1.1,
            brightness = 1.0,
            vibrancy = 0.1696,       -- satura los colores que pasan por el blur (efecto "liquid glass")
            vibrancy_darkness = 0.0,
            special = true,
            popups = true,           -- difumina también popups/menús contextuales
        },
    },
})
