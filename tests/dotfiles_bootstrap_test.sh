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

    grep -Fq "$expected" "$file" || fail "$file is missing: $expected"
}

assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"

    ! grep -Fq "$unexpected" "$file" || fail "$file unexpectedly contains: $unexpected"
}

with_fake_hostname() {
    local temp_home temp_bin output

    temp_home="$(mktemp -d)"
    temp_bin="$(mktemp -d)"
    trap 'rm -rf "$temp_home" "$temp_bin"' RETURN

    printf '#!/usr/bin/env bash\nprintf "Ziyuns-MBP\\n"\n' > "$temp_bin/hostname"
    chmod +x "$temp_bin/hostname"

    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/install.sh" 2>&1
    )"
    [[ "$output" == *"[dotfiles] Installing dotfiles for device: Ziyuns-MBP"* ]] ||
        fail "install.sh did not default to hostname"
    [[ "$output" == *"Would link: $temp_home/.zshrc -> $ROOT_DIR/devices/Ziyuns-MBP/.zshrc"* ]] ||
        fail "install.sh did not include the MBP .zshrc starter"

    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/uninstall.sh" 2>&1
    )"
    [[ "$output" == *"[dotfiles] Uninstalling dotfiles for device: Ziyuns-MBP"* ]] ||
        fail "uninstall.sh did not default to hostname"
}

assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" 'typeset -U path'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" '"$HOME/.local/bin"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" '"$HOME/.opencode/bin"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" '"$HOME/bin"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" '"$HOME/go/bin"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" '"$HOME/.cargo/bin"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" '# MBP zsh configuration'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'DEVICE_PLUGINS=(macos)'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'source ~/.zshrc.common'
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'brew shellenv'
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'export PATH='
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/.local/bin:$PATH"'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/bin:$PATH"'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/go/bin:$PATH"'
assert_file_not_contains "$ROOT_DIR/shared/.zshrc.common" 'export PATH="$HOME/.cargo/bin:$PATH"'

assert_file_contains "$ROOT_DIR/README.md" '### Bootstrap a new Mac'
assert_file_contains "$ROOT_DIR/README.md" '### Zsh startup files'
assert_file_contains "$ROOT_DIR/README.md" '`~/.zprofile` is for login-shell environment'
assert_file_contains "$ROOT_DIR/README.md" '`~/.zshrc` is for interactive shell behavior'
assert_file_contains "$ROOT_DIR/README.md" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
assert_file_contains "$ROOT_DIR/README.md" 'brew install gh'
assert_file_contains "$ROOT_DIR/README.md" 'ssh-keygen -t ed25519 -C "your_email@example.com"'
assert_file_contains "$ROOT_DIR/README.md" 'gh ssh-key add ~/.ssh/id_ed25519.pub --title "personal laptop"'
assert_file_contains "$ROOT_DIR/README.md" 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
assert_file_contains "$ROOT_DIR/README.md" 'git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf'
assert_file_contains "$ROOT_DIR/README.md" 'git clone --depth 1 https://github.com/agkozak/agkozak-zsh-theme ~/.oh-my-zsh/custom/themes/agkozak'

with_fake_hostname

echo "ok - dotfiles bootstrap checks passed"
