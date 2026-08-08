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

    printf '#!/usr/bin/env bash\nprintf "Ziyuns-M5-MBP\\n"\n' > "$temp_bin/hostname"
    chmod +x "$temp_bin/hostname"

    set +e
    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/install.sh" 2>&1
    )"
    status=$?
    set -e
    [[ "$status" -eq 0 ]] ||
        fail "install.sh reports that no Ziyuns-M5-MBP device configuration exists: $output"
    [[ "$output" == *"[dotfiles] Installing dotfiles for device: Ziyuns-M5-MBP"* ]] ||
        fail "install.sh did not default to hostname"
    [[ "$output" == *"Would link: $temp_home/.zprofile.macos -> $ROOT_DIR/shared/.zprofile.macos"* ]] ||
        fail "install.sh did not include the shared macOS .zprofile"
    [[ "$output" != *"Would link: $temp_home/.pi/agent/AGENTS.md ->"* ]] ||
        fail "install.sh should not link ~/.pi/agent/AGENTS.md into the repo (pi-config write-through risk)"
    [[ "$output" == *"Would link: $temp_home/.pi/agent/APPEND_SYSTEM.md -> $ROOT_DIR/shared/.pi/agent/APPEND_SYSTEM.md"* ]] ||
        fail "install.sh did not link the Pi APPEND_SYSTEM.md personal channel"
    [[ "$output" == *"Would seed local ~/.pi/agent/AGENTS.md"* ]] ||
        fail "install.sh did not plan to seed a local ~/.pi/agent/AGENTS.md"
    [[ "$output" != *"Would link: $temp_home/AGENTS.md ->"* ]] ||
        fail "install.sh should not link the root AGENTS.md"
    [[ "$output" == *"Would link: $temp_home/.zprofile -> $ROOT_DIR/devices/Ziyuns-M5-MBP/.zprofile"* ]] ||
        fail "install.sh did not include the current MBP .zprofile starter"
    # Migrated devices ship .zshrc.local: the repo file is linked to
    # ~/.zshrc.local and ~/.zshrc is seeded as an untracked shim that sources it,
    # leaving ~/.zshrc free for tool-appended blocks.
    [[ "$output" == *"Would link: $temp_home/.zshrc.local -> $ROOT_DIR/devices/Ziyuns-M5-MBP/.zshrc.local"* ]] ||
        fail "install.sh did not include the current MBP .zshrc.local starter"
    [[ "$output" == *"Would seed local ~/.zshrc sourcing ~/.zshrc.local"* ]] ||
        fail "install.sh did not plan to seed the local ~/.zshrc shim"
    [[ "$output" != *"Would link: $temp_home/.zshrc -> "* ]] ||
        fail "install.sh should not link ~/.zshrc directly on a migrated device"
    [[ "$output" == *"Would link: $temp_home/.local/bin/laguna -> $ROOT_DIR/devices/Ziyuns-M5-MBP/.local/bin/laguna"* ]] ||
        fail "install.sh did not include the Laguna launcher"
    [[ "$output" == *"Would link: $temp_home/.pi/agent/models.json -> $ROOT_DIR/devices/Ziyuns-M5-MBP/.pi/agent/models.json"* ]] ||
        fail "install.sh did not include the Laguna Pi model configuration"
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

    [[ -L "$temp_home/.config/opencode.personal.json" ]] ||
        fail "install.sh did not symlink the shared opencode overlay on a personal device"
    assert_file_contains "$temp_home/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
    assert_file_not_contains "$temp_home/.config/opencode.personal.json" '"model"'

    output="$(
        PATH="$temp_bin:$PATH" HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/uninstall.sh" 2>&1
    )"
    [[ "$output" == *"[dotfiles] Uninstalling dotfiles for device: Ziyuns-M5-MBP"* ]] ||
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
    [[ "$output" == *"Would link: $temp_home/.zshrc.local -> $ROOT_DIR/devices/insta-laptop/.zshrc.local"* ]] ||
        fail "insta-laptop install did not include work laptop .zshrc.local"
    [[ "$output" == *"Would seed local ~/.zshrc sourcing ~/.zshrc.local"* ]] ||
        fail "insta-laptop install did not plan to seed the local ~/.zshrc shim"
    [[ "$output" == *"Would link: $temp_home/.claude/CLAUDE.md -> $ROOT_DIR/devices/insta-laptop/.claude/CLAUDE.md"* ]] ||
        fail "insta-laptop install did not override CLAUDE.md with the work overlay"
    [[ "$output" == *"Would link: $temp_home/.claude/instacart-work-context.md -> $ROOT_DIR/devices/insta-laptop/.claude/instacart-work-context.md"* ]] ||
        fail "insta-laptop install did not link the curated work-context overlay"

    # The opencode overlay is a .dotfiles-merge path on work devices, so it must
    # be composed in the merge phase -- never symlinked from the shared OR the
    # device pass (the latter is what the unconditional is_merged deferral fixes).
    [[ "$output" != *"Would link: $temp_home/.config/opencode.personal.json ->"* ]] ||
        fail "insta-laptop opencode overlay must be merged, not symlinked"
    [[ "$output" == *"Would merge: $ROOT_DIR/shared/.config/opencode.personal.json + $ROOT_DIR/devices/insta-laptop/.config/opencode.personal.json + $temp_home/.config/opencode.personal.json -> $temp_home/.config/opencode.personal.json"* ]] ||
        fail "insta-laptop install did not compose the opencode overlay from shared + device + local"

    output="$(
        HOME="$temp_home" DRY_RUN=1 "$ROOT_DIR/install.sh" bento 2>&1
    )"
    [[ "$output" == *"[dotfiles] Installing dotfiles for device: bento"* ]] ||
        fail "install.sh did not accept explicit bento device"
    [[ "$output" == *"Would link: $temp_home/.shellrc.d/005_oh-my-zshrc.zsh -> $ROOT_DIR/devices/bento/.shellrc.d/005_oh-my-zshrc.zsh"* ]] ||
        fail "bento install did not include oh-my-zsh shellrc hook"
    [[ "$output" == *"Would link: $temp_home/.shellrc.d/080_fzf.zsh -> $ROOT_DIR/devices/bento/.shellrc.d/080_fzf.zsh"* ]] ||
        fail "bento install did not include fzf shellrc hook"
    [[ "$output" == *"Would link: $temp_home/.claude/CLAUDE.md -> $ROOT_DIR/devices/bento/.claude/CLAUDE.md"* ]] ||
        fail "bento install did not override CLAUDE.md with the work overlay"
    [[ "$output" == *"Would link: $temp_home/.claude/instacart-work-context.md -> $ROOT_DIR/devices/bento/.claude/instacart-work-context.md"* ]] ||
        fail "bento install did not link the curated work-context overlay"
    [[ "$output" != *"Would link: $temp_home/.config/opencode.personal.json ->"* ]] ||
        fail "bento opencode overlay must be merged, not symlinked"
    [[ "$output" == *"Would merge: $ROOT_DIR/shared/.config/opencode.personal.json + $ROOT_DIR/devices/bento/.config/opencode.personal.json + $temp_home/.config/opencode.personal.json -> $temp_home/.config/opencode.personal.json"* ]] ||
        fail "bento install did not compose the opencode overlay from shared + device + local"
}

with_local_zshenv() {
    local temp_home temp_bin

    temp_home="$(mktemp -d)"
    temp_bin="$(mktemp -d)"
    trap 'rm -rf "$temp_home" "$temp_bin"' RETURN

    printf '#!/usr/bin/env bash\nprintf "Ziyuns-M5-MBP\\n"\n' > "$temp_bin/hostname"
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

with_local_pi_agents() {
    local temp_home temp_bin

    temp_home="$(mktemp -d)"
    temp_bin="$(mktemp -d)"
    trap 'rm -rf "$temp_home" "$temp_bin"' RETURN

    printf '#!/usr/bin/env bash\nprintf "Ziyuns-M5-MBP\\n"\n' > "$temp_bin/hostname"
    chmod +x "$temp_bin/hostname"

    # Fresh install: ~/.pi/agent/AGENTS.md is a real local file (never a repo
    # symlink), and personal content reaches Pi via ~/.pi/agent/APPEND_SYSTEM.md.
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -f "$temp_home/.pi/agent/AGENTS.md" && ! -L "$temp_home/.pi/agent/AGENTS.md" ]] ||
        fail "install.sh did not seed a real local ~/.pi/agent/AGENTS.md"
    [[ -L "$temp_home/.pi/agent/APPEND_SYSTEM.md" ]] ||
        fail "install.sh did not link ~/.pi/agent/APPEND_SYSTEM.md"
    grep -Fq "You are an experienced, pragmatic software engineer" "$temp_home/.pi/agent/APPEND_SYSTEM.md" ||
        fail "Pi APPEND_SYSTEM.md does not resolve to the personal prompt"

    # Idempotent: a pi-config-style overwrite of the local AGENTS.md is preserved.
    printf '# Instacart Engineering\n' > "$temp_home/.pi/agent/AGENTS.md"
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -f "$temp_home/.pi/agent/AGENTS.md" && ! -L "$temp_home/.pi/agent/AGENTS.md" ]] ||
        fail "install.sh turned ~/.pi/agent/AGENTS.md into a symlink"
    grep -Fq "# Instacart Engineering" "$temp_home/.pi/agent/AGENTS.md" ||
        fail "install.sh clobbered the local pi-config-written ~/.pi/agent/AGENTS.md"

    # An obsolete repo-owned symlink at ~/.pi/agent/AGENTS.md is replaced with a local file.
    rm "$temp_home/.pi/agent/AGENTS.md"
    ln -s "$ROOT_DIR/shared/AGENTS.md" "$temp_home/.pi/agent/AGENTS.md"
    PATH="$temp_bin:$PATH" HOME="$temp_home" "$ROOT_DIR/install.sh" >/dev/null
    [[ -f "$temp_home/.pi/agent/AGENTS.md" && ! -L "$temp_home/.pi/agent/AGENTS.md" ]] ||
        fail "install.sh did not replace the obsolete ~/.pi/agent/AGENTS.md symlink with a local file"
}

with_work_opencode_overlay() {
    local work_root insta_home bento_home

    work_root="$(mktemp -d)"
    trap 'rm -rf "$work_root"' RETURN

    # Work device (insta-laptop): the overlay is COMPOSED into a real file --
    # superpowers (from the shared base) + the work model (from the device layer).
    # Explicit device arg means no hostname fake is needed.
    insta_home="$work_root/insta"
    mkdir -p "$insta_home"
    HOME="$insta_home" "$ROOT_DIR/install.sh" insta-laptop >/dev/null
    [[ -f "$insta_home/.config/opencode.personal.json" && ! -L "$insta_home/.config/opencode.personal.json" ]] ||
        fail "insta-laptop install did not compose a real opencode overlay file"
    assert_file_contains "$insta_home/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
    assert_file_contains "$insta_home/.config/opencode.personal.json" 'openai/gpt-5.4'

    # bento shares insta-laptop's work fragment via a repo symlink; the compose
    # must read through it and still yield both keys.
    bento_home="$work_root/bento"
    mkdir -p "$bento_home"
    HOME="$bento_home" "$ROOT_DIR/install.sh" bento >/dev/null
    [[ -f "$bento_home/.config/opencode.personal.json" && ! -L "$bento_home/.config/opencode.personal.json" ]] ||
        fail "bento install did not compose a real opencode overlay file"
    assert_file_contains "$bento_home/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
    assert_file_contains "$bento_home/.config/opencode.personal.json" 'openai/gpt-5.4'
}

with_settings_backward_compat() {
    local temp_home

    temp_home="$(mktemp -d)"
    trap 'rm -rf "$temp_home"' RETURN

    # Pre-seed a local Claude settings file with a personal key.
    mkdir -p "$temp_home/.claude"
    printf '{"local_only_key": "keep-me"}\n' > "$temp_home/.claude/settings.json"

    # A work-device install merges shared settings over the local file. There is
    # no devices/insta-laptop/.claude/settings.json fragment, so the new device
    # layer is a no-op: local values still survive AND shared keys are merged in
    # (proving a real deep-merge, not a clobber or a symlink). Explicit device
    # arg means no hostname fake is needed.
    HOME="$temp_home" "$ROOT_DIR/install.sh" insta-laptop >/dev/null
    [[ -f "$temp_home/.claude/settings.json" && ! -L "$temp_home/.claude/settings.json" ]] ||
        fail "settings.json merge did not produce a real local file"
    assert_file_contains "$temp_home/.claude/settings.json" 'local_only_key'
    assert_file_contains "$temp_home/.claude/settings.json" 'keep-me'
    assert_file_contains "$temp_home/.claude/settings.json" 'ANTHROPIC_MODEL'
}

with_herdr_hook_guard() {
    local temp_home hook_cmd stderr_file marker status

    temp_home="$(mktemp -d)"
    trap 'rm -rf "$temp_home"' RETURN

    hook_cmd="$(python3 -c '
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
data = json.loads((root / "shared/.claude/settings.json").read_text())
starts = data["hooks"]["SessionStart"]
cmds = [h["command"] for e in starts for h in e["hooks"]]
herdr = [c for c in cmds if "herdr-agent-state.sh" in c]
if len(herdr) != 1:
    raise SystemExit("expected exactly one herdr SessionStart hook, got %d" % len(herdr))
print(herdr[0])
' "$ROOT_DIR")"

    # The hook script is generated per-machine by `herdr integration install
    # claude` and is deliberately untracked (see shared/HERDR_GUIDE.md), but the
    # registration lives in shared/ and therefore reaches every device. On a
    # machine that has not run the install the command must degrade to a silent
    # no-op instead of failing SessionStart with a 127.
    stderr_file="$temp_home/stderr"
    set +e
    HOME="$temp_home" bash -c "$hook_cmd" >/dev/null 2>"$stderr_file"
    status=$?
    set -e
    [[ $status -eq 0 ]] ||
        fail "herdr SessionStart hook exited $status with no script installed"
    [[ ! -s "$stderr_file" ]] ||
        fail "herdr SessionStart hook wrote to stderr with no script installed: $(cat "$stderr_file")"

    # Where the integration *is* installed the guard must stay out of the way:
    # the script still runs and still receives the `session` argument.
    marker="$temp_home/invoked"
    mkdir -p "$temp_home/.claude/hooks"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$1" > "%s"\n' "$marker" \
        > "$temp_home/.claude/hooks/herdr-agent-state.sh"
    chmod +x "$temp_home/.claude/hooks/herdr-agent-state.sh"

    HOME="$temp_home" bash -c "$hook_cmd" >/dev/null 2>&1 ||
        fail "herdr SessionStart hook failed with the script installed"
    [[ -f "$marker" ]] ||
        fail "herdr SessionStart hook did not run the installed script"
    assert_file_contains "$marker" 'session'
}

assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" 'typeset -U path'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/.local/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/.opencode/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/go/bin"'
assert_file_contains "$ROOT_DIR/shared/.zprofile.macos" '"$HOME/.cargo/bin"'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zprofile" 'source ~/.zprofile.macos'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" '# MBP zsh configuration'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'DEVICE_PLUGINS=(macos)'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'source ~/.zshrc.common'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-Mac-mini/.zprofile" 'source ~/.zprofile.macos'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zprofile" 'source ~/.zprofile.macos'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zprofile" 'source ~/.orbstack/shell/init.zsh 2>/dev/null || :'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zshrc.local" 'DEVICE_PLUGINS=(macos)'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zshrc.local" 'source ~/.zshrc.common'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.zshrc.local" 'source "$HOME/.instacart_shell_profile"'
# gohan (Instacart tooling) is sourced from a machine-local, untracked ~/.zshenv
# that gohan's own installer manages -- never from repo-tracked files. The shared
# env stays clean, the old redundant interactive-shell source is gone, and the
# only repo-tracked gohan hook is bento's (its remote env may not auto-inject).
assert_file_not_contains "$ROOT_DIR/devices/insta-laptop/.zshrc.local" 'gohan'
assert_file_contains "$ROOT_DIR/devices/bento/.shellrc.d/090_gohan.zsh" 'source "$HOME/.config/gohan/gohan.sh"'
assert_file_not_contains "$ROOT_DIR/shared/.zshenv.shared" 'gohan'
assert_file_contains "$ROOT_DIR/shared/.zshenv.shared" '$HOME/.fzf/bin'
# The personal prompt must be the canonical shared/AGENTS.md content, never the
# company boilerplate (a re-clobber landing in the repo would trip this).
assert_file_contains "$ROOT_DIR/shared/AGENTS.md" 'You are an experienced, pragmatic software engineer'
assert_file_not_contains "$ROOT_DIR/shared/AGENTS.md" '# Instacart Engineering'

# No tracked file may be a pi-config write target. shared/.pi/agent/AGENTS.md is
# retired; personal reaches Pi through APPEND_SYSTEM.md instead.
assert_path_not_exists "$ROOT_DIR/shared/.pi/agent/AGENTS.md"
[[ -L "$ROOT_DIR/shared/.pi/agent/APPEND_SYSTEM.md" ]] ||
    fail "shared/.pi/agent/APPEND_SYSTEM.md should be a symlink to the personal prompt"
[[ "$(readlink "$ROOT_DIR/shared/.pi/agent/APPEND_SYSTEM.md")" == "../../AGENTS.md" ]] ||
    fail "shared/.pi/agent/APPEND_SYSTEM.md should point to ../../AGENTS.md"

# Work-device Claude overlay: personal first (@AGENTS.md), curated company facts second.
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/CLAUDE.md" '@AGENTS.md'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/CLAUDE.md" '@instacart-work-context.md'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/instacart-work-context.md" 'aigateway.instacart.tools'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.claude/instacart-work-context.md" 'isc-web'
assert_file_contains "$ROOT_DIR/devices/bento/.claude/CLAUDE.md" '@AGENTS.md'
assert_file_contains "$ROOT_DIR/devices/bento/.claude/CLAUDE.md" '@instacart-work-context.md'
# bento's overlay is a symlink to insta-laptop's canonical copy; grep follows it.
assert_file_contains "$ROOT_DIR/devices/bento/.claude/instacart-work-context.md" 'aigateway.instacart.tools'

# Personal opencode overlay: superpowers plugin everywhere via the shared base;
# the work model default is layered in only on work devices (Tasks 2-3).
assert_file_contains "$ROOT_DIR/shared/.config/opencode.personal.json" 'superpowers@git+https://github.com/obra/superpowers.git'
assert_file_not_contains "$ROOT_DIR/shared/.config/opencode.personal.json" '"model"'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.config/opencode.personal.json" 'openai/gpt-5.4'
assert_file_contains "$ROOT_DIR/devices/insta-laptop/.dotfiles-merge" '.config/opencode.personal.json'
[[ -L "$ROOT_DIR/devices/bento/.config/opencode.personal.json" ]] ||
    fail "devices/bento/.config/opencode.personal.json should be a symlink to insta-laptop's fragment"
[[ "$(readlink "$ROOT_DIR/devices/bento/.config/opencode.personal.json")" == "../../insta-laptop/.config/opencode.personal.json" ]] ||
    fail "devices/bento/.config/opencode.personal.json should point to ../../insta-laptop/.config/opencode.personal.json"
assert_file_contains "$ROOT_DIR/devices/bento/.dotfiles-merge" '.config/opencode.personal.json'

# opencode reads OPENCODE_CONFIG and deep-merges it over its global config, so
# the personal overlay reaches opencode without touching the tool-managed dir.
assert_file_contains "$ROOT_DIR/shared/.zshenv.shared" 'if [[ -f "$HOME/.config/opencode.personal.json" ]]; then'
assert_file_contains "$ROOT_DIR/shared/.zshenv.shared" 'export OPENCODE_CONFIG="$HOME/.config/opencode.personal.json"'

# The tool-managed ~/.config/opencode/ dir embeds the work email in every provider
# URL and is regenerated by the company opencode-config tool. No repo file may map
# into it (install.sh would symlink it into ~/.config/opencode/), or that email and
# provider block would leak into git. Our overlay is the sibling
# ~/.config/opencode.personal.json, which this -path pattern does not match.
if [[ -n "$(find "$ROOT_DIR/shared" "$ROOT_DIR/devices" -path '*/.config/opencode/*' -print -quit)" ]]; then
    fail "no repo file may map into ~/.config/opencode/ (tool-managed; would leak the work email)"
fi

assert_path_not_exists "$ROOT_DIR/shared/.zshenv"
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'brew shellenv'
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-Mac-mini/.zshrc.local" 'brew shellenv'
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-MBP/.zshrc" 'export PATH='
assert_file_not_contains "$ROOT_DIR/devices/Ziyuns-Mac-mini/.zshrc.local" '.opencode/bin'
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

# Herdr hook scripts are per-machine and untracked, so bootstrapping a machine
# has to reinstall them. Keep the README list in step with the integrations
# HERDR_GUIDE.md declares this repo expects.
assert_file_contains "$ROOT_DIR/README.md" '### Install herdr agent integrations'
for integration in claude pi opencode codex; do
    assert_file_contains "$ROOT_DIR/README.md" "herdr integration install $integration"
    assert_file_contains "$ROOT_DIR/shared/HERDR_GUIDE.md" "\`$integration\`"
done
assert_file_contains "$ROOT_DIR/README.md" 'herdr integration status'
assert_file_contains "$ROOT_DIR/shared/TMUX_GUIDE.md" 'Ghostty-launched interactive shells auto-attach to tmux session `main`.'
assert_file_contains "$ROOT_DIR/shared/GHOSTTY_GUIDE.md" '`ssh-env`'
assert_file_contains "$ROOT_DIR/devices/bento/.shellrc.d/005_oh-my-zshrc.zsh" 'source ~/.zshrc.common'

with_fake_hostname
with_explicit_work_devices
with_local_zshenv
with_local_pi_agents
with_work_opencode_overlay
with_settings_backward_compat
with_herdr_hook_guard

assert_file_contains "$ROOT_DIR/devices/Ziyuns-M5-MBP/.zprofile" 'source ~/.zprofile.macos'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-M5-MBP/.zshrc.local" 'DEVICE_PLUGINS=(macos)'
assert_file_contains "$ROOT_DIR/devices/Ziyuns-M5-MBP/.zshrc.local" 'source ~/.zshrc.common'
assert_path_not_exists "$ROOT_DIR/devices/Ziyuns-M5-MacBook-Pro"

echo "ok - dotfiles bootstrap checks passed"
