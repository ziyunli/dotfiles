# Environment for every zsh invocation, including non-login, non-interactive
# shells (`zsh -c …`) that source only ~/.zshenv — not ~/.zprofile or ~/.zshrc.
# Login/interactive PATH setup belongs in those files; keep this one minimal.

# fzf's git-based install (~/.fzf) is added to PATH by ~/.fzf.zsh, which is
# sourced from ~/.zshrc, so only interactive shells receive it. The tmux alt-p
# file picker runs its `display-popup` body as `zsh -c`; without ~/.fzf/bin here
# that shell cannot find `fzf`, so the popup's command exits and it closes at
# once. The directory guard makes this a no-op where fzf is installed elsewhere.
if [[ -d "$HOME/.fzf/bin" && ":$PATH:" != *":$HOME/.fzf/bin:"* ]]; then
  export PATH="$HOME/.fzf/bin:$PATH"
fi

# >>> gohan setup, do not edit this section <<<
# !! Contents within this block are managed by gohan !!
[ -f "/Users/stephenli/.config/gohan/gohan.sh" ] && source "/Users/stephenli/.config/gohan/gohan.sh"
# <<< gohan setup end <<<
