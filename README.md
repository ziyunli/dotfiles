# Dotfiles

Personal dotfiles managed with a single-branch structure. Shared configuration lives in `shared/`, device-specific configuration lives in `devices/<hostname>/`.

## Structure

```
dotfiles/
├── shared/           # Configuration shared across all machines
│   ├── .gitconfig    # Base git config (includes ~/.gitconfig.local)
│   ├── .tmux.conf
│   ├── TMUX_GUIDE.md # Tmux configuration guide
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

## Dependencies

The shared configuration expects certain tools to be installed. These are optional—the config guards against missing tools—but for full functionality:

### FZF (Fuzzy Finder)

Install via git (preferred method for consistent shell integration):

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

This creates `~/.fzf.zsh` which is sourced by `shared/.zshrc.common`.

### Agkozak ZSH Prompt

Oh-my-zsh theme used by `shared/.zshrc.common`. Install via git:

```bash
git clone --depth 1 https://github.com/agkozak/agkozak-zsh-theme ~/.oh-my-zsh/custom/themes/agkozak
ln -s ~/.oh-my-zsh/custom/themes/agkozak/agkozak-zsh-prompt.plugin.zsh ~/.oh-my-zsh/custom/themes/agkozak.zsh-theme
```

### Other Tools

- `ncdu` - disk usage analyzer (aliased to `du` if available)
- `htop` - process viewer (aliased to `top` if available)
- `prettyping` - prettier ping with colors (aliased to `ping` if available; **note:** overrides system `ping`)
- `bat` - syntax-highlighted file viewer (used by fzf previews)
- `fd` - fast file finder (used by fzf)
- `eza` - modern `ls` replacement (aliased to `ls` if available)
- `nvim` - Neovim text editor (set as `$EDITOR`)
- `gh` - GitHub CLI (required for `pr-checkout` function)
- `jq` - JSON processor (required for `pr-checkout` function)
- `zoxide` - smarter cd command (oh-my-zsh plugin)
- `tig` - text-mode interface for git (oh-my-zsh plugin)

Install via Homebrew:
```bash
brew install ncdu htop prettyping bat fd eza neovim gh jq zoxide tig
```

### Zsh startup files

Use zsh startup files by responsibility:

- `~/.zprofile.macos` contains macOS login-shell environment shared by personal Apple devices.
- `~/.zprofile` is for login-shell environment inherited by child processes: Homebrew `shellenv`, durable PATH entries, and language or tool paths.
- `~/.zshrc` is for interactive shell behavior: Oh My Zsh, prompt, plugins, completions, aliases, and shell functions.
- Non-login interactive shells such as `zsh -ic '...'` do not read `~/.zprofile`; they inherit PATH from their parent process.

Personal Apple device `.zprofile` files should source `~/.zprofile.macos`. Device-specific `.zshrc` files should set `DEVICE_PLUGINS` before sourcing `~/.zshrc.common`. Avoid adding installer PATH snippets to both `.zprofile` and `.zshrc`; put durable entries in `.zprofile` and keep them idempotent.

### GBrain token for Codex MCP

`~/.zprofile.macos` exports `GBRAIN_REMOTE_TOKEN` from macOS Keychain when a `gbrain-remote-token` item exists. Store or rotate the token with:

```bash
security add-generic-password -a "$USER" -s gbrain-remote-token -w "gbrain_xxx" -U
```

Restart Codex from a new login shell after updating the Keychain item. Keep the token out of repo files, shell history, and process logs.

## Recipes

### Install dotfiles on a new system

```bash
git clone git@github.com:ziyunli/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh              # Uses $(hostname -s) as device name
# or
./install.sh <device>     # Specify device explicitly
```

### Bootstrap a new Mac

Install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Add Homebrew to login shells so `brew` is available after opening a new terminal:

```bash
echo >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

After the dotfiles are installed, personal Apple device `.zprofile` files source the repo-managed `~/.zprofile.macos` for this setup.

Install and authenticate GitHub CLI, then add an SSH key for SSH-based GitHub clones:

```bash
brew install gh
gh auth login
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
gh ssh-key add ~/.ssh/id_ed25519.pub --title "personal laptop"
```

Install Oh My Zsh:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Install the shell dependencies used by `shared/.zshrc.common`:

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

git clone --depth 1 https://github.com/agkozak/agkozak-zsh-theme ~/.oh-my-zsh/custom/themes/agkozak
ln -s ~/.oh-my-zsh/custom/themes/agkozak/agkozak-zsh-prompt.plugin.zsh ~/.oh-my-zsh/custom/themes/agkozak.zsh-theme
```

Then install the dotfiles for the current hostname:

```bash
git clone git@github.com:ziyunli/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
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
mv ~/.dotfiles ~/.dotfiles.bare-backup
mv ~/.dotfiles-new ~/.dotfiles
~/.dotfiles/install.sh <device-name>

# Clean up: remove dotfiles() function from .zshrc/.bashrc
# Then delete backup once verified: rm -rf ~/.dotfiles.bare-backup
```

## Untracked Files

These files are gitignored and must be created/maintained by the user.

### `~/.gitconfig.local` (required)

Personal git settings included by `shared/.gitconfig`. Create from the template:

```bash
cp ~/.dotfiles/.gitconfig.local.example ~/.gitconfig.local
# Then edit with your details
```

```gitconfig
[user]
    name = Your Name
    email = your@email.com

[github]
    user = yourusername

[credential]
    helper = osxkeychain  # or appropriate helper for your OS
```

`install.sh` will remind you if this file is missing.

### `devices/<hostname>/.dotfiles-skip` (optional)

Lists paths from `shared/` that should NOT be symlinked for this device. One path per line, relative to `$HOME`. Lines starting with `#` are comments.

```bash
# Example: devices/bento/.dotfiles-skip
# The company environment manages these directly.
.claude/settings.json
```

Use this when a device manages certain configs externally (e.g., corporate-managed settings) or when a shared config conflicts with device-specific needs.

### `devices/<hostname>/.dotfiles-merge` (optional)

Lists paths from `shared/` that should be **deep-merged** instead of symlinked. One path per line, relative to `$HOME`. Lines starting with `#` are comments.

```bash
# Example: devices/bento/.dotfiles-merge
# Personal settings are merged with existing local (company) config.
.claude/settings.json
```

Use this when a device has its own version of a config file (e.g., company-injected settings) that should be combined with your personal settings. Merge semantics: objects are recursively merged, arrays are unioned, and existing local scalar values take precedence. Conflicts are reported to stderr.

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
