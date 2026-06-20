# ajay-cc-plugins

Focused, zero-config plugins for the [Claude Code](https://code.claude.com) harness. One job each, done well.

## Plugins

| Plugin | What it does |
|--------|--------------|
| [**subagent-verifier**](plugins/subagent-verifier) | Trust subagent output. Makes delegated agents return cited, structured findings, then independently re-checks every citation before you act. |
| [**hook-doctor**](plugins/hook-doctor) | Diagnose why your Claude Code hooks silently fail — lint config, dry-run each hook against a synthetic event, and get copy-pasteable fixes. |

## Install

```sh
# Add this marketplace
/plugin marketplace add saiajay1/ajay-cc-plugins

# Install a plugin from it
/plugin install subagent-verifier@ajay-cc-plugins
/plugin install hook-doctor@ajay-cc-plugins
```

> Live at **https://github.com/saiajay1/ajay-cc-plugins**.

### Try it locally first (no GitHub needed)

```sh
/plugin marketplace add /Users/ajay/Downloads/Models/subagent-verifier
/plugin install subagent-verifier@ajay-cc-plugins
```

Validate the manifests at any time:

```sh
claude plugin validate /Users/ajay/Downloads/Models/subagent-verifier
```

## License

MIT — see [LICENSE](LICENSE).
