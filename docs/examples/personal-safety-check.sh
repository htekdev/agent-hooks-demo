#!/bin/bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs // "{}"')
MODE="${SAFETY_MODE:-all}"

if [ "$TOOL_NAME" != "bash" ] && [ "$TOOL_NAME" != "powershell" ]; then
  exit 0
fi

COMMAND=$(echo "$TOOL_ARGS" | jq -r '.command // empty')
if [ -z "$COMMAND" ]; then
  exit 0
fi

COMMAND_LC=$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]')

is_dangerous_command() {
  printf '%s' "$COMMAND_LC" | grep -Eq 'rm[[:space:]]+-[[:alnum:]-]*r[[:alnum:]-]*f[[:alnum:]-]*[[:space:]]+/|format[[:space:]]+[a-z]:|(^|[;&|[:space:]])del([[:space:]]+/[a-z]+)*[[:space:]]+/f|(^|[;&|[:space:]])rd[[:space:]]+/s[[:space:]]+/q|(^|[;&|[:space:]])mkfs(\.|[[:space:]])|(^|[;&|[:space:]])dd[[:space:]].*of=/dev/|(^|[;&|[:space:]])diskpart([[:space:]]|$)'
}

is_force_push() {
  printf '%s' "$COMMAND_LC" | grep -Eq 'git[[:space:]]+push([^\n]|$)*([[:space:]]--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$))'
}

if [ "$MODE" = "block-dangerous" ] || [ "$MODE" = "all" ]; then
  if is_dangerous_command; then
    jq -n --arg reason "Blocked dangerous system-level command. Personal safety policy denies wipe, reformat, and destructive device commands such as rm -rf /, format C:, del /f, rd /s /q, mkfs, dd to /dev, or diskpart." '{permissionDecision: "deny", permissionDecisionReason: $reason}'
    exit 0
  fi
fi

if [ "$MODE" = "confirm-force-push" ] || [ "$MODE" = "all" ]; then
  if is_force_push; then
    jq -n --arg reason "This git push uses --force or -f and can rewrite shared history. Please confirm before proceeding." '{permissionDecision: "ask", permissionDecisionReason: $reason}'
    exit 0
  fi
fi

exit 0
