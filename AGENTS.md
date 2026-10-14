## Dotfiles Repository

Structure:
- `shared/` - config files linked to all machines
- `devices/<hostname>/` - machine-specific config (overrides shared)
- `install.sh` - creates symlinks from repo to $HOME
- `uninstall.sh` - removes symlinks
- `migrate.sh` - one-time migration from bare repo pattern

Shell quirk: zsh has issues with `git show ... > file` redirection. Use `/bin/bash -c '...'` for reliable file redirection.

Device folders use hostnames (`hostname -s`). Check `devices/` for available devices.

Shell config pattern:
- `shared/.zshrc.common` - shared zsh config (OMZ setup, aliases, FZF, functions). Tracked in git, symlinked to `~/.zshrc.common`
- `devices/<dev>/.zshrc.local` - device-specific config. Tracked in git, symlinked to `~/.zshrc.local`. Sets `DEVICE_PLUGINS` array before sourcing `~/.zshrc.common`, then adds machine-specific hooks.
- `~/.zshrc` - machine-local shim. NOT tracked and NOT symlinked; `install.sh` seeds it (see `seed_local_zshrc`) to `source ~/.zshrc.local`. Tools (e.g. Instacart setup) append their own blocks here without churning the repo. Devices that ship a plain `devices/<dev>/.zshrc` instead of `.zshrc.local` fall back to symlinking it directly.
- Always back up `~/.zshrc` before modifying (it's untracked, so no git safety net)

AI harness configs (Pi and omp) — work/personal split, see README "AI harness configs":
- `shared/.pi/agent/settings.json` - personal Pi base (no model allowlist). Work devices overlay `devices/<dev>/.pi/agent/settings.json` (gateway allowlist) via `.dotfiles-merge`; arrays union.
- `shared/.omp/agent/config.yml` - personal omp config (ChatGPT catalog roles). omp config is YAML, so there is no jq merge: work devices ship their own `devices/<dev>/.omp/agent/config.yml` and `install.sh` links it over the shared one.
- `shared/.pi/agent/APPEND_SYSTEM.md`, `shared/.omp/agent/APPEND_SYSTEM.md` - personal prompt channels, linked for every device. The omp one is not inherited by task subagents (by design; the `task` role carries subagent routing).
- The gateway provider definitions (`~/.omp/agent/models.yml`, `~/.pi/agent/models.json`, `~/.pi/agent/AGENTS.md`) are Instacart-managed and MUST stay untracked — never add them to `shared/`.

Migrating a device to the `.zshrc.local` shim:
- Run `./migrate-zshrc.sh [device]` **on the device being migrated** (defaults to `hostname -s`). It renames the tracked `devices/<dev>/.zshrc` → `.zshrc.local` (`git mv`, staged not committed), removes the legacy `~/.zshrc` symlink, links `~/.zshrc.local` into the repo, and seeds the `~/.zshrc` shim — the same end state `install.sh` produces. Preview with `DRY_RUN=1`.
- It is idempotent and self-healing: if a run is interrupted, just run it again to finish. It **refuses** (leaving the migration to a human) when `~/.zshrc` is a real file that isn't the shim, points at a different device or outside the repo, when `~/.zshrc.local` is an external symlink, or when the device `.zshrc` is untracked.
- Migrate per-device, on the device — don't rename another device's file remotely (that dangles its live `~/.zshrc` until it re-runs the migration or `install.sh`).
- Afterward, review **both** staged and unstaged changes (`git mv` leaves tool-appended content unstaged, so `git diff --staged` alone hides it): `git status` and `git diff HEAD -- devices/<dev>/.zshrc.local`. Relocate any flagged machine-local blocks into `~/.zshrc`, then commit the rename.
