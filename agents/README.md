# Agents

This folder keep system prompts and commands that are shared by different LLM CLIs. Each agent has its own configuration folder, so we soft-link from this folder.

Currently I am using

- Claude Code: `~/.claude`, see https://code.claude.com/docs/en/settings
- OpenAI Codex: `~/.codex`, see https://developers.openai.com/codex/guides/agents-md
- Google Gemini: `~/.gemini`, see https://geminicli.com/docs/cli/gemini-md/
- AMP: `~/.config/amp`, see https://ampcode.com/manual#AGENTS.md

`AGENTS.md` stores global user preference:

```shell
ln -s ~/agents/AGENTS.md ~/.claude/CLAUDE.md
ln -s ~/agents/AGENTS.md ~/.codex/AGENTS.md
ln -s ~/agents/AGENTS.md ~/.gemini/GEMINI.md

mkdir -p ~/.config/amp
ln -s ~/agents/AGENTS.md ~/.config/amp/AGENTS.md
```

# Commands

CLI commands are even more different for each agent.

Claude Code and Codex use more standard format, so we just soft-link from this folder.

```shell
ln -s ~/agents/commands ~/.claude/commands
ln -s ~/agents/commands ~/.codex/prompts
```
