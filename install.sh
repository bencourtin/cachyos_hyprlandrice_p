#!/usr/bin/env bash
# install.sh — deploy the rice with GNU Stow.
#
#   ./install.sh          seed matugen defaults, clear conflicts, `stow` the rice
#   ./install.sh --dry    show what would happen, touch nothing
#
# Re-run any time after `git pull` — stow just re-links, changes are live
# immediately (the linked files ARE the repo's). Nothing here needs root,
# except installing `stow` itself the first time: sudo pacman -S --needed stow
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$REPO_DIR/rice"
SRC="$PKG_DIR/.config"
DST="$HOME/.config"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.rice-backup-$STAMP"
DRY=0
[ "${1:-}" = "--dry" ] && DRY=1

command -v stow >/dev/null || { echo "stow not found — install it first: sudo pacman -S --needed stow" >&2; exit 1; }

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" = 1 ]; then say "  [dry] $*"; else eval "$@"; fi; }

# Whole directories that are 100% part of the rice -> stow folds each into a
# single directory symlink once nothing real is left in its way.
DIR_LINKS=(hypr waybar quickshell matugen rofi swaync wlogout cava uwsm yazi fcitx5 fastfetch)

# Individual files/dirs inside locations shared with non-rice config, plus
# top-level files -> stow symlinks just these, leaving siblings untouched.
FILE_LINKS=(
  gtk-3.0/gtk.css
  gtk-3.0/settings.ini
  gtk-4.0/gtk.css
  fish/config.fish
  fish/conf.d/yazi.fish
  kitty/kitty.conf
  alacritty/alacritty.toml
  alacritty/themes/noctalia.toml
  btop/btop.conf
  mimeapps.list
)

# matugen writes these; they are gitignored. Seed from *.default when absent so
# the session has valid colors before the first `wallpaper.sh` run.
DEFAULTS=(
  hypr/config/colors-matugen.lua
  hypr/hyprlock-colors.conf
  waybar/colors.css
  rofi/colors.rasi
  quickshell/clima/colors.json
  quickshell/calendario/colors.json
  quickshell/mediactl/colors.json
  quickshell/mixerctl/colors.json
  quickshell/netmon/colors.json
  quickshell/keyhints/colors.json
  cava/config
  wlogout/colors.css
  swaync/colors.css
  yazi/theme.toml
  gtk-3.0/matugen.css
  gtk-4.0/matugen.css
  kitty/matugen.conf
  btop/themes/matugen.theme
)

# True both when $1 is itself a symlink into the repo (whole-dir link) and
# when $1 is a plain file only reached AS the repo's own file because some
# ancestor directory is the symlink (per-file link inside a DIR_LINKS dir).
same_target() { [ -e "$1" ] && [ "$(readlink -f "$1")" = "$(readlink -f "$2")" ]; }

# Move a real (non-symlink) file/dir aside so stow has a clear spot to link into.
clear_conflict() { # $1 = repo-relative path under .config
  local rel="$1"
  local tgt="$DST/$rel"
  local src="$SRC/$rel"
  [ -e "$src" ] || { say "  ! missing in repo: $rel (skipped)"; return 0; }
  if same_target "$tgt" "$src"; then say "  = $rel (already linked)"; return 0; fi
  if [ -e "$tgt" ] || [ -L "$tgt" ]; then
    mkdir -p "$(dirname "$BACKUP/$rel")"
    run "mv \"$tgt\" \"$BACKUP/$rel\""
    say "  ~ backed up $rel -> $BACKUP/$rel"
  fi
}

say "rice install (repo: $REPO_DIR)"
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
say "clearing conflicts in \$HOME/.config so stow can link cleanly:"
for d in "${DIR_LINKS[@]}"; do clear_conflict "$d"; done
for f in "${FILE_LINKS[@]}"; do clear_conflict "$f"; done
# DEFAULTS entries living inside a DIR_LINKS dir are already gone (whole dir
# moved above); the ones inside a shared FILE_LINKS-only dir still need it.
for rel in "${DEFAULTS[@]}"; do clear_conflict "$rel"; done
if [ -e "$HOME/.local/share/applications/yazi.desktop" ] && [ ! -L "$HOME/.local/share/applications/yazi.desktop" ]; then
  mkdir -p "$BACKUP/local/share/applications"
  run "mv \"$HOME/.local/share/applications/yazi.desktop\" \"$BACKUP/local/share/applications/yazi.desktop\""
  say "  ~ backed up local/share/applications/yazi.desktop -> $BACKUP/..."
fi

say ""
say "stowing rice/ into \$HOME:"
if [ "$DRY" = 1 ]; then
  stow -n -v -d "$REPO_DIR" -t "$HOME" rice
else
  stow -v -d "$REPO_DIR" -t "$HOME" rice
fi

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
