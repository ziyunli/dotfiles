# Deep Merge for `.claude/settings.json`

## Problem

`~/.claude/settings.json` is symlinked from the dotfiles repo on personal machines.
On work machines (AWS Bedrock), the company injects env vars, plugins, and other
config into this file. Symlinking would leak company config into the public repo.

Currently, work machines skip the symlink entirely via `.dotfiles-skip`, losing
all personal settings (hooks, permissions, plugins, model preferences).

## Solution

Add a `.dotfiles-merge` convention to the install system. Files listed in a
device's `.dotfiles-merge` are deep-merged instead of symlinked, combining
personal settings from the repo with existing local (company) config.

## Merge Semantics

- **Objects**: recursively merge
- **Arrays**: concatenate + deduplicate (union)
- **Scalars**: existing local value wins
- **Missing local file**: shared file copied as-is
- **Conflicts**: reported to stderr with path, both values, and which was kept

## Components

### 1. `.dotfiles-merge` file

Same format as `.dotfiles-skip` — one relative path per line, comments with `#`.
Lives in `devices/<dev>/`. Files listed are implicitly excluded from symlinking.

### 2. `merge-json.sh`

Helper script taking two JSON files (base and overlay):

- Base = shared dotfiles version (personal settings)
- Overlay = existing local file (company settings)
- Output: merged JSON to stdout, conflicts to stderr
- Uses a custom `jq` function for recursive deep merge with array union

### 3. `install.sh` changes

- Load merge list from `.dotfiles-merge` (parallel to skip list loading)
- Files in merge list are skipped during symlink phase
- After linking, run merge phase: for each entry, invoke `merge-json.sh`
- If no local file exists, copy shared file directly (no merge needed)

## Conflict Reporting

```
[dotfiles] CONFLICT at .model: shared="opus", local="bedrock-claude" (keeping local)
```

## Edge Cases

- `.dotfiles-merge` takes precedence over `.dotfiles-skip` for the same path
- Personal machines without `.dotfiles-merge` are unaffected (pure symlinks)
