# protect-hooks.ps1 — Prevent agents from modifying hook governance files
#
# Hook type: preToolUse
# The "who watches the watchmen" hook — blocks edit/create/delete of files
# inside .github/hooks/, .copilot/hooks/, .github/agents/*.agent.md,
# and scripts/hooks/ so agents can't weaken their own governance.
# Input: JSON with toolName, toolArgs
# Output: JSON with permissionDecision if blocked

$ErrorActionPreference = "Stop"

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $jsonInput.toolName

# Only check file modification tools
if ($toolName -ne "edit" -and $toolName -ne "create") {
    exit 0
}

# Extract the file path from tool arguments
$toolArgs = $jsonInput.toolArgs | ConvertFrom-Json
$filePath = if ($toolArgs.path) { $toolArgs.path } elseif ($toolArgs.file) { $toolArgs.file } else { $null }

if (-not $filePath) {
    exit 0
}

# Block changes to protected hook configuration and script files
if ($filePath -match '(^|[/\\])\.github[/\\]hooks[/\\]|(^|[/\\])\.copilot[/\\]hooks[/\\]|(^|[/\\])\.github[/\\]agents[/\\][^/\\]+\.agent\.md$|(^|[/\\])scripts[/\\]hooks[/\\]') {
    if ($filePath -match '(^|[/\\])\.github[/\\]hooks[/\\]') {
        $protectedArea = "Hook configuration files"
        $protectedPath = ".github/hooks/"
    } elseif ($filePath -match '(^|[/\\])\.copilot[/\\]hooks[/\\]') {
        $protectedArea = "Hook configuration files"
        $protectedPath = ".copilot/hooks/"
    } elseif ($filePath -match '(^|[/\\])\.github[/\\]agents[/\\][^/\\]+\.agent\.md$') {
        $protectedArea = "Agent definition files"
        $protectedPath = ".github/agents/*.agent.md"
    } else {
        $protectedArea = "Hook scripts"
        $protectedPath = "scripts/hooks/"
    }

    @{
        permissionDecision = "deny"
        permissionDecisionReason = "🛡️ Blocked: $protectedArea ($protectedPath) can only be modified by humans, not by the agents they govern."
    } | ConvertTo-Json -Compress
}
