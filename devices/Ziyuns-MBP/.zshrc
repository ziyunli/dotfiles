# MBP zsh configuration
# Sources shared config and adds machine-specific settings

# Homebrew must be before sourcing shared config for completions/plugins.
eval "$(/opt/homebrew/bin/brew shellenv)"

# macOS-specific plugin must be set before sourcing shared config.
DEVICE_PLUGINS=(macos)

source ~/.zshrc.common
