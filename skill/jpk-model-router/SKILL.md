---
name: jpk-model-router
description: Route Codex tasks to GPT-5.6 Luna, Terra, or Sol subagents with explicit reasoning effort. Use for 자동 라우팅, 모델 선택, 비용·품질 최적화, route-only checks, or explicit $jpk-model-router invocation.
---

# J.P Codex Model Router

Route one explicitly invoked Codex request to one GPT-5.6 subagent, then verify and report the actual execution path. This skill is instruction-only.

## Hard boundaries

- Do not claim that the parent thread changed models. The selected model applies only to a spawned child.
- Do not report a model transition before a model-aware spawn succeeds.
- Do not spawn a child unless both model and reasoning effort can be set explicitly.
- Use at most one child for a normal request. Never use parallel agents.
- Use at most one write-capable child. The parent and child must not edit files concurrently.
- Never let the child invoke `jpk-model-router` or spawn another routing child.
- Do not fall back to GPT-5.5 or any model outside the three allowed GPT-5.6 IDs.
- Do not modify Codex configuration, custom agents, shell profiles, credentials, or unrelated files.
- Keep all user-facing routing output in the language of the user's request.

## Parse the request

Separate these optional controls from the actual task:

- `route-only:` means classify and report without spawning, running the task, or modifying files.
- `force=luna`, `force=terra`, or `force=sol` overrides the classified model.
- `effort=low`, `effort=medium`, `effort=high`, or `effort=xhigh` overrides the classified effort.
- `allow-fallback` permits current-thread execution only when explicit model-aware spawning is unavailable.

Reject any other `force` value or ordinary effort value as `ROUTE_OVERRIDE_INVALID`. Do not silently normalize it.

If the user asks for Max or Ultra, do not execute it. Check available surface metadata when it is already exposed, then return:

```text
MVP_UNSUPPORTED_OVERRIDE
- requested_override: <max|ultra>
- verified_surface_support: <supported|unavailable|unknown>
- execution: not_started
- reason: this router MVP does not automate Max or Ultra
- recommended_action: select it manually in the model UI or with /model, then rerun the task
```

Max and Ultra are not interchangeable reasoning efforts. `MVP_UNSUPPORTED_OVERRIDE` describes this router's boundary, not a claim that Codex never supports the selection.

## Classify

Assess four dimensions without inventing a numeric average:

1. **Clarity** — Are the outcome, inputs, and acceptance checks explicit?
2. **Scope** — Is this one mechanical edit or a multi-module change?
3. **Risk** — Could it affect security, authentication, data integrity, production availability, or reversibility?
4. **Verification** — Can a direct check prove the result, or must the agent reconcile subtle or conflicting evidence?

The strongest material signal wins. Words such as “important,” “deeply,” or “do your best” do not raise a route by themselves.

Apply the first matching high-risk rule before ordinary routing:

- Any security, authentication, data-loss, irreversible-migration, or severe production-impact signal selects S1.
- Architecture, materially ambiguous requirements, conflicting evidence, or consequential design judgment selects S0 unless S1 applies.
- Multi-module debugging, subtle invariants, non-obvious failures, or expensive rework selects T1.
- Ordinary bounded implementation, tests, standard refactoring, or scoped debugging selects T0.
- Multi-file search, state collection, log organization, focused test runs, or deterministic batch work selects L1.
- One typo, simple formatting, exact extraction, or one command selects L0.

## Route table

| Route | Model | Effort | Default role | Use when |
|---|---|---|---|---|
| L0 | `gpt-5.6-luna` | `low` | explorer or worker | One mechanical edit, exact extraction, or one command |
| L1 | `gpt-5.6-luna` | `medium` | explorer | Multi-file search, state gathering, focused tests, deterministic batches |
| T0 | `gpt-5.6-terra` | `medium` | worker | Ordinary implementation, tests, refactoring, or bounded debugging |
| T1 | `gpt-5.6-terra` | `high` | worker | Multiple modules, subtle invariants, non-obvious failures, expensive rework |
| S0 | `gpt-5.6-sol` | `high` | explorer or worker | Architecture, ambiguity, conflicting evidence, consequential design choices |
| S1 | `gpt-5.6-sol` | `xhigh` | worker | Security or auth boundaries, data integrity, irreversible changes, severe impact |

Choose `explorer` when the outcome is read-only. Choose `worker` when any file modification is authorized. A write task gets one worker that may inspect before editing; do not add a separate explorer.

## Apply explicit overrides

First classify a baseline route, then replace only the model or effort fields explicitly supplied by the user.

- A valid explicit override wins over ordinary classification.
- If the final model/effort pair exactly matches the table, use that route ID; otherwise use `FORCED`.
- If the underlying task is S1-risk and the user forces Luna, warn and return `ROUTING_BLOCKED` without spawning or modifying files.
- Max and Ultra always follow the MVP unsupported-override path above.
- Never substitute another model for an invalid or unavailable override.

## Route-only mode

Do not spawn a child, run task commands, or modify files. Report:

```text
ROUTE_DECISION
- route_id: <L0|L1|T0|T1|S0|S1|FORCED>
- requested_model: <exact model ID>
- requested_effort: <low|medium|high|xhigh>
- agent_role: <explorer|worker>
- execution: not_started
- reason: <one concise reason grounded in task shape>
```

## Prepare one child

Before spawning, inspect the callable subagent tool surface. Continue only if the spawn request can explicitly carry both:

- `model`: one of `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.6-sol`
- `reasoning_effort`: one of `low`, `medium`, `high`, `xhigh`

Use a built-in explorer or worker role when the surface exposes role selection. Otherwise put the selected role and its read/write boundary in the child brief; do not claim role metadata was verified if it was not returned.

Do not copy the full parent transcript. When the spawn tool exposes context-forking, use no inherited turns and include only the paths, errors, current state, constraints, and acceptance checks needed for the task.

Use this brief:

```text
Router child: do not invoke jpk-model-router and do not spawn another routing child.

Route:
- model: <model>
- reasoning_effort: <effort>
- role: <explorer/worker>

Outcome:
<result to complete>

Inputs:
<required paths, files, commit, and error messages>

Constraints:
<authorization, exact change scope, single-writer rule, and prohibitions>

Acceptance:
<tests and inspections that prove completion>

Return:
<concise report with changed files, test results, and remaining risks>
```

Send the exact selected model and effort in the spawn tool fields as well as the brief. A prompt-only mention does not satisfy explicit routing.

## Execute with one writer

1. Record the relevant pre-existing worktree state before spawn. Do not treat user changes as child changes.
2. Spawn exactly one child with the selected model, effort, role boundary, and brief.
3. While the child runs, the parent must not edit files.
4. Wait for that same child to finish or request attention.
5. If verification fails because of the child's work, send one focused correction to the same child.
6. After one correction, verify again. If it still fails, report failure; do not spawn a replacement child.

For read-only work, prohibit file changes in the child constraints. For write work, prohibit unrelated changes and keep the checkout single-writer.

## Verify independently

Do not accept the child's success statement as proof. After it finishes, perform the relevant checks available on the current surface:

1. List changed files and separate pre-existing changes.
2. Run `git diff --check` when the target is a Git worktree.
3. Read the relevant diff or returned evidence.
4. Confirm the child's reported test output.
5. Rerun the smallest critical test when practical.
6. Check that unrelated files were not changed.
7. Compare the result with the requested acceptance conditions.

For a non-Git target, use a scoped before/after inventory or hashes when practical. Do not broaden verification into unrelated files.

Treat the request as successful only when the observable result passes these checks. If the execution tool returns the actual child model metadata, compare it with the request. Otherwise use `model_execution_verified: unavailable`, never `true` by inference.

## Honest fallback

If no subagent tool exists, or the tool cannot explicitly set both model and effort, do not claim routing occurred and do not modify files by default. Report:

```text
ROUTING_BLOCKED
- requested_model: <model>
- requested_effort: <effort>
- verified_execution: false
- reason: explicit model-aware subagent routing is unavailable
- recommended_action: select the model manually and rerun the request
```

Only when the original request contains `allow-fallback` may the parent execute the task. In that case report all of the following:

```text
- execution_mode: current-thread fallback
- selected_route: recommendation_only
- verified_model_switch: false
```

The fallback does not authorize work beyond the original request.

## Final report

Return the report in the user's language:

```text
ROUTING_RESULT
- route_id: <route>
- requested_model: <model sent to spawn>
- requested_effort: <effort sent to spawn>
- agent_role: <explorer|worker>
- execution_mode: <subagent|current-thread fallback>
- model_request_sent: <true|false>
- model_execution_verified: <true|false|unavailable>
- files_changed: <list or none>
- validation: <checks and actual outcomes>
- result: <success|failed|blocked>
- remaining_risks: <concise list or none>
```

Keep `requested` and `verified` distinct. Never turn unavailable execution metadata into a verified claim.
