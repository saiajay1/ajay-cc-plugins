# Hook footgun catalog

Each entry: **symptom → cause → fix**. Ordered roughly by how often it bites.

## 1. `"matcher": "*"` matches nothing
- **Symptom:** a `PreToolUse`/`PostToolUse` hook never fires.
- **Cause:** `matcher` is a **regex** tested against the tool name. `*` is not a valid "match anything" token.
- **Fix:** use `".*"`, or omit `matcher` entirely to match all tools. To target specific tools use alternation: `"Write|Edit"`.

## 2. Matcher on an event that has no tool
- **Symptom:** a `matcher` on `SessionStart`/`Stop`/`UserPromptSubmit`/`SubagentStop` seems ignored.
- **Cause:** matchers only apply to tool events (`PreToolUse`, `PostToolUse`, `PermissionRequest`). Other events have no tool name to match.
- **Fix:** drop the `matcher`; those events always run their hooks.

## 3. Event name typo / wrong casing
- **Symptom:** hook never runs, no error.
- **Cause:** event keys are case-sensitive: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `SessionStart`, `SessionEnd`, `Stop`, `SubagentStop`, `PreCompact`, `Notification`. `posttooluse` or `PostTooluse` silently does nothing.
- **Fix:** match the documented casing exactly.

## 4. Relative path / wrong working directory
- **Symptom:** exit 127 "command not found", or the script can't find sibling files.
- **Cause:** hooks don't necessarily run from your project root.
- **Fix:** absolute paths, or `"$CLAUDE_PROJECT_DIR"/scripts/x.sh`; in a plugin, `"${CLAUDE_PLUGIN_ROOT}"/scripts/x.sh`. Always quote (paths may contain spaces).

## 5. Missing executable bit / shebang
- **Symptom:** exit 126, or "permission denied".
- **Cause:** script invoked directly isn't executable, or lacks a shebang.
- **Fix:** `chmod +x script.sh` and start it with `#!/usr/bin/env bash` — or sidestep both by invoking through the interpreter: `bash "$CLAUDE_PROJECT_DIR"/scripts/x.sh`.

## 6. Misunderstood exit codes
- **Symptom:** "the hook runs but nothing happens," or it unexpectedly blocks.
- **Cause:** exit `0` = proceed; exit `2` = **block** + return stderr to Claude; any other nonzero = non-blocking error.
- **Fix:** to *gate* an action, exit `2` and write the reason to **stderr**. To merely observe, exit `0`.

## 7. Ignoring stdin
- **Symptom:** the hook can't tell which tool/prompt triggered it.
- **Cause:** the event payload is delivered as JSON on **stdin**, not as arguments.
- **Fix:** read stdin, e.g. `payload=$(cat)`, then `tool=$(jq -r .tool_name <<<"$payload")`.

## 8. Invalid JSON in settings
- **Symptom:** *all* hooks in a file stop working.
- **Cause:** a trailing comma or unquoted key makes the whole `settings.json` unparseable.
- **Fix:** validate the file (`jq . < settings.json`). Settings JSON does not allow comments or trailing commas.

## 9. Long-running / hanging command
- **Symptom:** hook seems skipped; session stalls.
- **Cause:** hooks have a timeout; a slow command is killed.
- **Fix:** keep hooks fast; background heavy work (`… &`) or move it out of the hot path.

## 10. Unquoted variable expansion
- **Symptom:** breaks for users whose paths contain spaces.
- **Cause:** `$CLAUDE_PROJECT_DIR/x.sh` unquoted splits on spaces.
- **Fix:** quote it: `"$CLAUDE_PROJECT_DIR"/x.sh`.

## 11. Version-specific bug: hooks only run under `--debug`
- **Symptom:** hooks fire only when Claude Code is started with `--debug`.
- **Cause:** a known regression in some past builds.
- **Fix:** upgrade Claude Code; confirm with `claude --version`.
