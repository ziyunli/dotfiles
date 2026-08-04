## Dotfiles Repository

Structure:
- `shared/` - config files linked to all machines
- `devices/<hostname>/` - machine-specific config (overrides shared)
- `install.sh` - creates symlinks from repo to $HOME
- `uninstall.sh` - removes symlinks
- `migrate.sh` - one-time migration from bare repo pattern

Shell quirk: zsh has issues with `git show ... > file` redirection. Use `/bin/bash -c '...'` for reliable file redirection.

Device folders use hostnames (`hostname -s`). Check `devices/` for available devices.

Shell config pattern:
- `shared/.zshrc.common` - shared zsh config (OMZ setup, aliases, FZF, functions). Tracked in git, symlinked to `~/.zshrc.common`
- `devices/<dev>/.zshrc.local` - device-specific config. Tracked in git, symlinked to `~/.zshrc.local`. Sets `DEVICE_PLUGINS` array before sourcing `~/.zshrc.common`, then adds machine-specific hooks.
- `~/.zshrc` - machine-local shim. NOT tracked and NOT symlinked; `install.sh` seeds it (see `seed_local_zshrc`) to `source ~/.zshrc.local`. Tools (e.g. Instacart setup) append their own blocks here without churning the repo. Devices that ship a plain `devices/<dev>/.zshrc` instead of `.zshrc.local` fall back to symlinking it directly.
- Always back up `~/.zshrc` before modifying (it's untracked, so no git safety net)
