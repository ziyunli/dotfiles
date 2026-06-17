#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    echo "not ok - $*" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local expected="$2"

    grep -Fq -- "$expected" "$file" || fail "$file is missing: $expected"
}

assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"

    ! grep -Fq -- "$unexpected" "$file" || fail "$file unexpectedly contains: $unexpected"
}

with_fake_hostname() {
    local temp_home temp_bin output

    temp_home="$(mktemp -d)"
    temp_bin="$(mktemp -d)"
    trap 'rm -rf "$temp_home" "$temp_bin"' RETURN

    printf '#!/usr/bin/env bash\nprintf "Ziyuns-M5-MacBook-Pro\\n"\n' > "$temp_bin/hostname"
    chmod +x "$temp_bin/hostname"

    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/install.sh" 2>&1
    )"
    [[ "$output" == *"[dotfiles] Installing dotfiles for device: Ziyuns-M5-MacBook-Pro"* ]] ||
        fail "install.sh did not default to hostname"
    [[ "$output" == *"Would link: $temp_home/.zprofile.macos -> $ROOT_DIR/shared/.zprofile.macos"* ]] ||
        fail "install.sh did not include the shared macOS .zprofile"
    [[ "$output" == *"Would link: $temp_home/.zprofile -> $ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro/.zprofile"* ]] ||
        fail "install.sh did not include the current MBP .zprofile starter"
    [[ "$output" == *"Would link: $temp_home/.zshrc -> $ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro/.zshrc"* ]] ||
        fail "install.sh did not include the current MBP .zshrc starter"

    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/uninstall.sh" 2>&1
    )"
    [[ "$output" == *"[dotfiles] Uninstalling dotfiles for device: Ziyuns-M5-MacBook-Pro"* ]] ||
        fail "uninstall.sh did not default to hostname"
}

assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" 'typeset -U path'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/.local/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/.opencode/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/go/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/.cargo/bin"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro/.zprofile" 'source ~/.zprofile.macos'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro/.zshrc" 'DEVICE_PLUGINS=(macos)'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro/.zshrc" 'source ~/.zshrc.common'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" 'source ~/.zprofile.macos'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" '# MBP zsh configuration'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'DEVICE_PLUGINS=(macos)'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'source ~/.zshrc.common'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-Mac-mini/.zprofile" 'source ~/.zprofile.macos'
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'brew shellenv'
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-Mac-mini/.zshrc" 'brew shellenv'
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'export PATH='
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-Mac-mini/.zshrc" '.opencode/bin'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/.local/bin:$PATH"'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/bin:$PATH"'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/go/bin:$PATH"'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/.cargo/bin:$PATH"'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export TERM="xterm-256color"'
assert_file_contains "$ROOT_DIR/shared/.zshrc.common" 'source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"'
assert_file_contains "$ROOT_DIR/shared/.zshrc.common" 'exec tmux new-session -A -s main'
assert_file_contains "$ROOT_DIR/shared/.zshrc.common" '-z "${SSH_CONNECTION:-}"'

assert_file_contains "$ROOT_DIR/shared/.tmux.conf" 'set -g extended-keys on'
assert_file_contains "$ROOT_DIR/shared/.tmux.conf" 'GHOSTTY_RESOURCES_DIR'
assert_file_contains "$ROOT_DIR/shared/.config/ghostty/config" 'config-file = "config.ghostty"'
assert_file_contains "$ROOT_DIR/shared/.config/ghostty/config.ghostty" 'shell-integration-features = cursor,no-sudo,title,ssh-env,ssh-terminfo,path'
assert_file_contains "$ROOT_DIR/shared/.config/ghostty/config.ghostty" 'macos-option-as-alt = left'
assert_file_contains "$ROOT_DIR/shared/Library/Application Support/com.mitchellh.ghostty/config.ghostty" 'config-file = "../../../.config/ghostty/config.ghostty"'

assert_file_contains "$ROOT_DIR/README.md" '### Bootstrap a new Mac'
assert_file_contains "$ROOT_DIR/README.md" '### Zsh startup files'
assert_file_contains "$ROOT_DIR/README.md" '`~/.zprofile.macos` contains macOS login-shell environment shared by personal Apple devices'
assert_file_contains "$ROOT_DIR/README.md" '`~/.zprofile` is for login-shell environment'
assert_file_contains "$ROOT_DIR/README.md" '`~/.zshrc` is for interactive shell behavior'
assert_file_contains "$ROOT_DIR/README.md" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
assert_file_contains "$ROOT_DIR/README.md" 'brew install gh'
assert_file_contains "$ROOT_DIR/README.md" 'ssh-keygen -t ed25519 -C "your_email@example.com"'
assert_file_contains "$ROOT_DIR/README.md" 'gh ssh-key add ~/.ssh/id_ed25519.pub --title "personal laptop"'
assert_file_contains "$ROOT_DIR/README.md" 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
assert_file_contains "$ROOT_DIR/README.md" 'git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf'
assert_file_contains "$ROOT_DIR/README.md" 'git clone --depth 1 https://github.com/agkozak/agkozak-zsh-theme ~/.oh-my-zsh/custom/themes/agkozak'
assert_file_contains "$ROOT_DIR/shared/TMUX_GUIDE.md" 'Ghostty-launched interactive shells auto-attach to tmux session `main`.'
assert_file_contains "$ROOT_DIR/shared/GHOSTTY_GUIDE.md" '`ssh-env`'

with_fake_hostname

echo "ok - dotfiles bootstrap checks passed"
