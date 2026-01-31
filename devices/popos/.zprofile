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

  alias brewski='brew update && brew upgrade && brew cleanup; brew doctor'

  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

  # Added by OrbStack: command-line tools and integration
  source ~/.orbstack/shell/init.zsh 2>/dev/null || :
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


# Added by Toolbox App
export PATH="$PATH:/home/ziyunli/.local/share/JetBrains/Toolbox/scripts"

