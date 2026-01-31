## Dotfiles Repository

Structure:
- `shared/` - config files linked to all machines
- `devices/<hostname>/` - machine-specific config (overrides shared)
- `install.sh` - creates symlinks from repo to $HOME
- `uninstall.sh` - removes symlinks
- `migrate.sh` - one-time migration from bare repo pattern

Shell quirk: zsh has issues with `git show ... > file` redirection. Use `/bin/bash -c '...'` for reliable file redirection.

Device folders use hostnames (`hostname -s`). Check `devices/` for available devices.
