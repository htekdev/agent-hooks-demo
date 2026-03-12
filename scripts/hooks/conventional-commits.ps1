# conventional-commits.ps1 — Enforce conventional commit message format
#
# Hook type: preToolUse
# Intercepts bash/powershell tool calls that run git commit and validates
# the commit message follows Conventional Commits format:
#   type(scope): description
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $jsonInput.toolName

# Only check bash and powershell tool calls
if ($toolName -ne "bash" -and $toolName -ne "powershell") {
    exit 0
}

# Extract the command being run
$toolArgs = $jsonInput.toolArgs | ConvertFrom-Json
$command = $toolArgs.command

if (-not $command) {
    exit 0
}

# Only check commands that include git commit
if ($command -notmatch 'git\s+commit') {
    exit 0
}

# Extract the commit message from -m flag
if ($command -match '-m\s+[''"]([^''"]+)[''"]') {
    $commitMsg = $Matches[1]
} else {
    # No -m flag found — might be using an editor, allow it
    exit 0
}

# Get the first line
$firstLine = ($commitMsg -split "`n")[0]

# Validate against Conventional Commits pattern
$pattern = '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+'

if ($firstLine -notmatch $pattern) {
    @{
        permissionDecision = "deny"
        permissionDecisionReason = "❌ Commit message does not follow Conventional Commits format.`n`n  Your message: $firstLine`n`n  Expected: type(scope): description`n  Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`n  Examples: feat(auth): add login endpoint | fix: resolve null pointer"
    } | ConvertTo-Json -Compress
}
