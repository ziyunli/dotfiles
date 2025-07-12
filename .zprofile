case $(uname) in
Darwin)
  # Go
  export PATH="${HOME}/go/bin:$PATH"

  # Rust
  export PATH="${HOME}/.cargo/bin:$PATH"

  export PATH="${HOME}/.local/bin:$PATH"

  eval "$(/opt/homebrew/bin/brew shellenv)"
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

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
