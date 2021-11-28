case $(uname) in
Darwin)
  # commands for OS X go here
  if [ "$(arch)" = "arm64" ]; then
    export PATH="/opt/homebrew/bin:$PATH"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    export PATH="/usr/local/bin:$PATH"
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # Collection of GNU find, xargs, and locate
  # brew info findutils
  PATH="$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin:$PATH"

  # https://github.com/zsh-users/zsh-syntax-highlighting
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

  # Load nvm from homebrew
  export NVM_DIR="$HOME/.nvm"
  [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

  # asdf from homebrew
  . "$HOMEBREW_PREFIX/opt/asdf/asdf.sh"

  ;;
Linux)
  # commands for Linux go here
  alias fd=fdfind

  # Syntax highlighting
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  # zsh options
  setopt notify
  setopt correct
  setopt auto_cd
  setopt auto_list
  # some nice formatting for you
  export PROMPT='%B%F{yellow}%~>%b%f '

  # from apt-file search fontconfig.pc
  export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/fontconfig.pc

  # adr-tool
  export PATH=$HOME/adr-tools-3.0.0/src:$PATH

  # Load nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

  # Load asdf
  . $HOME/.asdf/asdf.sh

  ;;
FreeBSD)
  # commands for FreeBSD go here
  ;;
esac

# Cargo
. "$HOME/.cargo/env"
