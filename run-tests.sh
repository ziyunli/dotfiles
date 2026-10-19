#!/usr/bin/env bash
#
# run-tests.sh - Run every test in tests/ and summarize the results
#
# Runs tests/*_test.sh with bash, then tests/*_test.py with `python3 -I`, one
# at a time and each group in name order, with stdin closed. A test passes only
# when it exits 0 AND writes nothing to stderr, so stray warnings fail the suite
# instead of scrolling past.
#
# Prints one line per test. For a failing test it also prints the tail of its
# stderr and stdout, keeps every test's full output, and prints the log
# directory; logs are deleted when everything passes.
#
# Usage:
#   ./run-tests.sh
#
# Exit status: 0 when every test passes, 1 otherwise (including no tests found),
# 2 for unexpected arguments.
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAIL_LINES=20

# Prints the header comment above, from the title line to the last comment line.
usage() {
    awk 'NR < 3 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

if [[ $# -gt 0 ]]; then
    if [[ $# -eq 1 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
        usage
        exit 0
    fi
    printf 'run-tests: unexpected arguments: %s\n' "$*" >&2
    usage >&2
    exit 2
fi

cd "$DOTFILES_DIR"
shopt -s nullglob
tests=(tests/*_test.sh tests/*_test.py)
if [[ ${#tests[@]} -eq 0 ]]; then
    printf 'run-tests: no tests found in %s/tests\n' "$DOTFILES_DIR" >&2
    exit 1
fi

log_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tests.XXXXXX")"
mkdir -p "$log_dir/tests"
passed=0
failed=0

show_tail() {  # <label> <file>
    [[ -s "$2" ]] || return 0
    printf '      --- %s (last %d lines)\n' "$1" "$TAIL_LINES"
    tail -n "$TAIL_LINES" "$2" | sed 's/^/      /'
}

for test in "${tests[@]}"; do
    stdout_log="$log_dir/$test.stdout"
    stderr_log="$log_dir/$test.stderr"
    status=0
    case "$test" in
        *.py) python3 -I "$test" < /dev/null > "$stdout_log" 2> "$stderr_log" || status=$? ;;
        *)    bash "$test" < /dev/null > "$stdout_log" 2> "$stderr_log" || status=$? ;;
    esac

    if [[ $status -eq 0 && ! -s "$stderr_log" ]]; then
        printf 'ok    %s\n' "$test"
        passed=$((passed + 1))
        continue
    fi

    if [[ $status -ne 0 ]]; then
        printf 'FAIL  %s (exit %d)\n' "$test" "$status"
    else
        printf 'FAIL  %s (passed but wrote to stderr)\n' "$test"
    fi
    show_tail stderr "$stderr_log"
    show_tail stdout "$stdout_log"
    failed=$((failed + 1))
done

printf '%d passed, %d failed\n' "$passed" "$failed"
if [[ $failed -gt 0 ]]; then
    printf 'logs: %s\n' "$log_dir"
    exit 1
fi
rm -rf "$log_dir"
