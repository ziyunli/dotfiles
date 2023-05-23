case $(uname) in
Darwin)
  # commands for OS X go here
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

  # Added by OrbStack: command-line tools and integration
  source ~/.orbstack/shell/init.zsh 2>/dev/null || :

  # For Zig
  export PATH="${HOME}/zig:$PATH"
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
