---
description: Verify a subagent's findings by independently re-checking every cited claim before you act on them.
argument-hint: "[paste subagent findings, or leave empty to verify the most recent subagent result]"
---

# Verify subagent output

You are running a **verification pass** on a subagent's findings using the `verified-delegation` methodology. Do not act on the findings until this pass completes.

## Input

The findings to verify are:

$ARGUMENTS

If the above is empty, use the **most recent subagent / Task result in this conversation** as the input.

## Steps

1. **Normalize the claims.** Re-express the findings as a numbered claim list (id, claim, type, evidence, confidence) per the Verification Contract. If the subagent returned prose without citations, note which assertions are *uncited* — uncited assertions are automatically `uncheckable` and must not be trusted.

2. **Check independently.** Delegate to the `claim-verifier` agent (or, for ≤4 file claims and no commands, re-read the cited lines yourself). The checker must re-read each cited `path:line-range` and re-run each cited command **without** relying on the original subagent's explanation. For `inference` claims, resolve them to the claims they depend on.

3. **Report a verdict table** — one row per claim:

   | id | claim | verdict | evidence checked | note |
   |----|-------|---------|------------------|------|

   Verdicts: `confirmed` · `unsupported` · `contradicted` · `uncheckable`.

4. **Give the decision.**
   - Any `contradicted` → **HALT**: state plainly that the subagent's output is unreliable and why.
   - Drop every `unsupported` / `uncheckable` claim.
   - List the surviving `confirmed` claims and state whether they are sufficient to proceed.
   - If you only spot-checked a subset, say so explicitly (e.g. "checked 3 of 11").

Be terse and evidence-first. The goal is a trustworthy go/no-go, not a restatement of the subagent's summary.
