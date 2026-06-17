# Homebrew must be on PATH before interactive zsh loads shared completions.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Login-shell environment inherited by child processes.
typeset -U path
path=(
  "$HOME/.local/bin"
  "$HOME/.opencode/bin"
  "$HOME/bin"
  "$HOME/go/bin"
  "$HOME/.cargo/bin"
  $path
)
export PATH
