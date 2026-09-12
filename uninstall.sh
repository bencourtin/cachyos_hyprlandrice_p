#!/usr/bin/env bash
# uninstall.sh — remove the symlinks install.sh created, via `stow -D`.
# Only removes paths stow itself owns. Anything that was backed up during
# install lives in ~/.rice-backup-* ; restore it by hand if you want it back.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v stow >/dev/null || { echo "stow not found — install it first: sudo pacman -S --needed stow" >&2; exit 1; }

stow -D -v -d "$REPO_DIR" -t "$HOME" rice
echo "done. backups (if any) are in ~/.rice-backup-*"
