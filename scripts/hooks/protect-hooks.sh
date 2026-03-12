#!/bin/bash
# protect-hooks.sh — Prevent agents from modifying hook governance files
#
# Hook type: preToolUse
# The "who watches the watchmen" hook — blocks edit/create/delete of files
# inside .github/hooks/, .copilot/hooks/, .github/agents/*.agent.md,
# and scripts/hooks/ so agents can't weaken their own governance.
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

# Block changes to protected hook configuration and script files
if echo "$FILE_PATH" | grep -qE '(^|[\\/])\.github[\\/]hooks[\\/]|(^|[\\/])\.copilot[\\/]hooks[\\/]|(^|[\\/])\.github[\\/]agents[\\/][^\\/]+\.agent\.md$|(^|[\\/])scripts[\\/]hooks[\\/]'; then
  if echo "$FILE_PATH" | grep -qE '(^|[\\/])\.github[\\/]hooks[\\/]'; then
    PROTECTED_AREA="Hook configuration files"
    PROTECTED_PATH=".github/hooks/"
  elif echo "$FILE_PATH" | grep -qE '(^|[\\/])\.copilot[\\/]hooks[\\/]'; then
    PROTECTED_AREA="Hook configuration files"
    PROTECTED_PATH=".copilot/hooks/"
  elif echo "$FILE_PATH" | grep -qE '(^|[\\/])\.github[\\/]agents[\\/][^\\/]+\.agent\.md$'; then
    PROTECTED_AREA="Agent definition files"
    PROTECTED_PATH=".github/agents/*.agent.md"
  else
    PROTECTED_AREA="Hook scripts"
    PROTECTED_PATH="scripts/hooks/"
  fi

  jq -n --arg protectedArea "$PROTECTED_AREA" --arg protectedPath "$PROTECTED_PATH" '{
    permissionDecision: "deny",
    permissionDecisionReason: ("🛡️ Blocked: " + $protectedArea + " (" + $protectedPath + ") can only be modified by humans, not by the agents they govern.")
  }'
fi
