#!/bin/bash
# log-prompt.sh — Log submitted user prompts for audit and usage tracking
#
# Hook type: userPromptSubmitted
# Input: JSON with timestamp, cwd, prompt
# Output: None (logging only)

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt')
CWD=$(echo "$INPUT" | jq -r '.cwd')
TIMESTAMP=$(echo "$INPUT" | jq -r '.timestamp')

LOG_DIR="$CWD/logs"
mkdir -p "$LOG_DIR"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] PROMPT | $PROMPT" >> "$LOG_DIR/agent-prompts.log"
