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
    'case "$call" in' \
    '  "brew services info ollama --json") print -r -- "$FRESHEN_TEST_OLLAMA_SERVICE" ;;' \
    '  "herdr integration status") print -r -- "$FRESHEN_TEST_HERDR_STATUS" ;;' \
    'esac' \
    'if [[ "$call" == "$FRESHEN_TEST_FAIL" ]]; then' \
    '  print -u2 -r -- "update failed: $call"' \
    '  exit 1' \
    'fi' >> "$temp_root/updater"
chmod +x "$temp_root/updater"
for tool in claude codex pi omp agy opencode amp omz brew herdr; do
    ln -s "$temp_root/updater" "$temp_root/bin/$tool"
done

# Probe output the fake brew and herdr print; tests override these per scenario.
ollama_service=''
herdr_status=''

run_freshen() {
    : > "$temp_root/calls"
    FRESHEN_TEST_CALLS="$temp_root/calls" FRESHEN_TEST_FAIL="${1:-}" \
        FRESHEN_TEST_OLLAMA_SERVICE="$ollama_service" FRESHEN_TEST_HERDR_STATUS="$herdr_status" \
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
brew doctor
brew services info ollama --json
herdr integration status'

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
    [[ "$calls" == *'herdr integration status' ]] || fail 'freshen stopped before the last updater'
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

# brew upgrade swaps the ollama binary under a still-running server.
ollama_service='[{"name": "ollama", "running": true, "status": "started"}]'
run_freshen
[[ "$calls" == *$'brew services info ollama --json\nbrew services restart ollama\nherdr integration status' ]] ||
    fail "running ollama service was not restarted after brew: $calls"
assert_summary '  ok    ollama-service'
[[ -z "$errors" ]] || fail "unexpected stderr: $errors"
printf '%s\n' 'ok - freshen restarts a running ollama brew service after upgrading'

rm "$temp_root/bin/brew"
run_freshen
assert_summary '  skip  brew (not installed)'
[[ "$output" != *ollama-service* ]] || fail "summary reports an ollama service without brew: $output"
[[ -z "$errors" ]] || fail "unexpected stderr: $errors"
ln -s "$temp_root/updater" "$temp_root/bin/brew"
printf '%s\n' 'ok - freshen runs cleanly without brew'

ollama_service='[{"name": "ollama", "running": false, "status": "none"}]'
run_freshen
[[ "$calls" == "$expected_calls" ]] || fail "stopped ollama service was touched: $calls"
[[ "$output" != *ollama-service* ]] || fail "summary reports a stopped ollama service: $output"
printf '%s\n' 'ok - freshen leaves a stopped ollama service alone'
ollama_service=''

herdr_status='pi: outdated (v8 < v9) (/home/u/.pi/agent/extensions/herdr-agent-state.ts)
omp: current (v10) (/home/u/.omp/agent/extensions/herdr-omp-agent-state.ts)
claude: outdated (v7 < v11) (/home/u/.claude/hooks/herdr-agent-state.sh)
codex: outdated (v7 < v10) (/home/u/.codex/herdr-agent-state.sh)
copilot: not installed (/home/u/.copilot/hooks/herdr-agent-state.sh)
letta (experimental): outdated (v1 < v2) (/home/u/.letta/hooks/herdr-agent-session.sh)'
run_freshen
[[ "$calls" == *$'herdr integration status\nherdr integration install pi\nherdr integration install codex\nherdr integration install letta' ]] ||
    fail "outdated herdr integrations were not reinstalled: $calls"
for agent in claude omp copilot; do
    [[ "$calls" != *"herdr integration install $agent"* ]] || fail "herdr $agent integration was reinstalled: $calls"
done
assert_summary '  ok    herdr-pi'
assert_summary '  ok    herdr-codex'
assert_summary '  ok    herdr-letta'
assert_summary '  WARN  herdr-claude (outdated; reinstall per ~/.dotfiles/shared/HERDR_GUIDE.md)'
[[ -z "$errors" ]] || fail "unexpected stderr: $errors"
printf '%s\n' 'ok - freshen reinstalls outdated herdr integrations and only reports claude'

run_freshen 'herdr integration install pi'
[[ "$calls" == *$'herdr integration install codex\nherdr integration install letta' ]] ||
    fail "herdr reinstalls stopped after pi failed: $calls"
[[ "$errors" == 'update failed: herdr integration install pi' ]] || fail "unexpected stderr: $errors"
assert_summary '  FAIL  herdr-pi'
assert_summary '  ok    herdr-codex'
printf '%s\n' 'ok - freshen continues after a herdr reinstall fails'

# The parsed agent name reaches eval, so it must stay one quoted word.
herdr_status='x;false: outdated (v1 < v2) (/home/u/.x/herdr-agent-state.sh)'
run_freshen
[[ "$calls" == *'herdr integration install x;false' ]] || fail "herdr agent name was split by eval: $calls"
assert_summary '  ok    herdr-x;false'
printf '%s\n' 'ok - freshen quotes herdr agent names before eval'

herdr_status='claude: current (v11) (/home/u/.claude/hooks/herdr-agent-state.sh)'
run_freshen
[[ "$calls" != *'herdr integration install'* ]] || fail "current herdr integration was reinstalled: $calls"
[[ "$output" != *herdr-claude* ]] || fail "summary reports a current claude integration: $output"
printf '%s\n' 'ok - freshen leaves current herdr integrations alone'

rm "$temp_root/bin/herdr"
run_freshen
[[ "$calls" != *herdr* ]] || fail "missing herdr was invoked: $calls"
[[ -z "$errors" ]] || fail "unexpected stderr: $errors"
ln -s "$temp_root/updater" "$temp_root/bin/herdr"
printf '%s\n' 'ok - freshen skips herdr integrations when herdr is missing'
herdr_status=''
