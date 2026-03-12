# Tests for block-skill.ps1 hook
# Usage: pwsh tests/hooks/block-skill.test.ps1

$ErrorActionPreference = "Stop"
$hook = Join-Path $PSScriptRoot "..\..\scripts\hooks\block-skill.ps1"
$pass = 0
$fail = 0

function Run-Test {
    param(
        [string]$Description,
        [string]$TestInput,
        [bool]$ExpectDeny
    )

    $output = $TestInput | pwsh -File $hook 2>$null

    if ($ExpectDeny) {
        if ($output) {
            try {
                $json = $output | ConvertFrom-Json
                if ($json.permissionDecision -eq "deny") {
                    Write-Host "  ✅ PASS: $Description"
                    $script:pass++
                } else {
                    Write-Host "  ❌ FAIL: $Description — expected deny, got: $($json.permissionDecision)"
                    $script:fail++
                }
            } catch {
                Write-Host "  ❌ FAIL: $Description — output not valid JSON: $output"
                $script:fail++
            }
        } else {
            Write-Host "  ❌ FAIL: $Description — expected deny output, got nothing"
            $script:fail++
        }
    } else {
        if (-not $output -or $output.Trim() -eq "") {
            Write-Host "  ✅ PASS: $Description"
            $script:pass++
        } else {
            Write-Host "  ❌ FAIL: $Description — expected no output, got: $output"
            $script:fail++
        }
    }
}

Write-Host ""
Write-Host "🧪 Block Skill Hook Tests (PowerShell)"
Write-Host "======================================="
Write-Host ""

# Test 1: Blocked skill should be denied
Run-Test -Description "Blocked skill (cloud-deploy) is denied" `
    -TestInput '{"toolName":"skill","toolArgs":"{\"skill\":\"cloud-deploy\"}"}' `
    -ExpectDeny $true

# Test 2: Allowed skill should pass through
Run-Test -Description "Allowed skill (pdf) passes through" `
    -TestInput '{"toolName":"skill","toolArgs":"{\"skill\":\"pdf\"}"}' `
    -ExpectDeny $false

# Test 3: Non-skill tool should pass through
Run-Test -Description "Non-skill tool (grep) passes through" `
    -TestInput '{"toolName":"skill","toolArgs":"{\"pattern\":\"TODO\"}"}' `
    -ExpectDeny $false

# Test 4: Another allowed skill passes through
Run-Test -Description "Allowed skill (hookflow) passes through" `
    -TestInput '{"toolName":"skill","toolArgs":"{\"skill\":\"hookflow\"}"}' `
    -ExpectDeny $false

# Test 5: Verify deny message mentions CI/CD
Write-Host ""
Write-Host "  Checking deny message content..."
$denyOutput = '{"toolName":"skill","toolArgs":"{\"skill\":\"cloud-deploy\"}"}' | pwsh -File $hook 2>$null
try {
    $denyJson = $denyOutput | ConvertFrom-Json
    $reason = $denyJson.permissionDecisionReason
    if ($reason -match "CI/CD|pipeline|deploy") {
        Write-Host "  ✅ PASS: Deny message mentions CI/CD or pipeline"
        $pass++
    } else {
        Write-Host "  ❌ FAIL: Deny message should mention CI/CD — got: $reason"
        $fail++
    }
} catch {
    Write-Host "  ❌ FAIL: Could not parse deny output for message check"
    $fail++
}

Write-Host ""
Write-Host "======================================="
Write-Host "Results: $pass passed, $fail failed"
Write-Host ""

if ($fail -gt 0) {
    exit 1
}
