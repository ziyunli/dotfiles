# omp model roles and profiles (work devices)

This guide explains every model role omp uses on the **bento** work device and
the **insta-laptop** work laptop, their two named model profiles, and switching.

Scope:

- This guide focuses on the work profiles; personal-device routing is documented
  in the section below.
- Live config: `~/.omp/agent/config.yml` — on **bento** this is a symlink to
  the tracked [`devices/bento/.omp/agent/config.yml`](devices/bento/.omp/agent/config.yml),
  so tracked edits are live. The laptop's live deployment is managed on that
  device (`./install.sh insta-laptop`); this repository asserts only its tracked
  source, not what the laptop currently runs.
- Repository sources: [`devices/bento/.omp/agent/config.yml`](devices/bento/.omp/agent/config.yml)
  and [`devices/insta-laptop/.omp/agent/config.yml`](devices/insta-laptop/.omp/agent/config.yml).
- This laptop's hostname is `Stephen-CFL6GJN2YR`; its installed dotfiles profile
  is `insta-laptop`. Use `./install.sh insta-laptop` when reinstalling its links.
  Both tracked work configs share the model policy; laptop UI, expanded model
  catalog, and compaction settings are preserved separately.
- The gateway itself (providers, endpoints, headers, credentials) is
  Instacart-managed in `~/.omp/agent/models.yml` and is **not** tracked here.
  This document names model selectors only; it contains no endpoints or secrets.

## Two named profiles

Both profiles are stored under `modelPresets` in the work config. Each one is a
snapshot of **every role assignment plus `defaultThinkingLevel`** (both set
`defaultThinkingLevel: high`). They do **not** snapshot retry/fallback chains,
advisor flags, title settings, memory settings, or the provider catalog — those
stay as configured and are shared by both profiles.

### `provider-diverse` — **active**

Both profiles put Sol 6.2 at `xhigh` on the main conversation (`default`); the
difference between them is how the specialist and worker lanes are staffed. This
one reduces concentration on a single model family for those lanes: DeepSeek v4.1
Flash runs `task` execution, GLM 5.3 Flash runs `smol`, Gemini 4 Carbon runs the
`slow` and `designer` specialist lanes, Gemini 4 Hydrogen runs `vision`, and the
remaining roles sit on GPT (instacart-openai) and Claude (instacart-anthropic).
This is about spreading work across model families, **not** independent
availability: every lane still shares the same Tally gateway, so a
gateway-wide outage can still affect all of them. A Tally credit limit is
different — it blocks premium models, while the baseline models (DeepSeek v4.1
Flash, GLM 5.3 Flash, GPT 6 Luna) remain usable and accrue usage beyond the
limit. Opus stays on planning.

Why those Gemini lanes: in this Tally catalog both Gemini 4 entries accept text
and image input, expose a 1M-token context window, and advertise reasoning
effort at `low`/`medium`/`high` only (no `xhigh`). Carbon is the current
`slow`/`designer` specialist; Hydrogen, whose catalog default effort is `high`,
is the `vision` analyst. Those are catalog capability statements, not native
Gemini marketing claims, and no local benchmark is implied. The `vision` role
still checks image-input support at request time; assigning Hydrogen there does
not by itself make some other model image-capable.

### `baseline-reasoning` — available, not active

Same Sol 6.2 `xhigh` main conversation, with the worker lanes pushed onto GPT 6
Luna (`xhigh` where the work is substantive) and Sol 6.1 for planning. Kept for
switching when you want the baseline-first reasoning allocation instead of
provider diversity. Apart from the user-approved Sol 6.2 default upgrade, this
preset's assignments are unchanged by the Gemini 4 specialist switch:
`slow`/`designer` remain Sol 6.1, `vision` remains Luna, and the shared fallback
chains (including the new `slow`/`designer`/`vision` hops) still apply to it.

### Role comparison

| Role | Kind | `provider-diverse` (active) | `baseline-reasoning` |
| ---- | ---- | --------------------------- | -------------------- |
| `default` | chat | `instacart-openai/gpt-6.2-sol:xhigh` | `instacart-openai/gpt-6.2-sol:xhigh` |
| `task` | chat | `open-weights/deepseek-v4p1-flash-priority:high` | `instacart-openai/gpt-6-luna:xhigh` |
| `smol` | chat | `open-weights/glm-5.3-flash-priority:high` | `open-weights/glm-5.3-flash-priority:high` |
| `tiny` | chat/tiny | `instacart-openai/gpt-6-luna:low` | `open-weights/glm-5.3-flash-priority:low` |
| `commit` | chat | `instacart-openai/gpt-6-luna:low` | `instacart-openai/gpt-6-luna:low` |
| `slow` | chat | `vertex-proxy/gemini-4-carbon:high` | `instacart-openai/gpt-6.1-sol:high` |
| `plan` | chat | `instacart-anthropic/claude-opus-5-5@default:high` | `instacart-openai/gpt-6.1-sol:high` |
| `designer` | chat (custom alias) | `vertex-proxy/gemini-4-carbon:high` | `instacart-openai/gpt-6.1-sol:high` |
| `vision` | chat | `vertex-proxy/gemini-4-hydrogen:high` | `instacart-openai/gpt-6-luna:xhigh` |
| `advisor` | chat | `instacart-openai/gpt-6.1-sol:high` | `instacart-openai/gpt-6.1-sol:medium` |

`judge` has **no** row: the work catalog no longer carries the Decisions
provider, so the role is unassigned (see the judge note and the unassigned
table below).

Reading a selector:

- `provider/model-id` — the leading segment before `/` is the **provider** on
  the Tally gateway (`open-weights`, `instacart-openai`, `instacart-anthropic`,
  `vertex-proxy`). Provider ids are not model names.
- `:high`, `:xhigh`, `:medium`, `:low` — the **thinking/effort suffix** for that
  role's chat requests. Not every model accepts every level; a suffix outside a
  model's supported ladder is clamped to what it supports. The effort column
  records the *role default*, not a guaranteed per-request effort — see
  “effort is a default” below.
- `@default` on `instacart-anthropic/claude-opus-5-5@default` is an **upstream
  routing suffix** (select the provider's default variant), not a role alias and
  not a thinking level.
- `default` at `xhigh` means a fresh session starts on Sol 6.2 at that effort;
  `defaultThinkingLevel: high` remains the global fallback thinking level for
  selections that carry no suffix.

## Switching profiles

From inside an omp session:

```text
/modelpreset list                     # list saved presets
/modelpreset switch provider-diverse  # apply the active profile
/modelpreset switch baseline-reasoning
```

`/modelpreset` with no argument opens an interactive picker. `/modelpreset save <name>`
and `/modelpreset delete <name>` manage the saved set; in the `/models` Roles
view, pressing `s` saves the current setup under a name.

What switching does (from the omp model docs):

- Writes the preset's role assignments the way the model picker does, clearing
  roles the preset leaves out, and replaces `--model` / `--smol` session
  overrides.
- Writes the preset's `defaultThinkingLevel` to the **global** config.
- Switches the **active model** of the current conversation to the resulting
  `default` (or a provider-default selection if the preset has no `default`),
  and sets the session's thinking level from the `:level` suffix on that
  selector or else the preset's `defaultThinkingLevel`.
- If the preset's `default` model is unavailable, **nothing changes**.

Caveats:

- A higher settings layer still wins. Roles owned by a `--config` file, a
  project config in `global` storage, or the global config in `project` storage
  are reported in the switch message with the layer that wins, instead of being
  reported as switched.
- When several config layers define the same preset name, the highest layer
  wins **whole**; entries are never merged across layers.
- Presets swap roles and thinking level only. They do **not** swap
  `retry.fallbackChains`, advisor flags, title settings, memory settings, or the
  provider catalog.

### Editing the config file vs. switching

- `~/.omp/agent/config.yml` is watched. Interactive sessions and RPC hosts
  reload it after a short debounce. A role/fallback change applies to
  **subsequent subagent launches** and later fallback decisions **without a
  restart**.
- Live reload does **not** switch a healthy active session's model and does not
  restart running subagents. So editing the file to change `modelRoles.default`
  will not by itself move an open conversation onto the new model.
- `/modelpreset switch` is different: it explicitly switches the active main
  model to the preset's resulting `default`.
- If a layer fails to parse, it keeps its last good values and logs a warning;
  the other layers still refresh. An invalid file is not moved aside on reload.

## Role reference: purpose and trigger

A role is a **model selector**, not an agent, not a permission, and not a
routing rule for arbitrary prose. Assigning a model to a role does not
auto-route text, does not grant tools, and does not fire on keywords. A role is
consulted when the corresponding *workload* is invoked.

### Assigned roles

| Role | Purpose | Concrete session trigger |
| ---- | ------- | ------------------------ |
| `default` | The main conversation model — on both profiles Sol 6.2 at `xhigh`, orchestrating work and delegating implementation to baseline workers. | Initial model selection for a new session when nothing explicit or restored is set, and an explicit `/model` or `/modelpreset switch` selection. Once chosen, ordinary turns run on the **active** model — they do not re-resolve `default` each turn. Changing `default` in `/models` also switches the active model. |
| `task` | General-purpose subagent workers (implementation, refactors, research with edits). | A `task` tool call whose agent resolves through the task role — i.e. the bundled generic `task` agent, or any agent whose frontmatter/`task.agentModelOverrides` resolves to `@task`. Not used by the main conversation. |
| `smol` | Cheap/fast lane. | Bundled `scout` and `sonic` agents; the prewalk hand-off target (when prewalk is armed); anything resolving `@smol`. |
| `tiny` | Lightweight background chat/tiny work. | The one-line labels for task/agent rows (the fire-and-forget UI label), and the **fallback** for session titles (see the title note below). |
| `commit` | Commit-message generation. | The `omp commit` CLI workflow, which generates a commit message and updates changelogs. **Not** every `git commit` you type and not agent-authored messages. |
| `slow` | Thorough analysis / review; on the active preset, Gemini 4 Carbon at `high` (Sol 6.1 is its availability fallback). | Bundled `reviewer` agent and the overridden `security-reviewer` agent (see the security-reviewer note below); anything resolving `@slow`. Also the fallback source for an unset `advisor`. |
| `plan` | Architectural planning; Opus 5.5 on the active preset and Sol 6.1 on `baseline-reasoning`. | Plan mode. See “Entering plan mode” below. Assigning `plan` does **not** itself enter plan mode, and calling `todo` does **not** select the plan model. While plan mode is active, changing the `plan` role reapplies its model. |
| `designer` | UI/design-focused lane; Gemini 4 Carbon at `high` on the active preset. | A **custom alias** with no built-in automatic trigger. Invoke it explicitly, e.g. `omp --model @designer` or by assigning it to an agent/workload. |
| `vision` | Image **analysis** (chat model with image input); Gemini 4 Hydrogen at `high` on the active preset. | A `read` of an image with a question, e.g. `read screenshot.png?q=what is wrong here`. |
| `advisor` | Reviewer that inspects primary turns and injects advice; Sol 6.1 on both presets. | Only when the advisor runtime is enabled: `advisor.enabled: true`, `/advisor on`, or `--advisor`. It is **disabled on both tracked work configs** (`advisor.enabled: false`). A `WATCHDOG.yml` roster can override the advisor model per advisor. |

### Judge note

`judge` is **unassigned** on this device. The work catalog no longer carries the
former `instacart-openai-decisions` provider, so managed configuration refresh
dropped that provider and its `gpt-6-luna` selector; the tracked config removed
the dead role entries rather than inventing a replacement endpoint.
`retry.fallbackChains.judge` remains `[]`.

Judge-triggered work (`find` relevance, Eval `judge`/`judge_batch`,
auto-thinking classification, typed judgments, AI-assisted staging) therefore
resolves through omp's built-in judgment behavior. Judge is a model-kind role and
takes no chat thinking suffix. If an older copy of the config still names the
removed Decisions selector, that assignment is inert — do not copy it into a new
config or treat its absence as a broken role.

### Title note

Automatic session titles are **fork-first**, not tiny-first. With no
`TITLE_SYSTEM.md` override (the current situation), the first title comes from a
**side turn on the active conversation model** — when the first reply's first
text or tool-call block starts, that model answers the title prompt on the
cached prefix. The `tiny` role only takes over as a **fallback** when the fork
fails, times out, declines, or never starts. With a `TITLE_SYSTEM.md` override
present, the first title skips the fork and uses the tiny title model instead.
Either way, the one-line task/agent row labels still use `tiny`.

### Unassigned built-ins

These roles have no selector in either profile, so they fall back to their
built-in behavior. Their mere existence does **not** activate the feature:

| Role | Kind | Behavior while unset | Concrete trigger |
| ---- | ---- | -------------------- | ---------------- |
| `judge` | judge | Falls back to omp's built-in judgment behavior. `retry.fallbackChains.judge` is `[]`; do not add a replacement endpoint just to fill the row. | `find` semantic relevance; Eval `judge` / `judge_batch`; auto-thinking classification; typed Eval judgments; AI-assisted git staging. |
| `memory` | chat/tiny | Resolves through `@tiny`. The memory backend is currently **off** (`memory.backend: off`), so no memory work runs regardless. | Extraction and consolidation work of a configured memory backend (e.g. Mnemopi extraction/consolidation in LLM mode, or the local summary pipeline). |
| `web` | search/grounded chat | Follows its built-in priority list / default runner chains. | The `web_search` tool (which follows `modelRoles.web` and `retry.fallbackChains.web`), and the `omp search` / `omp q` / `omp web-search` CLI commands. |
| `image` | image generation | Falls back to its built-in priority list. | The `generate_image` tool, when image generation is enabled. Separate workload from `vision`; leaving `image` unset does not enable generation. |
| `speech` | TTS | Built-in priority list (local candidates first). | Speech features when enabled: text-to-speech playback such as `omp say`, the `tts` tool, or the vocalizer used when `speech.enabled` is true. |
| `dictation` | STT | Built-in priority list (local candidates first). | Speech-to-text features when enabled: the Tern microphone button, or keyboard dictation following `stt.submitTrigger`. |

Unassigned does not mean enabled. The `memory`, `speech`, and `dictation`
features are off until their own settings/flags turn them on, and `image`
generation is off until enabled; an unassigned role never turns a feature on by
itself.

`vision` and `image` are different workloads. Assigning a model to `vision` does
not give it image-input support: an image question additionally checks that the
model can actually send image input to its provider.

## Entering plan mode

Plan mode is enabled by `plan.enabled` (default true). Documented entry points:

- Keybinding `app.plan.toggle` (default `Alt+Shift+P`) toggles plan mode.
- Setting `plan.defaultOnStartup: true` starts each fresh interactive session in
  plan mode (ignored in print mode).
- CLI `--plan-yolo` starts read-only plan mode and auto-approves the model's plan
  proposal, then switches to the execution target.

There is **no documented `/plan` slash command**; `/plan-review` reopens the
Plan Review overlay while plan mode is already active. Once plan mode is active,
the `plan` role supplies the planning model.

## `designer` alias

`designer` is a custom chat role, not a bundled agent. It has no automatic
trigger — nothing routes to it on its own. Use it explicitly with
`omp --model @designer`, or point an agent/override at `@designer`. Because it is
a normal chat role, it accepts a thinking suffix (`:high` here).

## Subagent model resolution (why `task`/`smol`/`slow` matter)

Task dispatch resolves a child's model in this order:

1. `task.agentModelOverrides[agentName]`
2. the agent frontmatter's prioritized `model` list
3. the parent's active model, then its configured/default fallback

Role aliases in (1) and (2) expand through `modelRoles`. So a custom agent
override or frontmatter model **can take precedence** over the role table above.

Installed bundled agents on this device (verified with `omp agents unpack`):

| Agent | Frontmatter model | Thinking |
| ----- | ----------------- | -------- |
| `task` | `@task` | `auto` |
| `scout` | `@smol` | `medium` |
| `sonic` | `@smol` | `medium` |
| `reviewer` | `@slow` | (unset) |
| `security-reviewer` | **no model or thinking field** | (unset) |

`security-reviewer` has no frontmatter model, so without an override it would
inherit the parent's active model. **Both tracked work configs** set
`task.agentModelOverrides["security-reviewer"]: "@slow"`, so both `reviewer` and
`security-reviewer` resolve `@slow`. On **bento** the live config is a symlink to
the tracked file, so the running config carries that override; on the active
preset both agents therefore run on Gemini 4 Carbon (falling back to Sol 6.1 on
request failure). The laptop's live deployment is managed on that device and is
not asserted here.

### Effort is a role default, not a guaranteed worker effort

The `:high`/`:xhigh`/`:low`/`:medium` suffixes in the table are the role
defaults. A subagent can end up at a different effort:

- the bundled `task` agent uses `thinkingLevel: auto`, and `solutionSpace`
  feeds the `auto` classifier;
- per-spawn `effort` (`lo`/`med`/`hi`) overrides the agent selector when
  `task.enableEffort` is on (default off), mapped onto the resolved model's
  supported range and clamped to `task.maxEffort`;
- `scout`/`sonic` request `medium` in frontmatter, and the effective level may
  clamp to whatever the resolved model's ladder supports;
- a custom agent's `thinkingLevel`/`thinking` frontmatter or a
  `task.agentModelOverrides` entry wins over the role default.

## Fallback chains are availability recovery, not escalation

Request-failure fallback lives in `retry.fallbackChains`, configured separately
from `modelRoles` and **shared by both profiles** (presets do not swap them).
The table is the tracked source for both work devices.

| Role | Shared fallback chain |
| ---- | --------------------- |
| `task` | `open-weights/glm-5.3-flash-priority:high` → `instacart-openai/gpt-6-luna:high` |
| `smol` | `instacart-openai/gpt-6-luna:high` |
| `commit` | `open-weights/glm-5.3-flash-priority:low` |
| `tiny` | `open-weights/glm-5.3-flash-priority:low` |
| `slow` | `instacart-openai/gpt-6.1-sol:high` |
| `designer` | `instacart-openai/gpt-6.1-sol:high` |
| `vision` | `vertex-proxy/gemini-3.8-flash:medium` |
| `judge` | `[]` (no fallbacks) |

These chains exist to survive a provider error or an unavailable model. They are
**not** a cognitive-escalation ladder: walking a fallback does not mean the work
got smarter, only that the primary could not serve the request. Notes:

- `slow` and `designer` recover onto Sol 6.1 `high`, which was their primary
  before the Gemini 4 Carbon assignment. `vision` recovers onto Gemini 3.8
  Flash `medium`, the previous `provider-diverse` `vision` primary. These are
  recovery hops, not an upgrade on failure.
- The chains keep their configured `:high` / `:medium` / `:low` entries
  whichever profile is active. On the `baseline-reasoning` profile the `task`
  **primary** is `gpt-6-luna:xhigh`, but its recovery entries remain the shared
  `:high` ones — do not read the chain as preserving `xhigh`. Likewise,
  `baseline-reasoning` already uses Sol 6.1 for `slow`/`designer` and Luna
  `xhigh` for `vision`; their newly shared recovery chains still apply
  unchanged.
- The former `instacart-openai/gpt-5.6-luna:high` entries were **removed** from
  both the `task` and `smol` chains: managed catalog refresh dropped GPT 5.6
  Luna from the work catalog, so those recovery hops could never serve a
  request. With the `smol` chain reduced to one real candidate, `smol` has GPT 6
  Luna as its only recovery hop.
- Managed configuration refresh rewrites the provider catalog and can re-sync
  `enabledModels`, but it **preserves user-authored `retry.fallbackChains`**. A
  stale selector surviving a refresh does not mean the model still exists —
  check `omp models --kind all --json` before trusting an entry.
- A comma-separated candidate list in a role value is **not** a retry chain;
  selection uses the first available match. Recovery is the `retry.fallbackChains`
  entry.
- `retry.fallbackRevertPolicy` (default `cooldown-expiry`) decides whether the
  session returns to the primary once its suppression window ends.

## Live config, tracked source, and managed refresh

- [`devices/bento/.omp/agent/config.yml`](devices/bento/.omp/agent/config.yml)
  is the tracked source, and on **bento** `~/.omp/agent/config.yml` is a
  **symlink** to it. Editing the tracked file is therefore a live edit: the
  running session reloads it. If that path is ever a local regular file again
  (for example after a tool rewrote it in place), rerun `./install.sh bento`:
  when a regular file is present, install moves it into
  `~/.dotfiles-backup-<timestamp>/` and replaces it with a symlink to the
  tracked source. That relink is a deliberate local action; nothing in this
  repository does it automatically.
- Instacart-managed configuration refresh owns the provider catalog and can
  rewrite `~/.omp/agent/models.yml` plus the `enabledModels` list. The tracked
  work configs' allowlist includes the Gemini 4 Carbon and Hydrogen selectors
  used by the active preset. Refresh **preserves user-authored role assignments
  and `retry.fallbackChains`** — which is why a retired selector such as
  `gpt-5.6-luna` survived in the fallback chains even after the catalog dropped
  it. Do not read an old fallback entry as proof the model exists.
- The new `default` (`instacart-openai/gpt-6.2-sol:xhigh`) applies to **fresh,
  non-restored sessions** and to explicit `/modelpreset switch`. Live reload
  applies role changes to later subagent launches but does **not** force the
  current conversation onto the new model; a healthy open session keeps its
  active model until you switch it deliberately.
- On bento there is no tracked-vs-live gap: the symlink means the live config
  includes `task.agentModelOverrides.security-reviewer: "@slow"`, the `tiny`
  fallback (`open-weights/glm-5.3-flash-priority:low`), and `advisor.enabled:
  false`. Role and fallback tables in this guide describe that tracked config.
  The laptop's live deployment is not asserted here.
- To check what the gateway actually exposes, run
  `omp models --kind all --json` rather than trusting a config selector. If a
  selector is absent there, treat it as unavailable and remove it instead of
  adding a replacement route by hand.

The user-approved requirements this pass implements are: Sol 6.2 `xhigh` as the
main-session orchestrator in both presets with cheaper models doing execution,
Gemini 4 Carbon on `slow`/`designer`, Gemini 4 Hydrogen `high` on `vision`, and
the advisor runtime disabled. The rest of the specialist and worker allocations,
the other `baseline-reasoning` assignments (retained unchanged apart from that
user-approved default upgrade), and the profile names are retained/editorial
choices rather than new user requirements. The dated Tally economics below is
the other user-provided material; the rest describes what the tracked config now
says.

## Tally credit economics (user-provided guidance, 2026-09-30)

These are the operating notes behind the profile choices. They are **user
guidance**, not a published rate card, and they are historical where the catalog
has moved on:

- The baseline models — DeepSeek v4.1 Flash, GLM 5.3 Flash, and GPT 6 Luna —
  are **not free**. They remain usable and accrue usage beyond the credit limit;
  **premium** models are blocked once the limit is reached. GPT 5.6 Luna is
  listed here only as **historical** user guidance: it is no longer in the work
  catalog and no current role or fallback chain names it.
- Actual per-model Tally credit rates (per 1M tokens) are not reproduced here.
  Read them in the Tally console under **My usage → Models used**. No OMP
  dollar-cost estimate is a Tally credit price.
- Preference for substantive/difficult work: GPT 6 Luna at `xhigh` — historical
  user guidance from before Sol became the profile default. The current
  `default` instead spends Sol 6.2 `xhigh` on orchestration and keeps execution
  on baseline workers.
- DeepSeek and GLM expose `high`/`max` (not `xhigh`) — use their supported levels.
- Sol 6.1: Medium/High/`xhigh` for ambiguity and plans; try Sol at `low` for
  simple high-level questions (a suggestion, not a guaranteed-sufficient level).
- The second profile's `plan` primary is Sol 6.1, not Opus. Reaching Opus
  requires an explicit model selection; switching to `baseline-reasoning` alone
  installs no Opus escalation path. The first profile intentionally keeps Opus
  on planning for provider diversity.
- `tiny` and `commit` at `low` effort are narrow exceptions for bounded work,
  not benchmark conclusions.

These model recommendations are **not** empirically benchmarked locally.

## Personal-device routing (2026-11-19)

All non-work devices use OpenAI Codex/ChatGPT OAuth for their main models; work
gateway selectors and credentials are not part of the personal configuration.
The shared [`shared/.omp/agent/config.yml`](shared/.omp/agent/config.yml)
defaults to `openai-codex/gpt-6.2-sol:xhigh`, uses Luna for lightweight and
worker roles, and uses Sol for planning and review. Its model allowlist contains
no Gemini selectors.

On `Ziyuns-M5-MBP`, [`devices/Ziyuns-M5-MBP/.omp/agent/config.yml`](devices/Ziyuns-M5-MBP/.omp/agent/config.yml)
overrides the shared omp file: Sol 6.2 runs the main session, Luna handles
`smol` and `memory`, local Ollama handles `tiny` and `commit`, and local ds4
handles `task`. Sol handles `slow`, `vision`, `plan`, `designer`, and
`advisor`. No role or retry fallback selects `google-antigravity/*`; `web` is
unassigned and uses omp's built-in search routing. `web/google` in the web
fallback chain is a search backend, not a Gemini chat model.

Pi's [`shared/.pi/agent/settings.json`](shared/.pi/agent/settings.json) has no
model allowlist or startup model. Each non-work device (`Ziyuns-M5-MBP`,
`Ziyuns-Mac-mini`, `Ziyuns-MBP`, and `popos`) merges a small device setting
that selects `openai-codex/gpt-6.2-sol` with the shared `xhigh` thinking level.
Running `./install.sh <device>` reapplies the tracked provider/model pair over
any Pi-saved selection on these devices. Other settings still merge with local
values taking precedence, and work-device model defaults stay local. If Pi
does not yet list Sol 6.2, run `pi update --models`.

Google AI Pro grants quota in Google's Antigravity products, but does not by
itself grant Gemini API access in a third-party harness. The personal routing
does not depend on the `google-antigravity` connector.

## Sources

- Role aliases, presets, and `/modelpreset` behavior: `omp://models.md`
- Settings, `modelRoles`, `modelPresets`, advisor flags: `omp://settings.md`
- `task` tool and subagent model precedence: `omp://tools/task.md`,
  `omp://task-agent-discovery.md`
- Advisor runtime and roster overrides: `omp://advisor-watchdog.md`
- `read` image questions: `omp://tools/read.md`
- Local tiny/speech models and judge usage: `omp://local-models.md`
- Memory backend modes: `omp://memory.md`
