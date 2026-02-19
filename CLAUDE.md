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
- `~/.zshrc` - device-specific config. NOT tracked. Sources `~/.zshrc.common`. Sets `DEVICE_PLUGINS` array before sourcing to add device-specific OMZ plugins.
- Always back up `~/.zshrc` before modifying (it's untracked, so no git safety net)
