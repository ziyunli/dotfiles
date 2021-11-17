# MacOS

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle
asdf install

# Python Poetry
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
mkdir $ZSH_CUSTOM/plugins/poetry
poetry completions zsh > $ZSH_CUSTOM/plugins/poetry/_poetry
```

# Linux (Debian-based)

```shell
sudo apt install tig zsh tmux neovim fd-find fasd build-essential curl cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
[[ ! -d $ZSH_CUSTOM/themes ]] && mkdir $ZSH_CUSTOM/themes\
git clone https://github.com/agkozak/agkozak-zsh-prompt $ZSH_CUSTOM/themes/agkozak\
ln -s $ZSH_CUSTOM/themes/agkozak/agkozak-zsh-prompt.plugin.zsh $ZSH_CUSTOM/themes/agkozak.zsh-theme

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting


# python
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
# open a new session
git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
./.fzf/install

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install exa ripgrep git-delta alacritty
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator ~/.cargo/bin/alacritty 50
sudo update-alternatives --config x-terminal-emulator

# Haskell Stack
curl -sSL https://get.haskellstack.org/ | sh

# dotnet + F#
wget https://packages.microsoft.com/config/ubuntu/20.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-5.0 aspnetcore-runtime-5.0

# asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0

# Prerequisite for Python
sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev libssl-dev git

asdf plugin add python
asdf install python 3.9.1

# Python Poetry
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
mkdir $ZSH_CUSTOM/plugins/poetry
poetry completions zsh > $ZSH_CUSTOM/plugins/poetry/_poetry

asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang latest

asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir latest

# Install fcitx input method system
sudo apt install fcitx-bin
# Install Google Pinyin Chinese input method
sudo apt install fcitx-googlepinyin
# Replace icon
sudo apt remove fcitx-ui-classic
sudo apt install fcitx-ui-qimpanel
```
