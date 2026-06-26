# Personal opencode Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Version-control the two personal opencode settings (the `superpowers` plugin everywhere, the work `model` default on work devices) as a tool-proof overlay the company `opencode-config` tool can never clobber, with no work email in git.

**Architecture:** Two tracked JSON fragments — `shared/.config/opencode.personal.json` (portable: superpowers) and `devices/insta-laptop/.config/opencode.personal.json` (work: model) — are composed at install time into a real `~/.config/opencode.personal.json` that opencode reads via `OPENCODE_CONFIG`. Composition extends `install.sh`'s existing `.dotfiles-merge` mechanism with an optional middle device layer: `shared → device → local` (later wins), built by chaining the existing `merge-json.sh`. The overlay lives **beside** (not inside) the tool-managed `~/.config/opencode/` dir, so `opencode-config` never sees it.

**Tech Stack:** Bash (`install.sh`, `merge-json.sh`), `jq`, JSON config, the shell test harness `tests/dotfiles_bootstrap_test.sh`.

**Spec:** `docs/superpowers/specs/2026-06-26-opencode-personal-overlay-design.md`

**Branch:** `opencode-personal-overlay` (already checked out).

---

## Background the engineer needs

- **opencode config precedence** (verified on opencode 1.17.11): global
  `~/.config/opencode/opencode.json` → the `OPENCODE_CONFIG` file →
  per-project `opencode.json`, deep-merged with later layers overriding earlier.
  Our overlay only adds/overrides `plugin` and `model`; everything the company
  tool manages (providers, agents, the managed plugin) flows through untouched.
  An identical `superpowers` plugin spec across layers resolves once (opencode
  dedupes), so no double-load.
- **`merge-json.sh <base> <overlay>`** prints the deep-merge to stdout: objects
  recurse, arrays union+dedupe, scalars resolve to the overlay (conflicts go to
  stderr). The base file is required; a missing overlay file makes it print the
  base verbatim. It reads transparently through a symlinked fragment.
- **`install.sh` link/merge flow** (current):
  - `link_directory "$src_dir" [check_skip]` walks a source tree and symlinks
    each file into `$HOME`. The shared pass runs with `check_skip=true`; the
    device pass runs with the default `false`.
  - `.dotfiles-skip` excludes shared paths; `.dotfiles-merge` lists paths that
    are **deep-merged instead of symlinked**. Only `insta-laptop` and `bento`
    have these files; both currently list only `.claude/settings.json`.
  - The merge phase (bottom of `main`) iterates `MERGE_FILES` and calls
    `merge_file "$DOTFILES_DIR/shared/$rel" "$HOME/$rel"` — i.e. today it
    composes exactly **shared (base) → existing-local (overlay)**, local wins.
  - `merge_file src dst` removes any symlink at `dst`, then merges `src` over an
    existing real `dst` (or copies `src` when `dst` is absent). It has its own
    `DRY_RUN` branch printing `Would merge` / `Would copy`.
- **Why a device layer (the core change):** opencode has a single
  `OPENCODE_CONFIG` slot, but we want superpowers on every machine and the work
  model on work machines only — without duplicating the plugin line across files.
  So composition gains an optional middle layer: `shared → device → local`. When
  no `devices/<DEVICE>/<rel>` fragment exists (e.g. `.claude/settings.json`), the
  device step is a no-op and behavior is byte-for-byte today's `shared → local`.
- **Why deferral must be unconditional:** merged paths must never be symlinked —
  from the shared pass *or* the device pass. Today the `is_merged` deferral in
  `link_directory` sits behind the `check_skip=="true"` gate, so the device pass
  (which runs with `check_skip=false`) would symlink a device fragment straight
  onto the merge target. Moving the deferral out of the gate fixes this.
- **No work email risk:** the tool-managed `~/.config/opencode/opencode.json`
  embeds the user's work email in every provider URL. We never track anything
  under `~/.config/opencode/`; our overlay is the **sibling**
  `~/.config/opencode.personal.json`. Task 5 adds a guard so a future commit
  can't reintroduce that path.

## File Structure

| File | Responsibility | Action |
|------|----------------|--------|
| `shared/.config/opencode.personal.json` | Portable overlay base: `$schema` + superpowers plugin. Reaches every machine. | Create (Task 1) |
| `devices/insta-laptop/.config/opencode.personal.json` | Work overlay layer: `model` default. | Create (Task 2) |
| `devices/bento/.config/opencode.personal.json` | Symlink → insta-laptop's work layer (shared work settings, no drift). | Create (Task 3) |
| `devices/insta-laptop/.dotfiles-merge` | Add the overlay path so it is composed, not symlinked. | Modify (Task 2) |
| `devices/bento/.dotfiles-merge` | Same, for bento. | Modify (Task 3) |
| `install.sh` | Unconditional merge deferral + three-layer `merge_path` compose. | Modify (Task 2) |
| `shared/.zshenv.shared` | Guarded `OPENCODE_CONFIG` export. | Modify (Task 4) |
| `tests/dotfiles_bootstrap_test.sh` | Regression coverage for every component. | Modify (Tasks 1–6) |

Run the whole suite with: `bash tests/dotfiles_bootstrap_test.sh`
Expected on success (final line): `ok - dotfiles bootstrap checks passed`

---

## Task 1: Portable shared overlay (superpowers everywhere)

The smallest end-to-end slice: a new file under `shared/` is auto-symlinked into
`$HOME` by the existing shared pass — **no `install.sh` change needed**. On a
personal device (no `.dotfiles-merge`), `~/.config/opencode.personal.json` becomes
a symlink to this fragment: superpowers only, no model.

**Files:**
- Create: `shared/.config/opencode.personal.json`
- Test: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Add the personal-device assertions to the existing real install**

`with_fake_hostname` already performs a real personal-device install (currently
ending around line 80–85, the XDG Ghostty check). Immediately **after** this
existing line:

```bash
    [[ -L "$temp_home/.config/ghostty/config.ghostty" ]] ||
        fail "install.sh did not link the XDG Ghostty config"
```

insert:

```bash
    [[ -L "$temp_home/.config/opencode.personal.json" ]] ||
        fail "install.sh did not symlink the shared opencode overlay on a personal device"
    assert_file_contains "$temp_home/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
    assert_file_not_contains "$temp_home/.config/opencode.personal.json" 'openai/gpt-5.4'
```

- [ ] **Step 2: Add the static fragment assertions**

In the top-level static assertion block, **after** this existing line (the bento
work-context assertion, around line 255–256):

```bash
assert_file_contains "$ROOT_DIR/devices/bento/.claude/instacart-work-context.md" 'aigateway.instacart.tools'
```

insert:

```bash
# Personal opencode overlay: superpowers plugin everywhere via the shared base;
# the work model default is layered in only on work devices (Tasks 2-3).
assert_file_contains "$ROOT_DIR/shared/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
assert_file_not_contains "$ROOT_DIR/shared/.config/opencode.personal.json" 'openai/gpt-5.4'
```

- [ ] **Step 3: Run the suite to verify it fails**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: FAIL — first at the static assertion `... shared/.config/opencode.personal.json is missing: superpowers@git+https://github.com/obra/superpowers.git` (the file does not exist yet).

- [ ] **Step 4: Create the shared overlay fragment**

Create `shared/.config/opencode.personal.json` with exactly:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

- [ ] **Step 5: Run the suite to verify it passes**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: PASS — final line `ok - dotfiles bootstrap checks passed`.

- [ ] **Step 6: Commit**

```bash
git add shared/.config/opencode.personal.json tests/dotfiles_bootstrap_test.sh
git status
git commit -m "$(cat <<'EOF'
feat: track portable opencode superpowers overlay

The superpowers plugin is personal, portable opencode config worth tracking
on every machine. Add it as shared/.config/opencode.personal.json so the
shared pass symlinks it to ~/.config/opencode.personal.json on personal
devices (superpowers only). Work devices layer the model on top in a later
change.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Three-layer compose + insta-laptop work layer

This is the core mechanism. On a work device the overlay must be **composed**
(shared superpowers + device model) into a real file, never symlinked. Two
`install.sh` changes (unconditional deferral, three-layer `merge_path`) plus the
insta-laptop fragment and `.dotfiles-merge` entry.

**Files:**
- Modify: `install.sh` (link_directory deferral; new `merge_path`; merge-loop rewire)
- Create: `devices/insta-laptop/.config/opencode.personal.json`
- Modify: `devices/insta-laptop/.dotfiles-merge`
- Test: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Add the work-device DRY_RUN assertions (deferral guard)**

In `with_explicit_work_devices`, the insta-laptop `DRY_RUN` block ends with this
existing line (around line 111–112):

```bash
    [[ "$output" == *"Would link: $temp_home/.claude/instacart-work-context.md -> $ROOT_DIR/devices/insta-laptop/.claude/instacart-work-context.md"* ]] ||
        fail "insta-laptop install did not link the curated work-context overlay"
```

Immediately **after** it (and before the `bento` block reassigns `output`),
insert:

```bash
    # The opencode overlay is a .dotfiles-merge path on work devices, so it must
    # be composed in the merge phase -- never symlinked from the shared OR the
    # device pass (the latter is what the unconditional is_merged deferral fixes).
    [[ "$output" != *"Would link: $temp_home/.config/opencode.personal.json ->"* ]] ||
        fail "insta-laptop opencode overlay must be merged, not symlinked"
    [[ "$output" == *"Would merge: $ROOT_DIR/shared/.config/opencode.personal.json + $ROOT_DIR/devices/insta-laptop/.config/opencode.personal.json + $temp_home/.config/opencode.personal.json -> $temp_home/.config/opencode.personal.json"* ]] ||
        fail "insta-laptop install did not compose the opencode overlay from shared + device + local"
```

- [ ] **Step 2: Add the work-device real-install compose test**

Add a new test function. Place it **after** the `with_local_pi_agents` function
definition (around line 202, before the top-level static assertions begin):

```bash
with_work_opencode_overlay() {
    local work_root insta_home

    work_root="$(mktemp -d)"
    trap 'rm -rf "$work_root"' RETURN

    # Work device (insta-laptop): the overlay is COMPOSED into a real file --
    # superpowers (from the shared base) + the work model (from the device layer).
    # Explicit device arg means no hostname fake is needed.
    insta_home="$work_root/insta"
    mkdir -p "$insta_home"
    HOME="$insta_home" "$ROOT_DIR/install.sh" insta-laptop >/dev/null
    [[ -f "$insta_home/.config/opencode.personal.json" && ! -L "$insta_home/.config/opencode.personal.json" ]] ||
        fail "insta-laptop install did not compose a real opencode overlay file"
    assert_file_contains "$insta_home/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
    assert_file_contains "$insta_home/.config/opencode.personal.json" 'openai/gpt-5.4'
}
```

Then register it: in the run list near the bottom (after `with_local_pi_agents`,
around line 300), **after**:

```bash
with_local_pi_agents
```

insert:

```bash
with_work_opencode_overlay
```

- [ ] **Step 3: Add the static insta-laptop assertions**

In the top-level static block, **after** the two shared-fragment assertions added
in Task 1, insert:

```bash
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.config/opencode.personal.json" 'openai/gpt-5.4'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.dotfiles-merge" '.config/opencode.personal.json'
```

- [ ] **Step 4: Run the suite to verify it fails**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: FAIL — at `... devices/insta-laptop/.config/opencode.personal.json is missing: openai/gpt-5.4` (file absent), and the DRY_RUN/compose assertions would also fail (no merge entry, no device-layer logic).

- [ ] **Step 5: Create the insta-laptop work fragment**

Create `devices/insta-laptop/.config/opencode.personal.json` with exactly:

```json
{ "model": "openai/gpt-5.4" }
```

- [ ] **Step 6: Add the overlay to insta-laptop's `.dotfiles-merge`**

Append a line to `devices/insta-laptop/.dotfiles-merge` so it reads:

```
# Paths (relative to $HOME) to deep-merge instead of symlink.
# Existing local values take precedence; conflicts are reported.
.claude/settings.json
.config/opencode.personal.json
```

- [ ] **Step 7: Make the `is_merged` deferral unconditional in `install.sh`**

In `link_directory`, update the comment and the deferral. Replace this block
(currently around lines 208–232):

```bash
# link_directory links all regular files and symbolic links found under a source
# directory into the user's $HOME, preserving each entry's relative path.
# When check_skip is "true", paths listed in .dotfiles-skip are excluded.
link_directory() {
```

with:

```bash
# link_directory links all regular files and symbolic links found under a source
# directory into the user's $HOME, preserving each entry's relative path.
# When check_skip is "true", paths listed in .dotfiles-skip are excluded.
# Paths listed in .dotfiles-merge are always deferred to the merge phase (from
# both the shared and the device pass), so a symlink never lands on a merge target.
link_directory() {
```

and replace this block (currently around lines 229–232):

```bash
        if [[ "$check_skip" == "true" ]] && is_merged "$rel"; then
            log "Deferred: $rel (will be merged)"
            continue
        fi
```

with:

```bash
        if is_merged "$rel"; then
            log "Deferred: $rel (will be merged)"
            continue
        fi
```

- [ ] **Step 8: Add the three-layer `merge_path` function**

Insert this function immediately **after** the `merge_file` function definition
(after its closing `}`, currently around line 206) and before the `link_directory`
comment block:

```bash
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
```

- [ ] **Step 9: Rewire the merge loop to use `merge_path`**

Replace the merge phase (currently around lines 368–380):

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

with:

```bash
# Merge files listed in .dotfiles-merge (shared -> device -> local; later wins)
if [[ -n "$MERGE_FILES" ]]; then
    log "Merging configuration files..."
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        merge_path "$rel"
    done <<< "$MERGE_FILES"
fi
```

- [ ] **Step 10: Run the suite to verify it passes**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: PASS — final line `ok - dotfiles bootstrap checks passed`.

- [ ] **Step 11: Sanity-check the composed output by hand (optional but recommended)**

Run:

```bash
TMP_HOME="$(mktemp -d)"; HOME="$TMP_HOME" ./install.sh insta-laptop >/dev/null && cat "$TMP_HOME/.config/opencode.personal.json"; rm -rf "$TMP_HOME"
```

Expected: a single JSON object containing both `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` and `"model": "openai/gpt-5.4"`.

- [ ] **Step 12: Commit**

```bash
git add install.sh devices/insta-laptop/.config/opencode.personal.json devices/insta-laptop/.dotfiles-merge tests/dotfiles_bootstrap_test.sh
git status
git commit -m "$(cat <<'EOF'
feat: compose opencode overlay from shared + device layers

Extend the .dotfiles-merge mechanism with an optional middle device layer so
composition becomes shared -> device -> local (later wins), built by chaining
merge-json.sh. Defer merged paths from every link pass (not just the shared
one) so a device fragment never gets symlinked onto a merge target. Wire the
work model default into ~/.config/opencode.personal.json on insta-laptop while
the portable superpowers plugin still comes from the shared base.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: bento shares the work overlay

`bento` is the second work device and should get the same work `model`. Mirror
the proven Claude-overlay pattern: a repo symlink to insta-laptop's fragment (so
the two work devices never drift) plus the matching `.dotfiles-merge` entry.

**Files:**
- Create: `devices/bento/.config/opencode.personal.json` (symlink)
- Modify: `devices/bento/.dotfiles-merge`
- Test: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Add the bento DRY_RUN assertions**

In `with_explicit_work_devices`, the bento `DRY_RUN` block ends with this existing
line (around line 125–126):

```bash
    [[ "$output" == *"Would link: $temp_home/.claude/instacart-work-context.md -> $ROOT_DIR/devices/bento/.claude/instacart-work-context.md"* ]] ||
        fail "bento install did not link the curated work-context overlay"
```

Immediately **after** it, insert:

```bash
    [[ "$output" != *"Would link: $temp_home/.config/opencode.personal.json ->"* ]] ||
        fail "bento opencode overlay must be merged, not symlinked"
    [[ "$output" == *"Would merge: $ROOT_DIR/shared/.config/opencode.personal.json + $ROOT_DIR/devices/bento/.config/opencode.personal.json + $temp_home/.config/opencode.personal.json -> $temp_home/.config/opencode.personal.json"* ]] ||
        fail "bento install did not compose the opencode overlay from shared + device + local"
```

- [ ] **Step 2: Add the bento block to the real-install compose test**

In `with_work_opencode_overlay` (added in Task 2), declare a `bento_home` local
and append the bento block. Change the locals line:

```bash
    local work_root insta_home
```

to:

```bash
    local work_root insta_home bento_home
```

and **after** the insta-laptop assertions (the last line in the function,
`assert_file_contains "$insta_home/.config/opencode.personal.json" 'openai/gpt-5.4'`),
insert:

```bash
    # bento shares insta-laptop's work fragment via a repo symlink; the compose
    # must read through it and still yield both keys.
    bento_home="$work_root/bento"
    mkdir -p "$bento_home"
    HOME="$bento_home" "$ROOT_DIR/install.sh" bento >/dev/null
    [[ -f "$bento_home/.config/opencode.personal.json" && ! -L "$bento_home/.config/opencode.personal.json" ]] ||
        fail "bento install did not compose a real opencode overlay file"
    assert_file_contains "$bento_home/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
    assert_file_contains "$bento_home/.config/opencode.personal.json" 'openai/gpt-5.4'
```

- [ ] **Step 3: Add the static bento symlink assertions**

In the top-level static block, **after** the insta-laptop static assertions added
in Task 2, insert:

```bash
[[ -L "$ROOT_DIR/devices/bento/.config/opencode.personal.json" ]] ||
    fail "devices/bento/.config/opencode.personal.json should be a symlink to insta-laptop's fragment"
[[ "$(readlink "$ROOT_DIR/devices/bento/.config/opencode.personal.json")" == "../../insta-laptop/.config/opencode.personal.json" ]] ||
    fail "devices/bento/.config/opencode.personal.json should point to ../../insta-laptop/.config/opencode.personal.json"
assert_file_contains "$ROOT_DIR/devices/bento/.dotfiles-merge" '.config/opencode.personal.json'
```

- [ ] **Step 4: Run the suite to verify it fails**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: FAIL — at `devices/bento/.config/opencode.personal.json should be a symlink ...` (the symlink does not exist yet).

- [ ] **Step 5: Create the bento symlink fragment**

```bash
mkdir -p devices/bento/.config
ln -s ../../insta-laptop/.config/opencode.personal.json devices/bento/.config/opencode.personal.json
```

Verify it resolves:

```bash
cat devices/bento/.config/opencode.personal.json
```

Expected: `{ "model": "openai/gpt-5.4" }`

- [ ] **Step 6: Add the overlay to bento's `.dotfiles-merge`**

Append a line to `devices/bento/.dotfiles-merge` so it reads:

```
# Paths (relative to $HOME) to deep-merge instead of symlink.
# Existing local values take precedence; conflicts are reported.
.claude/settings.json
.config/opencode.personal.json
```

- [ ] **Step 7: Run the suite to verify it passes**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: PASS — final line `ok - dotfiles bootstrap checks passed`.

- [ ] **Step 8: Commit**

```bash
git add devices/bento/.config/opencode.personal.json devices/bento/.dotfiles-merge tests/dotfiles_bootstrap_test.sh
git status
git commit -m "$(cat <<'EOF'
feat: share opencode work overlay with bento

bento is a work device and gets the same work model. Symlink its overlay
fragment to insta-laptop's canonical copy (no drift between work devices) and
add the matching .dotfiles-merge entry. merge-json.sh reads through the symlink,
so the compose still yields superpowers + model.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Point opencode at the overlay via `OPENCODE_CONFIG`

The composed file exists after install, but opencode only reads it when
`OPENCODE_CONFIG` points at it. Add a guarded export to `shared/.zshenv.shared`
(reaches every zsh, including `zsh -c`), matching the existing fzf-block style.

**Files:**
- Modify: `shared/.zshenv.shared`
- Test: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Add the static export assertions**

In the top-level static block, **after** the bento static assertions added in
Task 3, insert:

```bash
# opencode reads OPENCODE_CONFIG and deep-merges it over its global config, so
# the personal overlay reaches opencode without touching the tool-managed dir.
assert_file_contains "$ROOT_DIR/shared/.zshenv.shared" 'if [[ -f "$HOME/.config/opencode.personal.json" ]]; then'
assert_file_contains "$ROOT_DIR/shared/.zshenv.shared" 'export OPENCODE_CONFIG="$HOME/.config/opencode.personal.json"'
```

- [ ] **Step 2: Run the suite to verify it fails**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: FAIL — `... shared/.zshenv.shared is missing: export OPENCODE_CONFIG="$HOME/.config/opencode.personal.json"`.

- [ ] **Step 3: Add the guarded export to `shared/.zshenv.shared`**

Append to `shared/.zshenv.shared` (after the existing fzf block, currently ending
at line 14):

```sh

# opencode deep-merges the file named by OPENCODE_CONFIG over its global config.
# install.sh composes the personal overlay (superpowers everywhere, plus the work
# model on work devices) into ~/.config/opencode.personal.json -- a sibling of the
# company-tool-managed ~/.config/opencode/ dir, which never sees it. The file
# guard only skips machines where the overlay was never installed (there
# .zshenv.shared is not sourced anyway).
if [[ -f "$HOME/.config/opencode.personal.json" ]]; then
  export OPENCODE_CONFIG="$HOME/.config/opencode.personal.json"
fi
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: PASS — final line `ok - dotfiles bootstrap checks passed`.

- [ ] **Step 5: Commit**

```bash
git add shared/.zshenv.shared tests/dotfiles_bootstrap_test.sh
git status
git commit -m "$(cat <<'EOF'
feat: point opencode at the personal overlay via OPENCODE_CONFIG

Export OPENCODE_CONFIG=~/.config/opencode.personal.json from the shared zsh env
so opencode deep-merges the tracked overlay over its global config. Guard on the
file's existence and match the existing fzf-block style; reaches every zsh
including `zsh -c`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Guard against leaking the tool-managed opencode config into git

The tool-managed `~/.config/opencode/opencode.json` embeds the work email in every
provider URL. Nothing in this repo may ever map into `~/.config/opencode/` (which
`install.sh` would then symlink into place). A static guard catches a future
regression. Because it scans only the repo, the live
`~/.config/opencode/skills/*` symlinks (owned by the separate skillshare repo, not
tracked here) cannot false-positive.

**Files:**
- Test: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Add the leak guard**

In the top-level static block, **after** the export assertions added in Task 4,
insert:

```bash
# The tool-managed ~/.config/opencode/ dir embeds the work email in every provider
# URL and is regenerated by the company opencode-config tool. No repo file may map
# into it (install.sh would symlink it into ~/.config/opencode/), or that email and
# provider block would leak into git. Our overlay is the sibling
# ~/.config/opencode.personal.json, which this -path pattern does not match.
if find "$ROOT_DIR/shared" "$ROOT_DIR/devices" -path '*/.config/opencode/*' -print -quit | grep -q .; then
    fail "no repo file may map into ~/.config/opencode/ (tool-managed; would leak the work email)"
fi
```

- [ ] **Step 2: Run the suite to verify it passes now**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: PASS — nothing under `.config/opencode/` exists in the repo yet.

- [ ] **Step 3: Verify the guard actually catches a violation**

Simulate the regression, run the suite, then clean up:

```bash
mkdir -p shared/.config/opencode
printf '{}\n' > shared/.config/opencode/opencode.json
bash tests/dotfiles_bootstrap_test.sh; echo "exit=$?"
rm -rf shared/.config/opencode
```

Expected: the run prints `not ok - no repo file may map into ~/.config/opencode/ (tool-managed; would leak the work email)` and `exit=1`. After `rm -rf`, re-run `bash tests/dotfiles_bootstrap_test.sh` and confirm it PASSES again (final line `ok - dotfiles bootstrap checks passed`). Confirm the simulated dir is gone: `git status --short` shows no `shared/.config/opencode/` entry.

- [ ] **Step 4: Commit**

```bash
git add tests/dotfiles_bootstrap_test.sh
git status
git commit -m "$(cat <<'EOF'
test: guard against leaking the tool-managed opencode config into git

Assert no repo file maps into ~/.config/opencode/, the company-managed dir whose
provider URLs embed the work email. Our overlay is the sibling
~/.config/opencode.personal.json, so this guard only trips if someone reintroduces
the tool config under version control.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Backward-compat — `settings.json` merge unchanged without a device layer

Prove the new device layer is a true no-op when no device fragment exists:
`.claude/settings.json` (which has only a shared source) must still deep-merge
shared over the existing local file with local winning — exactly today's behavior.

**Files:**
- Test: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Add the backward-compat test function**

Add this function **after** `with_work_opencode_overlay` (before the static
assertion block):

```bash
with_settings_backward_compat() {
    local temp_home

    temp_home="$(mktemp -d)"
    trap 'rm -rf "$temp_home"' RETURN

    # Pre-seed a local Claude settings file with a personal key.
    mkdir -p "$temp_home/.claude"
    printf '{"local_only_key": "keep-me"}\n' > "$temp_home/.claude/settings.json"

    # A work-device install merges shared settings over the local file. There is
    # no devices/insta-laptop/.claude/settings.json fragment, so the new device
    # layer is a no-op: local values still survive AND shared keys are merged in
    # (proving a real deep-merge, not a clobber or a symlink). Explicit device
    # arg means no hostname fake is needed.
    HOME="$temp_home" "$ROOT_DIR/install.sh" insta-laptop >/dev/null
    [[ -f "$temp_home/.claude/settings.json" && ! -L "$temp_home/.claude/settings.json" ]] ||
        fail "settings.json merge did not produce a real local file"
    assert_file_contains "$temp_home/.claude/settings.json" 'local_only_key'
    assert_file_contains "$temp_home/.claude/settings.json" 'keep-me'
    assert_file_contains "$temp_home/.claude/settings.json" 'ANTHROPIC_MODEL'
}
```

Then register it: in the run list near the bottom, **after**
`with_work_opencode_overlay`, insert:

```bash
with_settings_backward_compat
```

- [ ] **Step 2: Run the suite to verify it passes**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: PASS — the device layer is already a no-op for `.claude/settings.json` (implemented in Task 2), so this guard documents and locks in that behavior.

> Note: this is a characterization guard for behavior delivered in Task 2. To
> confirm it has teeth, temporarily break it: in `merge_path`, change
> `merge_file "$shared_src" "$HOME/$rel"` to `return` (skipping the no-device
> merge), run the suite, and watch this test fail with
> `settings.json ... is missing: ANTHROPIC_MODEL`. Restore the line and re-run to
> green before committing.

- [ ] **Step 3: Commit**

```bash
git add tests/dotfiles_bootstrap_test.sh
git status
git commit -m "$(cat <<'EOF'
test: assert settings.json merge is unchanged without a device layer

Lock in backward compatibility for the new device layer: .claude/settings.json
has only a shared source, so the device step must be a no-op and the original
shared -> local deep-merge (local wins, shared keys merged in) must still hold.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Final verification (after all tasks)

- [ ] **Full suite green**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: `ok - dotfiles bootstrap checks passed`.

- [ ] **DRY_RUN shows compose, never a symlink (spec verification 1 & 3)**

```bash
DRY_RUN=1 ./install.sh insta-laptop  | grep opencode.personal.json
DRY_RUN=1 ./install.sh Ziyuns-Mac-mini | grep opencode.personal.json
```

Expected: insta-laptop shows a `Would merge: ... shared ... + ... insta-laptop ... + ... -> ...` line and **no** `Would link:` for the overlay; Ziyuns-Mac-mini (personal) shows a `Would link: .../opencode.personal.json -> .../shared/.config/opencode.personal.json` line (symlinked, superpowers only).

- [ ] **Real composed file on a work device (spec verification 2)**

```bash
TMP_HOME="$(mktemp -d)"; HOME="$TMP_HOME" ./install.sh insta-laptop >/dev/null
cat "$TMP_HOME/.config/opencode.personal.json"
rm -rf "$TMP_HOME"
```

Expected: a real JSON file containing both `plugin` (superpowers) and `model`
(`openai/gpt-5.4`).

- [ ] **Repo stays clean (no email/provider block tracked)**

Run: `git status --short`
Expected: clean working tree; `git log --oneline -6` shows the six task commits;
no file under `shared/.config/opencode/` or `devices/*/.config/opencode/` exists.

---

## Self-review notes (author)

- **Spec coverage:** Component A → Tasks 1 (shared fragment) + 4 (OPENCODE_CONFIG
  export); Component B → Task 2 (unconditional deferral + `merge_path`); Component
  C → Task 3 (bento symlink + merge entry); Component D → Tasks 1/2/3 content
  tests + Task 5 (leak guard) + Task 6 (backward-compat). All four components and
  all three Component-D test items are covered.
- **Why two tests for Task 2:** the real-install content test forces the
  `merge_path` device-layer + device fragment + merge entry (it passes even
  without the deferral fix, because `merge_file` removes a stray symlink); the
  DRY_RUN negative assertion is what forces the unconditional deferral (it fails
  if the device pass symlinks the merge target). Both are required.
- **No placeholders:** every code/edit step shows complete content; every run step
  states the exact command and expected pass/fail.
- **Naming consistency:** `merge_path` (new function), `is_merged` (existing,
  now ungated), `with_work_opencode_overlay` / `with_settings_backward_compat`
  (new test functions) are referenced identically wherever they appear.
