# Dotfiles

Personal dotfiles managed with a single-branch structure. Shared configuration lives in `shared/`, device-specific configuration lives in `devices/<hostname>/`.

## Structure

```
dotfiles/
├── shared/           # Configuration shared across all machines
│   ├── .gitconfig    # Base git config (includes ~/.gitconfig.local)
│   ├── .tmux.conf
│   ├── .myclirc
│   └── ...
├── devices/          # Machine-specific configuration
│   ├── Ziyuns-Mac-mini/
│   ├── bento/
│   ├── m1/
│   └── popos/
├── install.sh        # Create symlinks
├── uninstall.sh      # Remove symlinks
└── migrate.sh        # Migrate from bare repo
```

## Recipes

### Install dotfiles on a new system

```bash
git clone git@github.com:ziyunli/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh              # Uses $(hostname -s) as device name
# or
./install.sh <device>     # Specify device explicitly
```

### Preview what install/uninstall would do

```bash
DRY_RUN=1 ./install.sh
DRY_RUN=1 ./uninstall.sh
```

### Add a new shared config file

```bash
cd ~/.dotfiles
# Add the file to shared/
cp ~/.some-new-config shared/.some-new-config
# Or create it directly
vim shared/.some-new-config

# Link it to $HOME
./install.sh

# Commit
git add shared/.some-new-config
git commit -m "add some-new-config"
```

### Add a device-specific config file

```bash
cd ~/.dotfiles
mkdir -p devices/$(hostname -s)
cp ~/.device-specific-config devices/$(hostname -s)/.device-specific-config

./install.sh

git add devices/
git commit -m "add device-specific config for $(hostname -s)"
```

### Add a new device

```bash
cd ~/.dotfiles
mkdir -p devices/<new-hostname>
# Copy any device-specific files
cp ~/.zshrc devices/<new-hostname>/.zshrc

git add devices/<new-hostname>
git commit -m "add device config for <new-hostname>"
```

### Remove all symlinks (uninstall)

```bash
cd ~/.dotfiles
./uninstall.sh

# Restore backed-up files if needed
ls ~/.dotfiles-backup-*/
cp ~/.dotfiles-backup-*/.some-file ~/
```

### Re-link after pulling changes

```bash
cd ~/.dotfiles
git pull
./install.sh    # Safe to re-run; skips already-correct symlinks
```

### Check which files are linked

```bash
# List all symlinks in $HOME pointing to dotfiles
find ~ -maxdepth 3 -type l -exec sh -c 'readlink "$1" | grep -q "\.dotfiles" && echo "$1 -> $(readlink "$1")"' _ {} \; 2>/dev/null
```

### Migrate from bare repo pattern

If you're using the old bare repo setup (`git --git-dir=$HOME/.dotfiles --work-tree=$HOME`):

```bash
# Option 1: Run migrate script directly
./migrate.sh <device-name>

# Option 2: Manual migration
git clone git@github.com:ziyunli/dotfiles.git ~/.dotfiles-new
~/.dotfiles-new/install.sh <device-name>
mv ~/.dotfiles ~/.dotfiles.bare-backup
mv ~/.dotfiles-new ~/.dotfiles

# Clean up: remove dotfiles() function from .zshrc/.bashrc
# Then delete backup once verified: rm -rf ~/.dotfiles.bare-backup
```

## Post-Install

Create `~/.gitconfig.local` with your personal settings:

```gitconfig
[user]
    name = Your Name
    email = your@email.com

[github]
    user = yourusername

[credential]
    helper = osxkeychain  # or appropriate helper for your OS
```

See `.gitconfig.local.example` in the repo root for more options.

## How It Works

- **install.sh** creates symlinks from `$HOME` to files in the repo
- Files in `shared/` are linked for all devices
- Files in `devices/<hostname>/` are linked only for that device
- Device-specific files override shared files (linked second)
- Existing files are backed up to `~/.dotfiles-backup-<timestamp>/`
- Edit files in the repo; changes take effect immediately (symlinks)

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `install.sh [device]` | Create symlinks to $HOME |
| `uninstall.sh [device]` | Remove symlinks |
| `migrate.sh <device>` | Migrate from bare repo pattern |

All scripts support `DRY_RUN=1` to preview changes.

## MCP

From https://github.com/obra/private-journal-mcp:

```bash
claude mcp add-json private-journal '{"type":"stdio","command":"npx","args":["github:obra/private-journal-mcp"]}' -s user
```
