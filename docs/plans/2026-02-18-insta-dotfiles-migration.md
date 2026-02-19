# Insta-Dotfiles Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create shared shell config and work-laptop device folder to replace insta-dotfiles repo.

**Architecture:** Extract generic zsh config to `shared/.zshrc.common`, create `devices/insta-laptop/.zshrc` that sources common and adds work-specific config.

**Tech Stack:** zsh, oh-my-zsh, fzf, asdf

---

### Task 1: Create shared/.zshrc.common

**Files:**
- Create: `shared/.zshrc.common`

**Step 1: Create the shared zshrc.common file**

```zsh
# Generic zsh configuration - sourced by device-specific .zshrc files

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="agkozak"

# Plugins
plugins=(
  # system
  macos
  brew
  colored-man-pages
  git
  gitfast
  gitignore
  # tools
  aws
  docker
  docker-compose
  zoxide
  httpie
  terraform
  tig
  tmux
  # Javascript
  node
  yarn
  # Ruby
  bundler
  ruby
  # Golang
  golang
)

# Custom zfuncs
fpath+=~/.zfunc

# Homebrew completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

source $ZSH/oh-my-zsh.sh

# Environment
export GIT_CEILING_DIRECTORIES=~
export TERM="xterm-256color"
export EDITOR='nvim'
export VISUAL='code'

# Aliases
alias vim='nvim'
alias zshconfig="vim ~/.zshrc"
alias brewski='bubu; brew doctor'

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
alias preview="fzf --preview 'bat --color \"always\" {}'"
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"

_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# CLI improvements
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
alias ping='prettyping --nolegend'
alias top="sudo htop"

# eza/ls
alias eza="eza --header --color-scale --time-style=long-iso --group-directories-first"
alias ls=eza

# PATH
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH=$PATH:$HOME/go/bin:/usr/local/opt/go/libexec/bin
export PATH=$PATH:$GOPATH/bin
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.docker/bin:$PATH
export PATH=$HOME/zig:$PATH
export PATH=$HOME/bin:$PATH

# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# zsh-syntax-highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Git utilities
alias git_delete_squashed='git checkout -q master && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base master $branch) && [[ $(git cherry master $(git commit-tree $(git rev-parse $branch\^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done'

# FZF functions
function branches () {
  git branch --sort=-committerdate |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --preview="git log {} | bat --style=plain --color=always --line-range :500" |
    xargs git checkout
}

function activate-venv() {
  local selected_env
  selected_env=$(ls ~/.venv/ | fzf)

  if [ -n "$selected_env" ]; then
    source "$HOME/.venv/$selected_env/bin/activate"
  fi
}

function delete-branches() {
  git branch |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --multi --preview="git log {} | bat --style=plain --color=always --line-range :500" |
    xargs git branch --delete --force
}

function pr-checkout() {
  local jq_template pr_number

  jq_template='"'\
'#\(.number) - \(.title)'\
'\t'\
'Author: \(.user.login)\n'\
'Created: \(.created_at)\n'\
'Updated: \(.updated_at)\n\n'\
'\(.body)'\
'"'

  pr_number=$(
    gh api 'repos/:owner/:repo/pulls' |
    jq ".[] | $jq_template" |
    sed -e 's/"\(.*\)"/\1/' -e 's/\\t/\t/' |
    fzf \
      --with-nth=1 \
      --delimiter='\t' \
      --preview='echo -e {2} | bat --style=plain --color=always --line-range :500 -l markdown' \
      --preview-window=top:wrap |
    sed 's/^#\([0-9]\+\).*/\1/'
  )

  if [ -n "$pr_number" ]; then
    gh pr checkout "$pr_number"
  fi
}
```

**Step 2: Verify syntax**

Run: `zsh -n shared/.zshrc.common`
Expected: No output (no syntax errors)

**Step 3: Commit**

```bash
git add shared/.zshrc.common
git commit -m "Add shared zshrc.common with generic shell config"
```

---

### Task 2: Create devices/insta-laptop directory and .zshrc

**Files:**
- Create: `devices/insta-laptop/.zshrc`

**Step 1: Create directory and .zshrc file**

```zsh
# Work laptop zsh configuration
# Sources shared config and adds work-specific settings

source ~/.zshrc.common

# Instacart shell profile (managed by insta-setup)
source ~/.instacart_shell_profile

# Bento completions
export BENTO_COMPLETIONS_VERSION=2
autoload -U compinit; compinit
source <(bento completion zsh --silent)
export PGHOST=localhost

# nvm auto-switch on directory change
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Gohan setup
[ -f "$HOME/.config/gohan/gohan.sh" ] && source "$HOME/.config/gohan/gohan.sh"

# Terraform alias (work-specific path)
alias terraform=~/tf-instacart/isc-terraform
```

**Step 2: Verify syntax**

Run: `zsh -n devices/insta-laptop/.zshrc`
Expected: No output (no syntax errors)

**Step 3: Commit**

```bash
git add devices/insta-laptop/.zshrc
git commit -m "Add insta-laptop device with work-specific zshrc"
```

---

### Task 3: Update existing device .zshrc files to source common (if needed)

**Files:**
- Check: `devices/bento/.zshrc` (if exists)
- Check: `devices/Ziyuns-Mac-mini/.zshrc` (if exists)

**Step 1: Check if other devices have .zshrc files that should source common**

Run: `ls -la devices/*/.zshrc 2>/dev/null || echo "No device .zshrc files found"`

If files exist, evaluate whether they should source `.zshrc.common`. This is a decision point - may require user input.

**Step 2: Commit any changes**

```bash
git add -A && git commit -m "Update device .zshrc files to source common" || echo "No changes"
```

---

### Task 4: Test install.sh dry run

**Step 1: Run dry run for insta-laptop**

Run: `DRY_RUN=1 ./install.sh insta-laptop`

Expected: Output showing what would be linked, including:
- `.zshrc.common -> shared/.zshrc.common`
- `.zshrc -> devices/insta-laptop/.zshrc`

**Step 2: Verify no errors in output**

Review output for any warnings or missing files.

---

### Task 5: Final commit and summary

**Step 1: Ensure all changes committed**

Run: `git status`
Expected: Clean working tree

**Step 2: Push to remote**

Run: `git push`

---

## Post-Implementation (Manual Steps)

On the work laptop:

1. Clone/pull this repo
2. Run `./install.sh insta-laptop`
3. Create `~/.gitconfig.local` with work email and signing key
4. Archive the insta-dotfiles repo on GitHub
