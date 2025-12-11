# Bento

## Instructions

Comment out `.shellrc.d/080_fzf.zsh`

Install latest fzf

```sh
sudo apt remove fzf -y
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

Install other dependencies
```
cargo install bat zoxide fd-find eza --locked

npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code
```
