#!/usr/bin/env bash
# install.sh — deploy the rice by symlinking config/ into ~/.config
#
#   ./install.sh          symlink everything (existing files are backed up)
#   ./install.sh --dry    show what would happen, touch nothing
#
# Re-run any time after `git pull` — symlinks mean the pulled changes are live
# immediately. Nothing here needs root.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/config"
DST="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.rice-backup-$STAMP"
DRY=0
[ "${1:-}" = "--dry" ] && DRY=1

# Whole directories that are 100% part of the rice -> one symlink each.
DIR_LINKS=(hypr waybar quickshell matugen rofi swaync wlogout cava uwsm)

# Individual files inside directories shared with non-rice config -> file symlinks.
FILE_LINKS=(
  gtk-3.0/gtk.css
  gtk-3.0/settings.ini
  gtk-4.0/gtk.css
  fish/config.fish
  kitty/kitty.conf
  alacritty/alacritty.toml
  alacritty/themes/noctalia.toml
  btop/btop.conf
)

# matugen writes these; they are gitignored. Seed from *.default when absent so
# the session has valid colors before the first `wallpaper.sh` run.
DEFAULTS=(
  hypr/config/colors-matugen.lua
  hypr/hyprlock-colors.conf
  waybar/colors.css
  rofi/colors.rasi
  quickshell/clima/colors.json
  quickshell/mediactl/colors.json
  quickshell/keyhints/colors.json
  cava/config
  wlogout/colors.css
  swaync/colors.css
  gtk-3.0/matugen.css
  gtk-4.0/matugen.css
  kitty/matugen.conf
  btop/themes/matugen.theme
)

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" = 1 ]; then say "  [dry] $*"; else eval "$@"; fi; }

same_target() { [ -L "$1" ] && [ "$(readlink -f "$1")" = "$(readlink -f "$2")" ]; }

backup() { # $1 = absolute path to move aside, $2 = repo-relative name
  local tgt="$1" rel="$2"
  mkdir -p "$(dirname "$BACKUP/$rel")"
  run "mv \"$tgt\" \"$BACKUP/$rel\""
  say "  ~ backed up $rel -> $BACKUP/$rel"
}

link() { # $1 = repo-relative path (file or dir)
  local rel="$1"
  local src="$SRC/$rel"
  local tgt="$DST/$rel"
  [ -e "$src" ] || { say "  ! missing in repo: $rel (skipped)"; return 0; }
  if same_target "$tgt" "$src"; then say "  = $rel"; return 0; fi
  run "mkdir -p \"$(dirname "$tgt")\""
  if [ -e "$tgt" ] || [ -L "$tgt" ]; then backup "$tgt" "$rel"; fi
  run "ln -s \"$src\" \"$tgt\""
  say "  + $rel"
}

say "rice install  (repo: $REPO_DIR)"
[ "$DRY" = 1 ] && say "DRY RUN — nothing will be written"

say ""
say "seeding matugen color files from *.default:"
for rel in "${DEFAULTS[@]}"; do
  if [ ! -e "$SRC/$rel" ] && [ -e "$SRC/$rel.default" ]; then
    run "cp \"$SRC/$rel.default\" \"$SRC/$rel\""
    say "  * $rel"
  else
    say "  = $rel (present)"
  fi
done

say ""
say "linking directories into $DST:"
for d in "${DIR_LINKS[@]}"; do link "$d"; done

say ""
say "linking individual files:"
for f in "${FILE_LINKS[@]}"; do link "$f"; done

say ""
say "done."
[ -d "$BACKUP" ] && say "previous config saved in: $BACKUP"
cat <<'EOF'

next steps:
  1. put wallpapers in ~/Pictures/wallpapers/
  2. generate the palette from the current wallpaper:
       img="$(readlink ~/.config/hypr/current_wallpaper)"
       matugen image "$img" -m dark --source-color-index 0
     (or just pick one: SUPER+SHIFT+W)
  3. reload: hyprctl reload ; killall -SIGUSR2 waybar
  4. see README.md for packages (packages.txt) and keybinds (SUPER+K)
EOF
