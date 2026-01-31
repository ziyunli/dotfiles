#!/usr/bin/env bash
set -euo pipefail

# Migration script: bare repo -> regular repo with symlinks
# Run this on each existing system to migrate from the old structure

DEVICE="${1:-}"
OLD_BARE_REPO="${OLD_BARE_REPO:-$HOME/.dotfiles}"
NEW_REPO_URL="${NEW_REPO_URL:-git@github.com:ziyunli/dotfiles.git}"
NEW_REPO_DIR="$HOME/.dotfiles-new"

log() { echo "[migrate] $*"; }
warn() { echo "[migrate] WARNING: $*" >&2; }
die() { echo "[migrate] ERROR: $*" >&2; exit 1; }

if [[ -z "$DEVICE" ]]; then
    echo "Usage: $0 <device-name>"
    echo ""
    echo "This script migrates from the bare repo pattern to the new structure."
    echo ""
    echo "Steps:"
    echo "  1. Clones new repo structure to ~/.dotfiles-new"
    echo "  2. Runs install.sh to create symlinks"
    echo "  3. Backs up and removes old bare repo"
    echo ""
    echo "Available devices after migration:"
    echo "  - Ziyuns-Mac-mini"
    echo "  - bento"
    echo "  - m1"
    echo "  - popos"
    echo ""
    echo "Or specify your hostname: $(hostname -s)"
    exit 1
fi

log "=== Migrating to new dotfiles structure ==="
log "Device: $DEVICE"
log "Old bare repo: $OLD_BARE_REPO"

# Check if old bare repo exists
if [[ -d "$OLD_BARE_REPO" ]]; then
    log "Found existing bare repo at $OLD_BARE_REPO"
else
    warn "No bare repo found at $OLD_BARE_REPO (continuing anyway)"
fi

# Clone new structure
if [[ -d "$NEW_REPO_DIR" ]]; then
    die "Directory already exists: $NEW_REPO_DIR"
fi

log "Cloning new repository structure..."
git clone "$NEW_REPO_URL" "$NEW_REPO_DIR"

# Run install
log "Installing dotfiles..."
"$NEW_REPO_DIR/install.sh" "$DEVICE"

# Handle old bare repo
if [[ -d "$OLD_BARE_REPO" ]]; then
    BACKUP_NAME="${OLD_BARE_REPO}.bare-backup-$(date +%Y%m%d)"
    log "Moving old bare repo to: $BACKUP_NAME"
    mv "$OLD_BARE_REPO" "$BACKUP_NAME"
fi

# Move new repo to final location
log "Moving new repo to $HOME/.dotfiles"
mv "$NEW_REPO_DIR" "$HOME/.dotfiles"

log ""
log "=== Migration complete ==="
log ""
log "Next steps:"
log "  1. Remove the old 'dotfiles' alias from your shell rc"
log "  2. Create ~/.gitconfig.local with your personal settings"
log "  3. Verify symlinks: ls -la ~/.tmux.conf ~/.gitconfig"
log "  4. Once verified, remove backup: rm -rf $BACKUP_NAME"
