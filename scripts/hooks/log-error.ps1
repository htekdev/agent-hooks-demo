# log-error.ps1 — Log hook and tool errors for troubleshooting and audit trail
#
# Hook type: errorOccurred
# Input: JSON with timestamp, cwd, error.message, error.name, error.stack
# Output: None (logging only)

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$errorMessage = $jsonInput.error.message
$errorName = $jsonInput.error.name
$cwd = $jsonInput.cwd
$logDir = Join-Path $cwd "logs"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = Join-Path $logDir "agent-errors.log"
$entryTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

Add-Content -Path $logFile -Value "[$entryTimestamp] ERROR | [$errorName] $errorMessage"
