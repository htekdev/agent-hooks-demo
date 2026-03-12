# validate-json.ps1 — Validate JSON syntax after any .json file is edited
#
# Hook type: postToolUse
# Runs after edit/create completes. If the file is a .json file, reads it
# from disk and validates the syntax. Logs a warning if invalid.
# Input: JSON with toolName, toolArgs, toolResult
# Output: None (advisory logging)

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $jsonInput.toolName
$resultType = $jsonInput.toolResult.resultType

# Only check after successful edit/create operations
if ($toolName -ne "edit" -and $toolName -ne "create") {
    exit 0
}

if ($resultType -ne "success") {
    exit 0
}

# Extract the file path
$toolArgs = $jsonInput.toolArgs | ConvertFrom-Json
$filePath = if ($toolArgs.path) { $toolArgs.path } elseif ($toolArgs.file) { $toolArgs.file } else { $null }

if (-not $filePath) {
    exit 0
}

# Only validate .json files (skip package-lock.json and node_modules)
if ($filePath -notmatch '\.json$') {
    exit 0
}

if ($filePath -match 'node_modules' -or $filePath -match 'package-lock\.json$') {
    exit 0
}

if (Test-Path $filePath) {
    $content = Get-Content $filePath -Raw
    try {
        $content | ConvertFrom-Json | Out-Null
        Write-Host "✅ Valid JSON: $filePath"
    } catch {
        Write-Host "❌ Invalid JSON detected in: $filePath" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
