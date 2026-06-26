# Protect Personal AGENTS.md — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop Instacart's `pi-config` from overwriting the personal `shared/AGENTS.md`, make the personal prompt load in all five AI tools again, and add a curated work-device-only company overlay for Claude.

**Architecture:** The only writer (`@instacart/pi-config`) overwrites exactly one path, `~/.pi/agent/AGENTS.md`, which today is a symlink chain into the repo — so the write follows through to `shared/AGENTS.md` and poisons every tool. We break that chain by making `~/.pi/agent/AGENTS.md` a real machine-local file (mirroring the existing `seed_local_zshenv` pattern) and delivering personal content to Pi through `~/.pi/agent/APPEND_SYSTEM.md` (a channel pi-config never touches). We restore the personal prompt, add a curated overlay for Claude on work devices via `CLAUDE.md` `@import`, and guard the whole thing with bootstrap tests.

**Tech Stack:** Bash (`install.sh`, `tests/dotfiles_bootstrap_test.sh`), git, POSIX symlinks, Claude Code `CLAUDE.md` `@import`, Pi `APPEND_SYSTEM.md`.

---

## Background facts (verified, for the implementer)

- `shared/AGENTS.md` is the single real personal prompt. It is currently clobbered in the **working tree only** (`git status` shows `M shared/AGENTS.md`); `HEAD` still has the personal content. It starts with the line `You are an experienced, pragmatic software engineer`.
- Every tool's instruction file is a symlink ending at `shared/AGENTS.md`:
  - `shared/.claude/AGENTS.md`, `shared/.codex/AGENTS.md`, `shared/.config/amp/AGENTS.md`, `shared/.gemini/GEMINI.md`, `shared/.pi/agent/AGENTS.md` all resolve to `shared/AGENTS.md`.
- `@instacart/pi-config`'s `syncAgents()` does `fs.writeFileSync(~/.pi/agent/AGENTS.md, <boilerplate>)` — a full overwrite of that one path, no other tool path.
- Pi runtime (`@earendil-works/pi-coding-agent/.../resource-loader.js`) loads `~/.pi/agent/AGENTS.md` as a global *context* file and appends `~/.pi/agent/APPEND_SYSTEM.md` to the system prompt. `APPEND_SYSTEM.md` has no writer.
- Work devices install with an explicit arg: `./install.sh insta-laptop` (or `bento`). Personal devices default to `hostname -s`.
- `install.sh` links `shared/` first, then `devices/<dev>/` (device files override shared). `link_file` replaces an existing symlink that points elsewhere. `seed_local_zshenv` (`install.sh:245`) is the proven pattern to copy.
- The existing test asserts the **buggy** behavior at `tests/dotfiles_bootstrap_test.sh:48-49` — that line must change.

## File Structure

**Phase 1 — core fix + guard**
- Modify: `install.sh` — add `seed_local_pi_agents()` and call it from `main`.
- Delete: `shared/.pi/agent/AGENTS.md` (the chain link; no longer needed).
- Create: `shared/.pi/agent/APPEND_SYSTEM.md` → symlink `../../AGENTS.md` (personal channel for Pi).
- Modify: `tests/dotfiles_bootstrap_test.sh` — replace the buggy Pi assertion, add `with_local_pi_agents()`, add repo-policy assertions.
- Restore (working tree only): `shared/AGENTS.md` from `HEAD`.

**Phase 2 — Claude work-device overlay**
- Create: `devices/insta-laptop/.claude/CLAUDE.md` — `@AGENTS.md` + `@instacart-work-context.md`.
- Create: `devices/insta-laptop/.claude/instacart-work-context.md` — curated facts (canonical copy).
- Create: `devices/bento/.claude/CLAUDE.md` — same two imports.
- Create: `devices/bento/.claude/instacart-work-context.md` → symlink `../../insta-laptop/.claude/instacart-work-context.md` (single source of truth, no drift).
- Modify: `tests/dotfiles_bootstrap_test.sh` — assert the work-device Claude overlay links and content.

**Out of scope (deferred — see end of plan):** Gemini and Amp overlays.

---

# Phase 1 — Core fix + regression guard

### Task 1: Encode the new Pi behavior as failing tests

**Files:**
- Modify: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Replace the buggy Pi link assertion in `with_fake_hostname`**

Find this block (currently `tests/dotfiles_bootstrap_test.sh:48-49`):

```bash
    [[ "$output" == *"Would link: $temp_home/.pi/agent/AGENTS.md -> $ROOT_DIR/shared/.pi/agent/AGENTS.md"* ]] ||
        fail "install.sh did not include the shared Pi agent instructions"
```

Replace it with:

```bash
    [[ "$output" != *"Would link: $temp_home/.pi/agent/AGENTS.md ->"* ]] ||
        fail "install.sh should not link ~/.pi/agent/AGENTS.md into the repo (pi-config write-through risk)"
    [[ "$output" == *"Would link: $temp_home/.pi/agent/APPEND_SYSTEM.md -> $ROOT_DIR/shared/.pi/agent/APPEND_SYSTEM.md"* ]] ||
        fail "install.sh did not link the Pi APPEND_SYSTEM.md personal channel"
    [[ "$output" == *"Would seed local ~/.pi/agent/AGENTS.md"* ]] ||
        fail "install.sh did not plan to seed a local ~/.pi/agent/AGENTS.md"
```

- [ ] **Step 2: Add the `with_local_pi_agents` test function**

Insert this function immediately after the end of `with_local_zshenv()` (after its closing `}`, currently near `tests/dotfiles_bootstrap_test.sh:154`):

```bash
with_local_pi_agents() {
    local temp_home temp_bin

    temp_home="$(mktemp -d)"
    temp_bin="$(mktemp -d)"
    trap 'rm -rf "$temp_home" "$temp_bin"' RETURN

    printf '#!/usr/bin/env bash\nprintf "Ziyuns-M5-MacBook-Pro\\n"\n' > "$temp_bin/hostname"
    chmod +x "$temp_bin/hostname"

    # Fresh install: ~/.pi/agent/AGENTS.md is a real local file (never a repo
    # symlink), and personal content reaches Pi via ~/.pi/agent/APPEND_SYSTEM.md.
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -f "$temp_home/.pi/agent/AGENTS.md" && ! -L "$temp_home/.pi/agent/AGENTS.md" ]] ||
        fail "install.sh did not seed a real local ~/.pi/agent/AGENTS.md"
    [[ -L "$temp_home/.pi/agent/APPEND_SYSTEM.md" ]] ||
        fail "install.sh did not link ~/.pi/agent/APPEND_SYSTEM.md"
    grep -Fq "You are an experienced, pragmatic software engineer" "$temp_home/.pi/agent/APPEND_SYSTEM.md" ||
        fail "Pi APPEND_SYSTEM.md does not resolve to the personal prompt"

    # Idempotent: a pi-config-style overwrite of the local AGENTS.md is preserved.
    printf '# Instacart Engineering\n' > "$temp_home/.pi/agent/AGENTS.md"
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -f "$temp_home/.pi/agent/AGENTS.md" && ! -L "$temp_home/.pi/agent/AGENTS.md" ]] ||
        fail "install.sh turned ~/.pi/agent/AGENTS.md into a symlink"
    grep -Fq "# Instacart Engineering" "$temp_home/.pi/agent/AGENTS.md" ||
        fail "install.sh clobbered the local pi-config-written ~/.pi/agent/AGENTS.md"

    # An obsolete repo-owned symlink at ~/.pi/agent/AGENTS.md is replaced with a local file.
    rm "$temp_home/.pi/agent/AGENTS.md"
    ln -s "$ROOT_DIR/shared/AGENTS.md" "$temp_home/.pi/agent/AGENTS.md"
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -f "$temp_home/.pi/agent/AGENTS.md" && ! -L "$temp_home/.pi/agent/AGENTS.md" ]] ||
        fail "install.sh did not replace the obsolete ~/.pi/agent/AGENTS.md symlink with a local file"
}
```

- [ ] **Step 3: Call `with_local_pi_agents` and add repo-policy assertions**

Find the test invocations near the end (currently `tests/dotfiles_bootstrap_test.sh:222-224`):

```bash
with_fake_hostname
with_explicit_work_devices
with_local_zshenv
```

Replace with:

```bash
with_fake_hostname
with_explicit_work_devices
with_local_zshenv
with_local_pi_agents
```

Then, immediately before the line `assert_path_not_exists "$ROOT_DIR/shared/.zshenv"` (currently `tests/dotfiles_bootstrap_test.sh:184`), insert these static repo-policy assertions:

```bash
# The personal prompt must be the canonical shared/AGENTS.md content, never the
# company boilerplate (a re-clobber landing in the repo would trip this).
assert_file_contains "$ROOT_DIR/shared/AGENTS.md" 'You are an experienced, pragmatic software engineer'
assert_file_not_contains "$ROOT_DIR/shared/AGENTS.md" '# Instacart Engineering'

# No tracked file may be a pi-config write target. shared/.pi/agent/AGENTS.md is
# retired; personal reaches Pi through APPEND_SYSTEM.md instead.
assert_path_not_exists "$ROOT_DIR/shared/.pi/agent/AGENTS.md"
[[ -L "$ROOT_DIR/shared/.pi/agent/APPEND_SYSTEM.md" ]] ||
    fail "shared/.pi/agent/APPEND_SYSTEM.md should be a symlink to the personal prompt"
[[ "$(readlink "$ROOT_DIR/shared/.pi/agent/APPEND_SYSTEM.md")" == "../../AGENTS.md" ]] ||
    fail "shared/.pi/agent/APPEND_SYSTEM.md should point to ../../AGENTS.md"
```

- [ ] **Step 4: Run the test suite to verify it FAILS**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: FAIL. The first failure will be one of:
- `shared/AGENTS.md is missing: You are an experienced, pragmatic software engineer` (working tree is still clobbered), or
- `... should not exist` for `shared/.pi/agent/AGENTS.md` (still present), or
- the `with_local_pi_agents` / `Would seed local` assertions (install.sh not updated yet).

This confirms the tests exercise the new behavior before it exists.

- [ ] **Step 5: Commit the failing tests**

```bash
git add tests/dotfiles_bootstrap_test.sh
git commit -m "test: assert personal AGENTS.md is protected from pi-config write-through

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

> NOTE: Stage `tests/dotfiles_bootstrap_test.sh` ONLY. Do not `git add -A` — the clobbered `shared/AGENTS.md` must never be committed.

---

### Task 2: Retire the chain link; add the Pi personal channel

**Files:**
- Delete: `shared/.pi/agent/AGENTS.md`
- Create: `shared/.pi/agent/APPEND_SYSTEM.md` (symlink → `../../AGENTS.md`)

- [ ] **Step 1: Remove the repo chain link and add the append channel**

```bash
git rm shared/.pi/agent/AGENTS.md
ln -s ../../AGENTS.md shared/.pi/agent/APPEND_SYSTEM.md
git add shared/.pi/agent/APPEND_SYSTEM.md
```

- [ ] **Step 2: Verify the new symlink resolves to the personal prompt**

Run: `readlink shared/.pi/agent/APPEND_SYSTEM.md && cat shared/.pi/agent/APPEND_SYSTEM.md | head -1`
Expected: prints `../../AGENTS.md` then `You are an experienced, pragmatic software engineer` (the latter only once `shared/AGENTS.md` is restored in Task 5; before that it prints the boilerplate first line — that's fine here, the symlink target is what matters).

- [ ] **Step 3: Close the live write-through window on this machine**

The live `~/.pi/agent/AGENTS.md` symlink now dangles toward the deleted repo file. Remove it so pi-config cannot recreate the repo file by writing through it before Task 5 runs:

```bash
rm -f "$HOME/.pi/agent/AGENTS.md"
```

(If pi-config runs before Task 5, it will now create a fresh **local** regular file at `~/.pi/agent/AGENTS.md` — safe.)

Do not commit yet; the install.sh change in Task 3 is committed together with this in Task 4.

---

### Task 3: Make `~/.pi/agent/AGENTS.md` a machine-local file in `install.sh`

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Add the `seed_local_pi_agents` function**

Insert this function immediately after the end of `seed_local_zshenv()` (after its closing `}`, currently `install.sh:294`):

```bash
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
```

- [ ] **Step 2: Call it from `main`**

Find the call site (currently `install.sh:311-312`):

```bash
# Ensure ~/.zshenv is a machine-local file sourcing the shared env (see above).
seed_local_zshenv
```

Replace with:

```bash
# Ensure ~/.zshenv is a machine-local file sourcing the shared env (see above).
seed_local_zshenv

# Ensure ~/.pi/agent/AGENTS.md is a machine-local file (see above) so pi-config
# can never write through it into the repo.
seed_local_pi_agents
```

- [ ] **Step 3: Verify DRY_RUN output looks right**

Run: `DRY_RUN=1 ./install.sh insta-laptop 2>&1 | grep -i 'pi/agent'`
Expected output contains both:
- `Would link: <home>/.pi/agent/APPEND_SYSTEM.md -> <repo>/shared/.pi/agent/APPEND_SYSTEM.md`
- `Would seed local ~/.pi/agent/AGENTS.md (machine-local; pi-config overwrites it here)`
and contains NO line matching `Would link: <home>/.pi/agent/AGENTS.md ->`.

---

### Task 4: Verify green and commit Phase 1 repo changes

- [ ] **Step 1: Run the full test suite to verify it PASSES**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: `ok - dotfiles bootstrap checks passed`

> If it fails on `shared/AGENTS.md is missing: You are an experienced...`, that's the working-tree clobber — restore it first (Task 5 Step 1 can be pulled forward), then re-run.

- [ ] **Step 2: Commit install.sh + repo file moves**

```bash
git add install.sh shared/.pi/agent/APPEND_SYSTEM.md
git commit -m "fix: stop pi-config from overwriting the personal AGENTS.md

Make ~/.pi/agent/AGENTS.md a machine-local file (seed_local_pi_agents) and
deliver personal content to Pi via ~/.pi/agent/APPEND_SYSTEM.md, so pi-config's
overwrite can no longer follow the symlink chain into shared/AGENTS.md.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

> The `git rm shared/.pi/agent/AGENTS.md` from Task 2 is already staged; this commit includes that deletion. Confirm with `git show --stat HEAD` that the commit touches only `install.sh`, `shared/.pi/agent/APPEND_SYSTEM.md`, and the deleted `shared/.pi/agent/AGENTS.md` — NOT `shared/AGENTS.md`.

---

### Task 5: Restore the personal prompt and deploy on the work machine

> Run these on the actual work machine (`./install.sh insta-laptop`). They mutate `$HOME`, not the repo.

- [ ] **Step 1: Restore the personal prompt in the working tree**

```bash
git restore shared/AGENTS.md
git status --short
```
Expected: `git status` is clean for `shared/AGENTS.md` (no `M`). Confirm content:
Run: `head -1 shared/AGENTS.md`
Expected: `You are an experienced, pragmatic software engineer. ...`

- [ ] **Step 2: Apply the fix locally**

```bash
./install.sh insta-laptop
```

- [ ] **Step 3: Verify the live Pi state**

```bash
ls -l "$HOME/.pi/agent/AGENTS.md" "$HOME/.pi/agent/APPEND_SYSTEM.md"
```
Expected: `AGENTS.md` is a regular file (no `->`); `APPEND_SYSTEM.md` is a symlink into the repo (`-> .../shared/.pi/agent/APPEND_SYSTEM.md`).

- [ ] **Step 4: Confirm pi-config can no longer churn the repo**

Trigger pi-config (or wait for its daemon), then:
Run: `git status --short`
Expected: no `M shared/AGENTS.md`. Optionally confirm pi-config wrote locally:
Run: `head -1 "$HOME/.pi/agent/AGENTS.md"`
Expected: `# Instacart Engineering` (boilerplate, now contained locally) or the seed comment — either is fine.

---

# Phase 2 — Claude work-device overlay

### Task 6: Add failing tests for the work-device Claude overlay

**Files:**
- Modify: `tests/dotfiles_bootstrap_test.sh`

- [ ] **Step 1: Assert the overlay links in `with_explicit_work_devices`**

In `with_explicit_work_devices()`, find the insta-laptop assertions (currently end around `tests/dotfiles_bootstrap_test.sh:104`, after the `.zshrc` check) and add, right after the insta-laptop `.zshrc` assertion block:

```bash
    [[ "$output" == *"Would link: $temp_home/.claude/CLAUDE.md -> $ROOT_DIR/devices/insta-laptop/.claude/CLAUDE.md"* ]] ||
        fail "insta-laptop install did not override CLAUDE.md with the work overlay"
    [[ "$output" == *"Would link: $temp_home/.claude/instacart-work-context.md -> $ROOT_DIR/devices/insta-laptop/.claude/instacart-work-context.md"* ]] ||
        fail "insta-laptop install did not link the curated work-context overlay"
```

Then find the bento assertions (currently end around `tests/dotfiles_bootstrap_test.sh:114`, after the `080_fzf.zsh` check) and add, right after the bento `080_fzf.zsh` assertion block:

```bash
    [[ "$output" == *"Would link: $temp_home/.claude/CLAUDE.md -> $ROOT_DIR/devices/bento/.claude/CLAUDE.md"* ]] ||
        fail "bento install did not override CLAUDE.md with the work overlay"
    [[ "$output" == *"Would link: $temp_home/.claude/instacart-work-context.md -> $ROOT_DIR/devices/bento/.claude/instacart-work-context.md"* ]] ||
        fail "bento install did not link the curated work-context overlay"
```

- [ ] **Step 2: Add static content assertions**

Immediately after the repo-policy assertions added in Task 1 Step 3 (before `assert_path_not_exists "$ROOT_DIR/shared/.zshenv"`), insert:

```bash
# Work-device Claude overlay: personal first (@AGENTS.md), curated company facts second.
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/CLAUDE.md" '@AGENTS.md'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/CLAUDE.md" '@instacart-work-context.md'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/instacart-work-context.md" 'aigateway.instacart.tools'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/instacart-work-context.md" 'isc-web'
assert_file_contains "$ROOT_DIR/devices/bento/.claude/CLAUDE.md" '@AGENTS.md'
assert_file_contains "$ROOT_DIR/devices/bento/.claude/CLAUDE.md" '@instacart-work-context.md'
# bento's overlay is a symlink to insta-laptop's canonical copy; grep follows it.
assert_file_contains "$ROOT_DIR/devices/bento/.claude/instacart-work-context.md" 'aigateway.instacart.tools'
```

- [ ] **Step 3: Run the test suite to verify it FAILS**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: FAIL with `devices/insta-laptop/.claude/CLAUDE.md is missing: @AGENTS.md` (the device files don't exist yet).

- [ ] **Step 4: Commit the failing tests**

```bash
git add tests/dotfiles_bootstrap_test.sh
git commit -m "test: assert curated work-device Claude overlay

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: Create the work-device Claude overlay files

**Files:**
- Create: `devices/insta-laptop/.claude/CLAUDE.md`
- Create: `devices/insta-laptop/.claude/instacart-work-context.md`
- Create: `devices/bento/.claude/CLAUDE.md`
- Create: `devices/bento/.claude/instacart-work-context.md` (symlink)

- [ ] **Step 1: Create the insta-laptop CLAUDE.md override**

Create `devices/insta-laptop/.claude/CLAUDE.md` with exactly this content:

```markdown
@AGENTS.md
@instacart-work-context.md
```

- [ ] **Step 2: Create the canonical curated overlay**

Create `devices/insta-laptop/.claude/instacart-work-context.md` with exactly this content:

```markdown
# Instacart Work Context

Supplementary context for work devices. Personal instructions in `~/.claude/AGENTS.md` take precedence; this only adds company facts.

## AI Gateway

All LLM requests route through the Instacart AI Gateway at `aigateway.instacart.tools` (per-user attribution, cost tracking, security monitoring).

## Key Repositories

- `isc-web` — main web monorepo (React, Next.js, Chakra UI)
- `ava` — backend API (Go, Python)
- `opencode-config` — OpenCode configuration
- `pi-config` — Pi configuration
```

- [ ] **Step 3: Create the bento CLAUDE.md override (identical imports)**

Create `devices/bento/.claude/CLAUDE.md` with exactly this content:

```markdown
@AGENTS.md
@instacart-work-context.md
```

- [ ] **Step 4: Point bento's overlay at the canonical copy (single source of truth)**

```bash
ln -s ../../insta-laptop/.claude/instacart-work-context.md devices/bento/.claude/instacart-work-context.md
```

- [ ] **Step 5: Verify the symlink resolves**

Run: `cat devices/bento/.claude/instacart-work-context.md | head -1`
Expected: `# Instacart Work Context`

- [ ] **Step 6: Run the test suite to verify it PASSES**

Run: `bash tests/dotfiles_bootstrap_test.sh`
Expected: `ok - dotfiles bootstrap checks passed`

- [ ] **Step 7: Commit Phase 2**

```bash
git add devices/insta-laptop/.claude devices/bento/.claude
git commit -m "feat: curated work-device Claude overlay (AI Gateway + key repos)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 8: Deploy and verify the overlay on the work machine

> Run on the work machine.

- [ ] **Step 1: Apply**

```bash
./install.sh insta-laptop
```

- [ ] **Step 2: Verify Claude sees personal + overlay**

```bash
ls -l "$HOME/.claude/CLAUDE.md" "$HOME/.claude/instacart-work-context.md"
cat "$HOME/.claude/CLAUDE.md"
```
Expected: `~/.claude/CLAUDE.md` → `devices/insta-laptop/.claude/CLAUDE.md`, content shows the two `@import` lines; `~/.claude/instacart-work-context.md` resolves to the curated facts. In a new Claude session the system prompt should contain both the personal prompt and `aigateway.instacart.tools`.

---

## Out of scope — deferred with rationale (not placeholders)

The approved spec listed Gemini and Amp as overlay targets "to re-confirm during planning." Planning revealed they are not cheap or safe to wire for two facts, so they are **deferred**. Both already receive the **personal** prompt today via their existing symlinks to `shared/AGENTS.md`; only the curated 2-fact overlay is deferred.

- **Gemini:** Adding a second context file requires setting `context.fileName` (confirmed real in the installed CLI) in `~/.gemini/settings.json`. Gemini writes that file at runtime, so symlinking it into the repo would recreate the exact write-through churn this plan eliminates. Doing it safely needs a real local `settings.json` deep-merged from a device source — but `install.sh`'s merge only sources from `shared/`, not `devices/<dev>/`. That is a separate install.sh feature, not justified by two facts.
- **Amp:** Not installed on this host (`which amp` finds nothing), so its secondary instruction-file location cannot be verified. Per the "never invent technical details" rule, wiring is deferred until it can be confirmed on a machine where Amp is installed.
- **Codex:** Already decided in the spec — personal only; no clean second-file global channel.

If these are wanted later, each is an independent follow-up: (Gemini) add device-source merge support to `install.sh`, then a merged `~/.gemini/settings.json`; (Amp) verify the read location, then a device-linked overlay file.

## Self-review

- **Spec coverage:** Component A (restore + canonical) → Task 5 Step 1 + repo-policy assertions. Component B (break Pi chain) → Tasks 1–4. Component C (curated overlay) → Phase 2 for Claude; Gemini/Amp explicitly deferred with rationale (documented deviation). Component D (regression guard) → Task 1 Step 3 assertions + `with_local_pi_agents`.
- **Placeholder scan:** none — every step has concrete code/commands and expected output.
- **Type/name consistency:** `seed_local_pi_agents` defined (Task 3) and called (Task 3 Step 2) and asserted (Task 1 message `Would seed local ~/.pi/agent/AGENTS.md`); `instacart-work-context.md` and the two `@import` names match across Tasks 6–7; `APPEND_SYSTEM.md` target `../../AGENTS.md` matches between Task 2 and the Task 1 assertion.
