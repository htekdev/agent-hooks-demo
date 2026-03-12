#!/bin/bash
# protect-hooks.sh — Prevent agents from modifying hook governance files
#
# Hook type: preToolUse
# The "who watches the watchmen" hook — blocks edit/create/delete of files
# inside .github/hooks/ so agents can't weaken their own governance.
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')

# Only check file modification tools
if [ "$TOOL_NAME" != "edit" ] && [ "$TOOL_NAME" != "create" ]; then
  exit 0
fi

# Extract the file path from tool arguments
FILE_PATH=$(echo "$INPUT" | jq -r '.toolArgs' | jq -r '.path // .file // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Block changes to hook configuration files
if echo "$FILE_PATH" | grep -qE '(^|/)\.github/hooks/'; then
  jq -n '{
    permissionDecision: "deny",
    permissionDecisionReason: "🛡️ Blocked: Hook governance files (.github/hooks/) can only be modified by humans, not by the agents they govern."
  }'
fi
