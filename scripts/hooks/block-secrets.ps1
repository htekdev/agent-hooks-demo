# block-secrets.ps1 — Block agents from creating or editing sensitive files
#
# Hook type: preToolUse
# Denies edit/create operations on .env, .pem, .key files and secrets/ directory.
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $jsonInput.toolName

# Only check edit and create tools
if ($toolName -ne "edit" -and $toolName -ne "create") {
    exit 0
}

# Extract the file path from tool arguments
$toolArgs = $jsonInput.toolArgs | ConvertFrom-Json
$filePath = if ($toolArgs.path) { $toolArgs.path } elseif ($toolArgs.file) { $toolArgs.file } else { $null }

if (-not $filePath) {
    exit 0
}

# Check against sensitive file patterns
$blocked = $false
$reason = ""

if ($filePath -match '\.env($|\.)' -or $filePath -match '[/\\]\.env') {
    $blocked = $true
    $reason = "Environment variable files (.env) may contain secrets"
}
elseif ($filePath -match '\.pem$') {
    $blocked = $true
    $reason = "PEM certificate/key files may contain private keys"
}
elseif ($filePath -match '\.key$') {
    $blocked = $true
    $reason = "Key files may contain private keys or secrets"
}
elseif ($filePath -match '(^|[/\\])secrets[/\\]') {
    $blocked = $true
    $reason = "Files in secrets/ directory are protected"
}

if ($blocked) {
    @{
        permissionDecision = "deny"
        permissionDecisionReason = "🚫 Blocked: $reason. File: $filePath. Manage secrets through CI/CD variables or a vault."
    } | ConvertTo-Json -Compress
}
