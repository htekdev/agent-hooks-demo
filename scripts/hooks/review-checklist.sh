#!/bin/bash
# review-checklist.sh — VS Code Stop hook for agent-scoped hooks
# Fires when the strict-reviewer agent is about to stop.
# Uses VS Code's hookSpecificOutput format to potentially block stopping.
#
# NOTE: This uses VS Code's output format, NOT CLI format.
# VS Code wraps decisions in hookSpecificOutput with hookEventName.

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent infinite loops — if we already continued once, let it stop
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Check if the agent mentioned running tests in its output
# This is a simplified example — real implementations might check
# for specific markers in the conversation or file system
echo '{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Please verify that all changes have test coverage before completing the review."
  }
}'
