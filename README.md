# Agent Hooks Demo

> Practical, emoji-heavy examples of **Copilot agent hooks** across **Copilot CLI**, **Copilot coding agent**, **VS Code**, **JetBrains IDEs**, and **personal `~/.copilot/hooks/` profiles**.

Agent hooks are deterministic guardrails for AI agents: small shell commands that run at specific lifecycle points, receive structured JSON on **stdin**, and can log, enrich context, warn, or block actions. This repository is the quick-start guide; for deeper examples, jump into [`docs/examples/personal-hooks.json`](docs/examples/personal-hooks.json) and [`docs/examples/strict-reviewer.agent.md`](docs/examples/strict-reviewer.agent.md).

> [!IMPORTANT]
> This demo intentionally keeps multiple hook profiles side-by-side so you can compare platforms. In a real repository, be selective: supported runtimes load **all** matching `.github/hooks/*.json` files, so leaving overlapping demo profiles enabled can cause duplicate hook execution.

---

## 🌍 Platform Support

| Platform | Status | Config Location | Format | Hook Events |
|---|---|---|---|---|
| **Copilot CLI** | **GA** — examples here reference [v1.0.5-0](https://github.com/github/copilot-cli/releases/tag/v1.0.5-0), [`ask` in v1.0.4-0](https://github.com/github/copilot-cli/releases/tag/v1.0.4-0), and [personal hooks in v0.0.422](https://github.com/github/copilot-cli/releases/tag/v0.0.422) | `.github/hooks/` + `~/.copilot/hooks/` | CLI JSON | `sessionStart`, `sessionEnd`, `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred` |
| **Copilot Coding Agent** | **GA** — repo hooks must live on the [default branch](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks) | `.github/hooks/` | CLI JSON | Same 6 as Copilot CLI |
| **VS Code** | **Preview** — [1.112 Insiders](https://code.visualstudio.com/updates/v1_112) adds `~/.copilot/hooks`; [1.111](https://code.visualstudio.com/updates/v1_111) adds agent-scoped hooks | `.github/hooks/` + `~/.copilot/hooks/` + custom paths via `chat.hookFilesLocations` | CLI JSON accepted + VS Code native format | `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PreCompact`, `SubagentStart`, `SubagentStop`, `Stop` |
| **JetBrains IDEs** | **Public Preview** — [March 11, 2026 changelog](https://github.blog/changelog/2026-03-11-major-agentic-capabilities-improvements-in-github-copilot-for-jetbrains-ides) | `.github/hooks/` | CLI JSON subset | `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred` |

### 🧭 What this matrix means in practice

- **CLI + coding agent** share the classic GitHub Docs hook model.
- **VS Code** accepts repo-level CLI-style JSON files, but its **hook input/output contract is different and more powerful**.
- **JetBrains preview** currently covers the overlapping four-event subset, which is why this repo ships a conservative [`hooks-jetbrains.json`](.github/hooks/hooks-jetbrains.json) profile.
- **Personal hooks** are ideal for things you want everywhere you work, without committing them into a team repository.

---

## 📦 What's in This Repo

### Hook profiles and examples

| File | Purpose |
|---|---|
| [`.github/hooks/hooks.json`](.github/hooks/hooks.json) | Main repo-level demo in classic CLI JSON format — the broadest compatibility baseline |
| [`.github/hooks/hooks-jetbrains.json`](.github/hooks/hooks-jetbrains.json) | JetBrains-compatible subset limited to preview-supported events |
| [`docs/examples/personal-hooks.json`](docs/examples/personal-hooks.json) | Example personal profile for `~/.copilot/hooks/` |
| [`docs/examples/strict-reviewer.agent.md`](docs/examples/strict-reviewer.agent.md) | VS Code agent-scoped hook example using `.agent.md` frontmatter |

### Included hook scripts

| Hook | Script | Event(s) | Where it fits | What it does |
|---|---|---|---|---|
| 📋 Session Log | [`session-log`](scripts/hooks/session-log.sh) | `sessionStart` / `sessionEnd` | CLI, coding agent, personal | Logs session start/end for audit trail |
| 🔒 Block Secrets | [`block-secrets`](scripts/hooks/block-secrets.sh) | `preToolUse` | CLI, coding agent, JetBrains, personal | Denies create/edit of `.env`, `.pem`, `.key`, and `secrets/` paths |
| 🛡️ Protect Hooks | [`protect-hooks`](scripts/hooks/protect-hooks.sh) | `preToolUse` | CLI, coding agent, JetBrains | Prevents agents from modifying hook configs, hook scripts, and agent definition files |
| 📝 Conventional Commits | [`conventional-commits`](scripts/hooks/conventional-commits.sh) | `preToolUse` | CLI, coding agent, JetBrains, personal | Enforces `type(scope): description` commit messages |
| 🧪 Require Tests | [`require-tests`](scripts/hooks/require-tests.sh) | `preToolUse` | CLI, coding agent, JetBrains | Blocks `git commit` when `src/` changes are staged without tests |
| ✅ Validate JSON | [`validate-json`](scripts/hooks/validate-json.sh) | `postToolUse` | CLI, coding agent, JetBrains | Validates edited `.json` files after a successful tool run |
| 🗒️ Log Prompt | [`log-prompt`](scripts/hooks/log-prompt.sh) | `userPromptSubmitted` | JetBrains, CLI, personal | Logs submitted prompts to `logs/agent-prompts.log` |
| 🚨 Log Error | [`log-error`](scripts/hooks/log-error.sh) | `errorOccurred` | JetBrains, CLI | Logs hook/tool errors to `logs/agent-errors.log` |
| 🛑 Review Checklist | [`review-checklist`](scripts/hooks/review-checklist.sh) | `Stop` | VS Code agent-scoped hooks | Blocks a reviewer agent from stopping until it has completed its checklist |

Every repo-level policy hook ships in **Bash and PowerShell**. The Stop-hook example is Bash-only because it demonstrates VS Code's native agent-scoped flow rather than the CLI contract.

---

## ⚙️ How Agent Hooks Work

### The basics

At a high level, every hook does three things:

1. **Receives structured JSON on stdin**
2. **Runs your policy or automation logic**
3. **Optionally writes JSON to stdout** to influence the agent

Repo-level hooks live in `.github/hooks/*.json`. Personal hooks live in `~/.copilot/hooks/*.json`. VS Code can also load custom paths through `chat.hookFilesLocations`, and agent-scoped hooks can live directly inside `.agent.md` frontmatter.

A minimal repo-level hook file looks like this:

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

For **Copilot coding agent**, that file must be present on the repository's **default branch**. For **Copilot CLI**, it is loaded from the current working directory. For **VS Code** and **JetBrains**, the file is discovered by the IDE when the feature is enabled.

### 🪝 Hook types

| Lifecycle moment | CLI / Coding Agent / JetBrains | VS Code | Can influence behavior? | Common use |
|---|---|---|---|---|
| Session starts | `sessionStart` | `SessionStart` | CLI: log only • VS Code: can inject context | Banners, audit logs, environment notes |
| User sends a prompt | `userPromptSubmitted` | `UserPromptSubmit` | Usually log/warn | Audit trails, prompt capture, policy notices |
| Before a tool runs | `preToolUse` | `PreToolUse` | **Yes** | Allow/deny/ask, input rewriting, approvals |
| After a tool runs | `postToolUse` | `PostToolUse` | CLI: advisory • VS Code: **yes** | Validation, formatter runs, follow-up context |
| Before context compacts | — | `PreCompact` | Session-level control only | Save state before prompt compaction |
| Subagent starts | — | `SubagentStart` | Can inject context | Track or steer nested agents |
| Main agent stops | `sessionEnd` | `Stop` | CLI: log only • VS Code: **yes** | Cleanup, summaries, review checklists |
| Subagent stops | — | `SubagentStop` | **Yes** | Force subagent follow-up before exit |
| Error happens | `errorOccurred` | — (no matching repo-level event in current preview docs) | Usually log only | Alerting, troubleshooting, audit |

### 🚫 How blocking works

#### CLI / Coding Agent / JetBrains: flat JSON on stdout

For the classic GitHub Docs hook model, the important blocking hook is `preToolUse`. A deny looks like this:

```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "Destructive command blocked by policy"
}
```

Current Copilot CLI builds recognize three decisions:

- `"allow"`
- `"deny"`
- `"ask"` — added in [Copilot CLI v1.0.4-0](https://github.com/github/copilot-cli/releases/tag/v1.0.4-0)

`sessionStart`, `sessionEnd`, `userPromptSubmitted`, `postToolUse`, and `errorOccurred` are **advisory/logging hooks** in the CLI-style contract: they can write to logs or stderr, but their stdout is ignored for control flow.

#### VS Code: hook-specific JSON or exit code `2`

VS Code adds several more control surfaces:

- `PreToolUse` uses `hookSpecificOutput.permissionDecision`
- `PostToolUse` can block further processing with `decision: "block"`
- `SessionStart` can inject `additionalContext`
- `Stop` and `SubagentStop` can keep the agent running until a condition is met
- Every hook also supports the common top-level fields `continue`, `stopReason`, and `systemMessage`
- Exit code `2` is a **blocking error** and sends stderr back to the model as context

VS Code exit codes:

| Exit Code | Meaning |
|---|---|
| `0` | Success — parse stdout JSON if present |
| `2` | Blocking error — stop processing and show stderr to the model |
| Other non-zero | Warning — continue, but surface the warning |

A practical VS Code hard-stop pattern looks like this:

```bash
echo "Security policy violation: run tests before stopping" >&2
exit 2
```

### 📨 Input format

#### CLI / Coding Agent / JetBrains input

The classic hook contract passes a **stringified** tool argument payload:

```json
{
  "timestamp": 1704614600000,
  "cwd": "/path/to/project",
  "toolName": "edit",
  "toolArgs": "{\"path\":\"src/index.js\",\"old_str\":\"...\",\"new_str\":\"...\"}"
}
```

Important details:

- `toolArgs` is a **JSON string**, so your script usually needs a second parse step.
- `postToolUse` adds `toolResult`, including `resultType` and `textResultForLlm`.
- `errorOccurred` receives an `error` object with `message`, `name`, and `stack`.

#### VS Code input

VS Code passes a richer, more structured payload:

```json
{
  "timestamp": "2026-03-11T10:30:00.000Z",
  "cwd": "/path/to/workspace",
  "sessionId": "session-123",
  "hookEventName": "PreToolUse",
  "transcript_path": "/path/to/transcript.json",
  "tool_name": "editFiles",
  "tool_input": { "files": ["src/index.js"] },
  "tool_use_id": "tool-123"
}
```

Important differences:

- `tool_input` is already an **object**, not a string.
- Tool naming is different: VS Code uses fields such as `tool_name`, `tool_input`, `tool_response`, and `tool_use_id`.
- `Stop` and `SubagentStop` include `stop_hook_active` so your hook can avoid infinite loops.
- `SubagentStart` / `SubagentStop` add `agent_id` and `agent_type`.

### 🔁 Output format differences — this is the big gotcha

The config files are getting more similar across platforms, but the **stdout contract is not**.

#### Side-by-side: deny a tool call before it runs

**CLI / Coding Agent / JetBrains**

```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "Editing .env files is blocked"
}
```

**VS Code**

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Editing .env files is blocked"
  }
}
```

#### Side-by-side: react after a tool call finishes

**CLI / Coding Agent / JetBrains**

```text
stdout is ignored for postToolUse
→ log to stderr or a file instead
```

**VS Code**

```json
{
  "decision": "block",
  "reason": "Post-processing validation failed",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "The edited JSON file is invalid. Fix it before continuing."
  }
}
```

#### Quick rules of thumb

- **CLI-style hooks**: think **flat JSON** and **`preToolUse` is the main blocker**.
- **VS Code hooks**: think **`hookSpecificOutput` wrapper**, richer lifecycle events, and **multiple ways to block or steer execution**.
- **JetBrains preview**: treat it as **CLI-style** unless the JetBrains docs say otherwise.

### 🔄 Format convergence

The ecosystem is converging, but not fully unified yet:

- **VS Code explicitly accepts CLI-style repo hook files**, which is why this repository keeps its shared examples in classic JSON.
- **Modern hook tooling is converging on `command` / `timeout` naming**, but the classic CLI fields `bash` / `powershell` / `timeoutSec` remain the clearest documented baseline for shared repo examples.
- In practice, that means **config portability is improving**, but **script output portability is not**.
- This demo deliberately uses the classic CLI-style config for repo-level examples because it is explicit, readable, and broadly portable.

---

## 🔍 Walkthrough of Each Hook

### 📋 Session Log (`session-log.sh` / `session-log.ps1`)

**Goal:** Create an audit trail of agent sessions.

**How it works:** Runs on both `sessionStart` and `sessionEnd`. It checks whether the input includes `source` or `reason`, then appends a timestamped line to `logs/agent-sessions.log`.

```bash
# Example log output:
# [2025-01-07T12:00:00Z] SESSION START | source=new | cwd=/home/user/project
# [2025-01-07T12:05:30Z] SESSION END   | reason=complete | cwd=/home/user/project
```

**Why it matters:** Session-level logging is the easiest way to prove when agent work started, how it ended, and where it ran.

---

### 🔒 Block Secrets (`block-secrets.sh` / `block-secrets.ps1`)

**Goal:** Prevent agents from creating or editing files that commonly contain secrets.

**How it works:** Intercepts `preToolUse` events where the tool is `edit` or `create`, extracts the target path, and denies access to `.env`, `.pem`, `.key`, and `secrets/` locations.

```bash
case "$FILE_PATH" in
  *.env|*/.env|*/.env.*)  BLOCKED=true ;;
  *.pem)                   BLOCKED=true ;;
  *.key)                   BLOCKED=true ;;
  */secrets/*|secrets/*)   BLOCKED=true ;;
esac
```

**Why it matters:** Secrets should live in vaults, CI/CD variables, or secure platform services — not in AI-generated file edits.

---

### 🛡️ Protect Hooks (`protect-hooks.sh` / `protect-hooks.ps1`)

**Goal:** Prevent agents from modifying the governance rules themselves.

**How it works:** Blocks edits and creates that target `.github/hooks/`, `.copilot/hooks/`, `.github/agents/*.agent.md`, or `scripts/hooks/`.

```bash
if echo "$FILE_PATH" | grep -qE '(^|[\\/])\.github[\\/]hooks[\\/]|(^|[\\/])\.copilot[\\/]hooks[\\/]|(^|[\\/])\.github[\\/]agents[\\/][^\\/]+\.agent\.md$|(^|[\\/])scripts[\\/]hooks[\\/]'; then
  # Deny — humans must change the rules that govern the agents
fi
```

**Why it matters:** Good governance protects itself. Otherwise an agent can simply weaken the rules that are slowing it down.

---

### 📝 Conventional Commits (`conventional-commits.sh` / `conventional-commits.ps1`)

**Goal:** Enforce consistent commit message formatting.

**How it works:** Watches `bash` / `powershell` tool calls for `git commit`, extracts the `-m` message, and validates the first line against the Conventional Commits pattern.

```bash
PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+'

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
  # Deny with examples and valid types
fi
```

**Why it matters:** Consistent commit messages unlock cleaner history, better changelogs, and predictable release notes.

---

### 🧪 Require Tests (`require-tests.sh` / `require-tests.ps1`)

**Goal:** Ensure source code changes are always accompanied by tests.

**How it works:** Intercepts `git commit`, inspects staged files, and denies the commit when `src/` changes are present without matching test files in `tests/` or `*.test.*` / `*.spec.*`.

```bash
HAS_SOURCE=$(echo "$STAGED_FILES" | grep -E '^src/' | grep -vE '\.(test|spec)\.' || true)
HAS_TESTS=$(echo "$STAGED_FILES" | grep -E '\.(test|spec)\.|^tests/' || true)

if [ -n "$HAS_SOURCE" ] && [ -z "$HAS_TESTS" ]; then
  # Deny — source changes need tests
fi
```

**Why it matters:** This turns “please add tests” from a convention into an enforceable policy.

---

### ✅ Validate JSON (`validate-json.sh` / `validate-json.ps1`)

**Goal:** Automatically validate JSON syntax after any successful edit or create.

**How it works:** Runs on `postToolUse`, filters for successful `.json` edits, skips `node_modules` and `package-lock.json`, and validates the file with `jq`. It reports success or failure to **stderr**.

```bash
if ! jq empty "$FILE_PATH" 2>/dev/null; then
  echo "❌ Invalid JSON detected in: $FILE_PATH" >&2
  echo "   Please fix the syntax error." >&2
else
  echo "✅ Valid JSON: $FILE_PATH" >&2
fi
```

**Why it matters:** On CLI-style platforms this is advisory, which makes it a great example of a non-blocking quality hook. In VS Code, the same idea can be upgraded into a blocking `PostToolUse` rule with `decision: "block"`.

---

### 🗒️ Log Prompt (`log-prompt.sh` / `log-prompt.ps1`)

**Goal:** Record submitted prompts for audit and usage tracking.

**How it works:** Reads `prompt`, `cwd`, and `timestamp` from stdin, creates `logs/` if needed, and appends a line to `logs/agent-prompts.log`.

```bash
# Example log output:
# [2026-03-11T14:20:00Z] PROMPT | Refactor src/index.js and add tests
```

**Why it matters:** Prompt logging helps teams understand what agents were asked to do, and it doubles as a lightweight audit trail for JetBrains preview setups that support `userPromptSubmitted`. In production, add redaction and retention rules before storing prompt text.

---

### 🚨 Log Error (`log-error.sh` / `log-error.ps1`)

**Goal:** Capture tool or hook failures for troubleshooting.

**How it works:** Reads `error.message`, `error.name`, and `cwd`, then appends a timestamped entry to `logs/agent-errors.log`.

```bash
# Example log output:
# [2026-03-11T14:22:10Z] ERROR | [TimeoutError] Network timeout
```

**Why it matters:** Error hooks are low-friction observability. They give you a paper trail when a policy script, tool, or integration misbehaves.

---

### 🛑 Review Checklist (`review-checklist.sh`)

**Goal:** Prevent a review-focused agent from stopping before it has completed its final checklist.

**How it works:** This is a **VS Code Stop hook**, intended for agent-scoped frontmatter. It checks `stop_hook_active` to avoid infinite loops, then returns VS Code-native `hookSpecificOutput` with `decision: "block"`.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Please verify that all changes have test coverage before completing the review."
  }
}
```

**Why it matters:** This is the clearest example in the repo of something **VS Code can do that CLI-style hooks cannot**: keep an agent running until it satisfies a final policy.

---

## 🚀 Getting Started

### 1) Copilot CLI / Copilot Coding Agent

**Best when:** You want repo-enforced hooks that work in terminal sessions and GitHub-hosted coding agent runs.

1. Copy the main profile and scripts into your repo.
2. Keep the hook file on the **default branch** for Copilot coding agent.
3. Run Copilot CLI from the repository root for local testing.

```bash
mkdir -p YOUR_REPO/.github/hooks
cp .github/hooks/hooks.json YOUR_REPO/.github/hooks/
cp -r scripts/hooks YOUR_REPO/scripts/hooks
chmod +x YOUR_REPO/scripts/hooks/*.sh
```

A minimal local smoke test:

```bash
echo '{
  "timestamp": 1704614600000,
  "cwd": "/tmp",
  "toolName": "create",
  "toolArgs": "{\"path\":\".env\",\"file_text\":\"SECRET=abc123\"}"
}' | ./scripts/hooks/block-secrets.sh
```

**Version notes:**

- `ask` decisions require **Copilot CLI v1.0.4-0+**.
- `preCompact` arrives in **v1.0.5-0**.
- Personal hooks require **v0.0.422+**.

### 2) VS Code (Preview)

**Best when:** You want richer lifecycle events, agent-scoped hooks, or the ability to inject context and block agent completion.

**Recommended versions:**

- **VS Code 1.112 Insiders+** for the new `~/.copilot/hooks` location
- **VS Code 1.111+** for agent-scoped hooks in `.agent.md`

Repo-level hooks are discovered from `.github/hooks/`. You can add more locations with `chat.hookFilesLocations`:

```json
{
  "chat.hookFilesLocations": {
    ".github/hooks": true,
    "~/.copilot/hooks": true,
    "custom/hooks": true
  },
  "chat.useCustomAgentHooks": true
}
```

**Native VS Code agent vs Copilot CLI in a terminal**

- If you are using the **native VS Code agent**, your hooks use the **VS Code event names and output schema** (`SessionStart`, `PreToolUse`, `Stop`, `hookSpecificOutput`, `tool_use_id`, and so on).
- If you open a terminal and run **Copilot CLI**, that terminal session uses the **CLI hook contract** instead.

**Tip:** Watch the **GitHub Copilot Chat Hooks** output channel when debugging VS Code hooks.

### 3) JetBrains IDEs (Public Preview)

**Best when:** You want repo-level policies in JetBrains, but you're happy staying within the currently documented four-event preview subset.

Use the conservative profile in this repo as your starting point:

```text
.github/hooks/hooks-jetbrains.json
```

That file intentionally limits itself to:

- `userPromptSubmitted`
- `preToolUse`
- `postToolUse`
- `errorOccurred`

**Recommended rollout:** keep only the JetBrains subset enabled in a JetBrains-first repo, or separate demo profiles so you don't duplicate overlapping hooks.

**Preview note:** Managed organizations may need the **Editor preview features** policy enabled before hooks appear in JetBrains.

### 4) Personal hooks (`~/.copilot/hooks/`)

**Best when:** You want your own universal guardrails everywhere, without changing team repos.

Copy the personal example into your home directory:

```bash
mkdir -p ~/.copilot/hooks ~/.copilot/scripts
cp docs/examples/personal-hooks.json ~/.copilot/hooks/personal-hooks.json
cp docs/examples/personal-session-log.sh ~/.copilot/scripts/
cp docs/examples/personal-safety-check.sh ~/.copilot/scripts/
chmod +x ~/.copilot/scripts/*.sh
```

The included personal example shows two high-value patterns:

- **Personal session logging** across all repos
- **Personal safety checks** that deny destructive commands and use `permissionDecision: "ask"` for force-pushes

Personal hooks run **in addition to** repo-level hooks — they are not a replacement for shared team policy.

### 5) Writing your own hook

A minimal CLI-style `preToolUse` hook looks like this:

```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs // "{}"')

if [ "$TOOL_NAME" = "bash" ]; then
  COMMAND=$(echo "$TOOL_ARGS" | jq -r '.command // empty')
  if echo "$COMMAND" | grep -qE 'rm -rf|mkfs'; then
    jq -n --arg reason "Dangerous command blocked" '{permissionDecision:"deny", permissionDecisionReason:$reason}'
    exit 0
  fi
fi

exit 0
```

For VS Code-native hooks, remember to switch to the **VS Code output wrapper** when you need to influence behavior.

---

## 🤖 Agent-Scoped Hooks (VS Code 1.111+)

VS Code custom agents can define hooks directly in `.agent.md` frontmatter. These hooks run **only when that agent is active** — either because the user selected it explicitly or because it was invoked as a subagent.

This repository includes a concrete example:

- [`docs/examples/strict-reviewer.agent.md`](docs/examples/strict-reviewer.agent.md)
- [`docs/examples/review-checklist.sh`](docs/examples/review-checklist.sh)

A shortened version of the example looks like this:

> [!NOTE]
> Agent-scoped hooks are still a preview feature. Treat the exact frontmatter shape as version-sensitive, and verify it against the current VS Code docs before rolling it out broadly.

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

### Why agent-scoped hooks are useful

- ✅ Apply stricter policy to one specialized agent without affecting every chat session
- ✅ Add a reviewer-only Stop checklist
- ✅ Run different post-processing for an editor agent vs a reviewer agent
- ✅ Keep repo-level hooks focused on organization-wide baseline rules

### Important notes

- Enable `chat.useCustomAgentHooks` in VS Code.
- Agent-scoped hooks use the **VS Code native hook contract**, not the flat CLI output contract.
- `Stop` and `SubagentStop` can keep an agent alive, so always check `stop_hook_active` to avoid loops.

---

## 🗂️ Repository Structure

```text
agent-hooks-demo/
├── .github/
│   └── hooks/
│       ├── hooks.json                        # Main hooks config (CLI format — works everywhere)
│       └── hooks-jetbrains.json              # JetBrains-compatible subset (preview events only)
├── scripts/
│   └── hooks/
│       ├── session-log.sh / .ps1             # Audit trail logging
│       ├── block-secrets.sh / .ps1           # Block sensitive file access
│       ├── protect-hooks.sh / .ps1           # Self-protecting governance
│       ├── conventional-commits.sh / .ps1    # Commit message format
│       ├── require-tests.sh / .ps1           # Tests required with source changes
│       ├── validate-json.sh / .ps1           # Post-edit JSON validation
│       ├── log-prompt.sh / .ps1              # Log user prompts (JetBrains/CLI)
│       ├── log-error.sh / .ps1               # Log errors (JetBrains/CLI)
│       └── review-checklist.sh               # VS Code Stop hook for agent-scoped hooks
├── docs/
│   └── examples/
│       ├── personal-hooks.json               # ~/.copilot/hooks/ config example
│       ├── personal-session-log.sh           # Personal session logging script
│       ├── personal-safety-check.sh          # Personal dangerous command blocker
│       ├── strict-reviewer.agent.md          # VS Code agent-scoped hooks example
│       └── review-checklist.sh               # Stop hook for agent-scoped example
├── src/index.js
├── tests/index.test.js
├── config/settings.json
├── logs/agent-sessions.log
└── README.md
```

---

## 📚 Learn More

### GitHub Docs

- [About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)
- [Hooks configuration reference](https://docs.github.com/en/copilot/reference/hooks-configuration)
- [Using hooks with GitHub Copilot agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)
- [Using hooks with Copilot CLI for predictable, policy-compliant execution](https://docs.github.com/en/copilot/tutorials/copilot-cli-hooks)
- [Using hooks with GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks)

### Release notes and platform docs

- [Copilot CLI v1.0.5-0](https://github.com/github/copilot-cli/releases/tag/v1.0.5-0) — includes `preCompact`
- [Copilot CLI v1.0.4-0](https://github.com/github/copilot-cli/releases/tag/v1.0.4-0) — adds `permissionDecision: "ask"`
- [Copilot CLI v0.0.422](https://github.com/github/copilot-cli/releases/tag/v0.0.422) — adds `~/.copilot/hooks`
- [VS Code agent hooks (Preview)](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [VS Code 1.112 Insiders](https://code.visualstudio.com/updates/v1_112) — adds `~/.copilot/hooks`
- [VS Code 1.111](https://code.visualstudio.com/updates/v1_111) — adds agent-scoped hooks
- [JetBrains March 11, 2026 changelog](https://github.blog/changelog/2026-03-11-major-agentic-capabilities-improvements-in-github-copilot-for-jetbrains-ides)

### Repo examples

- [Personal hooks example](docs/examples/personal-hooks.json)
- [Strict reviewer agent example](docs/examples/strict-reviewer.agent.md)
- [JetBrains subset profile](.github/hooks/hooks-jetbrains.json)

---

## 📄 License

MIT
