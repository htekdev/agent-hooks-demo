# JetBrains Setup Guide

This guide shows how to use agent hooks in JetBrains IDEs with the GitHub Copilot plugin preview.

## Prerequisites

- A JetBrains IDE with the GitHub Copilot plugin installed
- JetBrains IDE version 2025.1+
- Copilot agent mode enabled

## Status

Agent hooks are in **public preview** as of March 11, 2026.

If you are on Copilot Business or Copilot Enterprise, an administrator must enable the **Editor preview features** policy in GitHub Copilot chat settings before hooks become available.

## Supported events

JetBrains currently supports only 4 of the 6 CLI hook events in the public preview used by this repository:

- `userPromptSubmitted` ✅
- `preToolUse` ✅
- `postToolUse` ✅
- `errorOccurred` ✅
- `sessionStart` ❌
- `sessionEnd` ❌

## Configuration

- Hooks load from `.github/hooks/` at the project root.
- JetBrains uses the CLI JSON format, so the same `version: 1` / `hooks` object structure applies.
- This repository includes [`.github/hooks/hooks-jetbrains.json`](../.github/hooks/hooks-jetbrains.json) as a ready-to-use config with only the currently supported events.

### How to use the JetBrains-specific config

Choose one of these approaches:

1. Rename `hooks-jetbrains.json` to `hooks.json` inside `.github/hooks/`
2. Merge the supported events from `hooks-jetbrains.json` into your existing `hooks.json`

If you already have a full cross-platform `hooks.json`, the safest option is usually to keep that file for CLI and VS Code, then keep a JetBrains-specific subset next to it so the preview limitations are explicit.

## Limitations

- No personal hooks support yet (`~/.copilot/hooks/` is not supported)
- No agent-scoped hooks
- No `Stop`, `SubagentStart`, `SubagentStop`, or `PreCompact` events
- No session lifecycle hooks yet, so `sessionStart` and `sessionEnd` are not available
- If you need error tracking in JetBrains, use `errorOccurred` instead of waiting for end-of-session hooks

## Practical recommendation

If you want the same repository to work everywhere:

- Keep the main cross-platform config in `.github/hooks/hooks.json`
- Keep the JetBrains subset in `.github/hooks/hooks-jetbrains.json`
- Document clearly which preview events JetBrains ignores so your team does not expect start/end logging there

## References

- [GitHub Copilot for JetBrains IDEs: March 11, 2026 changelog](https://github.blog/changelog/2026-03-11-major-agentic-capabilities-improvements-in-github-copilot-for-jetbrains-ides)
- [Using hooks with GitHub Copilot coding agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)
- [Platform comparison guide](platforms.md)
- [JetBrains preview config in this repo](../.github/hooks/hooks-jetbrains.json)
