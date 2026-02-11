#!/usr/bin/env bash
# Claude Code status line script
# Shows: user@host:cwd ModelName [████████░░░░] 60%

input=$(cat)
user=$(whoami)
host=$(hostname -s)
cwd=$(pwd)
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$user" "$host" "$cwd"

if [ -n "$used" ]; then
  filled=$(awk -v p="$used" 'BEGIN{printf "%.0f",p/5}')
  empty=$((20 - filled))
  bar='['
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$((i + 1)); done
  while [ $i -lt 20 ]; do bar="${bar}░"; i=$((i + 1)); done
  bar="${bar}]"

  if [ "${used%%.*}" -ge 90 ]; then
    c='\033[01;31m'   # red
  elif [ "${used%%.*}" -ge 70 ]; then
    c='\033[01;33m'   # yellow
  else
    c='\033[01;36m'   # cyan
  fi

  printf ' %b%s\033[00m %s %.0f%%' "$c" "$model" "$bar" "$used"
fi
