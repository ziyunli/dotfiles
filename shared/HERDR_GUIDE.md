# Herdr Guide

This guide documents the shared [herdr](https://herdr.dev) configuration in `shared/.config/herdr/config.toml`, which is symlinked to `~/.config/herdr/config.toml` by `install.sh`. Herdr is a terminal workspace manager for AI coding agents; this config mirrors the tmux muscle memory in `shared/.tmux.conf`.

## Config philosophy

Only herdr defaults that differ from the tmux bindings are set; every unset key keeps its herdr default (see `herdr --default-config`). The config sets four keys:

| Key | Value | Herdr default |
| --- | --- | --- |
| `prefix` | `ctrl+a` | `ctrl+b` |
| `split_vertical` | `prefix+\|` | `prefix+v` |
| `reload_config` | `prefix+r` | `prefix+shift+r` |
| `resize_mode` | `prefix+shift+r` | `prefix+r` |

`reload_config` and `resize_mode` are swapped so `prefix r` reloads (matching tmux), and `split_vertical` moves to `prefix |` so a vertical split is side-by-side like tmux's `bind |`.

## Reloading and validating config

- `prefix r` reloads `config.toml` in the running session.
- `herdr server reload-config` reloads it from the CLI.
- `herdr config check` validates the file and prints diagnostics.
- `herdr config reset-keys` backs up `config.toml` and removes custom keybindings.

## Agent integrations

Herdr shows each agent pane's state via a per-agent hook installed with `herdr integration install <agent>`. The states are `idle`, `working`, `blocked`, `done`, and `unknown` (the canonical list is the `--until` values in `herdr agent wait --help`). `blocked` means the agent is waiting on input — it is the state the sidebar exists to surface, and the one screen detection is worst at, since a blocked agent and an idle one often look identical on screen. This is **separate** from installing the agent CLI itself (e.g. via `gohan`): the CLI lets you run the agent in a pane; the integration hook lets herdr track it.

The integrations this repo expects are `claude`, `pi`, `opencode`, and `codex` — the four agent CLIs installed across these machines. Hook state is per-machine, so `herdr integration status` is the only authority on what is actually installed here; it lists every supported agent with its hook path and version. Remove one with `herdr integration uninstall <agent>`.

The hook scripts themselves live in each agent's own config dir, **not** in this repo, so they are not tracked here — reinstall them on a new machine with `herdr integration install`. Each agent gets a hook script (`herdr integration status` prints the exact path): `~/.claude/hooks/herdr-agent-state.sh`, `~/.pi/agent/extensions/herdr-agent-state.ts`, `~/.config/opencode/plugins/herdr-agent-state.js`, and `~/.codex/herdr-agent-state.sh`. `codex` additionally registers the hook in `~/.codex/hooks.json` and touches `~/.codex/config.toml`.

**`herdr integration install claude` dirties this repo.** It registers the `SessionStart` hook in `~/.claude/settings.json`, which is a symlink to `shared/.claude/settings.json` — so the install shows up as an uncommitted change here. Two things to check after running it:

- It writes the hook command as an **absolute** path (`/Users/<user>/.claude/hooks/...`). That breaks the `shared/` contract of working on all machines, so rewrite it to `~/.claude/hooks/herdr-agent-state.sh` (the `statusLine` entry in the same file is the precedent). Re-verify with `herdr integration status` — it resolves the hook by path on disk, not by the settings entry, so the tilde form still reports `current`.
- It writes minified JSON into an otherwise pretty-printed file; reformat to match.

Re-check both after any `herdr update`, since a reinstall may reintroduce them.

## Launching

- `herdr` launches or attaches the persistent session.
- `herdr --session <name>` uses or creates a named session.
- `herdr status` shows client and server status; `herdr server stop` stops the background server.
- `herdr --remote <ssh-target>` attaches through SSH to a remote herdr server.

## Keybindings

All bindings require the prefix (`Ctrl-a`) first, unless noted. This is the effective set from `herdr --default-config` plus the four overrides above.

### App / session

| Binding | Action |
| --- | --- |
| `C-a ?` | In-app help (key list) |
| `C-a s` | Settings |
| `C-a q` | Detach |
| `C-a r` | Reload config *(override; default `C-a R`)* |
| `C-a o` | Open notification target |
| `C-a g` | Navigate / goto overlay |
| `C-a b` | Toggle sidebar |

### Tabs

| Binding | Action |
| --- | --- |
| `C-a c` | New tab |
| `C-a T` | Rename tab |
| `C-a p` / `C-a n` | Previous / next tab |
| `C-a 1..9` | Jump to tab 1–9 |
| `C-a X` | Close tab |

### Panes

| Binding | Action |
| --- | --- |
| `C-a h/j/k/l` | Focus pane left/down/up/right |
| `C-a Tab` / `C-a S-Tab` | Cycle panes forward / back |
| `C-a \|` | Split vertical (side-by-side) *(override; default `C-a v`)* |
| `C-a -` | Split horizontal (top/bottom) |
| `C-a x` | Close pane |
| `C-a z` | Zoom / fullscreen pane |
| `C-a R` | Resize mode *(override; default `C-a r`)* |
| `C-a P` | Rename pane |
| `C-a e` | Edit scrollback |

### Workspaces and git worktrees

| Binding | Action |
| --- | --- |
| `C-a w` | Workspace picker |
| `C-a N` | New workspace |
| `C-a W` | Rename workspace |
| `C-a D` | Close workspace |
| `C-a G` | New git worktree |

### Navigate mode (no prefix; active while the `C-a g` overlay is open)

| Binding | Action |
| --- | --- |
| `↑` / `↓` | Move workspace up / down |
| `h/j/k/l` (or arrows) | Move between panes |

### Unset by default

These actions exist but are unbound in the default config, so they are not active here: previous/next workspace, previous/next agent, indexed `focus_agent` / `switch_workspace`, `last_pane`, and open/remove worktree. Bind them in `config.toml` if wanted (see `herdr --default-config`). Custom command bindings (e.g. a `lazygit` popup) are also supported via a `[[keys.command]]` block.

## Notes for tmux muscle memory

- Detach is `C-a q`, not `C-a d` (unbound in herdr).
- Bare `C-a` (beginning-of-line) is shadowed inside panes — herdr has no `send-prefix`, unlike tmux's `bind C-a send-prefix`.
- Workspaces and git worktrees have no tmux equivalent; they provide the per-agent isolation that is herdr's main advantage over tmux.
- `herdr --skill` prints instructions for driving herdr from inside a pane via its socket API (for an agent to open panes, tabs, etc.).
