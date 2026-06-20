# ajay-cc-plugins

Focused, zero-config plugins for the [Claude Code](https://code.claude.com) harness — one job each, done well. This repo is a **marketplace** that aggregates the plugins below; each plugin lives in its own repo.

## Plugins

| Plugin | What it does | Repo |
|--------|--------------|------|
| **subagent-verifier** | Trust subagent output — make delegated agents return cited, structured findings, then independently re-check every citation before you act. | [saiajay1/subagent-verifier](https://github.com/saiajay1/subagent-verifier) |
| **hook-doctor** | Diagnose why your Claude Code hooks silently fail — lint config, dry-run each hook against a synthetic event, and get copy-pasteable fixes. | [saiajay1/hook-doctor](https://github.com/saiajay1/hook-doctor) |

## Install

```sh
# Add this marketplace once
/plugin marketplace add saiajay1/ajay-cc-plugins

# Then install any plugin from it
/plugin install subagent-verifier@ajay-cc-plugins
/plugin install hook-doctor@ajay-cc-plugins
```

## Validate

```sh
claude plugin validate .   # this marketplace manifest
```

Each plugin repo additionally passes `claude plugin validate --strict` on its own.

## License

MIT — see [LICENSE](LICENSE).
