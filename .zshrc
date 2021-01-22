# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=agkozak

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git               # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/git
  colored-man-pages # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/colored-man-pages
  # tools
  fasd # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/fasd
  tmux # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/tmux
  tig  # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/tig
  taskwarrior
  # Rust
  rust  # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/rust
  cargo # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/cargo
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# User configuration
export TERM="xterm-256color"

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
export EDITOR='nvim'
alias vim='nvim'
alias zshconfig="vim ~/.zshrc"
alias brewski='brew update && brew upgrade && brew cleanup; brew doctor'

export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# rbenv
export PATH=$HOME/.rbenv/shims:$PATH

# Golang
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Flutter
export PATH=$PATH:$HOME/flutter/bin

# Exercism
if [ -f ~/.config/exercism/exercism_completion.zsh ]; then
  . ~/.config/exercism/exercism_completion.zsh
fi

export GIT_CEILING_DIRECTORIES=~

case $(uname) in
Darwin)
  # commands for OS X go here
  eval "$(/usr/local/bin/pyenv init -)"
  if which pyenv-virtualenv-init >/dev/null; then eval "$(pyenv virtualenv-init -)"; fi

  eval "$(/usr/local/bin/rbenv init -)"

  eval $(thefuck --alias)

  # https://github.com/zsh-users/zsh-syntax-highlighting
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ;;
Linux)
  # commands for Linux go here
  alias fd=fdfind

  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  # Syntax highlighting
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  # zsh options
  setopt notify
  setopt correct
  setopt auto_cd
  setopt auto_list
  # some nice formatting for you
  export PROMPT='%B%F{yellow}%~>%b%f '
  ;;
FreeBSD)
  # commands for FreeBSD go here
  ;;
esac

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}
# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# https://remysharp.com/2018/08/23/cli-improved
alias preview="fzf --preview 'bat --color \"always\" {}'"
# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"
# Follow symbolic links, and don't want it to exclude hidden files
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/ziyunli/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/ziyunli/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/ziyunli/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/ziyunli/google-cloud-sdk/completion.zsh.inc'; fi

# https://remysharp.com/2018/08/23/cli-improved
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
alias ping='prettyping --nolegend'
alias top="sudo htop" # alias top and fix high sierra bug
eval "$(fasd --init auto)"

# ~/bin overrides everything else
export PATH=$HOME/bin:$HOME/.local/bin:$PATH

autoload -Uz compinit
compinit
