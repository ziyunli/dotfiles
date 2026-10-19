# omp model roles and profiles (bento work device)

This guide explains every model role omp uses on the **bento** work device, the
two named model profiles configured for it, and how to switch between them.

Scope:

- Device: `bento` (work). Other devices and the shared config are unchanged.
- Live config: `~/.omp/agent/config.yml` — currently a **regular file**, not a
  symlink, so it stays independently writable at runtime.
- Repository source of truth: [`devices/bento/.omp/agent/config.yml`](devices/bento/.omp/agent/config.yml).
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

Reduces concentration on a single model family: roles are spread across
DeepSeek/GLM (open-weights), GPT (instacart-openai), Claude
(instacart-anthropic), Gemini (vertex-proxy), and a separate judgment endpoint
(`instacart-openai-decisions`). This is about spreading work across model
families, **not** independent availability: every lane still shares the same
Tally gateway, so a gateway-wide outage can still affect all of them. A Tally
credit limit is different — it blocks premium models, while the baseline models
(DeepSeek v4.1 Flash, GLM 5.3 Flash, GPT 6 Luna) remain usable and accrue usage
beyond the limit. Keeps Opus on planning and Gemini on vision.

### `baseline-reasoning` — available, not active

Pushes more work onto GPT 6 Luna (with `xhigh` effort where the work is
substantive) and Sol 6.1 for planning. Kept for switching when you want the
baseline-first reasoning allocation instead of provider diversity.

### Role comparison

| Role | Kind | `provider-diverse` (active) | `baseline-reasoning` |
| ---- | ---- | --------------------------- | -------------------- |
| `default` | chat | `open-weights/deepseek-v4p1-flash-priority:high` | `open-weights/deepseek-v4p1-flash-priority:high` |
| `task` | chat | `open-weights/deepseek-v4p1-flash-priority:high` | `instacart-openai/gpt-6-luna:xhigh` |
| `smol` | chat | `open-weights/glm-5.3-flash-priority:high` | `open-weights/glm-5.3-flash-priority:high` |
| `tiny` | chat/tiny | `instacart-openai/gpt-6-luna:low` | `open-weights/glm-5.3-flash-priority:low` |
| `commit` | chat | `instacart-openai/gpt-6-luna:low` | `instacart-openai/gpt-6-luna:low` |
| `slow` | chat | `instacart-openai/gpt-6.1-sol:high` | `instacart-openai/gpt-6.1-sol:high` |
| `plan` | chat | `instacart-anthropic/claude-opus-5-5@default:high` | `instacart-openai/gpt-6.1-sol:high` |
| `designer` | chat (custom alias) | `instacart-openai/gpt-6.1-sol:high` | `instacart-openai/gpt-6.1-sol:high` |
| `vision` | chat | `vertex-proxy/gemini-3.8-flash:medium` | `instacart-openai/gpt-6-luna:xhigh` |
| `advisor` | chat | `instacart-openai/gpt-6.1-sol:high` | `instacart-openai/gpt-6.1-sol:medium` |
| `judge` | judge | `instacart-openai-decisions/gpt-6-luna` | `instacart-openai-decisions/gpt-6-luna` |

Reading a selector:

- `provider/model-id` — the leading segment before `/` is the **provider** on
  the Tally gateway (`open-weights`, `instacart-openai`, `instacart-anthropic`,
  `vertex-proxy`, `instacart-openai-decisions`). Provider ids are not model
  names.
- `:high`, `:xhigh`, `:medium`, `:low` — the **thinking/effort suffix** for that
  role's chat requests. Not every model accepts every level; a suffix outside a
  model's supported ladder is clamped to what it supports. The effort column
  records the *role default*, not a guaranteed per-request effort — see
  “effort is a default” below.
- `@default` on `instacart-anthropic/claude-opus-5-5@default` is an **upstream
  routing suffix** (select the provider's default variant), not a role alias and
  not a thinking level.
- `judge` is a model-kind role; it takes **no** chat thinking suffix. The
  `instacart-openai-decisions/gpt-6-luna` row is a judgment endpoint (OpenAI
  Decisions wire), not a chat model.

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
| `default` | The main conversation model. | Initial model selection for a new session when nothing explicit or restored is set, and an explicit `/model` or `/modelpreset switch` selection. Once chosen, ordinary turns run on the **active** model — they do not re-resolve `default` each turn. Changing `default` in `/models` also switches the active model. |
| `task` | General-purpose subagent workers (implementation, refactors, research with edits). | A `task` tool call whose agent resolves through the task role — i.e. the bundled generic `task` agent, or any agent whose frontmatter/`task.agentModelOverrides` resolves to `@task`. Not used by the main conversation. |
| `smol` | Cheap/fast lane. | Bundled `scout` and `sonic` agents; the prewalk hand-off target (when prewalk is armed); anything resolving `@smol`. |
| `tiny` | Lightweight background chat/tiny work. | The one-line labels for task/agent rows (the fire-and-forget UI label), and the **fallback** for session titles (see the title note below). |
| `commit` | Commit-message generation. | The `omp commit` CLI workflow, which generates a commit message and updates changelogs. **Not** every `git commit` you type and not agent-authored messages. |
| `slow` | Thorough analysis / review. | Bundled `reviewer` agent (see the security-reviewer note below); anything resolving `@slow`. Also the fallback source for an unset `advisor`. |
| `plan` | Architectural planning. | Plan mode. See “Entering plan mode” below. Assigning `plan` does **not** itself enter plan mode, and calling `todo` does **not** select the plan model. While plan mode is active, changing the `plan` role reapplies its model. |
| `designer` | UI/design-focused lane. | A **custom alias** with no built-in automatic trigger. Invoke it explicitly, e.g. `omp --model @designer` or by assigning it to an agent/workload. |
| `vision` | Image **analysis** (chat model with image input). | A `read` of an image with a question, e.g. `read screenshot.png?q=what is wrong here`. |
| `advisor` | Reviewer that inspects primary turns and injects advice. | Only when the advisor runtime is enabled: `advisor.enabled: true`, `/advisor on`, or `--advisor`. It is **disabled initially** on this device. A `WATCHDOG.yml` roster can override the advisor model per advisor. |
| `judge` | Judgment/semantic decisions. | `find` semantic relevance; Eval `judge` / `judge_batch`; auto-thinking classification; typed Eval judgments; AI-assisted git staging. See the judge note below. |

### Judge note

`judge` points at `instacart-openai-decisions/gpt-6-luna`, a **native Decisions**
judgment endpoint (no chat thinking suffix). How the Tally baseline treats this
endpoint — its credit/usage treatment compared with the chat GPT 6 Luna lane —
has **not** been verified, so do not infer it from the chat Luna economics
below.

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
inherit the parent's active model. The config sets
`task.agentModelOverrides["security-reviewer"]: "@slow"` so both `reviewer` and
`security-reviewer` resolve `@slow`.

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
from `modelRoles` and **shared by both profiles** (presets do not swap them):

| Role | Shared fallback chain |
| ---- | --------------------- |
| `task` | `open-weights/glm-5.3-flash-priority:high` → `instacart-openai/gpt-6-luna:high` → `instacart-openai/gpt-5.6-luna:high` |
| `smol` | `instacart-openai/gpt-6-luna:high` → `instacart-openai/gpt-5.6-luna:high` |
| `commit` | `open-weights/glm-5.3-flash-priority:low` |
| `tiny` | `open-weights/glm-5.3-flash-priority:low` |
| `judge` | `[]` (no fallbacks) |

These chains exist to survive a provider error or an unavailable model. They are
**not** a cognitive-escalation ladder: walking a fallback does not mean the work
got smarter, only that the primary could not serve the request. Notes:

- The chains keep their configured `:high` / `:low` entries whichever profile is
  active. On the `baseline-reasoning` profile the `task` **primary** is
  `gpt-6-luna:xhigh`, but its recovery entries remain the shared `:high` ones —
  do not read the chain as preserving `xhigh`.
- A comma-separated candidate list in a role value is **not** a retry chain;
  selection uses the first available match. Recovery is the `retry.fallbackChains`
  entry.
- `retry.fallbackRevertPolicy` (default `cooldown-expiry`) decides whether the
  session returns to the primary once its suppression window ends.

## Tally credit economics (user-provided guidance, 2026-09-30)

These are the operating notes behind the profile choices. They are **user
guidance**, not a published rate card:

- The baseline models — DeepSeek v4.1 Flash, GLM 5.3 Flash, GPT 6 Luna, GPT 5.6
  Luna — are **not free**. They remain usable and accrue usage beyond the credit
  limit; **premium** models are blocked once the limit is reached.
- Actual per-model Tally credit rates (per 1M tokens) are not reproduced here.
  Read them in the Tally console under **My usage → Models used**. No OMP
  dollar-cost estimate is a Tally credit price.
- Preference for substantive/difficult work: GPT 6 Luna at `xhigh`.
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

## Sources

- Role aliases, presets, and `/modelpreset` behavior: `omp://models.md`
- Settings, `modelRoles`, `modelPresets`, advisor flags: `omp://settings.md`
- `task` tool and subagent model precedence: `omp://tools/task.md`,
  `omp://task-agent-discovery.md`
- Advisor runtime and roster overrides: `omp://advisor-watchdog.md`
- `read` image questions: `omp://tools/read.md`
- Local tiny/speech models and judge usage: `omp://local-models.md`
- Memory backend modes: `omp://memory.md`
