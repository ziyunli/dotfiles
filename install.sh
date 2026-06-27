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
# Obsolete repo-owned symlinks are removed when configs move or are retired.
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

OBSOLETE_SHARED_LINKS=(
    "AGENTS.md"
    ".config/ghostty/config"
    "Library/Application Support/com.mitchellh.ghostty/config.ghostty"
)

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

is_obsolete_shared_link() {
    local rel="$1" obsolete

    for obsolete in "${OBSOLETE_SHARED_LINKS[@]}"; do
        [[ "$rel" == "$obsolete" ]] && return 0
    done
    return 1
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

remove_obsolete_shared_link() {
    local rel="$1" dst="$HOME/$rel"

    if [[ -L "$dst" ]]; then
        local target
        target="$(readlink "$dst")"
        if [[ "$target" == "$DOTFILES_DIR/"* ]]; then
            if [[ -n "$DRY_RUN" ]]; then
                echo "Would remove obsolete symlink: $dst"
            else
                rm "$dst"
                log "Removed obsolete symlink: $dst"
            fi
        else
            warn "Obsolete path is a symlink outside this repo: $dst -> $target"
        fi
    elif [[ -e "$dst" ]]; then
        warn "Obsolete path exists and may shadow managed config: $dst"
    fi
}

remove_obsolete_shared_links() {
    local rel

    for rel in "${OBSOLETE_SHARED_LINKS[@]}"; do
        remove_obsolete_shared_link "$rel"
    done
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

# merge_path composes a single .dotfiles-merge entry from up to three layers --
# shared/<rel> (base), devices/<DEVICE>/<rel> (optional device overlay), and the
# existing local file at $HOME/<rel> (optional) -- with later layers winning
# (local > device > shared). With no device overlay this is exactly the original
# shared -> local merge, so paths merged only against shared (e.g.
# .claude/settings.json) are unaffected.
merge_path() {
    local rel="$1"
    local shared_src="$DOTFILES_DIR/shared/$rel"
    local device_src="$DOTFILES_DIR/devices/$DEVICE/$rel"

    if [[ ! -f "$shared_src" ]]; then
        warn "Merge source not found: $shared_src"
        return
    fi

    # No device overlay: identical to the original shared -> local merge.
    if [[ ! -f "$device_src" ]]; then
        merge_file "$shared_src" "$HOME/$rel"
        return
    fi

    if [[ -n "$DRY_RUN" ]]; then
        echo "Would merge: $shared_src + $device_src + $HOME/$rel -> $HOME/$rel"
        return
    fi

    # Compose shared + device into a temp base, then merge the existing local
    # file on top via merge_file (which also clears any stale symlink at $dst).
    local base_tmp="$HOME/$rel.base.tmp"
    mkdir -p "$(dirname "$base_tmp")"
    "$DOTFILES_DIR/merge-json.sh" "$shared_src" "$device_src" > "$base_tmp"
    merge_file "$base_tmp" "$HOME/$rel"
    rm -f "$base_tmp"
}

# link_directory links all regular files and symbolic links found under a source
# directory into the user's $HOME, preserving each entry's relative path.
# When check_skip is "true", paths listed in .dotfiles-skip are excluded.
# Paths listed in .dotfiles-merge are always deferred to the merge phase (from
# both the shared and the device pass), so a symlink never lands on a merge target.
link_directory() {
    local src_dir="$1" check_skip="${2:-false}"

    if [[ ! -d "$src_dir" ]]; then
        return
    fi

    while IFS= read -r -d '' src; do
        local rel="${src#$src_dir/}"
        [[ "$(basename "$rel")" == ".dotfiles-skip" || "$(basename "$rel")" == ".dotfiles-merge" || "$(basename "$rel")" == ".gitkeep" ]] && continue
        if [[ "$check_skip" == "true" ]] && is_obsolete_shared_link "$rel"; then
            log "Skipped obsolete shared link: $rel"
            continue
        fi
        if [[ "$check_skip" == "true" ]] && is_skipped "$rel"; then
            log "Skipped: $rel (listed in .dotfiles-skip)"
            continue
        fi
        if is_merged "$rel"; then
            log "Deferred: $rel (will be merged)"
            continue
        fi
        link_file "$src" "$HOME/$rel"
    done < <(find "$src_dir" \( -type f -o -type l \) -print0)
}

# ~/.zshenv must be a real, machine-local file rather than a symlink into this
# repo. Tools like gohan auto-inject shell setup into ~/.zshenv on every run; if
# it were a repo symlink, that churn (and machine-specific absolute paths) would
# be written straight back into tracked files and leak to every other device.
# Instead the local ~/.zshenv just sources the shared env, and tool-managed
# blocks accumulate locally where they belong.
SHARED_ENV_SOURCE_LINE='source "$HOME/.zshenv.shared"'

seed_local_zshenv() {
    local dst="$HOME/.zshenv"

    # Retire the obsolete repo-owned symlink left by the previous layout.
    if [[ -L "$dst" ]]; then
        local target
        target="$(readlink "$dst")"
        if [[ "$target" == "$DOTFILES_DIR/"* ]]; then
            if [[ -n "$DRY_RUN" ]]; then
                echo "Would replace obsolete ~/.zshenv symlink with a local seed sourcing ~/.zshenv.shared"
                return
            fi
            rm "$dst"
        else
            warn "~/.zshenv is a symlink outside this repo; leaving it untouched: $dst -> $target"
            return
        fi
    fi

    if [[ -n "$DRY_RUN" ]]; then
        if [[ -e "$dst" ]]; then
            if grep -Fq "$SHARED_ENV_SOURCE_LINE" "$dst" 2>/dev/null; then
                echo "Would leave ~/.zshenv as-is (already sources ~/.zshenv.shared)"
            else
                echo "Would add shared-env source line to existing ~/.zshenv"
            fi
        else
            echo "Would seed local ~/.zshenv sourcing ~/.zshenv.shared"
        fi
        return
    fi

    if [[ ! -e "$dst" ]]; then
        printf '%s\n' \
            '# Machine-local zsh environment (not tracked by dotfiles).' \
            '# Sources the repo-shared env; tools like gohan append their own' \
            '# blocks below without churning the dotfiles repo.' \
            "$SHARED_ENV_SOURCE_LINE" > "$dst"
        log "Seeded local ~/.zshenv (sources ~/.zshenv.shared)"
    elif ! grep -Fq "$SHARED_ENV_SOURCE_LINE" "$dst"; then
        # Preserve existing local content (e.g. a gohan block); prepend the source.
        local tmp="$dst.dotfiles.tmp"
        {
            printf '%s\n' "$SHARED_ENV_SOURCE_LINE"
            cat "$dst"
        } > "$tmp"
        mv "$tmp" "$dst"
        log "Added shared-env source line to existing local ~/.zshenv"
    fi
}

# ~/.pi/agent/AGENTS.md must be a real, machine-local file rather than a symlink
# into this repo. @instacart/pi-config's syncAgents() does a full overwrite of
# this exact path on every run; if it were a repo symlink, that write would
# follow the chain into shared/AGENTS.md and clobber the personal prompt for all
# tools. Personal content reaches Pi instead via ~/.pi/agent/APPEND_SYSTEM.md
# (linked from shared/), which pi-config never touches.
seed_local_pi_agents() {
    local dst="$HOME/.pi/agent/AGENTS.md"

    # Retire a repo-owned symlink (current or dangling) from the old layout.
    if [[ -L "$dst" ]]; then
        local target
        target="$(readlink "$dst")"
        if [[ "$target" == "$DOTFILES_DIR/"* ]]; then
            if [[ -n "$DRY_RUN" ]]; then
                echo "Would replace obsolete ~/.pi/agent/AGENTS.md symlink with a local file"
                return
            fi
            rm "$dst"
        else
            warn "~/.pi/agent/AGENTS.md is a symlink outside this repo; leaving it untouched: $dst -> $target"
            return
        fi
    fi

    if [[ -n "$DRY_RUN" ]]; then
        if [[ -e "$dst" ]]; then
            echo "Would leave ~/.pi/agent/AGENTS.md as-is (real local file)"
        else
            echo "Would seed local ~/.pi/agent/AGENTS.md (machine-local; pi-config overwrites it here)"
        fi
        return
    fi

    # Only create a seed when nothing is there. A real file (e.g. pi-config's
    # boilerplate) is left untouched — it is local and safe to overwrite.
    if [[ ! -e "$dst" ]]; then
        mkdir -p "$(dirname "$dst")"
        printf '%s\n' \
            '# Machine-local Pi agent instructions (not tracked by dotfiles).' \
            '# pi-config overwrites this file on work devices; personal instructions' \
            '# are supplied separately via ~/.pi/agent/APPEND_SYSTEM.md.' > "$dst"
        log "Seeded local ~/.pi/agent/AGENTS.md"
    fi
}

# Main
log "Installing dotfiles for device: $DEVICE"
log "Dotfiles directory: $DOTFILES_DIR"
load_skip_list
load_merge_list
remove_obsolete_shared_links

# Link shared files
if [[ -d "$DOTFILES_DIR/shared" ]]; then
    log "Linking shared configuration..."
    link_directory "$DOTFILES_DIR/shared" true
else
    warn "No shared directory found"
fi

# Ensure ~/.zshenv is a machine-local file sourcing the shared env (see above).
seed_local_zshenv

# Ensure ~/.pi/agent/AGENTS.md is a machine-local file (see above) so pi-config
# can never write through it into the repo.
seed_local_pi_agents

# Link device-specific files
log "Linking device-specific configuration for '$DEVICE'..."
link_directory "$DOTFILES_DIR/devices/$DEVICE"

# Merge files listed in .dotfiles-merge (shared -> device -> local; later wins)
if [[ -n "$MERGE_FILES" ]]; then
    log "Merging configuration files..."
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        merge_path "$rel"
    done <<< "$MERGE_FILES"
fi

# Remind about local config
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    log ""
    log "NOTE: Create ~/.gitconfig.local with your personal git settings."
    log "      See .gitconfig.local.example in the dotfiles repo for a template."
fi

log "Done!"
