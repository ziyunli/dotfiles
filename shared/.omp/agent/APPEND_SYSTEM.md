# Model routing and delegation

Frontier models (Sol 6.1, Opus 5.5) are for judgment: planning, research, review,
architectural decisions, and advising. Once a plan exists, implementation is
baseline-model work — keep expensive lanes out of the execution path.

## Choosing a model

- Default conversation work: use the configured `default` role. On the **bento**
  work device both presets default to Sol 6.1 at `xhigh`, so the main session
  orchestrates and delegates implementation to the baseline `task` workers. On
  personal devices follow whatever `default` the active config sets — the
  personal device override is Gemini-first, the shared config is
  `openai-codex/*` — and never substitute work-gateway selectors
  (`instacart-openai/*`, `open-weights/*`) there.
- Judgment-heavy but still baseline (long-horizon reasoning, tricky multi-step
  changes): GPT 6 Luna.
- GPT 5.6 Luna: only where the active catalog still exposes it. It is absent
  from the bento work catalog (and was removed from its fallback chains), so
  treat it as unavailable there; on any device, check catalog availability
  rather than assuming the old personal guidance still holds.
- Frontier lanes (`slow`, `plan`, `advisor`, `designer`, plus `default` on
  bento): reserved for planning, researching, reviewing, advising, and
  orchestration. NEVER use them for mechanical implementation, refactors, or
  bulk edits with a plan in hand — hand those to `task` workers.

## Spawning subagents

- General-purpose task agents resolve `modelRoles.task`; specialist agents keep their configured role (`smol` for bundled scouts/sonic, `slow` for `reviewer` and `security-reviewer`) unless an agent override is configured. Respect the device's configured roles and fallback order. Do not override a task spawn to a frontier model unless the slice genuinely requires frontier judgment — and say why.
- A subagent that implements an existing plan is a baseline-model job by default.
- Fact-gathering scouts are baseline-model work too; reserve frontier models for
  synthesis, review, and judgment calls.
- Parallel design/plan work may fan out on frontier lanes, but the execution wave
  that follows the plan must land on baseline models via the `task` role.
