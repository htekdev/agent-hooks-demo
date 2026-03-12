#!/usr/bin/env bash
# Tests for block-skill.sh hook
# Usage: bash tests/hooks/block-skill.test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../scripts/hooks/block-skill.sh"
PASS=0
FAIL=0

run_test() {
  local description="$1"
  local input="$2"
  local expect_deny="$3"

  local output
  output=$(echo "$input" | bash "$HOOK" 2>/dev/null) || true

  if [ "$expect_deny" = "true" ]; then
    if echo "$output" | grep -q '"permissionDecision"'; then
      local decision
      decision=$(echo "$output" | jq -r '.permissionDecision' 2>/dev/null)
      if [ "$decision" = "deny" ]; then
        echo "  ✅ PASS: $description"
        PASS=$((PASS + 1))
      else
        echo "  ❌ FAIL: $description — expected deny, got: $decision"
        FAIL=$((FAIL + 1))
      fi
    else
      echo "  ❌ FAIL: $description — expected deny output, got: $output"
      FAIL=$((FAIL + 1))
    fi
  else
    if [ -z "$output" ]; then
      echo "  ✅ PASS: $description"
      PASS=$((PASS + 1))
    else
      echo "  ❌ FAIL: $description — expected no output, got: $output"
      FAIL=$((FAIL + 1))
    fi
  fi
}

echo ""
echo "🧪 Block Skill Hook Tests"
echo "========================="
echo ""

# Test 1: Blocked skill should be denied
run_test "Blocked skill (cloud-deploy) is denied" \
  '{"toolName":"skill","toolArgs":"{\"skill\":\"cloud-deploy\"}"}' \
  "true"

# Test 2: Allowed skill should pass through
run_test "Allowed skill (pdf) passes through" \
  '{"toolName":"skill","toolArgs":"{\"skill\":\"pdf\"}"}' \
  "false"

# Test 3: Non-skill tool should pass through
run_test "Non-skill tool (grep) passes through" \
  '{"toolName":"grep","toolArgs":"{\"pattern\":\"TODO\"}"}' \
  "false"

# Test 4: Another allowed skill passes through
run_test "Allowed skill (hookflow) passes through" \
  '{"toolName":"skill","toolArgs":"{\"skill\":\"hookflow\"}"}' \
  "false"

# Test 5: Verify deny message mentions CI/CD
echo ""
echo "  Checking deny message content..."
DENY_OUTPUT=$(echo '{"toolName":"skill","toolArgs":"{\"skill\":\"cloud-deploy\"}"}' | bash "$HOOK" 2>/dev/null) || true
DENY_REASON=$(echo "$DENY_OUTPUT" | jq -r '.permissionDecisionReason' 2>/dev/null)

if echo "$DENY_REASON" | grep -qi "ci/cd\|pipeline\|deploy"; then
  echo "  ✅ PASS: Deny message mentions CI/CD or pipeline"
  PASS=$((PASS + 1))
else
  echo "  ❌ FAIL: Deny message should mention CI/CD — got: $DENY_REASON"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "========================="
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
