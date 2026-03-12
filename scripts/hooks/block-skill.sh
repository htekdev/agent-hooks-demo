#!/bin/bash
# block-skill.sh — Block agents from using restricted skills
#
# Hook type: preToolUse
# Denies invocation of specific skills that require human oversight.
# Input: JSON with toolName, toolArgs (where toolArgs contains skill name)
# Output: JSON with permissionDecision if blocked

# ── Configurable blocked skills list ──────────────────────────────────────────
# Add skill names to this array to block them. Case-sensitive.
BLOCKED_SKILLS=(
  "cloud-deploy"
)
# ──────────────────────────────────────────────────────────────────────────────

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')

# Only check the "skill" tool
if [ "$TOOL_NAME" != "skill" ]; then
  exit 0
fi

# Extract the skill name from toolArgs (double JSON parse: toolArgs is a string)
SKILL_NAME=$(echo "$INPUT" | jq -r '.toolArgs' | jq -r '.skill // empty')

if [ -z "$SKILL_NAME" ]; then
  exit 0
fi

# Check if the skill is in the blocked list
for BLOCKED in "${BLOCKED_SKILLS[@]}"; do
  if [ "$SKILL_NAME" = "$BLOCKED" ]; then
    jq -n \
      --arg skill "$SKILL_NAME" \
      '{
        permissionDecision: "deny",
        permissionDecisionReason: ("🚫 Skill blocked: \"" + $skill + "\" is not permitted in this repository.\n\n  Reason: Cloud deployments must go through the CI/CD pipeline and require human approval via the release management process.\n\n  To deploy, open a pull request and use the standard deployment workflow.")
      }'
    exit 0
  fi
done
