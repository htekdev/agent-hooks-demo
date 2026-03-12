# Platform Comparison Guide

This guide compares how agent hooks behave across GitHub Copilot CLI, GitHub Copilot coding agent, VS Code, and JetBrains IDEs.

## Configuration Format Comparison

### Quick summary

| Platform | Preferred config style | Event name style | Command fields | Timeout field | Notes |
|---|---|---|---|---|---|
| Copilot CLI | CLI JSON format (`version: 1`) | lowercase (`preToolUse`) | `bash` / `powershell` | `timeoutSec` | Flat `preToolUse` JSON output only |
| Coding Agent | CLI JSON format (`version: 1`) | lowercase (`preToolUse`) | `bash` / `powershell` | `timeoutSec` | Same hook file shape as CLI |
| VS Code | Native VS Code hook format **or** CLI format | PascalCase in native format (`PreToolUse`) | `command` with optional `windows` / `linux` / `osx` | `timeout` | Native format unlocks `hookSpecificOutput` features |
| JetBrains | CLI JSON format | lowercase (`preToolUse`) | `bash` / `powershell` | `timeoutSec` | Use the same repo hook file shape as CLI |

### The same hook in each format variant

The examples below all express the same policy: run a `preToolUse` hook that blocks or inspects edits before they happen.

#### CLI / Coding Agent / JetBrains: portable CLI format

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "./scripts/hooks/block-secrets.sh",
        "powershell": "./scripts/hooks/block-secrets.ps1",
        "timeoutSec": 10
      }
    ]
  }
}
```

#### CLI-style single-command variant

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "command": "./scripts/hooks/block-secrets.sh",
        "timeout": 10
      }
    ]
  }
}
```

Use this when you only need one command string and do not need separate Bash and PowerShell entries. For the broadest cross-platform compatibility, explicit `bash` and `powershell` entries are still the safest choice.

#### VS Code native format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "./scripts/hooks/block-secrets.sh",
        "windows": "powershell -File scripts\\hooks\\block-secrets.ps1",
        "timeout": 10
      }
    ]
  }
}
```

### Compatibility rules

- VS Code can load the same CLI-style `hooks.json` files you use for the CLI and coding agent.
- JetBrains uses the CLI format, so `.github/hooks/hooks.json` and `.github/hooks/hooks-jetbrains.json` follow the same basic structure.
- VS Code native hooks add platform-native input/output behavior and more lifecycle events, but they are not required for basic cross-platform hook files.

## Event Support Matrix

| Event | CLI | Coding Agent | VS Code | JetBrains |
|---|---|---|---|---|
| sessionStart | ✅ | ✅ | ✅ (`SessionStart`) | ❌ |
| sessionEnd | ✅ | ✅ | ❌ (use `Stop`) | ❌ |
| userPromptSubmitted | ✅ | ✅ | ✅ (`UserPromptSubmit`) | ✅ |
| preToolUse | ✅ | ✅ | ✅ (`PreToolUse`) | ✅ |
| postToolUse | ✅ | ✅ | ✅ (`PostToolUse`) | ✅ |
| errorOccurred | ✅ | ✅ | ❌ | ✅ |
| PreCompact | ❌ | ❌ | ✅ | ❌ |
| SubagentStart | ❌ | ❌ | ✅ | ❌ |
| SubagentStop | ❌ | ❌ | ✅ | ❌ |
| Stop | ❌ | ❌ | ✅ | ❌ |

### Event naming note

- CLI, coding agent, and JetBrains use lowercase event names in JSON.
- VS Code native hooks use PascalCase event names such as `SessionStart`, `PreToolUse`, and `Stop`.
- When you use CLI-format hook files in VS Code, VS Code handles the compatibility for you, but native-only events still require native VS Code hooks.

## Input/Output Format Reference

### CLI / Coding Agent input

All CLI-style hooks receive JSON on stdin. A generic tool hook payload looks like this:

```json
{ "timestamp": 1704614600000, "cwd": "/path/to/project", "toolName": "edit", "toolArgs": "{...}" }
```

Additional fields by event:

- `postToolUse`: adds `toolResult`
- `sessionStart`: adds `source`
- `sessionEnd`: adds `reason`
- `userPromptSubmitted`: adds `prompt`
- `errorOccurred`: adds `error`

### CLI / Coding Agent output

- `preToolUse` only:

```json
{ "permissionDecision": "deny", "permissionDecisionReason": "This operation is blocked by policy." }
```

- Supported values are `deny`, `allow`, and `ask`, but CLI-style blocking behavior is centered on the flat `permissionDecision` payload.
- All other hook output is ignored.

### VS Code input

Every VS Code hook receives common fields such as:

- `timestamp`
- `cwd`
- `sessionId`
- `hookEventName`
- `transcript_path`
- `source` where applicable

Hook-specific fields include:

- `tool_name`, `tool_input`, `tool_use_id`
- `tool_response`
- `stop_hook_active`
- `agent_id`, `agent_type`
- `trigger`
- `prompt`

### VS Code output

All VS Code hooks support this common wrapper:

```json
{ "continue": true, "stopReason": "...", "systemMessage": "..." }
```

VS Code also supports event-specific behavior:

- `PreToolUse`
  - `permissionDecision`
  - `permissionDecisionReason`
  - `updatedInput`
  - `additionalContext`
- `PostToolUse`
  - `decision: "block"`
  - `reason`
  - `additionalContext`
- `SessionStart`
  - `additionalContext`
- `SubagentStart`
  - `additionalContext`
- `Stop` / `SubagentStop`
  - `decision: "block"`
  - `reason`

In native VS Code hooks, these values are typically returned through `hookSpecificOutput` for the corresponding event.

### Exit codes

- `0` = success, parse stdout as JSON
- `2` = blocking error, stderr is sent to the model
- any other non-zero exit code = non-blocking warning

## Key Compatibility Notes

- CLI flat JSON output will **not** trigger VS Code `hookSpecificOutput` features.
- VS Code `postToolUse` hooks can block further processing; CLI `postToolUse` hooks cannot.
- VS Code `SessionStart` can inject context; CLI `sessionStart` cannot.
- Personal hooks (`~/.copilot/hooks/`) work on CLI and VS Code, not JetBrains yet.
- The same `hooks.json` config file works on all platforms, but output behavior differs by platform.

## References

- [Using hooks with GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks)
- [Hooks configuration reference](https://docs.github.com/en/copilot/reference/hooks-configuration)
- [Using hooks with GitHub Copilot coding agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)
- [Agent hooks in Visual Studio Code (Preview)](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [VS Code 1.111 release notes](https://code.visualstudio.com/updates/v1_111)
- [VS Code 1.112 release notes](https://code.visualstudio.com/updates/v1_112)
- [GitHub Copilot for JetBrains IDEs: March 11, 2026 changelog](https://github.blog/changelog/2026-03-11-major-agentic-capabilities-improvements-in-github-copilot-for-jetbrains-ides)
- [`.github/hooks/hooks-jetbrains.json`](../.github/hooks/hooks-jetbrains.json)
