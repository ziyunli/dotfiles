# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="cobalt2"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

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
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(brew brew-cask git git-extras node npm yarn nvm python taskwarrior fasd opam)

# User configuration

export PATH=~/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}
# export MANPATH="/usr/local/man:$MANPATH"
export LIBRARY_PATH="$LIBRARY_PATH:/usr/local/lib"

fpath+=~/.zfunc

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
export EDITOR='nvim'
alias vim='nvim'
alias zshconfig="vim ~/.zshrc"
alias brewski='brew update && brew upgrade && brew cleanup; brew doctor'

export PATH="/usr/local/opt/curl/bin:$PATH"

# https://news.ycombinator.com/item?id=11806767
precmd() {
    eval 'if [ "$(id -u)" -ne 0 ]; then echo "$(date "+%Y-%m-%d.%H:%M:%S") $(pwd) $(history | tail -n 1)" >>! ~/Dropbox/Logs/Zsh/zsh-history-$(date "+%Y-%m-%d").log; fi'
}

# Init NVM
export NVM_DIR="$HOME/.nvm"
. "/usr/local/opt/nvm/nvm.sh"

# Init OPAM
test -r /Users/ziyunli/.opam/opam-init/init.zsh && . /Users/ziyunli/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

# Yarn global install into nvm directory
alias yga='yarn global add --global-folder=`yarn global bin` '
alias ygr='yarn global remove --global-folder=`yarn global bin` '
alias ygu='yarn global upgrade --global-folder=`yarn global bin` '

export PYTHONUSERBASE=~/.local
export PATH=$PATH:$PYTHONUSERBASE
source /usr/local/opt/autoenv/activate.sh
eval "$(pipenv --completion)"

# Haskell
export PATH=~/.cabal/bin:$PATH

# Golang
export PATH=~/go/bin:/usr/local/opt/go/libexec/bin:$PATH

# Exercism
if [ -f ~/.config/exercism/exercism_completion.zsh ]; then
  . ~/.config/exercism/exercism_completion.zsh
fi

eval $(thefuck --alias)

export GIT_CEILING_DIRECTORIES=~

function gi() { curl -L -s https://www.gitignore.io/api/$@ ;} 

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# https://remysharp.com/2018/08/23/cli-improved
alias preview="fzf --preview 'bat --color \"always\" {}'"
# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"
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

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
