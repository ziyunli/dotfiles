# Dotfiles

Personal dotfiles managed with a single-branch structure. Shared configuration lives in `shared/`, device-specific configuration lives in `devices/<hostname>/`.

## Structure

```
dotfiles/
├── shared/           # Configuration shared across all machines
│   ├── .gitconfig    # Base git config (includes ~/.gitconfig.local)
│   ├── .tmux.conf
│   ├── TMUX_GUIDE.md # Tmux configuration guide
│   ├── HERDR_GUIDE.md # Herdr configuration guide
│   ├── .myclirc
│   └── ...
├── devices/          # Machine-specific configuration (one dir per `hostname -s`)
│   ├── insta-laptop/
│   ├── bento/
│   ├── Ziyuns-Mac-mini/
│   └── ...
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
- `~/.zshenv` is read by every zsh, including non-interactive `zsh -c '...'`. It is a machine-local, untracked file (seeded by `install.sh`) that sources the repo-managed `~/.zshenv.shared`. Keeping it local lets machine tooling append its own setup without churning this repo; `~/.zshenv.shared` holds env every shell needs (e.g. fzf on PATH for the tmux file-picker popup).
- Non-login interactive shells such as `zsh -ic '...'` do not read `~/.zprofile`; they inherit PATH from their parent process.

Personal Apple device `.zprofile` files should source `~/.zprofile.macos`. Device-specific `.zshrc` files should set `DEVICE_PLUGINS` before sourcing `~/.zshrc.common`. Avoid adding installer PATH snippets to both `.zprofile` and `.zshrc`; put durable entries in `.zprofile` and keep them idempotent.

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

### Install herdr agent integrations

[Herdr](https://herdr.dev) tracks each agent pane's state through a per-agent hook script. Those scripts live in each agent's own config directory and are **not** tracked in this repo, so every machine needs its own copy — install one per agent CLI in use here:

```bash
herdr integration install claude
herdr integration install pi
herdr integration install opencode
herdr integration install codex
```

Run these *after* `./install.sh`, not before: `herdr integration install claude` registers its hook in `~/.claude/settings.json`, which `install.sh` symlinks into this repo. That install dirties the working tree and needs the fixups described in [`shared/HERDR_GUIDE.md`](shared/HERDR_GUIDE.md) — a portable `~` path, the missing-script guard, and pretty-printed JSON.

Hook state is per-machine, so `herdr integration status` is the only authority on what is actually installed here; it lists every supported agent with its hook path and version.

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

## User-Maintained Files

These files are created and maintained by the user. `~/.gitconfig.local` is personal and gitignored (never committed); the per-device `.dotfiles-skip` and `.dotfiles-merge` control files are committed under `devices/<hostname>/`.

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

Lists paths that should be **deep-merged** instead of symlinked. One path per line, relative to `$HOME`. Lines starting with `#` are comments.

```bash
# Example: devices/insta-laptop/.dotfiles-merge
.claude/settings.json
.config/opencode.personal.json
.pi/agent/settings.json
```

For each listed path, `install.sh` composes up to three layers, with later layers winning:

```
shared/<path>  ->  devices/<hostname>/<path>  ->  existing ~/<path>
  (base)             (optional device layer)         (optional local)
```

The result is written as a real file, never a symlink, so an externally-managed local file (e.g. company-injected settings) keeps its own values while your shared and device-specific settings merge in. When no `devices/<hostname>/<path>` fragment exists, this reduces to the original `shared -> local` merge. Merge semantics (`merge-json.sh`): objects merge recursively, arrays union, and scalar conflicts resolve to the later layer; conflicts are reported to stderr.

For example, `.config/opencode.personal.json` is composed from the shared `superpowers` plugin plus a work-device `model` override, then loaded by opencode via `OPENCODE_CONFIG` (exported from `.zshenv.shared`). `.claude/settings.json` has only a shared source, so its device layer is a no-op.

## AI harness configs (Pi and omp)

Both harnesses are tracked with a work/personal split:

| File | Layer | Purpose |
| ---- | ----- | ------- |
| `shared/.pi/agent/settings.json` | shared | Personal base (ChatGPT subscription); no `enabledModels`, so the built-in catalog stays available |
| `devices/<work-host>/.pi/agent/settings.json` | device | Work overlay: Tally gateway `enabledModels` allowlist (merged, arrays union) |
| `shared/.pi/agent/APPEND_SYSTEM.md` | shared | Personal prompt appended to every Pi session (both work and personal) |
| `shared/.omp/agent/config.yml` | shared | Personal omp config: model roles on the built-in `openai/*` ChatGPT catalog |
| `devices/<work-host>/.omp/agent/config.yml` | device | Work omp config: model roles on the internal Tally gateway, baseline-first |
| `devices/Ziyuns-M5-MBP/.omp/agent/config.yml` | device | Personal Gemini-first omp roles; preserves the local theme and web-search order |
| `shared/.omp/agent/APPEND_SYSTEM.md` | shared | Personal prompt appended to every omp session (task subagents don't inherit it) |

Work devices list `.pi/agent/settings.json` in `.dotfiles-merge` (deep-merged: shared base + device allowlist + local). The gateway provider definitions themselves (`~/.omp/agent/models.yml`, `~/.pi/agent/models.json`) and `~/.pi/agent/AGENTS.md` are Instacart-managed and intentionally not tracked.

The work omp model policy separates judgment from execution:

- Frontier lanes (`plan`, `slow`, `advisor`, `designer`): Sol 6.1 / Opus 5.5 — planning, research, review, advising.
- Execution lanes (`default`, `task`, `smol`, `commit`, `tiny`): baseline models — DeepSeek v4.1 Flash first, GLM 5.3 Flash, GPT 6 Luna for judgment-heavy baseline work, GPT 5.6 Luna as last resort.
- General-purpose task agents resolve `modelRoles.task` (with `retry.fallbackChains.task` as fallbacks). Bundled scouts and sonic use `smol`; reviewers use `slow`, unless an agent override is configured. `APPEND_SYSTEM.md` tells both harnesses to keep frontier models out of implementation paths.

On `Ziyuns-M5-MBP`, the device override keeps `google-antigravity/gemini-3.8-flash`
as the default. Gemini also handles `smol` and `memory`;
`ollama/qwen3.5:4b:off` handles `commit` and `tiny`;
`ds4/qwen3.8-flash-next:medium` handles `task`; Sol 6.1 handles `slow`,
`vision`, `designer`, and `advisor`; `anthropic/claude-opus-5-5:xhigh`
handles `plan`. These are provider-specific selectors from the installed omp
catalog, not the shared config's `openai/*` selectors. Credentials stay local.
`./install.sh Ziyuns-M5-MBP` links this override instead of the shared omp config.

The personal device sets `title.generator: tiny` so automatic session titles use
the local `tiny` role rather than a fork of the conversation model. Start Ollama
with the already-installed `qwen3.5:4b` model available; thinking is disabled for
both lightweight roles. No model download is needed on this device. On a fresh
machine, run `ollama pull qwen3.5:4b` before using these roles.

### Local ds4 task workers on the personal device

`devices/Ziyuns-M5-MBP/.local/bin/ds4-serve` is a foreground launcher for
Qwen3.8 Flash Next Q4. `./install.sh Ziyuns-M5-MBP` links it into `~/.local/bin`.
Run `ds4-serve` in one terminal, then use omp in another. Ctrl-C stops the
server and releases its model memory; it is not started at login or by Pi.
The runtime defaults to `~/codebase/ds4` (`DS4_RUNTIME_DIR` overrides it) and
must already be built with `make`. The launcher does not build or download.

Download the pinned, self-contained GGUF without changing the checkout's
existing `ds4flash.gguf` symlink:

```sh
uv tool run --from huggingface-hub==1.24.0 hf download \
  antirez/qwen3.8-flash-next-gguf Qwen3.8-Flash-Next-Q4.gguf \
  --revision d600fe1a43d2e1cdcadb85144ce3142f66f9eefe \
  --local-dir "$HOME/codebase/ds4/gguf"
shasum -a 256 "$HOME/codebase/ds4/gguf/Qwen3.8-Flash-Next-Q4.gguf"
```

Verify SHA-256 `680944460a8cbe93ba8b6d7b6107213ffb7e22320bd913000e563ca0a0f25a8a`
and size `177280286720` bytes before starting the model. Its n-gram table stays
on SSD; main/MTP weights occupy about 69.74 GiB of unified memory, plus runtime
and context buffers.

Merge this provider into the machine-local, untracked `~/.omp/agent/models.yml`;
do not replace existing providers or add the file to dotfiles:

```yaml
providers:
  ds4:
    baseUrl: http://127.0.0.1:8040/v1
    api: openai-responses
    auth: none
    models:
      - id: qwen3.8-flash-next
        name: Qwen3.8 Flash Next Q4 (local ds4)
        reasoning: true
        thinking:
          mode: effort
          efforts: [low, medium, xhigh]
          defaultLevel: medium
          requiresEffort: false
        input: [text]
        contextWindow: 32768
        maxTokens: 8192
        cost:
          input: 0
          output: 0
          cacheRead: 0
          cacheWrite: 0
        compat:
          supportsDeveloperRole: false
          supportsReasoningEffort: true
          supportsStrictMode: false
          supportsForcedToolChoice: false
          statefulResponses: false
```

The launcher and provider use the dedicated loopback port `8040`, leaving
Laguna's port `8000` unchanged. Both cap context at 32768 tokens; change them
together. The server uses ordinary decoding and one resident session, so
concurrent workers queue rather than loading additional copies of the model.
Private KV checkpoints live under `${XDG_CACHE_HOME:-$HOME/.cache}/ds4/qwen38-q4/kv`
with an 8192 MiB disk budget. Checkpoints contain prompts and model state.

The device's `task` role has an explicit empty fallback chain: stopped or
unavailable ds4 does not select a cloud fallback for task work. Start the
server before delegating. Luna remains manually selectable as
`openai-codex/gpt-6-luna:high`. Main chat, scouts, review, and other roles keep
their existing providers, so this is a local worker lane, not a fully offline
omp configuration. Titles and commit messages remain on Ollama, not ds4.

### omp extensions on the personal device

Plugins are installed separately from dotfile symlinks. The migrated Pi packages
live under `~/.omp/plugins`; no Pi configuration or credentials are copied.

```sh
omp plugin install github:obra/superpowers npm:@ff-labs/pi-fff
omp plugin install npm:@ollama/pi-web-search npm:pi-web-access
omp plugin disable @ollama/pi-web-search
omp plugin disable pi-web-access
```

- **Superpowers 7.0.0:** enabled; loads its extension and 15 skills, including
  `/skill:brainstorming`, `/skill:writing-plans`, and `/skill:systematic-debugging`.
- **pi-fff 0.11.0:** enabled in its default `tools-and-ui` mode. Adds discoverable
  `fffind` and `ffgrep` tools (`read xd://fffind` / `read xd://ffgrep`), plus
  `/fff-mode`, `/fff-health`, and `/fff-rescan`. Native `glob` and `grep` stay intact.
  Pi-specific autocomplete is skipped when the omp UI API does not support it.
- **@ollama/pi-web-search 0.0.5** and **pi-web-access 0.40.0:** installed but
  disabled because both register `web_search`, overriding omp's native search.
  The Ollama package also targets localhost's experimental Ollama web endpoints.
  `omp plugin enable <package>` restores a package, including that override;
  do not enable both together.
- **pi-subagents 0.78.0:** not installed. omp 18.11.0 rejects its `MouseRegion`
  import from the Pi TUI compatibility module and rolls back installation.
  Use omp's native `task` tool with the configured `task` model role instead.

Inspect state with `omp plugin list`; update an installed package with
`omp plugin upgrade <package>`. Package versions above record the verified setup,
not pins on future installations.

### Adding a new work device

1. Add `devices/<hostname>/.dotfiles-merge` with `.claude/settings.json`, `.config/opencode.personal.json`, and `.pi/agent/settings.json`.
2. Copy the gateway `enabledModels` allowlist into `devices/<hostname>/.pi/agent/settings.json` (see `devices/bento/.pi/agent/settings.json`).
3. Copy `devices/bento/.omp/agent/config.yml` to `devices/<hostname>/.omp/agent/config.yml` (gateway model roles).
4. Run `./install.sh <hostname>`.

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
