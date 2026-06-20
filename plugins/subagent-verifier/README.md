# Subagent Verifier

> Trust subagent output. Make delegated agents return **cited, structured findings**, then **independently re-check every citation** before you act.

When you delegate to a subagent, it compresses thousands of tokens of investigation into a few hundred tokens of summary. You never see what was dropped or invented — so acting on that summary is acting on *trust*, not *evidence*. Lossy summaries and confidently-wrong claims from subagents are the number-one blocker to autonomous multi-agent work ([subagent context loss](https://github.com/anthropics/claude-code/issues/9521)).

Subagent Verifier turns "trust me" into "here's the proof, re-checked."

## How it works

```
delegate ──► subagent returns CLAIMS (each with a citation)
                         │
                         ▼
            claim-verifier independently re-reads
            every file:line and re-runs every command
                         │
                         ▼
          verdicts: confirmed · unsupported · contradicted · uncheckable
                         │
                         ▼
              act ONLY on confirmed claims · HALT on contradicted
```

The original subagent never grades its own homework — verification runs in a **fresh, independent context** (the `claim-verifier` agent), so it can't inherit the same mistake.

## What's in the box

| Component | Type | Role |
|-----------|------|------|
| `verified-delegation` | skill | The methodology: the Verification Contract you attach to a delegation, verdict semantics, and the decision rule. Auto-triggers when you delegate and need to trust the result. |
| `/subagent-verifier:verify-subagent` | command | Run a verification pass on demand — paste findings, or verify the latest subagent result. |
| `claim-verifier` | agent | The read-only, independent checker. Re-reads citations, re-runs commands, returns per-claim verdicts. Never modifies anything. |
| `SubagentStop` hook | hook | A quiet reminder to verify whenever any subagent finishes. Optional — disable if you delegate constantly. |

## Usage

**Automatic** — just delegate as usual. When a subagent finishes, the skill/hook nudges Claude to verify its cited claims before acting.

**On demand** — verify a specific result:

```
/subagent-verifier:verify-subagent
```

…or paste the findings after the command.

**By hand** — ask in plain language: *"delegate this investigation, but verify the subagent's findings before you act on them."* The `verified-delegation` skill triggers on intent.

## Example

A subagent claims the test suite passes and timeouts aren't retried. The verifier re-runs `npm test` and re-reads the cited lines:

```
C1 confirmed    — client.ts:42 = `const MAX_RETRIES = 5`
C2 contradicted — client.ts:55-58 retries ECONNABORTED (timeouts ARE retried)
C3 unsupported  — `npm test` actually prints "Tests: 80 passed, 8 failed"
VERDICT: HALT
```

Two of three "high-confidence" claims were wrong — including the test-pass. Acting on the raw summary would have shipped a fix on a false premise. See [`examples/sample-findings.md`](examples/sample-findings.md) for the full walkthrough.

## Why it's different

Plenty of "anti-hallucination" packs exist, but they're broad and unfocused. Subagent Verifier does exactly one thing: **make delegated findings checkable, and check them.** Zero config, no server, no external infra — just a skill, a command, an agent, and a hook.

## License

MIT — see [LICENSE](LICENSE).
