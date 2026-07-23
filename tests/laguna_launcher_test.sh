#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$ROOT_DIR/devices/Ziyuns-M5-MBP/.local/bin/laguna"

fail() {
    printf 'not ok - %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local value="$1" expected="$2"
    [[ "$value" == *"$expected"* ]] || fail "output is missing: $expected"
}

[[ -x "$LAUNCHER" ]] || fail "$LAUNCHER is not executable"
bash -n "$LAUNCHER" || fail "$LAUNCHER has invalid Bash syntax"

output="$("$LAUNCHER" help)"
assert_contains "$output" 'Usage: laguna <command>'
assert_contains "$output" 'download q4|dflash'
assert_contains "$output" 'serve [--dflash]'

set +e
output="$("$LAUNCHER" unknown 2>&1)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "unknown command exited $exit_status instead of 2"
assert_contains "$output" 'Unknown command: unknown'

empty_home="$(mktemp -d)"
trap 'rm -rf "$empty_home"' EXIT
set +e
output="$(
    HOME="$empty_home" \
    LAGUNA_RUNTIME_DIR="$empty_home/runtime" \
    LAGUNA_STATE_DIR="$empty_home/state" \
    "$LAUNCHER" status 2>&1
)"
exit_status=$?
set -e
[[ "$exit_status" == "1" ]] || fail "incomplete status exited $exit_status instead of 1"
assert_contains "$output" 'runtime: missing'
assert_contains "$output" 'q4: missing'
assert_contains "$output" 'dflash: missing (optional)'
assert_contains "$output" 'server: stopped'

set +e
output="$("$LAUNCHER" download invalid 2>&1)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "invalid download exited $exit_status instead of 2"
assert_contains "$output" 'download target must be q4 or dflash'

set +e
output="$(
    HOME="$empty_home" \
    LAGUNA_RUNTIME_DIR="$empty_home/prompt-runtime" \
    LAGUNA_STATE_DIR="$empty_home/state" \
    "$LAUNCHER" prompt 2>&1
)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "missing prompt exited $exit_status instead of 2"
assert_contains "$output" 'prompt requires text'

set +e
output="$("$LAUNCHER" serve invalid 2>&1)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "invalid serve argument exited $exit_status instead of 2"
assert_contains "$output" 'serve accepts only --dflash'

wrong_origin_runtime="$empty_home/wrong-origin-runtime"
git init -q "$wrong_origin_runtime"
git -C "$wrong_origin_runtime" remote add origin https://example.invalid/wrong.git
set +e
output="$(
    HOME="$empty_home" \
    LAGUNA_RUNTIME_DIR="$wrong_origin_runtime" \
    LAGUNA_STATE_DIR="$empty_home/state" \
    "$LAUNCHER" setup 2>&1
)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "wrong-origin setup exited $exit_status instead of 2"
assert_contains "$output" 'origin is https://example.invalid/wrong.git; expected https://github.com/poolsideai/llama.cpp.git'

dirty_runtime="$empty_home/dirty-runtime"
git init -q "$dirty_runtime"
git -C "$dirty_runtime" remote add origin https://github.com/poolsideai/llama.cpp.git
touch "$dirty_runtime/untracked"
set +e
output="$(
    HOME="$empty_home" \
    LAGUNA_RUNTIME_DIR="$dirty_runtime" \
    LAGUNA_STATE_DIR="$empty_home/state" \
    "$LAUNCHER" setup 2>&1
)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "dirty setup exited $exit_status instead of 2"
assert_contains "$output" 'has uncommitted changes; clean or move them before setup'

rewritten_origin_runtime="$empty_home/rewritten-origin-runtime"
git init -q "$rewritten_origin_runtime"
git -C "$rewritten_origin_runtime" remote add origin https://github.com/poolsideai/llama.cpp.git
rewrite_config="$empty_home/rewrite.gitconfig"
git config --file "$rewrite_config" url."git@github.com:".insteadOf https://github.com/
set +e
output="$(
    HOME="$empty_home" \
    PATH="/usr/bin:/bin" \
    GIT_CONFIG_GLOBAL="$rewrite_config" \
    LAGUNA_RUNTIME_DIR="$rewritten_origin_runtime" \
    LAGUNA_STATE_DIR="$empty_home/state" \
    "$LAUNCHER" setup 2>&1
)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "rewritten-origin setup exited $exit_status instead of 2"
[[ "$output" == *'cmake is required; run: brew install cmake'* ]] ||
    fail "rewritten-origin setup did not reach CMake prerequisite: $output"
[[ "$output" != *'origin is git@github.com:poolsideai/llama.cpp.git'* ]] ||
    fail 'setup validated the transport-rewritten origin instead of the configured origin'

printf '%s\n' 'ok - Laguna launcher checks passed'
