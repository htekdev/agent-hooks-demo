#!/bin/bash
# block-secrets.sh — Block agents from creating or editing sensitive files
#
# Hook type: preToolUse
# Denies edit/create operations on .env, .pem, .key files and secrets/ directory.
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')

# Only check edit and create tools
if [ "$TOOL_NAME" != "edit" ] && [ "$TOOL_NAME" != "create" ]; then
  exit 0
fi

# Extract the file path from tool arguments
FILE_PATH=$(echo "$INPUT" | jq -r '.toolArgs' | jq -r '.path // .file // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Check against sensitive file patterns
BLOCKED=false
REASON=""

case "$FILE_PATH" in
  *.env|*/.env|*/.env.*)
    BLOCKED=true
    REASON="Environment variable files (.env) may contain secrets"
    ;;
  *.pem)
    BLOCKED=true
    REASON="PEM certificate/key files may contain private keys"
    ;;
  *.key)
    BLOCKED=true
    REASON="Key files may contain private keys or secrets"
    ;;
  */secrets/*|secrets/*)
    BLOCKED=true
    REASON="Files in secrets/ directory are protected"
    ;;
esac

if [ "$BLOCKED" = true ]; then
  jq -n \
    --arg reason "🚫 Blocked: $REASON. File: $FILE_PATH. Manage secrets through CI/CD variables or a vault." \
    '{permissionDecision: "deny", permissionDecisionReason: $reason}'
fi
