# Agents

This folder keep system prompts and commands that are shared by different LLM CLIs.

Currently I am using
* Claude Code
* OpenAI Codex
* Google Gemini

Each of them use different folders to store system prompts, so we just soft-link from this folder.

For example

```sh
ln -s ~/agents/AGENTS.md ~/.claude/CLAUDE.md
ln -s ~/agents/AGENTS.md ~/.codex/AGENTS.md
ln -s ~/agents/AGENTS.md ~/.gemini/GEMINI.md
```
