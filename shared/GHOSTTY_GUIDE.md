# Ghostty Guide

This guide documents the shared Ghostty configuration managed by this repo.

## Config files

Ghostty 1.3 reads `config.ghostty`. On macOS, Ghostty checks:

1. `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
2. `~/.config/ghostty/config.ghostty`

The repo manages the XDG path only:

- `shared/.config/ghostty/config.ghostty` contains the XDG default settings.

`install.sh` removes repo-owned symlinks at the macOS default path and the older
`~/.config/ghostty/config` filename. Ghostty checks the macOS default path before
XDG, so leaving an old symlink there would shadow the canonical config.

Do not use `config-file` to point one default Ghostty config file at another.
Ghostty can load multiple default files during startup, and that indirection can
trigger cycle detection.

## Shell integration

`shell-integration = detect` lets Ghostty load integration for supported shells.

`shell-integration-features = cursor,no-sudo,title,ssh-env,ssh-terminfo,path` enables:

- `cursor`: Ghostty can adjust cursor shape at prompts.
- `title`: shells can update the terminal title.
- `ssh-env`: Ghostty wraps `ssh` so remote sessions get truecolor/program metadata and a safe `xterm-256color` fallback.
- `ssh-terminfo`: Ghostty can install and cache `xterm-ghostty` terminfo on remote hosts that do not already have it.
- `path`: Ghostty adds its binary directory to `PATH` when needed.
- `no-sudo`: Ghostty does not wrap `sudo` from shared config.

The zsh config sources Ghostty shell integration manually because tmux panes are not direct child shells of Ghostty.

## Remote TERM fallback

Ghostty advertises `TERM=xterm-ghostty` and, via the `ssh-terminfo` / `ssh-env`
features above, installs that terminfo (or falls back to `xterm-256color`) on
remotes it opens through its own `ssh` wrapper. Wrappers that bypass that shim --
notably `bento remote ssh` -- forward `xterm-ghostty` to hosts that lack the
terminfo entry, so terminfo lookups during shell startup fail with
`can't find terminal definition for xterm-ghostty`.

The durable fix is a guard in `shared/.zshenv.shared` that swaps an unresolvable
`TERM` for `xterm-256color`:

```zsh
if [[ -o interactive && -n "${TERM:-}" ]] && ! infocmp "$TERM" &>/dev/null; then
  export TERM=xterm-256color
fi
```

It lives in `~/.zshenv` (sourced before `~/.zshrc`) rather than in
`~/.zshrc.common` because `~/.zshrc` sources terminfo-touching init before the
interactive config does. On the bento remote, `~/.shellrc.d/004_devbox.sh` runs
`eval "$(devbox global shellenv)"` before `~/.shellrc.d/005_oh-my-zshrc.zsh`
sources `~/.zshrc.common`, so a guard inside `~/.zshrc.common` would run one file
too late. Setting the fallback in `~/.zshenv` guarantees it precedes every
`~/.zshrc` code path (login shells, tmux panes, `zsh -i`).

To install the real `xterm-ghostty` terminfo on a specific host instead (one
instance only; lost when the box is reprovisioned), run from the Ghostty client:

```sh
infocmp -x xterm-ghostty | ssh <host> -- tic -x -
```

`tic` may print `older tic versions may treat the description field as an alias`
-- a harmless warning; the entry still compiles.

## Keyboard

`macos-option-as-alt = left` makes left Option behave as terminal Alt/Meta for readline, zsh, Vim, and tmux. Right Option remains available for macOS character input.

## Clipboard

`clipboard-read = ask` keeps clipboard reads gated by confirmation.

`clipboard-write = allow` lets terminal programs write to the clipboard, including OSC52 copy flows from tmux and SSH sessions.

`copy-on-select = true` keeps the standard terminal behavior where selected text is copied automatically.
