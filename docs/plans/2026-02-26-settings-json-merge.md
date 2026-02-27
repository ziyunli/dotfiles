# Settings JSON Deep Merge Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `.dotfiles-merge` support to `install.sh` so JSON files can be deep-merged instead of symlinked, preserving company-injected config while applying personal settings.

**Architecture:** A `merge-json.sh` helper script uses `jq` to recursively deep-merge two JSON files (shared base + existing local overlay). `install.sh` loads a `.dotfiles-merge` list per device and calls the helper for listed files instead of creating symlinks.

**Tech Stack:** bash, jq (1.7.1 available on system)

---

### Task 1: Create `merge-json.sh` helper script

**Files:**
- Create: `merge-json.sh`

**Step 1: Create `merge-json.sh` with deep merge and conflict reporting**

Create `merge-json.sh` at repo root (alongside `install.sh`). The script:

- Takes two args: `base` (shared dotfiles) and `overlay` (existing local file)
- Deep merges: objects recurse, arrays union, scalars overlay wins
- Outputs merged JSON to stdout
- Outputs conflict lines to stderr

```bash
#!/usr/bin/env bash
#
# merge-json.sh - Deep merge two JSON files
#
# Merges a base JSON file with an overlay JSON file:
#   - Objects: recursively merged
#   - Arrays: concatenated and deduplicated (union)
#   - Scalars: overlay value wins (conflicts reported to stderr)
#
# Usage:
#   ./merge-json.sh <base> <overlay>
#
# Arguments:
#   base      Path to the base JSON file (e.g., shared dotfiles settings)
#   overlay   Path to the overlay JSON file (e.g., existing local settings)
#
# Output:
#   stdout    Merged JSON
#   stderr    Conflict reports (one per line)
#
# Exit codes:
#   0         Success
#   1         Missing arguments or files
#   2         jq not found
#
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <base> <overlay>" >&2
    exit 1
fi

BASE="$1"
OVERLAY="$2"

if [[ ! -f "$BASE" ]]; then
    echo "Error: base file not found: $BASE" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not found" >&2
    exit 2
fi

# If no overlay file exists, output the base as-is
if [[ ! -f "$OVERLAY" ]]; then
    jq '.' "$BASE"
    exit 0
fi

# Deep merge with conflict detection
# Pass base as $base via --slurpfile so the jq program receives both inputs
jq --slurpfile base "$BASE" '

# Recursively deep merge two values. overlay wins for scalar conflicts.
# path tracks the current JSON path for conflict reporting.
def deepmerge(base; overlay; path):
  if (base | type) == "object" and (overlay | type) == "object" then
    (base | keys_unsorted) as $bkeys |
    (overlay | keys_unsorted) as $okeys |
    ($bkeys + $okeys) | unique |
    map(. as $k |
      if (base | has($k)) and (overlay | has($k)) then
        { ($k): (null | deepmerge(base[$k]; overlay[$k]; path + "." + $k)) }
      elif (overlay | has($k)) then
        { ($k): overlay[$k] }
      else
        { ($k): base[$k] }
      end
    ) | add // {}
  elif (base | type) == "array" and (overlay | type) == "array" then
    (base + overlay) | unique
  elif base == overlay then
    overlay
  else
    # Scalar conflict: overlay wins, report to stderr
    (path + ": shared=" + (base | tojson) + ", local=" + (overlay | tojson) + " (keeping local)") | debug |
    overlay
  end;

. as $overlay | null | deepmerge($base[0]; $overlay; "")

' "$OVERLAY" 2> >(
    # Transform jq debug output into readable conflict lines
    while IFS= read -r line; do
        # jq debug outputs: ["DEBUG:","message"]
        msg="${line#*\"DEBUG:\",\"}"
        msg="${msg%\"]*}"
        if [[ -n "$msg" ]]; then
            echo "CONFLICT at $msg" >&2
        fi
    done
)
```

**Step 2: Make it executable and test manually**

Run:
```bash
chmod +x merge-json.sh
```

Create two temporary test files and verify:
```bash
echo '{"model":"opus","permissions":{"allow":["Read","Write"]},"hooks":{"Stop":[{"matcher":""}]}}' > /tmp/base.json
echo '{"model":"bedrock","permissions":{"allow":["Write","Custom"]},"env":{"AWS_REGION":"us-east-1"}}' > /tmp/overlay.json
./merge-json.sh /tmp/base.json /tmp/overlay.json
```

Expected stdout (merged JSON with):
- `model` = `"bedrock"` (overlay wins)
- `permissions.allow` = union of both arrays
- `hooks.Stop` = from base (not in overlay)
- `env.AWS_REGION` = from overlay (not in base)

Expected stderr:
```
CONFLICT at .model: shared="opus", local="bedrock" (keeping local)
```

Also test with no overlay file:
```bash
./merge-json.sh /tmp/base.json /tmp/nonexistent.json
```
Expected: outputs base JSON as-is, no errors.

**Step 3: Commit**

```bash
git add merge-json.sh
git commit -m "Add merge-json.sh for deep merging JSON config files"
```

---

### Task 2: Add `.dotfiles-merge` support to `install.sh`

**Files:**
- Modify: `install.sh`

**Step 1: Add merge list loading (parallel to skip list)**

Add after the `is_skipped` function (after line 83), a matching `MERGE_FILES` / `load_merge_list` / `is_merged` pattern:

```bash
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
```

**Step 2: Make `link_directory` also skip merge-listed files**

In `link_directory`, update the skip check (line 128-131) to also skip merge-listed files. Change:

```bash
        [[ "$(basename "$rel")" == ".dotfiles-skip" || "$(basename "$rel")" == ".gitkeep" ]] && continue
```

to:

```bash
        [[ "$(basename "$rel")" == ".dotfiles-skip" || "$(basename "$rel")" == ".dotfiles-merge" || "$(basename "$rel")" == ".gitkeep" ]] && continue
```

And after the skip check (line 129-131), add a merge check:

```bash
        if [[ "$check_skip" == "true" ]] && is_merged "$rel"; then
            log "Deferred: $rel (will be merged)"
            continue
        fi
```

**Step 3: Add `merge_file` function**

Add a `merge_file` function after `link_file` (after line 114):

```bash
merge_file() {
    local src="$1" dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    if [[ -n "$DRY_RUN" ]]; then
        if [[ -f "$dst" ]]; then
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
        local merged
        merged="$("$DOTFILES_DIR/merge-json.sh" "$src" "$dst" 2>&1 1>&3)" 3>&1
        # merged now has stdout (the JSON), conflicts went to stderr (visible in terminal)
        # Actually, let's do this differently to properly separate streams
        "$DOTFILES_DIR/merge-json.sh" "$src" "$dst" > "$dst.tmp"
        mv "$dst.tmp" "$dst"
        log "Merged: $src + $dst -> $dst"
    else
        cp "$src" "$dst"
        log "Copied: $src -> $dst (no existing file to merge)"
    fi
}
```

Wait — the above has a bug with stream separation. Simpler approach:

```bash
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
```

**Step 4: Add merge phase to main section**

After the device linking block (after line 152), add the merge phase:

```bash
# Merge files listed in .dotfiles-merge
if [[ -n "$MERGE_FILES" ]]; then
    log "Merging configuration files..."
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        local src="$DOTFILES_DIR/shared/$rel"
        if [[ -f "$src" ]]; then
            merge_file "$src" "$HOME/$rel"
        else
            warn "Merge source not found: $src"
        fi
    done <<< "$MERGE_FILES"
fi
```

Note: `local` can't be used outside a function. Use a subshell or inline variable:

```bash
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
```

**Step 5: Call `load_merge_list` in main section**

Add `load_merge_list` call right after `load_skip_list` (line 140):

```bash
load_merge_list
```

**Step 6: Update script header comment**

Add `.dotfiles-merge` mention to the header. After line 14:

```bash
# A devices/<dev>/.dotfiles-merge file can list paths to deep-merge instead of symlink.
```

**Step 7: Test with DRY_RUN**

```bash
DRY_RUN=1 ./install.sh bento
```

Verify output shows "Would merge" for `.claude/settings.json` instead of "Skipped".

**Step 8: Commit**

```bash
git add install.sh
git commit -m "Add .dotfiles-merge support to install.sh for deep merging JSON files"
```

---

### Task 3: Update device `.dotfiles-skip` → `.dotfiles-merge`

**Files:**
- Modify: `devices/bento/.dotfiles-skip`
- Create: `devices/bento/.dotfiles-merge`
- Modify: `devices/insta-laptop/.dotfiles-skip`
- Create: `devices/insta-laptop/.dotfiles-merge`

**Step 1: Remove `.claude/settings.json` from skip files**

For both `bento` and `insta-laptop`, remove the `.claude/settings.json` line from `.dotfiles-skip`. If that's the only non-comment line, the file can be deleted or left with just the comment.

`devices/bento/.dotfiles-skip` becomes:
```
# Paths (relative to $HOME) to skip when linking shared files.
```

`devices/insta-laptop/.dotfiles-skip` becomes:
```
# Paths (relative to $HOME) to skip when linking shared files.
```

**Step 2: Create `.dotfiles-merge` files**

`devices/bento/.dotfiles-merge`:
```
# Paths (relative to $HOME) to deep-merge instead of symlink.
# Existing local values take precedence; conflicts are reported.
.claude/settings.json
```

`devices/insta-laptop/.dotfiles-merge`:
```
# Paths (relative to $HOME) to deep-merge instead of symlink.
# Existing local values take precedence; conflicts are reported.
.claude/settings.json
```

**Step 3: Commit**

```bash
git add devices/bento/.dotfiles-skip devices/bento/.dotfiles-merge
git add devices/insta-laptop/.dotfiles-skip devices/insta-laptop/.dotfiles-merge
git commit -m "Move .claude/settings.json from skip to merge for work devices"
```

---

### Task 4: Update README and uninstall.sh

**Files:**
- Modify: `README.md` (add brief mention of `.dotfiles-merge`)
- Modify: `uninstall.sh` (handle merged files — they're regular files, not symlinks)

**Step 1: Add `.dotfiles-merge` section to README.md**

Find the section that documents `.dotfiles-skip` and add a parallel section for `.dotfiles-merge`. Keep it brief.

**Step 2: Update `uninstall.sh` to handle merged files**

`uninstall.sh` currently only removes symlinks. For merged files, it should:
- Check if the file exists and is NOT a symlink
- Warn the user that merged files are not automatically removed
- The user can manually restore from backup

Add after the unlink phase:

```bash
# Warn about merged files (not symlinks, can't auto-remove)
merge_file="$DOTFILES_DIR/devices/$DEVICE/.dotfiles-merge"
if [[ -f "$merge_file" ]]; then
    log ""
    log "NOTE: The following files were merged (not symlinked) and cannot be auto-removed:"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        echo "  ~/$line"
    done < "$merge_file"
    log "You may want to manually remove or restore them."
fi
```

**Step 3: Commit**

```bash
git add README.md uninstall.sh
git commit -m "Document .dotfiles-merge and handle merged files in uninstall"
```
