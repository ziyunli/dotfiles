set PYENV_ROOT ~/.pyenv
set GOPATH ~/go
set CARGO_PATH ~/.cargo/bin
set RBENV_ROOT  ~/.rbenv/shims/
set FLUTTER_PATH ~/flutter/bin
set PATH ~/bin \
    $FLUTTER_PATH \
    $CARGO_PATH \
    $GOPATH \
    $RBENV_ROOT \
    $PYENV_ROOT \
    /usr/local/opt/curl/bin \
    /usr/local/bin \
    /usr/local/sbin \
    $PATH

alias brewski="brew update && brew upgrade && brew cleanup; brew doctor"

# https://github.com/junegunn/fzf#fish-shell
set -g FZF_CTRL_T_COMMAND "command find -L \$dir -type f 2> /dev/null | sed '1d; s#^\./##'"

# Completion for Kitty
kitty + complete setup fish | source

# eval op signin my