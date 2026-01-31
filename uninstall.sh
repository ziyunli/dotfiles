#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE="${1:-$(hostname -s)}"
DRY_RUN="${DRY_RUN:-}"

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
