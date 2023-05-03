sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev libssl-dev git \
tig zsh tmux neovim fd-find fasd curl cmake pkg-config \
libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3 \
automake autoconf unzip \
postgresql postgresql-contrib postgresql-client

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

[[ ! -d $ZSH_CUSTOM/themes ]] && mkdir $ZSH_CUSTOM/themes
git clone https://github.com/agkozak/agkozak-zsh-prompt $ZSH_CUSTOM/themes/agkozak
ln -s $ZSH_CUSTOM/themes/agkozak/agkozak-zsh-prompt.plugin.zsh $ZSH_CUSTOM/themes/agkozak.zsh-theme

# zsh-syntax-highlighting
[[ ! -d $ZSH_CUSTOM/themes ]] && mkdir $ZSH_CUSTOM/plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
./.fzf/install

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install exa ripgrep git-delta zoxide

# Python Poetry
curl -sSL https://install.python-poetry.org | python3 -
[[ ! -d ~/.zfunc ]] && mkdir ~/.zfunc
poetry completions zsh > ~/.zfunc/_poetry

# SSH Server https://linuxhint.com/enable-ssh-server-pop-os/
sudo apt install openssh-server
sudo systemctl status ssh

# Mamba
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
conda config --set auto_activate_base false
