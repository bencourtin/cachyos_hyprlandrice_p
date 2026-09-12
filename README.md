# cachyos-hyprland-rice

A modular **CachyOS + Hyprland** rice with **Material You** colors generated from
the wallpaper by [matugen](https://github.com/InioX/matugen). No Noctalia — every
component is a plain config you can read and swap.

The bar, the wallpaper picker and four pop-up "islands" (weather, media, calendar,
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
| Night light | hyprsunset — auto solar schedule (`DarkLight.sh`, `SUPER+SHIFT+N`) |
| Islands | Quickshell — weather, media players, calendar, keybind cheatsheet, wallpaper dock |

## Install

Deployed with [GNU Stow](https://www.gnu.org/software/stow/): the repo has a
single stow package, `rice/`, whose internal layout (`rice/.config/hypr`,
`rice/.local/share/applications/yazi.desktop`, …) mirrors `$HOME` exactly, so
`stow` symlinks each piece straight into place.

```sh
# 1. packages (CachyOS / Arch) — includes `stow` itself
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

`install.sh` seeds the matugen color files from their `*.default` sibling when
missing, moves any real (non-symlink) file/dir in the way to
`~/.rice-backup-<timestamp>`, then runs `stow -d "$REPO" -t "$HOME" rice`.
Whole directories that are 100% rice (`hypr`, `waybar`, `quickshell`, `fcitx5`, …)
become one directory symlink each; directories shared with non-rice config
(`gtk-3.0`, `fish`, `kitty`, …) get stow's normal per-file folding instead, so
unrelated files there are left untouched. After the first run, `git pull` +
`./install.sh` is enough to pick up changes — they're live immediately since
the linked files ARE the repo's. `./uninstall.sh` runs `stow -D` to remove them.

## How theming works

`matugen` reads the wallpaper and renders every `~/.config/matugen/templates/*`
to its target (see `rice/.config/matugen/config.toml`). Generated color files are
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
`rice/.config/hypr/config/binds.lua`). A few:

| Key | Action |
| --- | --- |
| `SUPER+Space` | rofi launcher |
| `SUPER+E` | file manager — yazi in a floating kitty |
| `SUPER+SHIFT+W` | wallpaper dock (Quickshell) · `SUPER+ALT+W` rofi fallback |
| `SUPER+ALT+C` | session menu (wlogout) |
| `SUPER+SHIFT+N` | night light toggle — auto solar schedule ⇄ off |
| `SUPER+SHIFT+C` | calendar island (month grid + today's weather) · ‹ › or ←/→ to change month |
| `SUPER+K` | keybind cheatsheet |
| `SUPER+SHIFT+1..0` | go to workspace N (created on demand; 5 persistent) |
| `SUPER+SHIFT+CONTROL+N` | move window to workspace N |
| click clock | weather island · right-click: refresh |
| click media pill | media island — album art, seek bar, ⏮⏯⏭, per-player switch |

## Repo layout

```
rice/                    the single stow package — this is what gets symlinked
  .config/               mirrors ~/.config
    hypr/                Lua config, scripts/, UserScripts/, hyprlock, hypridle
    waybar/              configs/, style/, Modules*
    quickshell/          clima · mediactl · calendario · keyhints · mixerctl · netmon · hyprquickpaper
    matugen/             config.toml + templates/
    fcitx5/              EN / ES latam / 中文 pinyin switching (ALT+SHIFT+Space)
    fastfetch/           terminal greeting
    yazi/                yazi.toml, keymap.toml, theme.toml (matugen)
    rofi swaync wlogout cava uwsm
    gtk-3.0 gtk-4.0 fish kitty alacritty btop   (selected files, stow folds per-file)
    mimeapps.list
    *.default            seed copies of matugen-generated color files
  .local/share/applications/yazi.desktop
install.sh  uninstall.sh  packages.txt
docs/architecture.md   how each piece is wired
```

## Credits

- Bar layout & scripts adapted from **JaKooLit** / `binnewbs/arch-hyprland`.
- Weather backend (Open-Meteo + IP geolocation) and the night-light solar
  schedule (`DarkLight.sh`) ported from
  **[serpantinum](https://github.com/ilyamiro/serpantinum)** (AGPL-3.0): the
  approach is reused, the code is reimplemented. Moon phase is computed locally
  in awk. The calendar island is a fresh, minimal take on serpantinum's
  `CalendarPopup`.
- Wallpaper dock after **iamsurjog/hyprquickpaper**.

## Caveats

- **Desktop-specific:** monitor hardcoded to `DP-1` in
  `rice/.config/hypr/config/monitors.lua`; `battery` waybar module is inert.
- The weather island's second city is set in the header of
  `rice/.config/hypr/UserScripts/ClimaClock.sh` (`CITY_FIXED`).
- Night light needs `hyprsunset`; without it `DarkLight.sh` is a no-op.
  It reuses the weather module's cached location
  (`~/.cache/waybar-clima/geo.json`) — pin `FIXED_LAT` / `FIXED_LON` in the
  script header to override. Day/night temps are `DAY_TEMP` / `NIGHT_TEMP`.
- If hyprlock rejects a correct password after a few tries, it's
  `pam_faillock` locking the account — see the troubleshooting note in
  [docs/architecture.md](docs/architecture.md).
- `quickshell` must be installed or `SUPER+SHIFT+W` and the islands do nothing.

## License

MIT — see [LICENSE](LICENSE).
