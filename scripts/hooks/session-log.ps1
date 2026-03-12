# session-log.ps1 — Log session start/end events for audit trail
#
# Hook types: sessionStart, sessionEnd
# Input: JSON with timestamp, cwd, source (start) or reason (end)
# Output: None (logging only)

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$cwd = $jsonInput.cwd
$logDir = Join-Path $cwd "logs"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = Join-Path $logDir "agent-sessions.log"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

if ($jsonInput.PSObject.Properties.Name -contains "source") {
    $entry = "[$timestamp] SESSION START | source=$($jsonInput.source) | cwd=$cwd"
} elseif ($jsonInput.PSObject.Properties.Name -contains "reason") {
    $entry = "[$timestamp] SESSION END   | reason=$($jsonInput.reason) | cwd=$cwd"
}

Add-Content -Path $logFile -Value $entry
