#!/bin/bash
# log-error.sh — Log hook and tool errors for troubleshooting and audit trail
#
# Hook type: errorOccurred
# Input: JSON with timestamp, cwd, error.message, error.name, error.stack
# Output: None (logging only)

INPUT=$(cat)
ERROR_MSG=$(echo "$INPUT" | jq -r '.error.message')
ERROR_NAME=$(echo "$INPUT" | jq -r '.error.name')
CWD=$(echo "$INPUT" | jq -r '.cwd')
LOG_DIR="$CWD/logs"
mkdir -p "$LOG_DIR"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ERROR | [$ERROR_NAME] $ERROR_MSG" >> "$LOG_DIR/agent-errors.log"
