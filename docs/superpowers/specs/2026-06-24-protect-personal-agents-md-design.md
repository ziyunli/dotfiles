# Protect the personal AGENTS.md from company tooling

- **Date:** 2026-06-24
- **Status:** Approved (design); pending implementation plan
- **Scope:** dotfiles repo (`~/.dotfiles`) — `install.sh`, `shared/.pi/`, `devices/<work>/`, `tests/`

## Problem

The personal global AI prompt is being overwritten by Instacart company tooling.
As of this writing the live damage is observable: tools load
`# Instacart Engineering` boilerplate instead of the personal prompt, and
`git status` shows `M shared/AGENTS.md` (the personal content survives only in
`HEAD`).

### Root cause (verified)

1. All five AI tools resolve their instruction file to a **single real file**,
   `shared/AGENTS.md`, through symlink chains:
   - `shared/.claude/AGENTS.md -> ../AGENTS.md`
   - `shared/.codex/AGENTS.md -> ../AGENTS.md`
   - `shared/.config/amp/AGENTS.md -> ../../AGENTS.md`
   - `shared/.gemini/GEMINI.md -> ../AGENTS.md`
   - `shared/.pi/agent/AGENTS.md -> ../../AGENTS.md`
2. The only writer is `@instacart/pi-config` (installed under
   `~/.config/gohan/tools/pi-config/.../dist/config.js`). Its `syncAgents()`
   does a full `fs.writeFileSync(~/.pi/agent/AGENTS.md, <bundled boilerplate>,
   {mode: 0o600})`. It writes **only** `~/.pi/agent/AGENTS.md` — no other tool
   path.
3. `~/.pi/agent/AGENTS.md` is a symlink into the repo
   (`-> shared/.pi/agent/AGENTS.md -> ../../AGENTS.md`). The OS follows the chain
   on write, so pi-config's overwrite lands in `shared/AGENTS.md` — poisoning all
   five tools at once, because they all read through to that same backing file.

So one writer, writing one file, clobbers everything. The fix targets the
**writer's path**, not the five readers.

## Decisions (from brainstorming)

- **Personal prompt is primary.** It loads first and is never replaced. Company
  content may only supplement it.
- **All five tools** stay in scope: Claude Code, Codex, Gemini CLI, Amp, Pi.
- **Curate, don't inherit.** Personal loads everywhere. Only the genuinely useful
  company facts (AI Gateway URL + key-repo list) are pulled into a
  **work-device-only** overlay the user controls, so they reach tools that never
  receive pi-config's write (notably Claude). The generic boilerplate is dropped.
  Pi's locally-written boilerplate is left in place as harmless.
- **Work devices:** `insta-laptop`, `bento`. **Personal devices:** `popos`,
  `Ziyuns-M5-MacBook-Pro`, `Ziyuns-Mac-mini`, `Ziyuns-MBP`.

## Goals / Non-goals

**Goals**
- Personal prompt loads in all five tools, on all devices, as primary content.
- `pi-config` can never again write through to a tracked repo file.
- Zero repo churn from any tool on any device.
- Curated company facts (AI Gateway URL + repo list) reach the non-Pi tools that
  have a clean load channel (guaranteed for Claude) on work devices.
- A regression test fails loudly if the clobber returns.

**Non-goals**
- Disabling or patching `pi-config` (it is vendored/managed; we defang its reach
  instead of fighting it).
- Carrying the full company boilerplate into the non-Pi tools.
- Giving Codex the curated overlay (see Component C — deliberate omission).

## Design

### Component A — Canonical source (unchanged design, restored content)

`shared/AGENTS.md` remains the single source of truth for the **personal**
prompt. Implementation step one restores it from `HEAD`
(`git restore shared/AGENTS.md`).

The four read-only tools keep their existing symlinks straight to
`shared/AGENTS.md`. No change is needed to Claude/Codex/Gemini/Amp wiring for
*personal* content — once Component B stops the overwrite, they recover
automatically with zero churn.

### Component B — Break the Pi write-through chain (core fix)

Make the path pi-config writes a **real machine-local file**, and deliver
personal content to Pi through a channel pi-config never touches.

```
BEFORE:  ~/.pi/agent/AGENTS.md ──(symlink chain)──> shared/.pi/agent/AGENTS.md ─> shared/AGENTS.md   ⟸ clobbered
AFTER:   ~/.pi/agent/AGENTS.md        = real local file          ⟸ pi-config overwrites a throwaway
         ~/.pi/agent/APPEND_SYSTEM.md = symlink -> shared/AGENTS.md   ⟸ personal reaches Pi
```

Repo changes:
- **Delete** `shared/.pi/agent/AGENTS.md` (it exists only to feed the chain; with
  personal delivered via append it is no longer needed). This also stops
  `link_directory` from recreating the `~/.pi/agent/AGENTS.md` repo symlink.
- **Add** `shared/.pi/agent/APPEND_SYSTEM.md -> ../../AGENTS.md`. `install.sh`
  links this to `~/.pi/agent/APPEND_SYSTEM.md`. Nothing writes `APPEND_SYSTEM.md`,
  so keeping it as a repo symlink is safe.

New `install.sh` function `seed_local_pi_agents()` (mirrors the proven
`seed_local_zshenv`, `install.sh:245`), called from `main` alongside it:
- If `~/.pi/agent/AGENTS.md` is a repo symlink (or dangling toward the deleted
  repo file), replace it with a **real local file** so pi-config's next overwrite
  stays local. Seed content is a short comment (pi-config overwrites it on work
  devices; on personal devices it stays as the harmless seed or absent).
- Idempotent across the same three states `seed_local_zshenv` handles: repo
  symlink → replace; existing local file → leave; absent → create.

Why `APPEND_SYSTEM.md` and not `SYSTEM.md`: Pi's `SYSTEM.md` **overrides** the
entire system prompt (`resource-loader.js` `discoverSystemPromptFile`, ~line 754),
which would discard Pi's own built-in agent instructions. `APPEND_SYSTEM.md` is
**appended** to the default prompt (`discoverAppendSystemPromptFile`, global path
at `resource-loader.js:765`), so personal content supplements rather than
replaces. Pi also loads `~/.pi/agent/AGENTS.md` as a global *context* file
(`loadContextFileFromDir`, `resource-loader.js:52`); leaving the company
boilerplate there is the intended harmless supplement.

Net: Pi shows company boilerplate (local context file) **plus** personal
(system-prompt append); the other four tools see personal only; `shared/AGENTS.md`
is unreachable by any writer.

### Component C — Curated work-device overlay

One tracked overlay file holds only the useful facts: **AI Gateway URL**
(`aigateway.instacart.tools`) and the **key-repo list** (`isc-web`, `ava`,
`opencode-config`, `pi-config`). It is linked into `$HOME` **only on `insta-laptop`
and `bento`** via the existing `devices/<host>/` override mechanism — no new
`install.sh` machinery. To avoid drift between the two work devices, the canonical
overlay content lives once and both work-device dirs reference it (exact dedup
mechanism — shared backing file vs. duplicated file — is an implementation detail
for the plan).

Loaded *after* personal by each tool:

| Tool   | Channel                                                                 | Confidence                              |
|--------|------------------------------------------------------------------------|-----------------------------------------|
| Claude | `devices/<work>/.claude/CLAUDE.md` imports `@AGENTS.md` + the overlay   | **Proven** — guaranteed target          |
| Gemini | `contextFileName` array in merged `settings.json` includes the overlay  | Verified earlier; re-confirm in plan    |
| Amp    | overlay placed at Amp's second read location (`~/.config/AGENTS.md`)    | Verified earlier; re-confirm in plan    |
| Pi     | already carries the facts via pi-config's local boilerplate             | No extra wiring                         |
| Codex  | only one global channel (`~/.codex/AGENTS.md`) — no clean 2nd-file hook | **Omitted** (see below)                 |

Because the overlay file always exists on work devices (device-override), Claude's
`@import` never references a missing file — there is no missing-import edge case.

**Codex — deliberate omission.** Codex's only verified global instruction file is
`~/.codex/AGENTS.md`, which we keep symlinked to personal. Adding the overlay would
require a work-device-only *local concatenated* file (personal + overlay), losing
auto-sync from `shared/AGENTS.md`. For two facts that is not worth the drift, so
**Codex gets personal only**. Revisit if a verified second-file channel appears.

### Component D — Regression guard

Extend `tests/dotfiles_bootstrap_test.sh` (same spirit as the existing
no-gohan-in-tracked-files policy):
1. Assert `shared/AGENTS.md` is a regular file whose content is the **personal**
   prompt and is **not** the `# Instacart Engineering` boilerplate. Catches a
   re-clobber that lands in the repo.
2. Assert no tracked file is reachable as a pi-config write target —
   specifically that `~/.pi/agent/AGENTS.md` does **not** resolve into the repo
   (it must be a regular local file, not a repo symlink).

## Data flow / load order

Everywhere: **personal first, curated overlay second** (supplement, never
replace). Pi realizes this via two channels (personal in the appended system
prompt; company boilerplate as a context file). The four non-Pi tools load
personal via their existing symlink to `shared/AGENTS.md`; on work devices they
additionally load the overlay after it.

## Error handling

- `seed_local_pi_agents()` is idempotent and handles repo-symlink / existing-local
  / absent states, exactly like `seed_local_zshenv`. A dangling symlink left by
  deleting `shared/.pi/agent/AGENTS.md` is treated as the repo-symlink case and
  replaced.
- pi-config failures are irrelevant to the repo after the fix: its writes land on
  a local file (`~/.pi/agent/AGENTS.md`) or non-destructive merges
  (`settings.json`, `models.json`).
- Personal devices without Pi installed: `~/.pi/agent/` may be absent; the seed
  and the `APPEND_SYSTEM.md` link are no-ops or create a harmless local file —
  nothing is required there.

## Implementation surface

- **New code:** `seed_local_pi_agents()` in `install.sh` (+ its call in `main`).
- **Repo file moves:** delete `shared/.pi/agent/AGENTS.md`; add
  `shared/.pi/agent/APPEND_SYSTEM.md -> ../../AGENTS.md`.
- **Restore:** `git restore shared/AGENTS.md`.
- **Overlay:** one tracked overlay file referenced from `devices/insta-laptop/`
  and `devices/bento/`; per-tool wiring (Claude `CLAUDE.md`, Gemini
  `settings.json` via `.dotfiles-merge`, Amp `~/.config/AGENTS.md`).
- **Test:** new assertions in `tests/dotfiles_bootstrap_test.sh`.
- **Reused mechanisms (no new code):** device overrides, `.dotfiles-merge`,
  obsolete-link handling.

## Open items (resolve during planning)

- Confirm Gemini's `contextFileName` key shape (array) against the live Gemini CLI
  config before wiring.
- Confirm Amp's secondary read location (`~/.config/AGENTS.md`) against the live
  Amp build before wiring.
- Choose the overlay dedup mechanism (shared backing file referenced by both work
  device dirs vs. duplicated two-fact file).

## Verification (post-implementation)

1. Run `DRY_RUN=1 ./install.sh insta-laptop` and confirm the planned link/seed
   actions.
2. After a real install, confirm `~/.pi/agent/AGENTS.md` is a regular file and
   `~/.pi/agent/APPEND_SYSTEM.md -> .../shared/AGENTS.md`.
3. Trigger / wait for a pi-config run; confirm `git status` in the repo stays
   clean (no `M shared/AGENTS.md`).
4. Confirm Claude on a work device sees personal prompt + curated overlay.
5. `tests/dotfiles_bootstrap_test.sh` passes and fails when the clobber is
   simulated.
