# VS Code Setup Guide

This guide shows how to use agent hooks in VS Code, when to stay with CLI-format hook files, and when to switch to VS Code's native hook features.

## Prerequisites

- VS Code Insiders 1.112+
- GitHub Copilot Chat extension
- A workspace that contains hook files or a user-level hook folder

> Hooks are still in Preview. Expect settings names and JSON contracts to evolve between builds.

## Configuration

VS Code auto-loads hook files from the workspace and user scopes.

### Default locations

- Workspace hooks: `.github/hooks/`
- Personal hooks: `~/.copilot/hooks/`
- Custom agent hooks: YAML frontmatter inside `.agent.md` files

### Custom hook locations

You can add extra folders with the `chat.hookFilesLocations` setting in `settings.json`.

```json
{
  "chat.hookFilesLocations": [
    ".github/hooks",
    "custom/hooks"
  ]
}
```

> Some preview builds expose `chat.hookFilesLocations` as a path-to-enabled map instead of a plain array. If VS Code flags the array form, use the Settings UI or convert it to the structure shown in the current VS Code docs.

## Two agent types in VS Code

### 1. Native VS Code agent

Use this when you want VS Code-specific lifecycle events and output behavior.

- Uses VS Code's native hook system
- Uses `hookSpecificOutput` for event-specific behavior
- Supports all 8 VS Code events, including `Stop`, `SubagentStart`, `SubagentStop`, and `PreCompact`
- Can inject additional context during `SessionStart` and `SubagentStart`
- Can block after `PostToolUse`

### 2. CLI background agent

Use this when you want maximum compatibility with repo hook files that already work in the CLI and coding agent.

- Runs the Copilot CLI in the background
- Uses the CLI hook format
- Supports the CLI's 6 lifecycle events
- Reuses the same `hooks.json` files used by Copilot CLI and coding agent

## Agent-scoped hooks (VS Code 1.111+)

VS Code can attach hooks directly to a custom agent definition in a `.agent.md` file.

### Requirements

- VS Code 1.111+
- `chat.useCustomAgentHooks` enabled
- A custom agent file with YAML frontmatter

### Example frontmatter

This repository includes [`docs/examples/strict-reviewer.agent.md`](examples/strict-reviewer.agent.md), which shows an agent-scoped hook setup:

```yaml
---
description: A strict code reviewer agent that enforces quality standards
hooks:
  - event: PreToolUse
    command: ./scripts/hooks/block-secrets.sh
    timeout: 10
  - event: PostToolUse
    command: ./scripts/hooks/validate-json.sh
    timeout: 10
  - event: Stop
    command: ./scripts/hooks/review-checklist.sh
    timeout: 15
---
```

### Important behavior

- These hooks only fire when that agent is active.
- When the same agent is invoked as a subagent, the scoped hooks follow the subagent.
- A `Stop` hook is treated as `SubagentStop` when the hook is scoped to an agent instead of the whole workspace.
- Agent-scoped hooks use VS Code's native input/output behavior, not the CLI flat JSON behavior.

## Debugging hooks

VS Code includes several ways to inspect hook execution.

- **GitHub Copilot Chat Hooks** output channel: shows hook execution, failures, and JSON parsing issues
- **Agent Debug** panel in VS Code 1.111+: inspect tool schemas, hook inputs, and event flow
- **`/create-hook`**: scaffolds a hook file from a natural-language description

## Tips

- Start with the CLI-format `hooks.json` if you want one hook file to travel across CLI, coding agent, VS Code, and JetBrains.
- Use `hookSpecificOutput` only when you need VS Code-only features such as `updatedInput`, `additionalContext`, `Stop`, or post-tool blocking.
- Test hooks locally by piping JSON into the script before wiring it into the editor.
- If you are debugging a native VS Code hook, compare the expected event name casing carefully: `PreToolUse` is not the same as `preToolUse`.

## References

- [Agent hooks in Visual Studio Code (Preview)](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [VS Code 1.111 release notes](https://code.visualstudio.com/updates/v1_111)
- [VS Code 1.112 release notes](https://code.visualstudio.com/updates/v1_112)
- [Platform comparison guide](platforms.md)
- [Strict reviewer example](examples/strict-reviewer.agent.md)
