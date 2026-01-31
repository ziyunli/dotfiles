# Create oh-my-zsh cache directories with proper permissions before oh-my-zsh creates them
if [[ ! -d "$HOME/.oh-my-zsh/cache/completions" ]]; then
    mkdir -p "$HOME/.oh-my-zsh/cache/completions"
    chmod 755 "$HOME/.oh-my-zsh/cache"
    chmod 755 "$HOME/.oh-my-zsh/cache/completions"
fi

# Disable async rendering of the git branch info in the prompt. This breaks some scripts.
zstyle ':omz:alpha:lib:git' async-prompt no
# shellcheck shell=bash
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bento"/' "$HOME/.oh-my-zsh/templates/zshrc.zsh-template"
# Uncomment line to auto update oh-my-zsh without prompting the user
sed -i "s/# zstyle ':omz:update' mode auto/zstyle ':omz:update' mode auto/" "$HOME/.oh-my-zsh/templates/zshrc.zsh-template"

# Allow the user to override our default config and provide their own
if [[ ! -f "$HOME/.zshrc.d/oh-my-zsh.zsh" ]]; then
    # Use the default template we provide
    source "$HOME/.oh-my-zsh/templates/zshrc.zsh-template"
fi
