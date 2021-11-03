case $(uname) in
Darwin)
  # commands for OS X go here
  if [ "$(arch)" = "arm64" ]; then
    export HOMEBREW_PATH="/opt/homebrew"
  else
    export HOMEBREW_PATH="/usr/local"
  fi

  eval "$($HOMEBREW_PATH/bin/brew shellenv)"

  # Collection of GNU find, xargs, and locate
  # brew info findutils
  PATH="$HOMEBREW_PATH/opt/findutils/libexec/gnubin:$PATH"

  # https://github.com/zsh-users/zsh-syntax-highlighting
  source "$HOMEBREW_PATH/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

  # asdf from homebrew
  . "$HOMEBREW_PATH/opt/asdf/asdf.sh"

  # Setup fzf
  # ---------
  export PATH="$PATH:$HOMEBREW_PATH/opt/fzf/bin"
  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "$HOMEBREW_PATH/opt/fzf/shell/completion.zsh" 2> /dev/null
  # Key bindings
  # ------------
  source "$HOMEBREW_PATH/opt/fzf/shell/key-bindings.zsh"
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

  # Load asdf
  . $HOME/.asdf/asdf.sh

  # FZF
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  ;;
FreeBSD)
  # commands for FreeBSD go here
  ;;
esac

# Cargo
. "$HOME/.cargo/env"
