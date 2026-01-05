#!/usr/bin/env powershell

# ============================================================================
# Guardian Agent - Windows Installation Script
# ============================================================================

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$BIN_DIR = "$SCRIPT_DIR\bin"
$LIB_DIR = "$SCRIPT_DIR\lib"

function Print-Banner {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Guardian Agent - Windows Installation" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

function Install-Windows {
    Print-Banner
    
    # Check if PowerShell execution policy allows script execution
    $policy = Get-ExecutionPolicy
    if ($policy -eq "Restricted") {
        Write-Host "⚠️  PowerShell execution policy is Restricted" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To run GGA, you need to allow PowerShell scripts."
        Write-Host "Run this command as Administrator:"
        Write-Host ""
        Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    
    # Create installation directory
    $INSTALL_DIR = "$env:USERPROFILE\AppData\Local\gga"
    
    Write-Host "Installing to: $INSTALL_DIR" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $INSTALL_DIR)) {
        New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    }
    
    # Copy files
    Copy-Item -Path "$BIN_DIR\gga.ps1" -Destination $INSTALL_DIR -Force
    
    if (-not (Test-Path "$INSTALL_DIR\lib")) {
        New-Item -ItemType Directory -Path "$INSTALL_DIR\lib" -Force | Out-Null
    }
    
    Copy-Item -Path "$LIB_DIR\*.ps1" -Destination "$INSTALL_DIR\lib" -Force
    
    Write-Host "✅ Files copied to: $INSTALL_DIR" -ForegroundColor Green
    Write-Host ""
    
    # Create wrapper script for PATH
    $wrapper_dir = "$env:USERPROFILE\AppData\Local\Programs\gga"
    
    if (-not (Test-Path $wrapper_dir)) {
        New-Item -ItemType Directory -Path $wrapper_dir -Force | Out-Null
    }
    
    $wrapper_content = @"
@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '$INSTALL_DIR\gga.ps1' %*"
"@
    
    Set-Content -Path "$wrapper_dir\gga.cmd" -Value $wrapper_content -Encoding ASCII
    
    Write-Host "✅ Created wrapper script: $wrapper_dir\gga.cmd" -ForegroundColor Green
    Write-Host ""
    
    # Add to PATH if not already there
    $user_path = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($user_path -notlike "*$wrapper_dir*") {
        $new_path = "$wrapper_dir;$user_path"
        [Environment]::SetEnvironmentVariable("PATH", $new_path, "User")
        
        Write-Host "✅ Added to PATH" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  Restart your terminal to use the 'gga' command" -ForegroundColor Yellow
    } else {
        Write-Host "ℹ️  Already in PATH" -ForegroundColor Blue
    }
    
    Write-Host ""
    Write-Host "Installation complete! 🎉" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Close and reopen your terminal (or restart PowerShell)"
    Write-Host "  2. Run: gga init"
    Write-Host "  3. Edit .gga with your preferred provider"
    Write-Host "  4. Create REVIEW.md with your coding standards"
    Write-Host "  5. Run: gga install"
    Write-Host ""
}

function Uninstall-Windows {
    Print-Banner
    
    $INSTALL_DIR = "$env:USERPROFILE\AppData\Local\gga"
    $wrapper_dir = "$env:USERPROFILE\AppData\Local\Programs\gga"
    
    if (Test-Path $INSTALL_DIR) {
        Remove-Item -Path $INSTALL_DIR -Recurse -Force
        Write-Host "✅ Removed: $INSTALL_DIR" -ForegroundColor Green
    }
    
    if (Test-Path "$wrapper_dir\gga.cmd") {
        Remove-Item -Path "$wrapper_dir\gga.cmd" -Force
        Write-Host "✅ Removed wrapper script" -ForegroundColor Green
    }
    
    # Remove from PATH
    $user_path = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($user_path -like "*$wrapper_dir*") {
        $new_path = $user_path -replace [regex]::Escape("$wrapper_dir;"), ""
        [Environment]::SetEnvironmentVariable("PATH", $new_path, "User")
        Write-Host "✅ Removed from PATH" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Uninstallation complete!" -ForegroundColor Green
    Write-Host ""
}

# Main
if ($Args -contains "uninstall") {
    Uninstall-Windows
} else {
    Install-Windows
}
