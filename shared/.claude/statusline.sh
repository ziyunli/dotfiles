#!/usr/bin/env bash
# Claude Code status line script
# Shows: user@host:cwd ModelName [████████░░░░] 60%

input=$(cat)
user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
model=$(echo "$input" | jq -r '.model.display_name')

# Calculate token usage from current_usage (reflects compaction)
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
total_tokens=$((input_tokens + cache_read))
if [ "$context_size" -gt 0 ]; then
  used=$((total_tokens * 100 / context_size))
else
  used=0
fi

# Git branch
git_branch=""
if [ -n "$dir" ] && [ -d "$dir" ]; then
  git_branch=$(cd "$dir" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$user" "$host" "$dir"

if [ -n "$git_branch" ]; then
  printf ' \033[01;35m(%s)\033[00m' "$git_branch"
fi

if [ "$context_size" -gt 0 ]; then
  filled=$((used / 5))
  [ "$filled" -gt 20 ] && filled=20
  bar='['
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$((i + 1)); done
  while [ $i -lt 20 ]; do bar="${bar}░"; i=$((i + 1)); done
  bar="${bar}]"

  if [ "$used" -ge 90 ]; then
    c='\033[01;31m'   # red
  elif [ "$used" -ge 70 ]; then
    c='\033[01;33m'   # yellow
  else
    c='\033[01;36m'   # cyan
  fi

  printf ' %b%s\033[00m %s %d%%' "$c" "$model" "$bar" "$used"
fi
