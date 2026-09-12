-- config/colors.lua — colores del rice
-- Fallback (paleta CachyOS original) + overlay de matugen si está disponible.
-- matugen escribe colors-matugen.lua; si falta o está roto, se mantiene el fallback
-- y la sesión arranca igual.

-- === Fallback ===
CACHYLGREEN = "rgba(82dcccff)"
CACHYMGREEN = "rgba(00aa84ff)"
CACHYDGREEN = "rgba(007d6fff)"
CACHYLBLUE  = "rgba(01ccffff)"
CACHYMBLUE  = "rgba(182545ff)"
CACHYDBLUE  = "rgba(111826ff)"
CACHYWHITE  = "rgba(ffffffff)"
CACHYGREY   = "rgba(ddddddff)"
CACHYGRAY   = "rgba(798bb2ff)"

-- === Overlay matugen (Material You desde wallpaper) ===
pcall(dofile, "/home/bcourtin/.config/hypr/config/colors-matugen.lua")
