#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    printf 'not ok - %s\n' "$*" >&2
    exit 1
}

command -v zsh >/dev/null || fail 'zsh is required to test freshen'
ZSH_BIN="$(command -v zsh)"
temp_root="$(mktemp -d)"
trap 'rm -rf "$temp_root"' EXIT
mkdir "$temp_root/bin"

# Load only freshen so interactive shell startup hooks do not run in unit tests.
awk '/^function freshen\(\) \{/ {copy=1} copy {print} copy && /^}$/ {exit}' \
    "$ROOT_DIR/shared/.zshrc.common" > "$temp_root/freshen.zsh"

# Replace external updaters at the process boundary; freshen itself runs unchanged.
printf '#!%s -f\n' "$ZSH_BIN" > "$temp_root/updater"
printf '%s\n' \
    'call="${0:t} $*"' \
    'print -r -- "$call" >> "$FRESHEN_TEST_CALLS"' \
    'if [[ "$call" == "$FRESHEN_TEST_FAIL" ]]; then' \
    '  print -u2 -r -- "update failed: $call"' \
    '  exit 1' \
    'fi' >> "$temp_root/updater"
chmod +x "$temp_root/updater"
for tool in claude codex pi omp agy opencode amp omz brew; do
    ln -s "$temp_root/updater" "$temp_root/bin/$tool"
done

run_freshen() {
    : > "$temp_root/calls"
    FRESHEN_TEST_CALLS="$temp_root/calls" FRESHEN_TEST_FAIL="${1:-}" \
        PATH="$temp_root/bin" "$ZSH_BIN" -f -c 'source "$1"; freshen' \
        -- "$temp_root/freshen.zsh" > "$temp_root/stdout" 2> "$temp_root/stderr" ||
        fail "freshen exited unsuccessfully: $(<"$temp_root/stderr")"
    output="$(<"$temp_root/stdout")"
    errors="$(<"$temp_root/stderr")"
    calls="$(<"$temp_root/calls")"
}

assert_summary() {
    grep -Fxq -- "$1" <<< "$output" || fail "summary is missing: $1"
}

expected_calls='claude update
codex update
pi update
pi update --extensions
omp update
omp update --plugins
agy update
opencode upgrade
amp update
omz update
brew update
brew upgrade
brew doctor'

run_freshen
[[ "$calls" == "$expected_calls" ]] || fail "unexpected updater calls: $calls"
[[ -z "$errors" ]] || fail "unexpected stderr: $errors"
for label in claude codex pi pi-extensions omp omp-plugins agy opencode amp omz brew; do
    assert_summary "  ok    $label"
done
printf '%s\n' 'ok - freshen updates installed CLIs and extensions independently'

for tool in pi omp; do
    rm "$temp_root/bin/$tool"
    run_freshen
    case "$tool" in
        pi) extensions_label=pi-extensions; other_tool=omp; other_extensions=omp-plugins ;;
        omp) extensions_label=omp-plugins; other_tool=pi; other_extensions=pi-extensions ;;
    esac
    assert_summary "  skip  $tool (not installed)"
    assert_summary "  skip  $extensions_label (not installed)"
    assert_summary "  ok    $other_tool"
    assert_summary "  ok    $other_extensions"
    assert_summary '  ok    brew'
    [[ "$calls" != *"$tool update"* ]] || fail "missing $tool was invoked: $calls"
    [[ "$calls" == *'brew doctor' ]] || fail 'freshen stopped before the last updater'
    [[ -z "$errors" ]] || fail "unexpected stderr: $errors"
    ln -s "$temp_root/updater" "$temp_root/bin/$tool"
    printf 'ok - freshen skips missing %s without blocking other updates\n' "$tool"
done

for failed_label in pi pi-extensions omp omp-plugins; do
    case "$failed_label" in
        pi) failed_command='pi update' ;;
        pi-extensions) failed_command='pi update --extensions' ;;
        omp) failed_command='omp update' ;;
        omp-plugins) failed_command='omp update --plugins' ;;
    esac
    run_freshen "$failed_command"
    [[ "$calls" == "$expected_calls" ]] || fail "updates stopped after $failed_label failed: $calls"
    [[ "$errors" == "update failed: $failed_command" ]] || fail "unexpected stderr: $errors"
    assert_summary "  FAIL  $failed_label"
    for label in pi pi-extensions omp omp-plugins; do
        if [[ "$label" != "$failed_label" ]]; then
            assert_summary "  ok    $label"
        fi
    done
    assert_summary '  ok    brew'
    printf 'ok - freshen continues after %s fails\n' "$failed_label"
done
