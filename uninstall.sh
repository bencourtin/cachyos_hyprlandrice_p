#!/usr/bin/env bash
# uninstall.sh — remove the symlinks install.sh created.
# Only touches paths that are symlinks pointing back into this repo. Anything
# you had before is in ~/.rice-backup-* ; restore by hand if you want it back.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/config"
DST="${XDG_CONFIG_HOME:-$HOME/.config}"

PATHS=(
  hypr waybar quickshell matugen rofi swaync wlogout cava uwsm
  gtk-3.0/gtk.css gtk-3.0/settings.ini gtk-4.0/gtk.css
  fish/config.fish kitty/kitty.conf
  alacritty/alacritty.toml alacritty/themes/noctalia.toml
  btop/btop.conf
)

for rel in "${PATHS[@]}"; do
  tgt="$DST/$rel"
  if [ -L "$tgt" ] && [[ "$(readlink -f "$tgt")" == "$(readlink -f "$SRC")"* ]]; then
    rm "$tgt"
    echo "  - removed $rel"
  fi
done
echo "done. backups (if any) are in ~/.rice-backup-*"
