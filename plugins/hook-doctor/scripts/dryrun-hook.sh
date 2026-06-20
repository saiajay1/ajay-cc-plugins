#!/usr/bin/env bash
# dryrun-hook.sh — Dry-run a Claude Code hook command against a synthetic event.
#
# Feeds an event JSON payload to the hook command on stdin, exactly as the
# Claude Code harness does, and reports exit code, stdout, stderr, and a
# plain-English verdict — so you can see what a hook *actually* does without
# waiting for a real trigger.
#
# Usage:   dryrun-hook.sh '<hook command>' '<event-json-file>'
# Example: dryrun-hook.sh 'jq -r .tool_name' reference/sample-events/PreToolUse.json
#
# WARNING: this EXECUTES the hook command. Only run it on hooks you trust.

set -uo pipefail

CMD="${1:-}"
EVENT="${2:-}"
if [ -z "$CMD" ] || [ -z "$EVENT" ]; then
  echo "usage: dryrun-hook.sh '<hook command>' '<event-json-file>'" >&2
  exit 64
fi
if [ ! -f "$EVENT" ]; then
  echo "event file not found: $EVENT" >&2
  exit 66
fi

out="$(mktemp)"; err="$(mktemp)"
trap 'rm -f "$out" "$err"' EXIT

# Run the hook exactly as the harness would: event JSON on stdin, via a shell.
bash -c "$CMD" <"$EVENT" >"$out" 2>"$err"
code=$?

echo "command : $CMD"
echo "event   : $EVENT"
echo "exit    : $code"
echo "--- stdout ---"; head -50 "$out"
echo "--- stderr ---"; head -50 "$err"
echo "--- verdict ---"
case "$code" in
  0) echo "OK (exit 0): non-blocking. For PreToolUse, JSON on stdout can shape the permission decision; otherwise stdout is informational." ;;
  2) echo "BLOCK (exit 2): the hook blocks the action and stderr is returned to Claude as the reason. Make sure stderr carries a useful message." ;;
  126) echo "ERROR (126): command found but not executable — 'chmod +x' the script, or invoke it via 'bash <script>'." ;;
  127) echo "ERROR (127): command not found — likely a relative path or wrong cwd. Use an absolute path or \"\$CLAUDE_PROJECT_DIR\"/... (plugins: \"\${CLAUDE_PLUGIN_ROOT}\"/...)." ;;
  *) echo "NON-BLOCKING ERROR (exit $code): Claude continues despite the failure. Check the command, its path, and that it reads stdin." ;;
esac
