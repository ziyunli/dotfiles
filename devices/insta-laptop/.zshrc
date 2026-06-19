# Instacart laptop zsh configuration
# Sources shared config and adds work-machine hooks

# macOS-specific plugin must be set before sourcing shared config.
DEVICE_PLUGINS=(macos)

source ~/.zshrc.common

# Instacart setup owns this profile; keep its generated contents local.
[ -f "$HOME/.instacart_shell_profile" ] && source "$HOME/.instacart_shell_profile"
