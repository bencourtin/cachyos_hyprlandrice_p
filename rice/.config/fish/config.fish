source /usr/share/cachyos-fish-config/cachyos-config.fish

# Greeting: fastfetch with a custom logo (config in ~/.config/fastfetch/config.jsonc).
# Drop an image at ~/.config/fastfetch/logo.png to use it; a ~/.config/fastfetch/logo.gif
# is used only if no logo.png exists (still shown as its first frame).
function fish_greeting
    if not test -f ~/.config/fastfetch/logo.png; and test -f ~/.config/fastfetch/logo.gif
        fastfetch --logo ~/.config/fastfetch/logo.gif --logo-type kitty
    else
        fastfetch
    end
end
