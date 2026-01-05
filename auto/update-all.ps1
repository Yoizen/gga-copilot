# Update All Repositories
# Updates GGA, SpecKit, and Copilot API installations

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Success { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Warning { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Update All GGA Tools" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Warning "DRY RUN MODE - No changes will be made"
    Write-Host ""
}

$repos = @(
    @{Name = "Copilot API"; Path = Join-Path $env:USERPROFILE ".copilot-api"; HasNpm = $true},
    @{Name = "SpecKit"; Path = Join-Path $env:USERPROFILE ".speckit"; HasNpm = $true},
    @{Name = "GGA"; Path = Join-Path $env:USERPROFILE ".gga"; HasNpm = $false}
)

$updated = 0
$failed = 0
$skipped = 0

foreach ($repo in $repos) {
    Write-Info "Checking $($repo.Name)..."
    
    if (-not (Test-Path $repo.Path)) {
        Write-Warning "$($repo.Name) not installed at $($repo.Path)"
        $skipped++
        continue
    }
    
    if ($DryRun) {
        Write-Info "Would update: $($repo.Path)"
        continue
    }
    
    try {
        Push-Location $repo.Path
        
        # Check for uncommitted changes
        $status = git status --porcelain 2>&1
        if ($status -and -not $Force) {
            Write-Warning "$($repo.Name) has uncommitted changes (use -Force to update anyway)"
            $skipped++
            Pop-Location
            continue
        }
        
        # Pull latest changes
        Write-Info "Updating $($repo.Name)..."
        git pull --quiet 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to update $($repo.Name)"
            $failed++
        } else {
            # Run npm install if needed
            if ($repo.HasNpm) {
                npm install --silent 2>&1 | Out-Null
            }
            Write-Success "$($repo.Name) updated successfully"
            $updated++
        }
        
        Pop-Location
    }
    catch {
        Write-Error "Error updating $($repo.Name): $_"
        $failed++
        Pop-Location
    }
    
    Write-Host ""
}

# Summary
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Update Summary" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Updated: $updated" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Info "This was a dry run. Use without -DryRun to apply changes."
}
