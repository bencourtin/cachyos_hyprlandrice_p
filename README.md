# cachyos-hyprland-rice

A modular **CachyOS + Hyprland** rice with **Material You** colors generated from
the wallpaper by [matugen](https://github.com/InioX/matugen). No Noctalia — every
component is a plain config you can read and swap.

The bar, the wallpaper picker and three pop-up "islands" (weather, media,
keybind cheatsheet) are small [Quickshell](https://quickshell.outfoxxed.me/)
programs; the rest is waybar + the usual Hyprland ecosystem.

> Built for a single-monitor **desktop** (`DP-1`), UWSM session. See
> [Caveats](#caveats) before deploying elsewhere.

![screenshot](docs/screenshot.png)

## Stack

| Role | Tool |
| --- | --- |
| Compositor | Hyprland (CachyOS build, **Lua** config — `~/.config/hypr/config/*.lua`) |
| Session | UWSM (`uwsm app --`) |
| Bar | waybar (JaKooLit multi-switcher layout, ported) |
| Colors | matugen — Material You from the wallpaper |
| Wallpaper | `awww` (CachyOS' renamed `swww`) |
| Notifications | swaync |
| Launcher / menus | rofi |
| File manager | yazi (Finder-like columns + preview, in kitty) |
| Lock / idle | hyprlock + hypridle |
| Session menu | wlogout (`SUPER+ALT+C`) |
| OSD | swayosd |
| Islands | Quickshell — weather, media players, keybind cheatsheet, wallpaper dock |

## Install

```sh
# 1. packages (CachyOS / Arch)
paru -S --needed - < packages.txt

# 2. clone + link
git clone https://github.com/<you>/cachyos-hyprland-rice ~/cachyos-hyprland-rice
cd ~/cachyos-hyprland-rice
./install.sh            # --dry to preview; existing config is moved to ~/.rice-backup-<ts>

# 3. wallpapers + first palette
mkdir -p ~/Pictures/wallpapers      # drop images here
img="$(readlink ~/.config/hypr/current_wallpaper)"
matugen image "$img" -m dark --source-color-index 0
hyprctl reload && killall -SIGUSR2 waybar
```

`install.sh` **symlinks** `config/<component>` into `~/.config`, so after the
first run a `git pull` is enough to update — the changes are live immediately.
Directories shared with non-rice config (`gtk-3.0`, `fish`, `kitty`, …) are
linked file-by-file instead. `./uninstall.sh` removes the symlinks.

## How theming works

`matugen` reads the wallpaper and renders every `~/.config/matugen/templates/*`
to its target (see `config/matugen/config.toml`). Generated color files are
**gitignored**; `install.sh` seeds each from a committed `*.default` so the
session has valid colors before the first run.

- Hyprland: `colors.lua` keeps a CachyOS fallback palette and `pcall`s the
  matugen overlay `colors-matugen.lua`. matugen never writes `colors.lua`
  directly.
- Trigger: `~/.config/hypr/scripts/wallpaper.sh <img>` sets the wallpaper (awww),
  runs matugen and updates the `current_wallpaper` symlink.
- Also themed: waybar, rofi, swaync, wlogout, hyprlock, kitty, gtk3/4, btop,
  cava, the Quickshell islands — and, optionally, Spotify (spicetify) and
  Discord (Vencord). Details in [docs/architecture.md](docs/architecture.md).

## Keybinds

Press **`SUPER+K`** for the full searchable cheatsheet (it mirrors
`config/hypr/config/binds.lua`). A few:

| Key | Action |
| --- | --- |
| `SUPER+Space` | rofi launcher |
| `SUPER+E` | file manager — yazi in a floating kitty |
| `SUPER+SHIFT+W` | wallpaper dock (Quickshell) · `SUPER+ALT+W` rofi fallback |
| `SUPER+ALT+C` | session menu (wlogout) |
| `SUPER+K` | keybind cheatsheet |
| `SUPER+SHIFT+1..0` | go to workspace N (created on demand; 5 persistent) |
| `SUPER+SHIFT+CONTROL+N` | move window to workspace N |
| click clock | weather island · right-click: refresh |
| click media pill | media-players island |

## Repo layout

```
config/            mirrors ~/.config
  hypr/            Lua config, scripts/, UserScripts/, hyprlock, hypridle
  waybar/          configs/, style/, Modules*
  quickshell/      clima · mediactl · keyhints · hyprquickpaper
  matugen/         config.toml + templates/
  yazi/            yazi.toml, keymap.toml, theme.toml (matugen)
  rofi swaync wlogout cava uwsm
  gtk-3.0 gtk-4.0 fish kitty alacritty btop   (selected files)
  *.default        seed copies of matugen-generated color files
local/share/applications/yazi.desktop
install.sh  uninstall.sh  packages.txt
docs/architecture.md   how each piece is wired
```

## Credits

- Bar layout & scripts adapted from **JaKooLit** / `binnewbs/arch-hyprland`.
- Weather backend (Open-Meteo + IP geolocation) ported from
  **[serpantinum](https://github.com/ilyamiro/serpantinum)**; moon phase is
  computed locally in awk.
- Wallpaper dock after **iamsurjog/hyprquickpaper**.

## Caveats

- **Desktop-specific:** monitor hardcoded to `DP-1` in
  `config/hypr/config/monitors.lua`; `battery` waybar module is inert.
- The weather island's second city is set in the header of
  `config/hypr/UserScripts/ClimaClock.sh` (`CITY_FIXED`).
- If hyprlock rejects a correct password after a few tries, it's
  `pam_faillock` locking the account — see the troubleshooting note in
  [docs/architecture.md](docs/architecture.md).
- `quickshell` must be installed or `SUPER+SHIFT+W` and the islands do nothing.

## License

MIT — see [LICENSE](LICENSE).
