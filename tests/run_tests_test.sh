#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    printf 'not ok - %s\n' "$*" >&2
    exit 1
}

temp_root="$(mktemp -d)"
trap 'rm -rf "$temp_root"' EXIT

# Each scenario gets its own repo copy holding only the runner and fake tests,
# so the runner under test never executes the real suite.
new_repo() {
    repo="$temp_root/$1"
    mkdir -p "$repo/tests"
    cp "$ROOT_DIR/run-tests.sh" "$repo/"
}

add_test() {  # <file-name> <body>
    printf '%s\n' "$2" > "$repo/tests/$1"
}

run_runner() {
    status=0
    TMPDIR="$temp_root" "$repo/run-tests.sh" "$@" > "$temp_root/stdout" 2> "$temp_root/stderr" || status=$?
    output="$(<"$temp_root/stdout")"
    errors="$(<"$temp_root/stderr")"
}

assert_output() {
    grep -Fxq -- "$1" <<< "$output" || fail "output is missing line: $1"$'\n'"$output"
}

new_repo passing
add_test a_test.sh 'echo "ok - shell"'
add_test b_test.py 'print("ok - python")'
run_runner
[[ "$status" -eq 0 ]] || fail "passing suite exited $status: $output $errors"
assert_output 'ok    tests/a_test.sh'
assert_output 'ok    tests/b_test.py'
assert_output '2 passed, 0 failed'
[[ -z "$errors" ]] || fail "unexpected stderr: $errors"
[[ "$output" != *'logs: '* ]] || fail "passing suite printed a log directory: $output"
! compgen -G "$temp_root/dotfiles-tests.*" > /dev/null || fail "passing suite left its logs behind"
printf '%s\n' 'ok - run-tests passes a clean shell and python suite and removes its logs'

new_repo failing
add_test a_test.sh 'echo "not ok - boom" >&2; exit 3'
add_test b_test.sh 'echo "ok - still runs"'
run_runner
[[ "$status" -eq 1 ]] || fail "failing suite exited $status"
assert_output 'FAIL  tests/a_test.sh (exit 3)'
assert_output 'ok    tests/b_test.sh'
assert_output '1 passed, 1 failed'
grep -Fq 'not ok - boom' <<< "$output" || fail "failure output was not shown: $output"
log_dir="$(sed -n 's/^logs: //p' <<< "$output")"
[[ -n "$log_dir" && -s "$log_dir/tests/a_test.sh.stderr" ]] || fail "failure logs were not kept: $output"
printf '%s\n' 'ok - run-tests reports a failure, keeps going, and keeps its logs'

new_repo noisy
add_test a_test.sh 'echo "warning: leaked" >&2'
run_runner
[[ "$status" -eq 1 ]] || fail "noisy suite exited $status"
assert_output 'FAIL  tests/a_test.sh (passed but wrote to stderr)'
grep -Fq 'warning: leaked' <<< "$output" || fail "stray stderr was not shown: $output"
printf '%s\n' 'ok - run-tests fails a passing test that writes to stderr'

new_repo empty
run_runner
[[ "$status" -eq 1 ]] || fail "empty suite exited $status"
grep -Fq 'no tests found' <<< "$errors" || fail "empty suite did not explain itself: $errors"
printf '%s\n' 'ok - run-tests fails when it finds no tests'

new_repo help
run_runner --help
[[ "$status" -eq 0 ]] || fail "--help exited $status"
assert_output 'Usage:'
assert_output '  ./run-tests.sh'
printf '%s\n' 'ok - run-tests prints usage with --help'

run_runner --bogus
[[ "$status" -eq 2 ]] || fail "unknown argument exited $status"
grep -Fxq 'run-tests: unexpected arguments: --bogus' <<< "$errors" || fail "unknown argument was not named: $errors"
grep -Fxq 'Usage:' <<< "$errors" || fail "unknown argument printed no usage: $errors"
[[ -z "$output" ]] || fail "unknown argument wrote to stdout: $output"
printf '%s\n' 'ok - run-tests rejects unknown arguments with exit 2'
