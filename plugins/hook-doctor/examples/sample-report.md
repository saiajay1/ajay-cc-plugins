# Example: a hook that won't fire

A real-looking `.claude/settings.json` with two hooks that both silently fail — and the Hook Doctor diagnosis.

## The input (`.claude/settings.json`)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "./scripts/format.sh" }
        ]
      }
    ],
    "posttooluse": [
      {
        "hooks": [
          { "type": "command", "command": "echo formatted" }
        ]
      }
    ]
  }
}
```

Looks reasonable. Neither hook ever runs.

## 1. Inventory
- `PostToolUse` (project) · matcher `*` · command `./scripts/format.sh`
- `posttooluse` (project) · no matcher · command `echo formatted`

## 2. Lint
- `matcher: "*"` → **footgun #1**: `*` isn't a valid catch-all regex; matches nothing.
- `./scripts/format.sh` → **footgun #4/#5**: relative path (likely not found from the hook cwd) and probably not `chmod +x`.
- `posttooluse` → **footgun #3**: event names are case-sensitive; `posttooluse` is never recognized.

## 3. Dry-run
```sh
$ dryrun-hook.sh './scripts/format.sh' reference/sample-events/PostToolUse.json
exit    : 127
--- stderr ---
  bash: ./scripts/format.sh: No such file or directory
--- verdict ---
ERROR (127): command not found — likely a relative path or wrong cwd.
```
Confirms the path problem dynamically.

## 4. Report

| scope | event | matcher | status | problem | fix |
|-------|-------|---------|--------|---------|-----|
| project | `PostToolUse` | `*` | **won't-fire** | `*` is not a valid regex matcher — matches no tool | use `".*"` (all tools) or `"Write\|Edit"` |
| project | `PostToolUse` | `*` | **errors** | `./scripts/format.sh` is relative and not executable (exit 127) | `bash "$CLAUDE_PROJECT_DIR"/scripts/format.sh` |
| project | `posttooluse` | — | **won't-fire** | event name mis-cased; never recognized | rename key to `PostToolUse` |

## The corrected config

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/scripts/format.sh" }
        ]
      }
    ]
  }
}
```

Both broken entries collapse into one correct hook. Re-dry-run → `exit 0`, green.

## Takeaways
- Three independent footguns, **zero error messages** — exactly why silent hook failure is so painful.
- Static lint caught the matcher and casing; the **dry-run** proved the path failure instead of guessing.
