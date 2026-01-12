#!/bin/bash
# Claude Code Notifications Setup for Ghostty on macOS from https://gist.github.com/bestdan/ffa396de6ac032fa9edd54971706a00b

# Send bell to the current TTY to trigger tab decoration
printf '\a' > /dev/tty

# Notify when Claude finishes a task and is waiting for input
osascript -e 'display notification "Claude has finished and needs your input" with title "Claude Code" sound name "Submarine"'

exit 0
