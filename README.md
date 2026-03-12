# Agent Hooks Demo

Practical examples of **Copilot agent hooks** — shell scripts that run at key points during AI agent sessions to enforce governance, security, and quality standards.

> Agent hooks let you execute custom shell commands before or after an agent takes an action — editing a file, running a command, or any tool call. They receive JSON context via stdin and can **approve or deny** operations. Think of them as guardrails for AI.

---

## What's in This Repo

This repository contains a complete hooks configuration with **7 example hooks** covering the most common agent governance patterns:

| Hook | Script | Type | What It Does |
|------|--------|------|--------------|
| 📋 Session Log | [`session-log`](scripts/hooks/session-log.sh) | `sessionStart` / `sessionEnd` | Logs session start and end events for audit trail |
| 🔒 Block Secrets | [`block-secrets`](scripts/hooks/block-secrets.sh) | `preToolUse` | Denies edit/create of `.env`, `.pem`, `.key`, and `secrets/` files |
| 🛡️ Protect Hooks | [`protect-hooks`](scripts/hooks/protect-hooks.sh) | `preToolUse` | Stops agents from modifying hook governance files |
| 📝 Conventional Commits | [`conventional-commits`](scripts/hooks/conventional-commits.sh) | `preToolUse` | Enforces `type(scope): description` commit message format |
| 🧪 Require Tests | [`require-tests`](scripts/hooks/require-tests.sh) | `preToolUse` | Blocks commits to `src/` unless test files are included |
| 🚫 Block Skill | [`block-skill`](scripts/hooks/block-skill.sh) | `preToolUse` | Blocks agents from invoking restricted skills (e.g., `cloud-deploy`) |
| ✅ Validate JSON | [`validate-json`](scripts/hooks/validate-json.sh) | `postToolUse` | Validates JSON syntax after any `.json` file is edited |

Every hook includes both **Bash** and **PowerShell** scripts for cross-platform support.

---

## How Agent Hooks Work

### The Basics

Hooks are configured in JSON files at `.github/hooks/*.json`. Each file declares which hook types to use and what scripts to run:

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

### Hook Types

| Hook Type | When It Fires | Can Block? | Example Use |
|-----------|--------------|------------|-------------|
| `sessionStart` | New agent session begins | No | Initialize logging, validate environment |
| `sessionEnd` | Agent session completes | No | Cleanup, generate reports |
| `userPromptSubmitted` | User submits a prompt | No | Audit logging, usage tracking |
| **`preToolUse`** | **Before any tool executes** | **Yes** | Block dangerous commands, enforce policies |
| `postToolUse` | After a tool completes | No | Validate results, log statistics |
| `errorOccurred` | An error occurs | No | Send alerts, track error patterns |

### How Blocking Works (`preToolUse`)

`preToolUse` is the most powerful hook — it can **deny tool executions** by returning JSON to stdout:

```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "This operation is not allowed because..."
}
```

If the script outputs nothing or returns `"allow"`, the tool call proceeds normally.

### Input Format

Every hook receives JSON context via stdin:

```json
{
  "timestamp": 1704614600000,
  "cwd": "/path/to/project",
  "toolName": "edit",
  "toolArgs": "{\"path\":\"src/auth.js\",\"old_str\":\"...\",\"new_str\":\"...\"}"
}
```

For `postToolUse`, the input also includes a `toolResult` field:

```json
{
  "toolResult": {
    "resultType": "success",
    "textResultForLlm": "File updated successfully"
  }
}
```

---

## Walkthrough of Each Hook

### 📋 Session Log (`session-log.sh` / `session-log.ps1`)

**Goal:** Create an audit trail of agent sessions.

**How it works:** Runs on both `sessionStart` and `sessionEnd`. Reads the JSON input to determine whether it's a start or end event (by checking for `source` vs `reason` fields) and appends a timestamped entry to `logs/agent-sessions.log`.

**Key concept:** Not all hooks need to block — some just observe and log.

```bash
# Example log output:
# [2025-01-07T12:00:00Z] SESSION START | source=new | cwd=/home/user/project
# [2025-01-07T12:05:30Z] SESSION END   | reason=complete | cwd=/home/user/project
```

---

### 🔒 Block Secrets (`block-secrets.sh` / `block-secrets.ps1`)

**Goal:** Prevent agents from creating or editing files that commonly contain secrets.

**How it works:** Intercepts `preToolUse` events where `toolName` is `edit` or `create`. Extracts the file path from `toolArgs` and checks it against sensitive patterns (`.env`, `.pem`, `.key`, `secrets/`). Returns a deny decision if matched.

```bash
# The core logic:
case "$FILE_PATH" in
  *.env|*/.env|*/.env.*)  BLOCKED=true ;;
  *.pem)                   BLOCKED=true ;;
  *.key)                   BLOCKED=true ;;
  */secrets/*|secrets/*)   BLOCKED=true ;;
esac
```

**Why it matters:** AI agents should never hardcode secrets. This enforces that secrets are managed through CI/CD variables or a vault.

---

### 🛡️ Protect Hooks (`protect-hooks.sh` / `protect-hooks.ps1`)

**Goal:** Prevent agents from modifying the governance rules themselves.

**How it works:** Checks if any `edit` or `create` operation targets a file inside `.github/hooks/`. If so, denies the operation. This is the "who watches the watchmen" hook.

```bash
if echo "$FILE_PATH" | grep -qE '(^|/)\.github/hooks/'; then
  # Deny — agents can't edit their own rules
fi
```

**Why it matters:** Without this, an agent could weaken or disable its own governance rules to complete a task. Self-protecting governance is a fundamental safety pattern.

---

### 📝 Conventional Commits (`conventional-commits.sh` / `conventional-commits.ps1`)

**Goal:** Enforce consistent commit message formatting.

**How it works:** Intercepts `bash`/`powershell` tool calls that contain `git commit`. Extracts the commit message from the `-m` flag and validates it against the Conventional Commits pattern: `type(scope): description`.

```bash
PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+'

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
  # Deny with helpful examples
fi
```

**Why it matters:** Consistent commit messages enable automated changelogs, semantic versioning, and a readable git history.

---

### 🧪 Require Tests (`require-tests.sh` / `require-tests.ps1`)

**Goal:** Ensure source code changes are always accompanied by tests.

**How it works:** Intercepts `git commit` commands (via `preToolUse` on `bash`/`powershell`) and inspects `git diff --cached --name-only`. If any staged files are in `src/` but no test files (`.test.*`, `.spec.*`, or `tests/`) are present, the commit is blocked.

```bash
HAS_SOURCE=$(echo "$STAGED_FILES" | grep -E '^src/' | grep -vE '\.(test|spec)\.')
HAS_TESTS=$(echo "$STAGED_FILES" | grep -E '\.(test|spec)\.|^tests/')

if [ -n "$HAS_SOURCE" ] && [ -z "$HAS_TESTS" ]; then
  # Deny — source changes need tests
fi
```

**Why it matters:** Tests are not optional. This enforces that every code change is tested before it enters the repository.

---

### 🚫 Block Skill (`block-skill.sh` / `block-skill.ps1`)

**Goal:** Prevent agents from invoking restricted skills that require human oversight.

**How it works:** Intercepts `preToolUse` events where `toolName` is `skill`. Extracts the skill name from `toolArgs` and checks it against a configurable blocked list defined at the top of the script. The default blocked skill is `cloud-deploy` — a skill that deploys applications to cloud environments.

```bash
# Configurable list — add skill names to block
BLOCKED_SKILLS=(
  "cloud-deploy"
)

# Check if the invoked skill is blocked
SKILL_NAME=$(echo "$INPUT" | jq -r '.toolArgs' | jq -r '.skill // empty')

for BLOCKED in "${BLOCKED_SKILLS[@]}"; do
  if [ "$SKILL_NAME" = "$BLOCKED" ]; then
    # Deny with governance reason
  fi
done
```

**Why it matters:** Some skills perform high-impact operations (deployments, infrastructure provisioning, data exports) that should require human approval. This hook enforces that policy at the agent level, ensuring restricted skills can never be invoked — even if they're installed and available.

**Example prompt that would trigger this hook:**

> "Deploy my application to the staging cloud environment so the QA team can start testing the new features."

If `cloud-deploy` were an available skill, the agent would attempt to invoke it, and this hook would block it with a message directing the user to the proper CI/CD workflow.

---

### ✅ Validate JSON (`validate-json.sh` / `validate-json.ps1`)

**Goal:** Automatically validate JSON syntax after any edit.

**How it works:** This is a `postToolUse` hook — it runs **after** an `edit` or `create` completes. If the file has a `.json` extension, the script reads it from disk and attempts to parse it. Advisory output is logged to stderr.

```bash
if ! jq empty "$FILE_PATH" 2>/dev/null; then
  echo "❌ Invalid JSON detected in: $FILE_PATH" >&2
fi
```

**Why it matters:** Invalid JSON breaks applications silently. Catching syntax errors immediately after an edit saves debugging time.

---

## Getting Started

### Using These Hooks in Your Repo

1. **Copy the hooks configuration** into your repo:

```bash
# Copy the hooks config
mkdir -p .github/hooks
cp .github/hooks/hooks.json YOUR_REPO/.github/hooks/

# Copy the hook scripts
cp -r scripts/hooks YOUR_REPO/scripts/hooks

# Make scripts executable (Unix)
chmod +x YOUR_REPO/scripts/hooks/*.sh
```

2. **Commit to your default branch** — hooks must be present on the default branch for Copilot coding agent. For Copilot CLI, hooks are loaded from the current working directory.

3. **That's it** — hooks run automatically during Copilot agent sessions. No registration or installation needed.

### Writing Your Own Hook

Create a script that reads JSON from stdin and optionally outputs a permission decision:

```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')
TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs')

# Your logic here...

# To block:
echo '{"permissionDecision":"deny","permissionDecisionReason":"Reason here"}'

# To allow: output nothing, or:
echo '{"permissionDecision":"allow"}'
```

Then wire it into `.github/hooks/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "./scripts/hooks/my-hook.sh",
        "powershell": "./scripts/hooks/my-hook.ps1",
        "timeoutSec": 10
      }
    ]
  }
}
```

### Testing Hooks Locally

Pipe test JSON into your script to validate behavior:

```bash
# Test a preToolUse hook
echo '{
  "timestamp": 1704614600000,
  "cwd": "/tmp",
  "toolName": "create",
  "toolArgs": "{\"path\":\".env\",\"file_text\":\"SECRET=abc123\"}"
}' | ./scripts/hooks/block-secrets.sh

# Check the output — should see a deny decision
```

---

## Repository Structure

```
agent-hooks-demo/
├── .github/
│   └── hooks/
│       └── hooks.json                     # 🔧 Main hooks configuration
├── scripts/
│   └── hooks/
│       ├── session-log.sh / .ps1          # 📋 Audit trail logging
│       ├── block-secrets.sh / .ps1        # 🔒 Block sensitive file access
│       ├── protect-hooks.sh / .ps1        # 🛡️ Self-protecting governance
│       ├── conventional-commits.sh / .ps1 # 📝 Commit message format
│       ├── require-tests.sh / .ps1        # 🧪 Tests required with source changes
│       ├── block-skill.sh / .ps1          # 🚫 Block restricted skills
│       └── validate-json.sh / .ps1        # ✅ Post-edit JSON validation
├── src/
│   └── index.js                           # Sample source code
├── tests/
│   ├── hooks/
│   │   └── block-skill.test.sh / .ps1     # 🧪 Block skill hook tests
│   └── index.test.js                      # Sample test file
├── config/
│   └── settings.json                      # Sample JSON config
├── .gitignore
└── README.md
```

---

## Learn More

- **[About Hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)** — Conceptual overview of agent hooks
- **[Hooks Configuration Reference](https://docs.github.com/en/copilot/reference/hooks-configuration)** — Full reference with all hook types and input/output formats
- **[Using Hooks](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)** — How-to guide for creating hooks
- **[GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli)** — Copilot in your terminal

---

## License

MIT
