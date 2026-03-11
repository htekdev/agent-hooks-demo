# Agent Hooks Demo

Practical examples of **Copilot agent hooks** — governance rules that control what AI agents can and can't do inside your repository.

> Agent hooks (powered by [hookflow](https://github.com/htekdev/gh-hookflow)) let you define YAML workflows that automatically run before or after an agent takes an action — editing a file, running a command, making a commit, or pushing code. Think of them as guardrails for AI.

---

## What's in This Repo

This repository contains **5 hookflow workflows** that demonstrate the most common agent governance patterns:

| Hook | File | Trigger | When | What It Does |
|------|------|---------|------|--------------|
| 🔒 Block Secrets | [`block-secrets.yml`](.github/hookflows/block-secrets.yml) | `file` | **pre** | Prevents agents from touching `.env`, `.pem`, `.key`, or `secrets/` files |
| 🛡️ Protect Hookflows | [`protect-hookflows.yml`](.github/hookflows/protect-hookflows.yml) | `file` | **pre** | Stops agents from modifying the governance rules themselves |
| ✅ Validate JSON | [`validate-json.yml`](.github/hookflows/validate-json.yml) | `file` | **post** | Checks JSON syntax after any `.json` file is edited |
| 📝 Conventional Commits | [`conventional-commits.yml`](.github/hookflows/conventional-commits.yml) | `commit` | **pre** | Enforces `type(scope): description` commit message format |
| 🧪 Require Tests | [`require-tests.yml`](.github/hookflows/require-tests.yml) | `commit` | **pre** | Blocks commits to `src/` unless test files are included |

---

## How Agent Hooks Work

### The Basics

Agent hooks intercept actions that an AI agent tries to perform. Each hook is a YAML file in `.github/hookflows/` with three parts:

```yaml
name: My Hook                    # Human-readable name
on:                               # When to trigger
  file:                           #   ↳ trigger type (file, commit, push, tool)
    paths: ['**/*.env']           #   ↳ which files to match
    types: [create, edit]         #   ↳ which actions to match
    lifecycle: pre                #   ↳ run BEFORE (pre) or AFTER (post) the action
steps:                            # What to do
  - name: Check something
    run: |
      echo "This runs when the hook triggers"
      exit 1                      # exit 1 = block the action
```

### Pre vs Post Lifecycle

- **`pre`** hooks run **before** the action happens. They can **block** it by exiting with code 1. Use these for prevention.
- **`post`** hooks run **after** the action completes. They can validate the result and flag issues. Use these for validation.

### Trigger Types

| Trigger | Fires When | Example Use |
|---------|-----------|-------------|
| `file` | A file is created, edited, or deleted | Block edits to sensitive files |
| `commit` | A git commit is made | Enforce commit message format |
| `push` | Code is pushed to remote | Require approvals for main branch |
| `tool` | A specific tool is called | Block dangerous shell commands |

---

## Walkthrough of Each Hook

### 🔒 Block Secrets (`block-secrets.yml`)

**Goal:** Prevent agents from creating or editing files that commonly contain secrets.

```yaml
on:
  file:
    lifecycle: pre
    paths:
      - '**/.env'
      - '**/.env.*'
      - '**/secrets/**'
      - '**/*.pem'
      - '**/*.key'
    types: [create, edit]
blocking: true
```

**How it works:** When an agent tries to create or edit any file matching these glob patterns, the hook fires *before* the edit happens and blocks it with a clear error message. The agent can't bypass it — the action simply doesn't execute.

**Why it matters:** AI agents should never hardcode secrets. This hook enforces that secrets are managed through proper channels (CI/CD variables, vaults, etc.).

---

### 🛡️ Protect Hookflows (`protect-hookflows.yml`)

**Goal:** Prevent agents from modifying the governance rules themselves.

```yaml
on:
  file:
    lifecycle: pre
    paths:
      - '.github/hookflows/**'
    types: [edit, create, delete]
blocking: true
```

**How it works:** This is the "who watches the watchmen" hook. If an agent tries to edit, create, or delete any file inside `.github/hookflows/`, it gets blocked. This ensures that only humans can change the rules that govern AI behavior.

**Why it matters:** Without this, an agent could weaken or disable its own governance rules to complete a task. Self-protecting governance is a fundamental safety pattern.

---

### ✅ Validate JSON (`validate-json.yml`)

**Goal:** Automatically validate JSON syntax after any edit.

```yaml
on:
  file:
    lifecycle: post
    paths: ['**/*.json']
    paths-ignore:
      - 'node_modules/**'
      - 'package-lock.json'
    types: [edit, create]
blocking: true
```

**How it works:** This is a **post** hook — it lets the edit happen first, then reads the file from disk and attempts to parse it. If the JSON is invalid, the agent is told to fix it. Note the `paths-ignore` to skip files the agent shouldn't need to validate.

**Why it matters:** Invalid JSON breaks applications silently. Catching syntax errors immediately after an edit saves debugging time.

---

### 📝 Conventional Commits (`conventional-commits.yml`)

**Goal:** Enforce consistent commit message formatting.

```yaml
on:
  commit:
    lifecycle: pre
blocking: true
```

**How it works:** Before every commit, the hook checks that the first line matches the Conventional Commits pattern: `type(scope): description`. Valid types include `feat`, `fix`, `docs`, `refactor`, `test`, etc. If the message doesn't match, the commit is blocked with helpful examples.

**Why it matters:** Consistent commit messages enable automated changelogs, semantic versioning, and make git history actually readable.

---

### 🧪 Require Tests (`require-tests.yml`)

**Goal:** Ensure source code changes are always accompanied by tests.

```yaml
on:
  commit:
    lifecycle: pre
    paths:
      - 'src/**'
    paths-ignore:
      - 'src/**/*.test.*'
      - 'src/**/*.spec.*'
blocking: true
```

**How it works:** When a commit includes files from `src/`, the hook checks whether any test files (`.test.*`, `.spec.*`, or files in `tests/`) are also included. If source code changes arrive without corresponding tests, the commit is blocked.

**Why it matters:** Tests are not optional. This hook enforces that every code change is tested before it enters the repository.

---

## Getting Started

### Prerequisites

Install the [hookflow CLI](https://github.com/htekdev/gh-hookflow):

```bash
gh extension install htekdev/gh-hookflow
```

### Using These Hooks in Your Repo

**Option 1: Copy the examples**

Copy the `.github/hookflows/` directory into your repository and customize the workflows to fit your needs.

**Option 2: Start from scratch**

```bash
# Initialize hookflow in your repo with example scaffolding
gh hookflow init --repo

# Or generate a hook from a plain-English description
gh hookflow create "block edits to any file in the config/ directory"
```

### Register the Hooks

To activate hooks in your Copilot CLI sessions:

```bash
gh hookflow register
```

This installs the Git hooks and Copilot skill that make hookflows run automatically during agent sessions.

### Validate Your Workflows

```bash
gh hookflow validate
```

### Test a Workflow

```bash
# Simulate a file event to see if your hook would trigger
gh hookflow test --workflow block-secrets --event file --path ".env"
```

---

## Repository Structure

```
agent-hooks-demo/
├── .github/
│   └── hookflows/
│       ├── block-secrets.yml          # 🔒 Block sensitive file access
│       ├── protect-hookflows.yml      # 🛡️ Self-protecting governance
│       ├── validate-json.yml          # ✅ Post-edit JSON validation
│       ├── conventional-commits.yml   # 📝 Commit message format
│       └── require-tests.yml          # 🧪 Tests required with source changes
├── src/
│   └── index.js                       # Sample source code
├── tests/
│   └── index.test.js                  # Sample test file
├── config/
│   └── settings.json                  # Sample JSON config
├── .gitignore
└── README.md
```

---

## Learn More

- **[gh-hookflow](https://github.com/htekdev/gh-hookflow)** — The hookflow CLI and runtime engine
- **[Hookflow Schema Reference](https://github.com/htekdev/gh-hookflow#schema)** — Full YAML schema documentation
- **[GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line)** — Copilot in your terminal

---

## License

MIT
