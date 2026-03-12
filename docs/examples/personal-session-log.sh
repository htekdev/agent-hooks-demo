#!/bin/bash
set -euo pipefail

INPUT=$(cat)
TIMESTAMP=$(echo "$INPUT" | jq -r '.timestamp // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')
REASON=$(echo "$INPUT" | jq -r '.reason // empty')

LOG_DIR="$HOME/.copilot/logs"
LOG_FILE="$LOG_DIR/sessions.log"
mkdir -p "$LOG_DIR"

touch "$LOG_FILE"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -n "$SOURCE" ]; then
  echo "[$NOW] SESSION START | source=$SOURCE | timestamp=$TIMESTAMP | cwd=$CWD" >> "$LOG_FILE"
elif [ -n "$REASON" ]; then
  echo "[$NOW] SESSION END   | reason=$REASON | timestamp=$TIMESTAMP | cwd=$CWD" >> "$LOG_FILE"
else
  echo "[$NOW] SESSION EVENT | timestamp=$TIMESTAMP | cwd=$CWD" >> "$LOG_FILE"
fi
