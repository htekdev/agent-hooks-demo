# log-prompt.ps1 — Log submitted user prompts for audit and usage tracking
#
# Hook type: userPromptSubmitted
# Input: JSON with timestamp, cwd, prompt
# Output: None (logging only)

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$prompt = $jsonInput.prompt
$cwd = $jsonInput.cwd
$timestamp = $jsonInput.timestamp
$logDir = Join-Path $cwd "logs"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = Join-Path $logDir "agent-prompts.log"
$entryTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

Add-Content -Path $logFile -Value "[$entryTimestamp] PROMPT | $prompt"
