#!/usr/bin/env pwsh
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path $ScriptDir -Parent
$SpecifyExe = Join-Path $ProjectRoot ".spec-kit-env\Scripts\specify.exe"

if (Test-Path $SpecifyExe) {
    & $SpecifyExe $args
} else {
    Write-Error "SpecKit not found at $SpecifyExe. Run auto/bootstrap.ps1 to install."
    exit 1
}
