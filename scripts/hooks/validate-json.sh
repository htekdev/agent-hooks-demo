#!/bin/bash
# validate-json.sh — Validate JSON syntax after any .json file is edited
#
# Hook type: postToolUse
# Runs after edit/create completes. If the file is a .json file, reads it
# from disk and validates the syntax. Logs a warning if invalid.
# Input: JSON with toolName, toolArgs, toolResult
# Output: None (advisory logging)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')
RESULT_TYPE=$(echo "$INPUT" | jq -r '.toolResult.resultType')

# Only check after successful edit/create operations
if [ "$TOOL_NAME" != "edit" ] && [ "$TOOL_NAME" != "create" ]; then
  exit 0
fi

if [ "$RESULT_TYPE" != "success" ]; then
  exit 0
fi

# Extract the file path
FILE_PATH=$(echo "$INPUT" | jq -r '.toolArgs' | jq -r '.path // .file // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only validate .json files (skip package-lock.json and node_modules)
case "$FILE_PATH" in
  *.json)
    case "$FILE_PATH" in
      */node_modules/*|*/package-lock.json) exit 0 ;;
    esac

    if [ -f "$FILE_PATH" ]; then
      if ! jq empty "$FILE_PATH" 2>/dev/null; then
        echo "❌ Invalid JSON detected in: $FILE_PATH" >&2
        echo "   Please fix the syntax error." >&2
      else
        echo "✅ Valid JSON: $FILE_PATH" >&2
      fi
    fi
    ;;
esac
