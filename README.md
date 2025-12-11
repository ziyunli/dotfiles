## Linux (Debian-based)

See `setup_linux.sh` instead.

Some extra steps for a 'real' Linux (i.e. not using WSL2 or Docker)

```shell
# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install alacritty
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator ~/.cargo/bin/alacritty 50
sudo update-alternatives --config x-terminal-emulator

# Install fcitx input method system
sudo apt install fcitx-bin
# Install Google Pinyin Chinese input method
sudo apt install fcitx-googlepinyin
# Replace icon
sudo apt remove fcitx-ui-classic
sudo apt install fcitx-ui-qimpanel
```
