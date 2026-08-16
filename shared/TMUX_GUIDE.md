# Tmux Guide

This guide documents the shared tmux configuration in `shared/.tmux.conf`, which is symlinked to `~/.tmux.conf` by `install.sh`.

## Reloading config

Use `prefix r` (with this config, `prefix` is `C-a`) to reload the file. Some options are server-only (notably `set-clipboard`) and require a full server restart to take effect.

## Terminal and clipboard

- Default terminal is set to `tmux-256color` when available, otherwise `screen-256color`.
- Extended keys use CSI-u format so modified keys such as Shift-Enter work in terminal apps that expect it.
- OSC52 clipboard integration is enabled via `set -s set-clipboard on`.
- `allow-passthrough` is enabled when supported (requires tmux 3.3+; no-op otherwise).

## Status line and colors

- Status bar uses a black background with colored window lists and pane borders.
- Left status shows session, window, and pane: `Session: #S #I #P`.
- Right status shows date/time: `%d %b %R`.
- Status updates every 60 seconds and centers the window list.
- Activity monitoring is enabled (`monitor-activity` + `visual-activity`).
- Popups use a high-contrast palette: white text on black with a yellow border.

## Behavior defaults

- Ghostty opens a plain shell; tmux is launched on demand (`tm` attaches or creates session `main`).
- Mouse support enabled.
- Prefix key is `C-a`; `C-b` is unbound.
- `escape-time` set to `1` for snappier prefix handling.
- Window and pane indices start at `1`.

## Ghostty and on-demand tmux

Ghostty opens a plain interactive shell — it no longer auto-starts tmux. Launch a persistent session yourself with `tm` (an alias for `tmux new-session -A -s main`, defined in `shared/.zshrc.common`) or plain `tmux`. This keeps tmux and [herdr](HERDR_GUIDE.md) from nesting: both bind the same `C-a` prefix, so run whichever multiplexer you want in a fresh Ghostty window instead of stacking one inside the other.

Ghostty shell integration is still sourced from `shared/.zshrc.common` when Ghostty exposes its resources directory. Ghostty only auto-injects integration into direct child shells; tmux-created shells need the manual source so prompt marks, title updates, and Ghostty's SSH helpers still work.

The tmux `update-environment` list includes Ghostty variables such as `GHOSTTY_RESOURCES_DIR`, `GHOSTTY_SHELL_FEATURES`, and `GHOSTTY_BIN_DIR`. That lets panes created from an existing tmux server see Ghostty integration metadata after a new Ghostty client attaches.

## Keybindings

| Binding | Action |
| --- | --- |
| `C-a r` | Reload config |
| `C-a C-a` | Send literal `C-a` to the app |
| `C-a |` | Split pane horizontally |
| `C-a -` | Split pane vertically |
| `C-a h/j/k/l` | Move between panes |
| `C-a C-h` | Previous window |
| `C-a C-l` | Next window |
| `C-a H/J/K/L` | Resize pane (5 cells) |
| `M-p` | Popup file picker (see below) |

## Popup file picker (`M-p`)

`M-p` opens a `tmux display-popup` file picker rooted at the current pane path.

- Uses `fd` to list files and `fzf` for selection.
- `ctrl-g` toggles `fd --no-ignore` with a `no-ignore>` prompt.
- `ctrl-h` restores the default `fd` search with a `>` prompt.
- Preview window is shown on the right; `bat` is used when available with a `cat` fallback.
- The selected path is typed into the active pane (no automatic Enter).
