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

See `setup_linux.sh` instead.

Some extra steps for a 'real' Linux (i.e. not using WSL2 or Docker)

```shell
# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install alacritty
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

# Install fcitx input method system
sudo apt install fcitx-bin
# Install Google Pinyin Chinese input method
sudo apt install fcitx-googlepinyin
# Replace icon
sudo apt remove fcitx-ui-classic
sudo apt install fcitx-ui-qimpanel
```
