---
name: hook-doctor
description: Use when Claude Code hooks aren't firing, fail silently, or behave unexpectedly — diagnosing settings.json hook configuration, debugging PreToolUse / PostToolUse / SessionStart / Stop / UserPromptSubmit hooks, "my hook doesn't run", a matcher not matching, or a hook script that errors. Lints the hook config, dry-runs each hook against a synthetic event, and reports the known footguns with concrete fixes. Trigger on hook setup, hook debugging, or auditing hooks before shipping a plugin.
---

# Hook Doctor

Hooks fail **silently**. A misconfigured hook doesn't raise an error — it just doesn't run, or it runs and quietly does nothing, and Claude Code gives you almost no feedback about why. This skill diagnoses hook problems systematically: find every hook, lint it against the known footguns, **dry-run it against a synthetic event**, and report exactly what's wrong and how to fix it.

Use this whenever a hook "isn't working," before shipping hooks in a plugin, or to audit an existing setup.

## Where hooks live — check all of these

A hook that "doesn't run" is often defined somewhere you aren't looking, or shadowed by another scope:

| Scope | File |
|---|---|
| User | `~/.claude/settings.json` |
| Project (shared) | `.claude/settings.json` |
| Project (local, gitignored) | `.claude/settings.local.json` |
| Enterprise | managed policy settings |
| Plugins | each enabled plugin's `hooks/hooks.json` (or inline `hooks` in its `plugin.json`) |

Collect hooks from **every** source before diagnosing — cross-scope merging and precedence is itself a common source of confusion.

## The diagnostic protocol

### 1. Inventory
Parse each settings file as JSON. List every hook as: `scope · event · matcher · type · command/target`. **If any settings file is invalid JSON, report that first** — one trailing comma disables every hook in that file.

### 2. Lint (static checks)
Run each hook through the footgun checklist in `reference/footguns.md`. The high-frequency ones:

- **Matcher syntax.** `matcher` is a regex tested against the tool name. `"*"` is *not* a valid catch-all — use `".*"` or omit the matcher. Matchers only apply to `PreToolUse` / `PostToolUse` / `PermissionRequest`; on `SessionStart`, `Stop`, `UserPromptSubmit`, etc. a matcher is meaningless and silently ignored.
- **Event-name casing.** Events are case-sensitive: `PostToolUse`, never `postToolUse` / `posttooluse`. A typo'd event simply never fires.
- **Relative paths / wrong cwd.** Hooks may not run from your project root, so `./scripts/x.sh` often can't be found. Use an absolute path or `"$CLAUDE_PROJECT_DIR"/scripts/x.sh` (in plugins: `"${CLAUDE_PLUGIN_ROOT}"/...`) — and quote it for spaces.
- **Executable bit / shebang.** A script invoked directly must be `chmod +x` and start with `#!/usr/bin/env bash`. Safer: invoke via the interpreter — `bash "$CLAUDE_PROJECT_DIR"/scripts/x.sh`.
- **Exit-code semantics.** `0` = proceed; `2` = **block** and feed `stderr` back to Claude; any other nonzero = non-blocking error (Claude continues). "It runs but nothing happens" is almost always a misread of this.
- **Reads stdin.** The event payload arrives as JSON on **stdin**. A script that ignores stdin can't branch on `tool_name`, `tool_input`, `prompt`, etc.
- **Timeout.** Hooks have a time budget; a slow or hanging command is killed and looks like it "didn't run."

### 3. Dry-run (dynamic check) — the part nothing else does
Don't wait for a real trigger. Feed the hook a **synthetic event** and watch what it actually does:

```sh
"${CLAUDE_PLUGIN_ROOT}/scripts/dryrun-hook.sh" '<the hook command>' "${CLAUDE_PLUGIN_ROOT}/reference/sample-events/PreToolUse.json"
```

The helper pipes a representative event JSON to the command on stdin — exactly as the harness does — and reports `exit_code`, `stdout`, `stderr`, and a plain-English verdict. Sample payloads for the common events ship in `reference/sample-events/`. For a tool-scoped hook, edit the sample's `tool_name` / `tool_input` to match the matcher you're testing.

> ⚠️ Dry-running **executes the hook command.** Only run it on hooks you trust (your own). Never dry-run an untrusted third-party hook.

### 4. Report
One row per hook:

| scope | event | matcher | status | problem | fix |
|-------|-------|---------|--------|---------|-----|

Status values: `ok` · `won't-fire` (config error) · `runs-but-noops` · `errors` · `risky`. Lead with showstoppers (invalid JSON, typo'd event, unfindable command), then the subtle ones.

## After diagnosis
- **Propose the corrected JSON/script**, don't just describe the problem.
- If the user is on an old Claude Code build with a known hook bug (e.g. the period where hooks only ran under `--debug`), flag it and recommend upgrading.
- **Re-dry-run after the fix** to confirm it's green.

See `reference/footguns.md` for the full catalog and `examples/sample-report.md` for a worked diagnosis.
