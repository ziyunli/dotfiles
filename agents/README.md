# Agents

This folder keep system prompts and commands that are shared by different LLM CLIs.

Currently I am using
* Claude Code
* OpenAI Codex
* Google Gemini
* Ampcode

Each of them use different folders to store system prompts, so we just soft-link from this folder.

For example

```sh
ln -s ~/agents/AGENTS.md ~/.claude/CLAUDE.md
ln -s ~/agents/AGENTS.md ~/.codex/AGENTS.md
ln -s ~/agents/AGENTS.md ~/.gemini/GEMINI.md
ln -s ~/agents/AGENTS.md ~/.config/amp/AGENTS.md

ln -s ~/agents/commands ~/.claude/commands
ln -s ~/agents/commands ~/.codex/prompts
ln -s ~/agents/commands ~/.config/amp/commands
```

Gemeni's commands are TOML based, so we can ask LLM to generate them. For example:

```text
Convert the commands within @agetns/commonds to TOML format that Google Geminu uses.

Below is an example.

# In: <project>/.gemini/commands/changelog.toml
# Invoked via: /changelog 1.2.0 added "Support for default argument parsing."

description = "Adds a new entry to the project\'s CHANGELOG.md file."
prompt = """
# Task: Update Changelog

You are an expert maintainer of this software project. A user has invoked a command to add a new entry to the changelog.

**The user\'s raw command is appended below your instructions.**

Your task is to parse the `<version>`, `<change_type>`, and `<message>` from their input and use the `write_file` tool to correctly update the `CHANGELOG.md` file.

## Expected Format
The command follows this format: `/changelog <version> <type> <message>`
- `<type>` must be one of: "added", "changed", "fixed", "removed".

## Behavior
1. Read the `CHANGELOG.md` file.
2. Find the section for the specified `<version>`.
3. Add the `<message>` under the correct `<type>` heading.
4. If the version or type section doesn\'t exist, create it.
5. Adhere strictly to the "Keep a Changelog" format.
"""

Save the generated TOML file to ~/.gemini/commands/
```
