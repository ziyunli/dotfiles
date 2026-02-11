#!/usr/bin/env bash
#
# uninstall.sh - Remove symlinks created by install.sh
#
# This script removes symlinks in $HOME that point to this dotfiles repo.
# Only symlinks pointing to this repo are removed; other files are untouched.
#
# After uninstalling, you may want to restore backed-up files from
# ~/.dotfiles-backup-*/ if they exist.
#
# Usage:
#   ./uninstall.sh <device-name>
#
# Arguments:
#   device-name   Name of device folder in devices/ (required)
#
# Environment:
#   DRY_RUN       Set to any value to preview changes without making them
#
# Examples:
#   ./uninstall.sh bento              # Uninstall for bento device
#   ./uninstall.sh Ziyuns-Mac-mini    # Uninstall for Mac mini
#   DRY_RUN=1 ./uninstall.sh bento    # Preview what would be removed
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-}"

if [[ $# -eq 0 ]]; then
    echo "Error: device name is required." >&2
    echo "" >&2
    echo "Available devices:" >&2
    devices=$(ls -1 "$DOTFILES_DIR/devices/" 2>/dev/null)
    if [[ -n "$devices" ]]; then
        echo "$devices" | sed 's/^/  /' >&2
    else
        echo "  (none)" >&2
    fi
    echo "" >&2
    echo "Usage: $0 <device-name>" >&2
    exit 1
fi

DEVICE="$1"

log() { echo "[dotfiles] $*"; }

unlink_if_points_here() {
    local dst="$1" expected_prefix="$2"

    if [[ -L "$dst" ]]; then
        local target
        target="$(readlink "$dst")"
        if [[ "$target" == "$expected_prefix"* ]]; then
            if [[ -n "$DRY_RUN" ]]; then
                echo "Would remove symlink: $dst"
            else
                rm "$dst"
                log "Removed: $dst"
            fi
        fi
    fi
}

unlink_directory() {
    local src_dir="$1"

    if [[ ! -d "$src_dir" ]]; then
        return
    fi

    while IFS= read -r -d '' src; do
        local rel="${src#$src_dir/}"
        unlink_if_points_here "$HOME/$rel" "$DOTFILES_DIR"
    done < <(find "$src_dir" -type f -print0)
}

# Main
log "Uninstalling dotfiles for device: $DEVICE"

# Unlink shared files
if [[ -d "$DOTFILES_DIR/shared" ]]; then
    log "Removing shared symlinks..."
    unlink_directory "$DOTFILES_DIR/shared"
fi

# Unlink device-specific files
if [[ -d "$DOTFILES_DIR/devices/$DEVICE" ]]; then
    log "Removing device-specific symlinks for '$DEVICE'..."
    unlink_directory "$DOTFILES_DIR/devices/$DEVICE"
fi

log "Done!"
log ""
log "NOTE: Backup files (if any) were left in ~/.dotfiles-backup-*"
log "      You may want to restore them manually."
