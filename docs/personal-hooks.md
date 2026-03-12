# Personal Hooks Guide

This guide explains how to use personal hooks from `~/.copilot/hooks/` so your own safety rules and automations follow you across repositories.

## What are personal hooks?

Personal hooks are hook files that live on your machine instead of in a repository.

They are useful when you want policies or automations that should apply everywhere you work, without changing team-owned repo configuration.

### Key properties

- They live in `~/.copilot/hooks/`
- They apply to **all** repositories you use locally
- They run in addition to repository-level hooks, not instead of them
- They are a good fit for personal security policies, logging preferences, and safety checks

## Platform support

| Platform | Support |
|---|---|
| Copilot CLI | v0.0.422+ ✅ |
| VS Code | 1.112 Insiders+ ✅ |
| JetBrains | Not yet supported ❌ |

## Setup

1. Create the `~/.copilot/hooks/` directory.
2. Add a `hooks.json` file inside it using the same CLI-style format as repository hooks.
3. Create the scripts referenced by the config, such as `~/.copilot/scripts/`.
4. Start a new session. Personal hooks are loaded automatically.

## Example use cases

- Log all sessions across every repo to one personal audit log
- Block dangerous system commands such as `rm -rf /`, `format`, or disk wipe commands everywhere
- Require confirmation for force-push operations
- Inject personal context such as timezone, preferred tools, or local environment details

## Working examples in this repo

Use these files as copyable starting points:

- [`docs/examples/personal-hooks.json`](examples/personal-hooks.json)
- [`docs/examples/personal-session-log.sh`](examples/personal-session-log.sh)
- [`docs/examples/personal-safety-check.sh`](examples/personal-safety-check.sh)

### What the example does

- Logs `sessionStart` and `sessionEnd` to a single file in `~/.copilot/logs/`
- Blocks dangerous destructive shell commands
- Uses `permissionDecision: "ask"` for force-push commands so a human must confirm them

## Interaction with repo hooks

Personal hooks and repository hooks are additive.

- Both personal and repo hooks run
- They do not replace each other
- If either one denies an operation, the operation is blocked
- Personal hooks run in addition to repo hooks and order may vary
- There is no supported way to override repository hooks with personal hooks

## Practical advice

- Keep repo hooks focused on shared team policy
- Keep personal hooks focused on your own safety rules and workflow preferences
- Avoid logging secrets or sensitive prompt content unless you also apply redaction and retention controls
- Test each script by piping in sample JSON before trusting it globally

## References

- [VS Code 1.112 release notes](https://code.visualstudio.com/updates/v1_112)
- [Using hooks with GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks)
- [Using hooks with Copilot CLI for predictable, policy-compliant execution](https://docs.github.com/en/copilot/tutorials/copilot-cli-hooks)
- [Personal hooks example in this repo](examples/personal-hooks.json)
- [Platform comparison guide](platforms.md)
