#!/usr/bin/env bash
#
# migrate-zshrc.sh - Migrate a device from the legacy ~/.zshrc symlink to the
# ~/.zshrc.local shim layout (see AGENTS.md "Shell config pattern").
#
# Legacy layout:  ~/.zshrc  ->  devices/<dev>/.zshrc   (symlink into the repo)
#   Tools that append to ~/.zshrc (Instacart setup, conda, OrbStack, ...) write
#   straight back through the symlink into the tracked file, leaking
#   machine-local content and absolute paths into git.
#
# New layout:     ~/.zshrc          machine-local shim (NOT tracked)
#                                    -> sources ~/.zshrc.local
#                 ~/.zshrc.local  -> devices/<dev>/.zshrc.local   (symlink)
#   ~/.zshrc is now a real local file, so tool appends stay on the machine
#   while the device config stays version-controlled in .zshrc.local. This is
#   the same shim install.sh's seed_local_zshrc seeds on a fresh install.
#
# This renames the tracked file, swaps the live symlinks, and seeds the shim.
# It stages the rename but does NOT commit; review and commit yourself.
#
# Run this ON the device being migrated. The script is idempotent and
# self-healing: if a run is interrupted, run it again to finish.
#
# Usage:
#   ./migrate-zshrc.sh [device-name]
#
# Arguments:
#   device-name   Name of device folder in devices/ (default: hostname -s)
#
# Environment:
#   DRY_RUN       Set to any value to preview changes without making them
#
# Examples:
#   ./migrate-zshrc.sh                 # Migrate current hostname
#   ./migrate-zshrc.sh Ziyuns-MBP      # Migrate a specific device
#   DRY_RUN=1 ./migrate-zshrc.sh       # Preview what would change
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-}"

log()  { echo "[migrate-zshrc] $*"; }
warn() { echo "[migrate-zshrc] WARNING: $*" >&2; }
die()  { echo "[migrate-zshrc] ERROR: $*" >&2; exit 1; }

# Same shim body install.sh's seed_local_zshrc writes, so a later install run
# recognizes ~/.zshrc as already migrated and leaves it untouched.
SHIM_SOURCE_LINE='source "$HOME/.zshrc.local"'

print_available_devices() {
    local devices
    devices=$(ls -1 "$DOTFILES_DIR/devices/" 2>/dev/null) || true
    if [[ -n "$devices" ]]; then
        echo "$devices" | sed 's/^/  /' >&2
    else
        echo "  (none)" >&2
    fi
}

DEVICE="${1:-$(hostname -s)}"

git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1 \
    || die "$DOTFILES_DIR is not a git repository."

if [[ ! -d "$DOTFILES_DIR/devices/$DEVICE" ]]; then
    echo "Error: no device configuration found for '$DEVICE'" >&2
    echo "" >&2
    echo "Available devices:" >&2
    print_available_devices
    echo "" >&2
    echo "Usage: $0 [device-name]" >&2
    exit 1
fi

SRC="$DOTFILES_DIR/devices/$DEVICE/.zshrc"
LOCAL_SRC="$DOTFILES_DIR/devices/$DEVICE/.zshrc.local"
DST="$HOME/.zshrc"
LOCAL_DST="$HOME/.zshrc.local"

# --- Detect current state -------------------------------------------------
#
# The migration has a repo side (rename the tracked file) and a HOME side
# (swap symlinks, seed the shim). A run can stop in between, and a second
# machine can git-pull the completed rename without ever touching its own
# HOME. So state is detected from BOTH sides and the work below converges to
# the finished layout no matter where a prior run left off.

repo_renamed=false
[[ -f "$LOCAL_SRC" ]] && repo_renamed=true

# Nothing to migrate: neither the legacy tracked file nor the renamed one.
if ! $repo_renamed && [[ ! -f "$SRC" ]]; then
    log "No devices/$DEVICE/.zshrc (or .zshrc.local) found. Nothing to do."
    exit 0
fi

home_linked=false
if [[ -L "$LOCAL_DST" && "$(readlink "$LOCAL_DST")" == "$LOCAL_SRC" ]]; then
    home_linked=true
fi

home_shim=false
if [[ -f "$DST" && ! -L "$DST" ]] && grep -Fq "$SHIM_SOURCE_LINE" "$DST"; then
    home_shim=true
fi

if $repo_renamed && $home_linked && $home_shim; then
    log "Already migrated (repo rename + ~/.zshrc shim + ~/.zshrc.local link all present). Nothing to do."
    exit 0
fi

# --- Guard against clobbering machine-local content -----------------------

# ~/.zshrc must be one of: the legacy symlink to THIS device's file, absent,
# or our own already-seeded shim. Anything else (a symlink to a different
# device/outside the repo, or a real file that is not our shim) may hold
# local-only content, so refuse and defer to a human.
if [[ -L "$DST" ]]; then
    dst_target="$(readlink "$DST")"
    if [[ "$dst_target" != "$DOTFILES_DIR/"* ]]; then
        die "~/.zshrc is a symlink outside this repo ($DST -> $dst_target); refusing to touch it."
    elif [[ "$dst_target" != "$SRC" ]]; then
        die "~/.zshrc points at $dst_target, not devices/$DEVICE/.zshrc.
  If you meant a different device, pass its name: $0 <device>."
    fi
elif [[ -e "$DST" ]] && ! $home_shim; then
    die "~/.zshrc is a real local file that does not source ~/.zshrc.local -- it may hold local-only content.
  Migrate by hand: back it up, replace the device-config lines with
  '$SHIM_SOURCE_LINE', and keep any tool-appended blocks below it. See AGENTS.md."
fi

# ~/.zshrc.local: only auto-replace a symlink that points into this repo; a
# symlink elsewhere or a real file may be intentional, so refuse.
if [[ -L "$LOCAL_DST" ]]; then
    local_dst_target="$(readlink "$LOCAL_DST")"
    if [[ "$local_dst_target" != "$DOTFILES_DIR/"* ]]; then
        die "~/.zshrc.local is a symlink outside this repo ($LOCAL_DST -> $local_dst_target); refusing to replace it."
    fi
elif [[ -e "$LOCAL_DST" ]]; then
    die "~/.zshrc.local already exists as a real file; refusing to overwrite: $LOCAL_DST"
fi

# The rename uses git mv, so the source must be tracked (skip if already done).
if ! $repo_renamed; then
    git -C "$DOTFILES_DIR" ls-files --error-unmatch "devices/$DEVICE/.zshrc" >/dev/null 2>&1 \
        || die "devices/$DEVICE/.zshrc is not tracked by git; commit it first, then re-run (or migrate by hand)."
fi

# --- Pollution warning ----------------------------------------------------

# High-signal markers of machine-local content that leaked into the tracked
# file under the legacy layout. It stays tracked in .zshrc.local after the
# rename; the user should relocate it into the local ~/.zshrc shim. Advisory
# only -- it never gates the migration, so erring toward over-warning is fine.
CONTENT_FILE="$SRC"
$repo_renamed && CONTENT_FILE="$LOCAL_SRC"
POLLUTION_MARKERS='BEGIN--Instacart|>>> conda initialize|>>> mamba initialize|Added by [A-Za-z]|OrbStack|NVM_DIR|BUN_INSTALL|PNPM_HOME|PYENV_ROOT|# bun|/Users/[^/]|/home/[^/]'
if grep -EqI "$POLLUTION_MARKERS" "$CONTENT_FILE" 2>/dev/null; then
    warn "devices/$DEVICE/$(basename "$CONTENT_FILE") holds machine-local blocks (tool init / absolute paths):"
    grep -EnI "$POLLUTION_MARKERS" "$CONTENT_FILE" | sed 's/^/    /' >&2 || true
    warn "These stay TRACKED in .zshrc.local after migration."
    warn "Consider moving them out of .zshrc.local into your local ~/.zshrc afterward."
fi

# --- Dry run --------------------------------------------------------------

if [[ -n "$DRY_RUN" ]]; then
    log "DRY RUN -- no changes will be made."
    if ! $repo_renamed; then
        log "Would: git mv devices/$DEVICE/.zshrc devices/$DEVICE/.zshrc.local"
    else
        log "Repo already renamed; would finish HOME-side setup only."
    fi
    if [[ -L "$DST" ]]; then
        log "Would: remove legacy symlink $DST -> $(readlink "$DST")"
    fi
    if ! $home_linked; then
        if [[ -L "$LOCAL_DST" ]]; then
            log "Would: remove stale symlink $LOCAL_DST -> $(readlink "$LOCAL_DST")"
        fi
        log "Would: ln -s $LOCAL_SRC $LOCAL_DST"
    fi
    if ! $home_shim; then
        log "Would: seed local shim at $DST sourcing ~/.zshrc.local"
    fi
    exit 0
fi

# --- Perform (idempotent) -------------------------------------------------

# If anything below fails or is interrupted, the layout may be half-applied.
# Re-running converges from any intermediate state, so point the user there.
trap 'warn "Migration did not complete. Re-run to finish (it is idempotent and will resume):"; warn "  $0 $DEVICE"' ERR

if ! $repo_renamed; then
    log "Renaming tracked file: devices/$DEVICE/.zshrc -> .zshrc.local"
    git -C "$DOTFILES_DIR" mv "devices/$DEVICE/.zshrc" "devices/$DEVICE/.zshrc.local"
fi

# Remove a legacy/dangling ~/.zshrc symlink before seeding the shim: writing
# to a dangling symlink would create the file at the symlink's (in-repo)
# target instead of at ~/.zshrc.
if [[ -L "$DST" ]]; then
    log "Removing legacy symlink: $DST"
    rm "$DST"
fi

# Point ~/.zshrc.local at the renamed device file (absolute path, matching install.sh).
if ! $home_linked; then
    [[ -L "$LOCAL_DST" ]] && rm "$LOCAL_DST"
    log "Linking: $LOCAL_DST -> $LOCAL_SRC"
    ln -s "$LOCAL_SRC" "$LOCAL_DST"
fi

# Seed the machine-local shim (only if nothing is there now).
if [[ ! -e "$DST" ]]; then
    printf '%s\n' \
        '# Machine-local zsh config (not tracked by dotfiles).' \
        '# Sources the device config (~/.zshrc.local, symlinked from the repo);' \
        '# tools like Instacart setup append their own blocks below without' \
        '# churning the dotfiles repo.' \
        "$SHIM_SOURCE_LINE" > "$DST"
    log "Seeded local shim: $DST"
fi

trap - ERR

# --- Verify ---------------------------------------------------------------

[[ "$(readlink "$LOCAL_DST")" == "$LOCAL_SRC" ]] || die "verification failed: ~/.zshrc.local does not point at $LOCAL_SRC"
grep -Fq "$SHIM_SOURCE_LINE" "$DST" || die "verification failed: ~/.zshrc does not source ~/.zshrc.local"

# git mv stages only the rename; any content tools appended since the last
# commit stays UNSTAGED, so `git diff --staged` shows a clean 100%-similarity
# rename and hides it. Flag it explicitly so it is not committed by accident.
if ! git -C "$DOTFILES_DIR" diff --quiet -- "devices/$DEVICE/.zshrc.local"; then
    warn "The renamed file has UNSTAGED changes -- machine-local content appended"
    warn "since the last commit. 'git diff --staged' will NOT show these. Review with:"
    warn "  git -C \"$DOTFILES_DIR\" diff -- devices/$DEVICE/.zshrc.local"
    warn "and relocate machine-local blocks into ~/.zshrc before committing."
fi

log "Done. ~/.zshrc is now a local shim sourcing ~/.zshrc.local."
log ""
log "Next steps:"
log "  1. Open a new shell and confirm your environment still loads correctly."
log "  2. If warned above, move machine-local blocks out of .zshrc.local into ~/.zshrc."
log "  3. Review BOTH staged and unstaged changes, then commit the rename:"
log "       git -C \"$DOTFILES_DIR\" status"
log "       git -C \"$DOTFILES_DIR\" diff HEAD -- devices/$DEVICE/.zshrc.local"
