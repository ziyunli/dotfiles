set PYENV_ROOT ~/.pyenv
set GOPATH ~/go
set CARGO_PATH ~/.cargo/bin
set RBENV_ROOT  ~/.rbenv/shims/
set FLUTTER_PATH ~/flutter/bin
set PATH $PATH \
    ~/bin \
    $FLUTTER_PATH \
    $CARGO_PATH \
    $GOPATH \
    $RBENV_ROOT \
    $PYENV_ROOT \
    /usr/local/opt/curl/bin \
    /usr/local/bin \
    /usr/bin \
    /bin \
    /usr/local/sbin \
    /usr/sbin \
    /sbin

# Completion for Kitty
kitty + complete setup fish | source

# eval op signin my