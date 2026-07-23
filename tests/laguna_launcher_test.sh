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

output="$($LAUNCHER help)"
assert_contains "$output" 'Usage: laguna <command>'
assert_contains "$output" 'download q4|dflash'
assert_contains "$output" 'serve [--dflash]'

set +e
output="$($LAUNCHER unknown 2>&1)"
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
output="$($LAUNCHER download invalid 2>&1)"
exit_status=$?
set -e
[[ "$exit_status" == "2" ]] || fail "invalid download exited $exit_status instead of 2"
assert_contains "$output" 'download target must be q4 or dflash'

printf '%s\n' 'ok - Laguna launcher checks passed'
