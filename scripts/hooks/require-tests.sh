#!/bin/bash
# require-tests.sh — Require test files when committing source changes
#
# Hook type: preToolUse
# Intercepts git commit commands and checks whether the staged files include
# tests alongside source changes in src/. If source files are staged without
# any corresponding test files, the commit is blocked.
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')

# Only check bash and powershell tool calls
if [ "$TOOL_NAME" != "bash" ] && [ "$TOOL_NAME" != "powershell" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.toolArgs' | jq -r '.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Get the list of staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

# Check if any source files in src/ are staged (excluding test files)
HAS_SOURCE=$(echo "$STAGED_FILES" | grep -E '^src/' | grep -vE '\.(test|spec)\.' || true)

# Check if any test files are staged
HAS_TESTS=$(echo "$STAGED_FILES" | grep -E '\.(test|spec)\.|^tests/' || true)

if [ -n "$HAS_SOURCE" ] && [ -z "$HAS_TESTS" ]; then
  SOURCE_LIST=$(echo "$HAS_SOURCE" | sed 's/^/    • /' | head -10)
  jq -n \
    --arg files "$SOURCE_LIST" \
    '{
      permissionDecision: "deny",
      permissionDecisionReason: ("❌ Source changes require accompanying tests.\n\n  Source files changed:\n" + $files + "\n\n  No test files found. Add or update tests in tests/ or as *.test.* / *.spec.* files.")
    }'
fi
