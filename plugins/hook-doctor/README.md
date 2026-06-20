# Hook Doctor

> Diagnose why your Claude Code hooks silently fail — lint the config, **dry-run each hook against a synthetic event**, and get copy-pasteable fixes.

Hooks fail *silently*. A misconfigured hook doesn't error — it just doesn't run, or runs and does nothing, and Claude Code tells you almost nothing about why. Hook debugging is one of the most common, least-supported frustrations in the harness ([hooks-not-working](https://github.com/anthropics/claude-code/issues/10401)). Hook Doctor turns "it's not firing 🤷" into "here's the exact line that's wrong, and here's the fix."

## How it works

```
inventory  →  lint  →  dry-run  →  report
   │            │          │           │
 find every   check the  feed each   table of
 hook in all  known      hook a      scope·event·status
 settings +   footguns   synthetic   ·problem·fix, with
 plugins                 event       corrected JSON/scripts
```

The **dry-run** is the part nothing else does: instead of waiting for a real trigger, it pipes a representative event JSON to the hook command on stdin — exactly as the harness does — and shows you the exit code, output, and a plain verdict.

## What's in the box

| Component | Type | Role |
|-----------|------|------|
| `hook-doctor` | skill | The diagnostic methodology + the footgun checklist. Auto-triggers on hook debugging. |
| `/hook-doctor` | command | Run a full diagnosis on demand (optionally focus on one file/event). |
| `scripts/dryrun-hook.sh` | script | Pipes a synthetic event to a hook command and reports `exit / stdout / stderr / verdict`. |
| `reference/footguns.md` | reference | The full catalog: symptom → cause → fix. |
| `reference/sample-events/` | fixtures | Synthetic payloads (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `SessionStart`) for dry-runs. |

## Usage

**On demand:**
```
/hook-doctor
```
…or focus it: `/hook-doctor PostToolUse` / `/hook-doctor .claude/settings.json`.

**By intent** — just ask: *"why isn't my PostToolUse hook firing?"* and the `hook-doctor` skill triggers.

**The dry-run directly:**
```sh
scripts/dryrun-hook.sh 'jq -r .tool_name' reference/sample-events/PreToolUse.json
```

## Example

A `PostToolUse` hook with `"matcher": "*"` and a relative command never fires. Hook Doctor catches both in one pass:

```
| scope   | event       | matcher | status     | problem                                  | fix                                   |
| project | PostToolUse | *       | won't-fire | "*" is not a valid regex matcher         | use ".*" or "Write|Edit"              |
| project | PostToolUse | *       | (same hook)| ./scripts/format.sh is relative + non-+x | bash "$CLAUDE_PROJECT_DIR"/scripts/…  |
```

See [`examples/sample-report.md`](examples/sample-report.md) for the full diagnosis.

## Why it's different

Hook *collections* and *templates* are everywhere. Hook Doctor is the only one that **diagnoses** — it lints **and dry-runs** your actual hooks against synthetic events and tells you precisely why one didn't fire. Zero config, no server.

> ⚠️ The dry-run **executes** the hook command. Only run it on hooks you trust (your own).

## License

MIT — see [LICENSE](LICENSE).
