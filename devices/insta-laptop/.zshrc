# Instacart laptop zsh configuration
# Sources shared config and adds work-machine hooks

# macOS-specific plugin must be set before sourcing shared config.
DEVICE_PLUGINS=(macos)

source ~/.zshrc.common

# Instacart setup owns this profile; keep its generated contents local.
[ -f "$HOME/.instacart_shell_profile" ] && source "$HOME/.instacart_shell_profile"

# >>> gohan setup, do not edit this section <<<
# !! Contents within this block are managed by gohan !!
[ -f "$HOME/.config/gohan/gohan.sh" ] && source "$HOME/.config/gohan/gohan.sh"
# <<< gohan setup end <<<
