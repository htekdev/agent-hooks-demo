#!/bin/bash
# session-log.sh — Log session start/end events for audit trail
#
# Hook types: sessionStart, sessionEnd
# Input: JSON with timestamp, cwd, source (start) or reason (end)
# Output: None (logging only)

INPUT=$(cat)
TIMESTAMP=$(echo "$INPUT" | jq -r '.timestamp')
CWD=$(echo "$INPUT" | jq -r '.cwd')
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')
REASON=$(echo "$INPUT" | jq -r '.reason // empty')

LOG_DIR="$CWD/logs"
mkdir -p "$LOG_DIR"

if [ -n "$SOURCE" ]; then
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] SESSION START | source=$SOURCE | cwd=$CWD" >> "$LOG_DIR/agent-sessions.log"
elif [ -n "$REASON" ]; then
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] SESSION END   | reason=$REASON | cwd=$CWD" >> "$LOG_DIR/agent-sessions.log"
fi
