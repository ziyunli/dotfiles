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

assert_path_not_exists() {
    local path="$1"

    [[ ! -e "$path" && ! -L "$path" ]] || fail "$path should not exist"
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
    [[ "$output" == *"Would link: $temp_home/.pi/agent/AGENTS.md -> $ROOT_DIR/shared/.pi/agent/AGENTS.md"* ]] ||
        fail "install.sh did not include the shared Pi agent instructions"
    [[ "$output" != *"Would link: $temp_home/AGENTS.md ->"* ]] ||
        fail "install.sh should not link the root AGENTS.md"
    [[ "$output" == *"Would link: $temp_home/.zprofile -> $ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro/.zprofile"* ]] ||
        fail "install.sh did not include the current MBP .zprofile starter"
    [[ "$output" == *"Would link: $temp_home/.zshrc -> $ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro/.zshrc"* ]] ||
        fail "install.sh did not include the current MBP .zshrc starter"
    [[ "$output" != *"Would link: $temp_home/.config/ghostty/config ->"* ]] ||
        fail "install.sh should not link the legacy Ghostty config filename"
    [[ "$output" != *"Would link: $temp_home/Library/Application Support/com.mitchellh.ghostty/config.ghostty ->"* ]] ||
        fail "install.sh should not link the macOS Ghostty config when XDG is canonical"

    mkdir -p "$temp_home/.config/ghostty" "$temp_home/Library/Application Support/com.mitchellh.ghostty"
    ln -s "$ROOT_DIR/shared/.config/ghostty/config" "$temp_home/.config/ghostty/config"
    ln -s "$ROOT_DIR/shared/Library/Application Support/com.mitchellh.ghostty/config.ghostty" "$temp_home/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
    ln -s "$ROOT_DIR/shared/AGENTS.md" "$temp_home/AGENTS.md"

    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/install.sh" 2>&1
    )"
    [[ "$output" == *"Would remove obsolete symlink: $temp_home/AGENTS.md"* ]] ||
        fail "install.sh dry run did not clean up the root AGENTS.md symlink"
    [[ "$output" == *"Would remove obsolete symlink: $temp_home/.config/ghostty/config"* ]] ||
        fail "install.sh dry run did not clean up the legacy Ghostty config symlink"
    [[ "$output" == *"Would remove obsolete symlink: $temp_home/Library/Application Support/com.mitchellh.ghostty/config.ghostty"* ]] ||
        fail "install.sh dry run did not clean up the macOS Ghostty config symlink"

    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    assert_path_not_exists "$temp_home/AGENTS.md"
    assert_path_not_exists "$temp_home/.config/ghostty/config"
    assert_path_not_exists "$temp_home/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
    [[ -L "$temp_home/.config/ghostty/config.ghostty" ]] ||
        fail "install.sh did not link the XDG Ghostty config"

    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/uninstall.sh" 2>&1
    )"
    [[ "$output" == *"[dotfiles] Uninstalling dotfiles for device: Ziyuns-M5-MacBook-Pro"* ]] ||
        fail "uninstall.sh did not default to hostname"
}

with_explicit_work_devices() {
    local temp_home output

    temp_home="$(mktemp -d)"
    trap 'rm -rf "$temp_home"' RETURN

    output="$(
        HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/install.sh" insta-laptop 2>&1
    )"
    [[ "$output" == *"[dotfiles] Installing dotfiles for device: insta-laptop"* ]] ||
        fail "install.sh did not accept explicit insta-laptop device"
    [[ "$output" == *"Would link: $temp_home/.zprofile -> $ROOT_DIR/devices/insta-laptop/.zprofile"* ]] ||
        fail "insta-laptop install did not include work laptop .zprofile"
    [[ "$output" == *"Would link: $temp_home/.zshrc -> $ROOT_DIR/devices/insta-laptop/.zshrc"* ]] ||
        fail "insta-laptop install did not include work laptop .zshrc"

    output="$(
        HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/install.sh" bento 2>&1
    )"
    [[ "$output" == *"[dotfiles] Installing dotfiles for device: bento"* ]] ||
        fail "install.sh did not accept explicit bento device"
    [[ "$output" == *"Would link: $temp_home/.shellrc.d/005_oh-my-zshrc.zsh -> $ROOT_DIR/devices/bento/.shellrc.d/005_oh-my-zshrc.zsh"* ]] ||
        fail "bento install did not include oh-my-zsh shellrc hook"
    [[ "$output" == *"Would link: $temp_home/.shellrc.d/080_fzf.zsh -> $ROOT_DIR/devices/bento/.shellrc.d/080_fzf.zsh"* ]] ||
        fail "bento install did not include fzf shellrc hook"
}

with_local_zshenv() {
    local temp_home temp_bin

    temp_home="$(mktemp -d)"
    temp_bin="$(mktemp -d)"
    trap 'rm -rf "$temp_home" "$temp_bin"' RETURN

    printf '#!/usr/bin/env bash\nprintf "Ziyuns-M5-MacBook-Pro\\n"\n' > "$temp_bin/hostname"
    chmod +x "$temp_bin/hostname"

    # Fresh install seeds ~/.zshenv as a real local file sourcing the shared env,
    # and links the shared env content as ~/.zshenv.shared.
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -L "$temp_home/.zshenv.shared" ]] ||
        fail "install.sh did not link ~/.zshenv.shared"
    [[ -f "$temp_home/.zshenv" && ! -L "$temp_home/.zshenv" ]] ||
        fail "install.sh did not seed a real local ~/.zshenv"
    grep -Fq 'source "$HOME/.zshenv.shared"' "$temp_home/.zshenv" ||
        fail "seeded ~/.zshenv does not source the shared env"

    # Re-running is idempotent: no duplicate source line, and local additions
    # (e.g. a gohan block) are preserved rather than clobbered.
    printf '\n# gohan setup\nsource "$HOME/.config/gohan/gohan.sh"\n' >> "$temp_home/.zshenv"
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ "$(grep -cF 'source "$HOME/.zshenv.shared"' "$temp_home/.zshenv")" == "1" ]] ||
        fail "install.sh duplicated the shared-env source line in ~/.zshenv"
    grep -Fq 'gohan' "$temp_home/.zshenv" ||
        fail "install.sh clobbered local additions in ~/.zshenv"

    # An obsolete repo-owned symlink at ~/.zshenv (old layout) is replaced with the seed.
    rm "$temp_home/.zshenv"
    ln -s "$ROOT_DIR/shared/.zshenv.shared" "$temp_home/.zshenv"
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -f "$temp_home/.zshenv" && ! -L "$temp_home/.zshenv" ]] ||
        fail "install.sh did not replace the obsolete ~/.zshenv symlink with a local file"
    grep -Fq 'source "$HOME/.zshenv.shared"' "$temp_home/.zshenv" ||
        fail "replaced ~/.zshenv does not source the shared env"
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
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zprofile" 'source ~/.zprofile.macos'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zprofile" 'source ~/.orbstack/shell/init.zsh 2>/dev/null || :'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zshrc" 'DEVICE_PLUGINS=(macos)'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zshrc" 'source ~/.zshrc.common'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zshrc" 'source "$HOME/.instacart_shell_profile"'
# gohan (Instacart tooling) is sourced from a machine-local, untracked ~/.zshenv
# that gohan's own installer manages -- never from repo-tracked files. The shared
# env stays clean, the old redundant interactive-shell source is gone, and the
# only repo-tracked gohan hook is bento's (its remote env may not auto-inject).
assert_file_not_contains "$ROOT_DIR/devices/insta-laptop/.zshrc" 'gohan'
assert_file_contains "$ROOT_DIR/devices/bento/.shellrc.d/090_gohan.zsh" 'source "$HOME/.config/gohan/gohan.sh"'
assert_file_not_contains "$ROOT_DIR/shared/.zshenv.shared" 'gohan'
assert_file_contains "$ROOT_DIR/shared/.zshenv.shared" '$HOME/.fzf/bin'
assert_path_not_exists "$ROOT_DIR/shared/.zshenv"
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
assert_file_contains "$ROOT_DIR/shared/.tmux.conf" 'set -g extended-keys-format csi-u'
assert_file_contains "$ROOT_DIR/shared/.tmux.conf" 'GHOSTTY_RESOURCES_DIR'
assert_file_contains "$ROOT_DIR/shared/.config/ghostty/config.ghostty" 'shell-integration-features = cursor,no-sudo,title,ssh-env,ssh-terminfo,path'
assert_file_contains "$ROOT_DIR/shared/.config/ghostty/config.ghostty" 'macos-option-as-alt = left'
assert_path_not_exists "$ROOT_DIR/shared/.config/ghostty/config"
assert_path_not_exists "$ROOT_DIR/shared/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

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
assert_file_contains "$ROOT_DIR/devices/bento/.shellrc.d/005_oh-my-zshrc.zsh" 'source ~/.zshrc.common'

with_fake_hostname
with_explicit_work_devices
with_local_zshenv

echo "ok - dotfiles bootstrap checks passed"
