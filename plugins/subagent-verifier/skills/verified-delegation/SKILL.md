---
name: verified-delegation
description: Use when delegating work to subagents and you need to trust what they report back — multi-agent verification, checking a subagent's findings before acting, guarding against lossy summaries or hallucinated claims from delegated agents. Makes delegated agents return cited, structured findings and independently re-checks every citation before the parent acts. Trigger when dispatching subagents for investigation/research/implementation where acting on a wrong finding is costly.
---

# Verified Delegation

A subagent compresses thousands of tokens of investigation into a few hundred tokens of summary. The parent agent never sees what was dropped, smoothed over, or invented. So acting on a raw subagent summary is acting on **trust**, not **evidence** — and that is the single biggest blocker to autonomous multi-agent work.

This skill makes delegated findings *checkable*. Every claim a subagent returns must carry a citation, and every citation gets independently re-checked before you act on it. Unsupported claims are surfaced, not silently obeyed.

**Use this whenever** you delegate non-trivial investigation, research, or implementation to a subagent and the cost of acting on a wrong finding is real (touching code, reporting facts to the user, making a decision).

---

## The protocol in one line

> **Dispatch under a contract → verify the citations → act only on what survives.**

There are two halves: how you *send* work to a subagent, and how you *receive* its results.

---

## Part 1 — Dispatch under the Verification Contract

When you spawn a subagent, append the **Verification Contract** to its task prompt verbatim. It forces the subagent to return evidence-bearing claims instead of prose you have to take on faith.

```
=== VERIFICATION CONTRACT (return your findings in exactly this form) ===
Return a numbered list of CLAIMS. Each claim MUST have:
  - id:        C1, C2, C3, ...
  - claim:     one falsifiable sentence (no hedging, no "it seems")
  - type:      file | command | inference
  - evidence:  for type=file    -> path:line-start-line-end  (the exact lines that prove it)
               for type=command -> the exact command you ran, then a VERBATIM ≤5-line output excerpt
               for type=inference -> the ids of the claims it is derived from (e.g. "from C1,C3")
  - confidence: high | medium | low

Rules:
  - If you cannot cite it, do not claim it. Put uncertain items under "UNVERIFIED" instead.
  - Quote evidence verbatim. Never paraphrase a file's contents inside `evidence`.
  - Prefer many small, individually-checkable claims over one big summary.
=== END CONTRACT ===
```

Keep the subagent's normal task description above the contract. The contract only changes the *shape* of what comes back.

---

## Part 2 — Verify before acting

When the subagent returns, do **not** act yet. Run a verification pass:

1. **Extract** every `type: file` and `type: command` claim. `inference` claims are checked transitively (an inference is only as good as the claims it rests on).
2. **Delegate the checking** to the independent `claim-verifier` subagent (it ships with this plugin). Hand it the claim list. It re-reads each cited `path:line` and re-runs each cited command **without** seeing the original subagent's reasoning, so it cannot inherit the same mistake. It returns a verdict per claim.
3. **Interpret the verdicts** (see below) and act only on `confirmed` claims.

For a small result set (≤4 file claims, no commands) you may verify inline yourself by just re-reading the cited lines — spawning a verifier is overkill. Use judgment: **the verifier exists for independence and volume**, not ceremony.

### Verdict semantics

| Verdict | Meaning | What to do |
|---|---|---|
| `confirmed` | The cited evidence actually supports the claim. | Safe to act on. |
| `unsupported` | The citation exists but does **not** show what the claim says. | Drop the claim or re-investigate. Treat as **false**. |
| `contradicted` | The cited evidence shows the **opposite**. | Stop. The subagent was wrong; surface this loudly. |
| `uncheckable` | Citation is missing, malformed, or non-reproducible. | Treat as unverified — do not act on it. |

### The decision rule

- **Any `contradicted` → halt and report.** A contradicted claim means the subagent's model of reality is wrong; nearby claims are now suspect.
- **`unsupported` / `uncheckable` → discard that claim**, then decide if the remaining confirmed claims are still enough to proceed.
- **Proceed only on `confirmed` claims.** When you report to the user or edit code, every load-bearing fact should trace to a `confirmed` verdict.

---

## How thoroughly should I verify?

Match effort to stakes — verifying has a cost too.

- **Sample (spot-check 2–3 highest-impact claims)** — low-stakes, read-only summaries; you mostly trust the subagent.
- **Full (check every file/command claim)** — before editing code, before reporting facts to the user, before an irreversible action, or any time a subagent's output will be chained into more delegated work.
- **Always fully verify** claims that will become the *premise* of further automated steps. Errors compound across a delegation chain.

If you sample rather than fully verify, **say so** in your summary ("spot-checked 3 of 11 claims"). Silent partial verification reads as full verification and is worse than none.

---

## Worked example

A subagent returns:

```
C1 | claim: The retry limit is 5.            | type: file    | evidence: src/http/client.ts:42-42       | confidence: high
C2 | claim: Timeouts are not retried.        | type: file    | evidence: src/http/client.ts:55-58       | confidence: medium
C3 | claim: The test suite passes.           | type: command | evidence: `npm test` -> "Tests: 88 passed"| confidence: high
C4 | claim: So retries are safe to raise.    | type: inference| evidence: from C1,C2                     | confidence: medium
```

Verification pass (via `claim-verifier`):

```
C1 confirmed    — client.ts:42 reads `const MAX_RETRIES = 5`
C2 contradicted — client.ts:55-58 retries ECONNABORTED (timeouts ARE retried)
C3 unsupported  — `npm test` actually prints "Tests: 80 passed, 8 failed"
C4 uncheckable  — rests on C2, which is contradicted
```

Outcome: **halt.** Two of four claims were wrong, including a "high-confidence" test-pass claim. Acting on the raw summary would have raised a retry limit on the false premise that the suite was green. This is exactly the failure verified delegation exists to catch.

---

## Companion tools in this plugin

- **`/subagent-verifier:verify-subagent`** — run a verification pass on a subagent's findings on demand (paste them, or point at the latest result).
- **`claim-verifier` agent** — the independent checker invoked in Part 2.
- **`SubagentStop` hook** — a quiet reminder to verify whenever any subagent finishes (optional; disable if you delegate constantly).

## Anti-patterns

- ❌ Accepting "I checked and it works" with no citation. That is the thing this skill exists to refuse.
- ❌ Letting the *same* subagent grade its own homework. Verification must be independent (fresh context).
- ❌ Verifying prose. You can only verify a claim that names where its evidence lives.
- ❌ Over-verifying trivial read-only summaries until delegation is slower than doing it yourself.
