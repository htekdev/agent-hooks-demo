# block-skill.ps1 — Block agents from using restricted skills
#
# Hook type: preToolUse
# Denies invocation of specific skills that require human oversight.
# Input: JSON with toolName, toolArgs (where toolArgs contains skill name)
# Output: JSON with permissionDecision if blocked

$ErrorActionPreference = "Stop"

# ── Configurable blocked skills list ──────────────────────────────────────────
# Add skill names to this array to block them. Case-sensitive.
$blockedSkills = @(
    "cloud-deploy"
)
# ──────────────────────────────────────────────────────────────────────────────

$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $jsonInput.toolName

# Only check the "skill" tool
if ($toolName -ne "skill") {
    exit 0
}

# Extract the skill name from toolArgs (double JSON parse: toolArgs is a string)
$toolArgs = $jsonInput.toolArgs | ConvertFrom-Json
$skillName = $toolArgs.skill

if (-not $skillName) {
    exit 0
}

# Check if the skill is in the blocked list
if ($blockedSkills -contains $skillName) {
    @{
        permissionDecision       = "deny"
        permissionDecisionReason = "🚫 Skill blocked: `"$skillName`" is not permitted in this repository.`n`n  Reason: Cloud deployments must go through the CI/CD pipeline and require human approval via the release management process.`n`n  To deploy, open a pull request and use the standard deployment workflow."
    } | ConvertTo-Json -Compress
}
