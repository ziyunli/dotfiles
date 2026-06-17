# Ghostty Guide

This guide documents the shared Ghostty configuration managed by this repo.

## Config files

Ghostty 1.3 reads `config.ghostty`. On macOS, Ghostty checks:

1. `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
2. `~/.config/ghostty/config.ghostty`

The repo manages both paths:

- `shared/Library/Application Support/com.mitchellh.ghostty/config.ghostty` contains the macOS default settings.
- `shared/.config/ghostty/config.ghostty` contains the XDG default settings.
- `shared/.config/ghostty/config` is a compatibility placeholder for Ghostty releases that read the older XDG filename.

Do not use `config-file` to point one default Ghostty config file at another. Ghostty can load multiple default files during startup, and that indirection can trigger cycle detection.

## Shell integration

`shell-integration = detect` lets Ghostty load integration for supported shells.

`shell-integration-features = cursor,no-sudo,title,ssh-env,ssh-terminfo,path` enables:

- `cursor`: Ghostty can adjust cursor shape at prompts.
- `title`: shells can update the terminal title.
- `ssh-env`: Ghostty wraps `ssh` so remote sessions get truecolor/program metadata and a safe `xterm-256color` fallback.
- `ssh-terminfo`: Ghostty can install and cache `xterm-ghostty` terminfo on remote hosts that do not already have it.
- `path`: Ghostty adds its binary directory to `PATH` when needed.
- `no-sudo`: Ghostty does not wrap `sudo` from shared config.

The zsh config sources Ghostty shell integration manually because auto-started tmux panes are not direct child shells of Ghostty.

## Keyboard

`macos-option-as-alt = left` makes left Option behave as terminal Alt/Meta for readline, zsh, Vim, and tmux. Right Option remains available for macOS character input.

## Clipboard

`clipboard-read = ask` keeps clipboard reads gated by confirmation.

`clipboard-write = allow` lets terminal programs write to the clipboard, including OSC52 copy flows from tmux and SSH sessions.

`copy-on-select = true` keeps the standard terminal behavior where selected text is copied automatically.
