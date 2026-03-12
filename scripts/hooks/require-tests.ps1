# require-tests.ps1 — Require test files when committing source changes
#
# Hook type: preToolUse
# Intercepts git commit commands and checks whether the staged files include
# tests alongside source changes in src/. If source files are staged without
# any corresponding test files, the commit is blocked.
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $jsonInput.toolName

# Only check bash and powershell tool calls
if ($toolName -ne "bash" -and $toolName -ne "powershell") {
    exit 0
}

$toolArgs = $jsonInput.toolArgs | ConvertFrom-Json
$command = $toolArgs.command

if (-not $command) {
    exit 0
}

# Only check git commit commands
if ($command -notmatch 'git\s+commit') {
    exit 0
}

# Get the list of staged files
$stagedFiles = git diff --cached --name-only 2>$null

if (-not $stagedFiles) {
    exit 0
}

# Check if any source files in src/ are staged (excluding test files)
$sourceFiles = $stagedFiles | Where-Object { $_ -match '^src/' -and $_ -notmatch '\.(test|spec)\.' }

# Check if any test files are staged
$testFiles = $stagedFiles | Where-Object { $_ -match '\.(test|spec)\.' -or $_ -match '^tests/' }

if ($sourceFiles -and -not $testFiles) {
    $fileList = ($sourceFiles | ForEach-Object { "    - $_" }) -join "`n"
    @{
        permissionDecision = "deny"
        permissionDecisionReason = "❌ Source changes require accompanying tests.`n`n  Source files changed:`n$fileList`n`n  No test files found. Add or update tests in tests/ or as *.test.* / *.spec.* files."
    } | ConvertTo-Json -Compress
}
