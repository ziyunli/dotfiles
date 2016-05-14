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
plugins=(brew brew-cask git vagrant node npm nvm python rust cargo t)

# User configuration

export PATH=~/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}
# export MANPATH="/usr/local/man:$MANPATH"
export LIBRARY_PATH="$LIBRARY_PATH:/usr/local/lib"

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
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Create CMD link for Visual Studio Code
code () {
    if [[ $# = 0 ]]
    then
        open -a "Visual Studio Code"
    else
        [[ $1 = /* ]] && F="$1" || F="$PWD/${1#./}"
        open -a "Visual Studio Code" --args "$F"
    fi
}

# read the EXAMPLES section only for a command
# from https://news.ycombinator.com/item?id=10025216
# `brew install gnu-sed` beforehand
eg () {
    MAN_KEEP_FORMATTING=1 man "$@" 2>/dev/null \
        | gsed --quiet --expression='/^E\(\x08.\)X\(\x08.\)\?A\(\x08.\)\?M\(\x08.\)\?P\(\x08.\)\?L\(\x08.\)\?E/{:a;p;n;/^[^ ]/q;ba}' \
        | ${MANPAGER:-${PAGER:-pager -s}}
}

# Init NVM
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

# Trick Emacs into GUI mode
alias gemacs=/Applications/Emacs.app/Contents/MacOS/Emacs

# Golang
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# OCaml
. ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

# Python
export WORKON_HOME=~/virtualenv
source /usr/local/bin/virtualenvwrapper.sh

# Haskell
export PATH=~/.cabal/bin/:$PATH

# Rust racer
export RUST_SRC_PATH=~/codebase/rust/src
export PATH=$PATH:~/codebase/racer/target/release:~/.cargo/bin
export OPENSSL_INCLUDE_DIR=/usr/local/opt/openssl/include
export DEP_OPENSSL_INCLUDE=/usr/local/opt/openssl/include

# The next line updates PATH for the Google Cloud SDK.
source ~/google-cloud-sdk/path.zsh.inc
# The next line enables shell command completion for gcloud.
source ~/google-cloud-sdk/completion.zsh.inc

export ANDROID_HOME=/usr/local/opt/android-sdk

export GIT_CEILING_DIRECTORIES=~

[ -s ~/.dnx/dnvm/dnvm.sh ] && . ~/.dnx/dnvm/dnvm.sh # Load dnvm
