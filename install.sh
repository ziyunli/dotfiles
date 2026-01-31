#!/usr/bin/env bash
#
# install.sh - Create symlinks from dotfiles repo to $HOME
#
# This script links configuration files from the repo to your home directory:
#   - shared/*        -> $HOME/*     (configuration common to all machines)
#   - devices/<dev>/* -> $HOME/*     (machine-specific configuration)
#
# Existing files are backed up to ~/.dotfiles-backup-<timestamp>/
# Existing symlinks pointing elsewhere are replaced.
# Symlinks already pointing to the correct target are skipped.
#
# Usage:
#   ./install.sh [device-name]
#
# Arguments:
#   device-name   Name of device folder in devices/ (default: hostname -s)
#
# Environment:
#   DRY_RUN       Set to any value to preview changes without making them
#
# Examples:
#   ./install.sh                    # Use hostname as device name
#   ./install.sh Ziyuns-Mac-mini    # Specify device explicitly
#   DRY_RUN=1 ./install.sh          # Preview what would be linked
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE="${1:-$(hostname -s)}"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN="${DRY_RUN:-}"

log() { echo "[dotfiles] $*"; }
warn() { echo "[dotfiles] WARNING: $*" >&2; }

link_file() {
    local src="$1" dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    if [[ -n "$DRY_RUN" ]]; then
        echo "Would link: $dst -> $src"
        return
    fi

    mkdir -p "$dst_dir"

    if [[ -L "$dst" ]]; then
        local current_target
        current_target="$(readlink "$dst")"
        if [[ "$current_target" == "$src" ]]; then
            return  # Already linked correctly
        fi
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/${dst#$HOME/}"
        mkdir -p "$(dirname "$backup_path")"
        mv "$dst" "$backup_path"
        log "Backed up: $dst -> $backup_path"
    fi

    ln -s "$src" "$dst"
    log "Linked: $dst -> $src"
}

link_directory() {
    local src_dir="$1" prefix="$2"

    if [[ ! -d "$src_dir" ]]; then
        return
    fi

    while IFS= read -r -d '' src; do
        local rel="${src#$src_dir/}"
        link_file "$src" "$HOME/$rel"
    done < <(find "$src_dir" -type f -print0)
}

# Main
log "Installing dotfiles for device: $DEVICE"
log "Dotfiles directory: $DOTFILES_DIR"

# Link shared files
if [[ -d "$DOTFILES_DIR/shared" ]]; then
    log "Linking shared configuration..."
    link_directory "$DOTFILES_DIR/shared" ""
else
    warn "No shared directory found"
fi

# Link device-specific files
if [[ -d "$DOTFILES_DIR/devices/$DEVICE" ]]; then
    log "Linking device-specific configuration for '$DEVICE'..."
    link_directory "$DOTFILES_DIR/devices/$DEVICE" ""
else
    warn "No device configuration found for '$DEVICE'"
    echo ""
    echo "Available devices:"
    ls -1 "$DOTFILES_DIR/devices/" 2>/dev/null || echo "  (none)"
    echo ""
    echo "Usage: $0 [device-name]"
    echo "   or: Set hostname to match a device folder"
fi

# Remind about local config
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    log ""
    log "NOTE: Create ~/.gitconfig.local with your personal git settings."
    log "      See .gitconfig.local.example in the dotfiles repo for a template."
fi

log "Done!"
