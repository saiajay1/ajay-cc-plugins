---
description: Diagnose why your Claude Code hooks aren't firing — lint config, dry-run against synthetic events, and report copy-pasteable fixes.
argument-hint: "[optional: a settings file, event name, or hook to focus on]"
---

# Diagnose hooks

Run a full hook diagnosis using the `hook-doctor` skill. Do not guess — inventory, lint, and **dry-run**.

**Focus:** $ARGUMENTS

If a focus is given above, narrow to that settings file / event / hook. Otherwise audit everything.

## Do this

1. **Inventory** hooks from every source: `~/.claude/settings.json`, `.claude/settings.json`, `.claude/settings.local.json`, and each enabled plugin's `hooks/hooks.json`. Parse each as JSON; if any file is invalid JSON, report that first — it disables every hook in the file.
2. **Lint** each hook against the footgun checklist in this plugin's `reference/footguns.md` (matcher syntax, event-name casing, relative paths/cwd, exec bit + shebang, exit-code semantics, stdin, timeout).
3. **Dry-run** each `command` hook with the matching synthetic payload:
   `"${CLAUDE_PLUGIN_ROOT}/scripts/dryrun-hook.sh" '<command>' "${CLAUDE_PLUGIN_ROOT}/reference/sample-events/<Event>.json"`
   Only dry-run the user's *own* hooks (it executes them). For tool-scoped hooks, tweak the sample's `tool_name`/`tool_input` to match the matcher.
4. **Report** a table: `scope · event · matcher · status · problem · fix`. Showstoppers first. For everything broken, propose the corrected JSON/script — copy-pasteable, citing the exact field or line at fault.

Keep it concrete and actionable. The goal is "here's why it didn't fire and here's the fix," not a lecture on hooks.
