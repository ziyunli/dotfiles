#!/usr/bin/env bash
#
# install.sh - Create symlinks from dotfiles repo to $HOME
#
# This script links configuration files from the repo to your home directory:
#   - shared/*        -> $HOME/*     (configuration common to all machines)
#   - devices/<dev>/* -> $HOME/*     (machine-specific configuration)
#
# Both regular files and symlinks in the source directories are processed.
#
# Existing files are backed up to ~/.dotfiles-backup-<timestamp>/
# Existing symlinks pointing elsewhere are replaced.
# Symlinks already pointing to the correct target are skipped.
# A devices/<dev>/.dotfiles-skip file can list paths to exclude from shared/.
# A devices/<dev>/.dotfiles-merge file can list paths to deep-merge instead of symlink.
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
#   ./install.sh                    # Install for current hostname
#   ./install.sh bento              # Install for bento device
#   ./install.sh Ziyuns-Mac-mini    # Install for Mac mini
#   DRY_RUN=1 ./install.sh          # Preview what would be linked
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN="${DRY_RUN:-}"

print_available_devices() {
    local devices
    devices=$(ls -1 "$DOTFILES_DIR/devices/" 2>/dev/null) || true
    if [[ -n "$devices" ]]; then
        echo "$devices" | sed 's/^/  /' >&2
    else
        echo "  (none)" >&2
    fi
}

if [[ $# -gt 1 ]]; then
    echo "Error: expected at most one device name." >&2
    echo "" >&2
    echo "Available devices:" >&2
    print_available_devices
    echo "" >&2
    echo "Usage: $0 [device-name]" >&2
    exit 1
fi

DEVICE="${1:-$(hostname -s)}"

if [[ ! -d "$DOTFILES_DIR/devices/$DEVICE" ]]; then
    echo "Error: no device configuration found for '$DEVICE'" >&2
    echo "" >&2
    echo "Available devices:" >&2
    print_available_devices
    echo "" >&2
    echo "Usage: $0 [device-name]" >&2
    exit 1
fi

log() { echo "[dotfiles] $*"; }
warn() { echo "[dotfiles] WARNING: $*" >&2; }

# Load device skip list (paths that shared/ should not overwrite)
SKIP_FILES=""
load_skip_list() {
    local skip_file="$DOTFILES_DIR/devices/$DEVICE/.dotfiles-skip"
    [[ -f "$skip_file" ]] || return 0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        SKIP_FILES="$SKIP_FILES$line"$'\n'
    done < "$skip_file"
}
is_skipped() {
    [[ -n "$SKIP_FILES" ]] && echo "$SKIP_FILES" | grep -qxF "$1"
}

# Load device merge list (paths that should be deep-merged instead of symlinked)
MERGE_FILES=""
load_merge_list() {
    local merge_file="$DOTFILES_DIR/devices/$DEVICE/.dotfiles-merge"
    [[ -f "$merge_file" ]] || return 0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        MERGE_FILES="$MERGE_FILES$line"$'\n'
    done < "$merge_file"
}
is_merged() {
    [[ -n "$MERGE_FILES" ]] && echo "$MERGE_FILES" | grep -qxF "$1"
}

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

merge_file() {
    local src="$1" dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    if [[ -n "$DRY_RUN" ]]; then
        if [[ -f "$dst" ]] && [[ ! -L "$dst" ]]; then
            echo "Would merge: $src + $dst -> $dst"
        else
            echo "Would copy: $src -> $dst (no existing file to merge)"
        fi
        return
    fi

    mkdir -p "$dst_dir"

    # Remove symlink if it exists (e.g., leftover from previous install)
    if [[ -L "$dst" ]]; then
        rm "$dst"
    fi

    if [[ -f "$dst" ]]; then
        "$DOTFILES_DIR/merge-json.sh" "$src" "$dst" > "$dst.merged.tmp"
        mv "$dst.merged.tmp" "$dst"
        log "Merged: $src + $dst -> $dst"
    else
        cp "$src" "$dst"
        log "Copied: $src -> $dst (no existing file to merge)"
    fi
}

# link_directory links all regular files and symbolic links found under a source
# directory into the user's $HOME, preserving each entry's relative path.
# When check_skip is "true", paths listed in .dotfiles-skip are excluded.
link_directory() {
    local src_dir="$1" check_skip="${2:-false}"

    if [[ ! -d "$src_dir" ]]; then
        return
    fi

    while IFS= read -r -d '' src; do
        local rel="${src#$src_dir/}"
        [[ "$(basename "$rel")" == ".dotfiles-skip" || "$(basename "$rel")" == ".dotfiles-merge" || "$(basename "$rel")" == ".gitkeep" ]] && continue
        if [[ "$check_skip" == "true" ]] && is_skipped "$rel"; then
            log "Skipped: $rel (listed in .dotfiles-skip)"
            continue
        fi
        if [[ "$check_skip" == "true" ]] && is_merged "$rel"; then
            log "Deferred: $rel (will be merged)"
            continue
        fi
        link_file "$src" "$HOME/$rel"
    done < <(find "$src_dir" \( -type f -o -type l \) -print0)
}

# Main
log "Installing dotfiles for device: $DEVICE"
log "Dotfiles directory: $DOTFILES_DIR"
load_skip_list
load_merge_list

# Link shared files
if [[ -d "$DOTFILES_DIR/shared" ]]; then
    log "Linking shared configuration..."
    link_directory "$DOTFILES_DIR/shared" true
else
    warn "No shared directory found"
fi

# Link device-specific files
log "Linking device-specific configuration for '$DEVICE'..."
link_directory "$DOTFILES_DIR/devices/$DEVICE"

# Merge files listed in .dotfiles-merge
if [[ -n "$MERGE_FILES" ]]; then
    log "Merging configuration files..."
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        merge_src="$DOTFILES_DIR/shared/$rel"
        if [[ -f "$merge_src" ]]; then
            merge_file "$merge_src" "$HOME/$rel"
        else
            warn "Merge source not found: $merge_src"
        fi
    done <<< "$MERGE_FILES"
fi

# Remind about local config
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    log ""
    log "NOTE: Create ~/.gitconfig.local with your personal git settings."
    log "      See .gitconfig.local.example in the dotfiles repo for a template."
fi

log "Done!"
