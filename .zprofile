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

  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
  ;;
Linux)
  # commands for Linux go here
  alias fd=fdfind

  # Syntax highlighting
  source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  # zsh options
  setopt notify
  setopt correct
  setopt auto_cd
  setopt auto_list
  # some nice formatting for you
  export PROMPT='%B%F{yellow}%~>%b%f '

  # from apt-file search fontconfig.pc
  export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/fontconfig.pc
  ;;
FreeBSD)
  # commands for FreeBSD go here
  ;;
esac

# Cargo
. "$HOME/.cargo/env"
