case $(uname) in
Darwin)
  # commands for OS X go here
  # Setup fzf
  # ---------
  export PATH="$PATH:$HOMEBREW_PREFIX/opt/fzf/bin"
  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" 2> /dev/null
  # Key bindings
  # ------------
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  ;;
Linux)
  # commands for Linux go here
  # Setup fzf
  # ---------
  if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
    export PATH="$PATH:/usr/local/opt/fzf/bin"
  fi

  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "/usr/local/opt/fzf/shell/key-bindings.zsh"
  ;;
FreeBSD)
  # commands for FreeBSD go here
  ;;
esac
