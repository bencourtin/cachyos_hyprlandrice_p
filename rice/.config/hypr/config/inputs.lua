-- Input configuration

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
        -- Layouts declarados (índice 0 = us/EN, 1 = latam/ES). El chino no es un
        -- layout xkb (no compone caracteres): lo maneja fcitx5 (pinyin) por encima
        -- del layout activo. Ciclar los 3 con ALT+SHIFT+Space (KeyboardLayout.sh).
        kb_layout = "us,latam",
    },
    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })
