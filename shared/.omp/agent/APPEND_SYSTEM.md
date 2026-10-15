# Model routing and delegation

Frontier models (Sol 6.1, Opus 5.5) are for judgment: planning, research, review,
architectural decisions, and advising. Once a plan exists, implementation is
baseline-model work — keep expensive lanes out of the execution path.

## Choosing a model

- Default conversation work: use the configured `default` role (Gemini Flash on personal Gemini-first devices; DeepSeek v4.1 Flash or GLM 5.3 Flash on work devices).
- Judgment-heavy but still baseline (long-horizon reasoning, tricky multi-step changes): GPT 6 Luna.
- GPT 5.6 Luna: last resort only — the others are unavailable or the lane specifically needs GPT behaviour on a baseline budget.
- Frontier lanes (`slow`, `plan`, `advisor`, `designer`): reserved for planning, researching, reviewing, and advising. NEVER use them for mechanical implementation, refactors, or bulk edits with a plan in hand.

## Spawning subagents

- General-purpose task agents resolve `modelRoles.task`; specialist agents keep their configured role (`smol` for bundled scouts/sonic, `slow` for reviewers) unless an agent override is configured. Respect the device's configured roles and fallback order. Do not override a task spawn to a frontier model unless the slice genuinely requires frontier judgment — and say why.
- A subagent that implements an existing plan is a baseline-model job by default.
- Fact-gathering scouts are baseline-model work too; reserve frontier models for
  synthesis, review, and judgment calls.
- Parallel design/plan work may fan out on frontier lanes, but the execution wave
  that follows the plan must land on baseline models via the `task` role.
