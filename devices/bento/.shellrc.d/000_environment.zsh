# Bento moved environment setup out of shellrc.d; older ~/.zshrc files do not load it.
# Load it before the interactive NVM and pyenv hooks.
for env_file in "$HOME"/.shellenv.d/*.(sh|zsh)(N); do
    source "$env_file"
done
unset env_file
