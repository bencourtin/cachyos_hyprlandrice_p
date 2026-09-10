# Architecture

How the pieces are wired. Paths are under `~/.config` unless noted.

## Session

- **CachyOS + Hyprland**, Hyprland configured in **Lua** (`hypr/config/*.lua`),
  not `.conf`. Entry point `hypr/hyprland.lua`.
- **UWSM** session: apps are launched with `uwsm app -- <cmd>` (see
  `hypr/config/autostart.lua`). Environment in `uwsm/env`.
- CachyOS quirk: `hyprctl dispatch workspace N` does **not** work from the Lua
  setup — use `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'`.

## Colors (matugen)

`matugen/config.toml` renders every `matugen/templates/*` to its target:

| Template | Output |
| --- | --- |
| `hypr-colors.lua` | `hypr/config/colors-matugen.lua` (`post_hook: hyprctl reload`) |
| `hyprlock-colors.conf` | `hypr/hyprlock-colors.conf` |
| `waybar-colors.css` | `waybar/colors.css`, `wlogout/colors.css`, `swaync/colors.css` |
| `rofi-colors.rasi` | `rofi/colors.rasi` |
| `clima/mediactl/keyhints-colors.json` | `quickshell/<island>/colors.json` |
| `kitty-colors.conf` | `kitty/matugen.conf` (`post_hook: kill -SIGUSR1 kitty`) |
| `gtk-colors.css` | `gtk-3.0/matugen.css`, `gtk-4.0/matugen.css` |
| `btop.theme` / `cava.conf` | `btop/themes/matugen.theme` / `cava/config` |
| `yazi-theme.toml` | `yazi/theme.toml` (no hook — yazi re-reads on launch) |
| `spicetify-colors.ini` | `spicetify/Themes/text/color.ini` (`post_hook: spicetify refresh`) |
| `discord-vencord.css` | `Vencord/themes/matugen.css` |

- `config.toml` needs a `[config]` header (even empty) and matugen must be
  called with `--source-color-index 0`, otherwise it prompts for `--prefer` in
  non-interactive use.
- `hypr/config/colors.lua` defines the CachyOS fallback palette (`CACHY*`), then
  `pcall`s `colors-matugen.lua` as an overlay. Never let matugen write
  `colors.lua` itself.
- Generated files are gitignored; `install.sh` seeds them from `*.default`.

Regenerate against the current wallpaper:

```sh
img="$(readlink ~/.config/hypr/current_wallpaper)"
matugen image "$img" -m dark --source-color-index 0
```

## Workspaces

- 5 persistent workspaces (`hypr/config/workspaces.lua` rules 1–5,
  `NUM_WPM = 5` in `variables.lua`).
- waybar module `hyprland/workspaces#kanji` (config `waybar/configs/bintang default`),
  `format-icons` = extended Chinese numerals 1–49, `persistent-workspaces {"*": 5}`.
- `binds.lua`: `SUPER+SHIFT+1..0` focus workspace N (loop `for i=1,10`, created on
  demand); `SUPER+SHIFT+CONTROL+N` move window to N. Workspaces 6+ are created
  on the fly. move-to-monitor binds are commented out (single monitor).

## waybar: clock + weather (`custom/clima`)

Replaces `clock` in `modules-left` of the `bintang default` config. Script
`hypr/UserScripts/ClimaClock.sh` (bash: curl + jq + awk).

- Bar text: ` h:MM AM/PM   <NF weather glyph> N°`.
- **Backend ported from serpantinum:** [Open-Meteo](https://open-meteo.com)
  (no API key, no rate limit) + IP geolocation cascade
  `ipapi.co → ip-api.com → ipwho.is`. A second city is geocoded via
  `geocoding-api.open-meteo.com` — set `CITY_FIXED` in the script header
  (`""` disables it).
- **Moon computed 100% locally in awk** (Schlyter low-precision ephemerides):
  phase index 0–7 + emoji, illumination %, altitude/azimuth, above/below
  horizon, waxing/waning.
- Cache in `~/.cache/waybar-clima/` (`geo*` TTL 24h, `wx_*` TTL 900s). Also
  writes a structured `state.json` consumed by the island.
- `on-click` → `hypr/scripts/ClimaIsland.sh` (toggle island);
  `on-click-right` → `ClimaClock.sh --refresh` (clears weather cache,
  `pkill -RTMIN+8 waybar`; module has `"signal": 8`).
- Day events = **empty hook** `get_events()` — no calendar wired up
  (gcalcli / khal / ics ideas are left as comments).
- CSS: `#custom-clima` in `waybar/style/islands.css`. The original `clock`
  module is kept in `Modules` to revert.
- If two bars appear, a `waybar.service` user unit is fighting the
  `uwsm app -- waybar` autostart: `systemctl --user stop waybar.service`.

## Quickshell islands

Small `PanelWindow` overlays, top-left, `margins.top: 44` to clear the bar.
Toggled by `hypr/scripts/*Island.sh` (pgrep/pkill on `quickshell.*-c[= ]<name>`,
launch if absent). Colors come from a matugen template → `colors.json`
(`FileView watchChanges`).

> QML `JsonAdapter` gotcha: properties can't start with `on` + uppercase (parsed
> as signal handlers) — hence `fg` / `fgDim`, not `onSurface`.

### `clima` — weather

`quickshell/clima/{shell.qml,colors.json}`. Reads
`~/.cache/waybar-clima/state.json`: clock + date, local weather (glyph + big
temp, hi/lo, humidity, wind, feels-like, sun), second city, moon, and an events
repeater. Auto-closes: mouse out 1.8s (only after entering — `everHovered`
flag), Esc, click, or 15s.

### `mediactl` — media players

`quickshell/mediactl/{shell.qml,colors.json}`. Uses the native
`Quickshell.Services.Mpris` service. Lists every player (Spotify, Firefox,
mpv…) with state glyph + app icon + `artist – title`. Click a row =
`togglePlaying()` for **that** player only. `Pause others` / `Pause all`
buttons when >1. Left border aligned to the player pill
(`margins.top: 44, left: 180`) — re-measure if the tray icon count changes.
Auto-closes: mouse out 2s, Esc, 20s.

### `keyhints` — keybind cheatsheet

`SUPER+K` → `hypr/scripts/KeyHints.sh`. `quickshell/keyhints/{shell.qml,colors.json}`.
Full-screen overlay + dimmed backdrop, 1000px centered window styled after the
rofi launcher (`rofi/config.rasi`). Left: wallpaper panel + a real search
`TextInput` + section filter buttons. Right: `Flickable` list of key caps +
descriptions with section headers.

> **The list is static — it mirrors `binds.lua`.** To add or change a binding,
> edit the `sections` array in `shell.qml` as well.

Needs `WlrKeyboardFocus.Exclusive` to type into the search box, which means
**`SUPER+K` no longer closes it** (Hyprland never sees the key) — close with
**Esc** or click outside.

## File manager (yazi)

A terminal file manager with Finder-style Miller columns (parent │ current │
preview) and Quick Look-ish previews (images/video/PDF/archives rendered in
kitty's graphics protocol).

- **`SUPER+E`** → `FILE_MANAGER` in `hypr/config/variables.lua` =
  `kitty --class yazi -e yazi`. `windowrules.lua` floats & centers the `yazi`
  class at ~62%×68% and gives it the same translucency as the other file
  managers.
- Config in `yazi/`: `yazi.toml` (`ratio = [1,3,4]`, dirs-first, hidden files
  off, `linemode = size`, openers → `micro` / `xdg-open` / `mpv`),
  `keymap.toml` (Finder muscle memory prepended: `←`/`Backspace` up, `→` enter,
  `Enter` open, `Space` select+down, `.` toggle hidden, `Ctrl+C` copy path).
- `theme.toml` is matugen-generated from `matugen/templates/yazi-theme.toml`;
  `theme.toml.default` (CachyOS teal/blue) seeds it pre-matugen and is
  gitignored like the other generated color files.
- `fish/conf.d/yazi.fish` defines `y` — the official wrapper that `cd`s the
  shell to wherever you left yazi.
- `local/share/applications/yazi.desktop` exists so yazi shows up in app
  menus, but Dolphin stays the `inode/directory` handler (a TUI is a poor GUI
  default). To switch: `xdg-mime default yazi.desktop inode/directory`.
- Preview deps: `ffmpeg`, `7zip`, `poppler`, `resvg`, `imagemagick`; nav helpers
  `fd`, `ripgrep`, `fzf`, `zoxide`.

## Wallpaper picker

Two front-ends, one backend `hypr/scripts/wallpaper.sh <path>` (awww + matugen +
`current_wallpaper` symlink). Wallpapers live in `~/Pictures/wallpapers/`.

- **`SUPER+SHIFT+W`** → `quickshell -n -c hyprquickpaper` — horizontal thumbnail
  dock. Config in `quickshell/hyprquickpaper/` (`config.json` →
  `wallpaper_path`, `cache.sh` builds x500 thumbs in
  `~/.cache/quickshell/thumbs/` with `magick`, `commands.sh` →
  `exec wallpaper.sh "$1"`). If it breaks, delete the thumbs cache.
- **`SUPER+ALT+W`** → rofi icon grid, `wallpaper.sh` with no args.
- `SUPER+W` stays the browser.

## Session menu (wlogout)

`SUPER+ALT+C` → `hypr/scripts/Wlogout.sh` (toggle,
`wlogout -b 5 -c 10 -r 10 -m 250`). `wlogout/layout` = one row of 5: lock
(`loginctl lock-session` → hypridle runs hyprlock), shutdown, reboot, suspend,
logout (`uwsm stop`). **Hibernate removed** — swap is zram-only with no resume
device, so `systemctl hibernate` would fail.

## hyprlock / faillock

If hyprlock rejects a correct password: it's `pam_faillock` (CachyOS default
`deny=3`, `unlock_time=600`) locking the account for 10 min after a few typos,
after which even the right password fails.

- Recover from a TTY: `faillock --user <you> --reset`.
- Soften it: `/etc/security/faillock.conf` → `deny=5`, `unlock_time=120`.
- Or give hyprlock its own PAM stack: copy `/etc/pam.d/system-auth` to
  `/etc/pam.d/hyprlock` **without the three `pam_faillock` lines**.

These are system files outside this repo — apply by hand.

## Spotify & Discord (optional)

Both follow the wallpaper through matugen templates.

- **spicetify:** template → `spicetify/Themes/text/color.ini` (sections
  `[Matugen]` + a static `[Monochrome]` fallback). `config-xpui.ini` →
  `color_scheme = Matugen`. `post_hook = spicetify refresh` hot-reloads
  `color.ini` into the running client with no restart — `spicetify apply` would
  re-inject and bounce Spotify on every wallpaper change. After a Spotify
  update, run `spicetify backup apply` once by hand.
- **Discord = Vencord:** official `discord` package, vanilla. Template →
  `Vencord/themes/matugen.css` (overrides `--background-*`, `--bg-base-*`,
  `--text-*`, `--brand-500`, scrollbars…). No post-hook (Vencord watches the
  themes folder). **Requires installing Vencord** (`vencord-installer-bin` →
  Install into Discord) and ticking `matugen.css` in Vencord → Themes. Until
  then the file is generated but unused.
