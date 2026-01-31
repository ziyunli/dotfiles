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

## Installation

### New System

```bash
git clone git@github.com:ziyunli/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

If your hostname doesn't match a device folder:
```bash
~/.dotfiles/install.sh <device-name>
```

### Migrating from Bare Repo

```bash
curl -fsSL https://raw.githubusercontent.com/ziyunli/dotfiles/main/migrate.sh | bash -s -- <device-name>
```

Or manually:
```bash
git clone git@github.com:ziyunli/dotfiles.git ~/.dotfiles-new
~/.dotfiles-new/install.sh <device-name>
mv ~/.dotfiles ~/.dotfiles.bare-backup
mv ~/.dotfiles-new ~/.dotfiles
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

## Usage

Edit files in `shared/` for changes that should apply everywhere.
Edit files in `devices/<hostname>/` for machine-specific changes.

Changes take effect immediately (files are symlinked).

## Adding a New Device

1. Create `devices/<hostname>/` directory
2. Add device-specific dotfiles
3. Run `./install.sh <hostname>`

## MCP

From https://github.com/obra/private-journal-mcp:

```bash
claude mcp add-json private-journal '{"type":"stdio","command":"npx","args":["github:obra/private-journal-mcp"]}' -s user
```
