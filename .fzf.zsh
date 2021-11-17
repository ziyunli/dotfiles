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
  if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    export PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
  fi

  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "$HOME/.fzf/shell/key-bindings.zsh"
  ;;
FreeBSD)
  # commands for FreeBSD go here
  ;;
esac
