# Quick Setup - One command installation
# Usage: irm https://tu-url/quick-setup.ps1 | iex
#    or: powershell -ExecutionPolicy Bypass -File quick-setup.ps1

$ErrorActionPreference = "Stop"

$REPO_URL = "https://github.com/github/gga-copilot.git"
$INSTALL_DIR = Join-Path $env:TEMP "gga-bootstrap-$(Get-Random)"

Write-Host "[INFO] GGA Quick Setup" -ForegroundColor Cyan
Write-Host ""

function Cleanup {
    if (Test-Path $INSTALL_DIR) {
        Start-Sleep -Milliseconds 500
        Get-ChildItem $INSTALL_DIR -Recurse | ForEach-Object { $_.IsReadOnly = $false }
        Remove-Item $INSTALL_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
    # Clone repo to temp
    Write-Host "Downloading bootstrap scripts..." -ForegroundColor Gray
    git clone --quiet $REPO_URL $INSTALL_DIR 2>&1 | Out-Null

    if (-not (Test-Path "$INSTALL_DIR\auto\bootstrap.ps1")) {
        Write-Host "[ERROR] Failed to download bootstrap script" -ForegroundColor Red
        exit 1
    }

    # Run bootstrap
    Write-Host "Running setup..." -ForegroundColor Gray
    & "$INSTALL_DIR\auto\bootstrap.ps1" $args

    Write-Host ""
    Write-Host "[OK] Setup complete!" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Setup failed: $_" -ForegroundColor Red
    exit 1
}
finally {
    Cleanup
}
