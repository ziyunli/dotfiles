# Tmux Guide

This guide documents the shared tmux configuration in `shared/.tmux.conf`, which is symlinked to `~/.tmux.conf` by `install.sh`.

## Reloading config

Use `prefix r` (with this config, `prefix` is `C-a`) to reload the file. Some options are server-only (notably `set-clipboard`) and require a full server restart to take effect.

## Terminal and clipboard

- Default terminal is set to `tmux-256color` when available, otherwise `screen-256color`.
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

- Mouse support enabled.
- Prefix key is `C-a`; `C-b` is unbound.
- `escape-time` set to `1` for snappier prefix handling.
- Window and pane indices start at `1`.

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
