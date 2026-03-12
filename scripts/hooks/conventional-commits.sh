#!/bin/bash
# conventional-commits.sh — Enforce conventional commit message format
#
# Hook type: preToolUse
# Intercepts bash/powershell tool calls that run git commit and validates
# the commit message follows Conventional Commits format:
#   type(scope): description
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')

# Only check bash and powershell tool calls
if [ "$TOOL_NAME" != "bash" ] && [ "$TOOL_NAME" != "powershell" ]; then
  exit 0
fi

# Extract the command being run
COMMAND=$(echo "$INPUT" | jq -r '.toolArgs' | jq -r '.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check commands that include git commit
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Extract the commit message from -m flag
COMMIT_MSG=$(echo "$COMMAND" | grep -oP '(?<=-m\s["\x27])[^"\x27]+' | head -1)

if [ -z "$COMMIT_MSG" ]; then
  # No -m flag found — might be using an editor, allow it
  exit 0
fi

# Get the first line of the commit message
FIRST_LINE=$(echo "$COMMIT_MSG" | head -1)

# Validate against Conventional Commits pattern
PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+'

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
  jq -n \
    --arg msg "$FIRST_LINE" \
    '{
      permissionDecision: "deny",
      permissionDecisionReason: ("❌ Commit message does not follow Conventional Commits format.\n\n  Your message: " + $msg + "\n\n  Expected: type(scope): description\n  Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert\n  Examples: feat(auth): add login endpoint | fix: resolve null pointer")
    }'
fi
