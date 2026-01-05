# Guardian Agent - Windows PowerShell Version
# Provider-agnostic code review using AI

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$VERSION = "2.2.x-windows"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR

# Resolve LIB_DIR
if (Test-Path "$PROJECT_DIR\lib") {
    $LIB_DIR = "$PROJECT_DIR\lib"
} else {
    $LIB_DIR = "$env:USERPROFILE\.local\share\gga\lib"
}

# Source library functions
. "$LIB_DIR\providers.ps1"
. "$LIB_DIR\cache.ps1"

# Defaults
$DEFAULT_FILE_PATTERNS = "*"
$DEFAULT_PROVIDER = "copilot:claude-haiku-4.5"
$DEFAULT_RULES_FILE = "REVIEW.md"
$DEFAULT_STRICT_MODE = "true"

# Helper Functions
function Log-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Log-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Log-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Log-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

function Print-Banner {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "  Guardian Agent v$VERSION" -ForegroundColor Cyan
    Write-Host "  Provider-agnostic code review using AI" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Help {
    Print-Banner
    Write-Host "USAGE:" -ForegroundColor White
    Write-Host "  gga <command> [options]"
    Write-Host ""
    Write-Host "COMMANDS:" -ForegroundColor White
    Write-Host "  run [--no-cache]  Run code review on staged files"
    Write-Host "  install           Install git pre-commit hook in current repo"
    Write-Host "  uninstall         Remove git pre-commit hook from current repo"
    Write-Host "  config            Show current configuration"
    Write-Host "  init              Create a sample .gga config file"
    Write-Host "  cache clear       Clear cache for current project"
    Write-Host "  cache clear-all   Clear all cached data"
    Write-Host "  cache status      Show cache status"
    Write-Host "  help              Show this help message"
    Write-Host "  version           Show version"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor White
    Write-Host "  gga init          # Create sample config"
    Write-Host "  gga install       # Install git hook"
    Write-Host "  gga run           # Run review (with cache)"
    Write-Host "  gga run --no-cache # Run review (ignore cache)"
    Write-Host ""
}

function Load-Config {
    # Reset to defaults
    $script:PROVIDER = $DEFAULT_PROVIDER
    $script:FILE_PATTERNS = $DEFAULT_FILE_PATTERNS
    $script:EXCLUDE_PATTERNS = ""
    $script:RULES_FILE = $DEFAULT_RULES_FILE
    $script:STRICT_MODE = $DEFAULT_STRICT_MODE

    # Load global config
    $GLOBAL_CONFIG = "$env:USERPROFILE\.config\gga\config"
    if (Test-Path $GLOBAL_CONFIG) {
        Get-Content $GLOBAL_CONFIG | ForEach-Object {
            if ($_ -match '^([A-Z_]+)="?([^"]+)"?$') {
                $key = $Matches[1]
                $value = $Matches[2]
                Set-Variable -Name $key -Value $value -Scope Script
            }
        }
    }

    # Load project config (overrides global)
    $PROJECT_CONFIG = ".gga"
    if (Test-Path $PROJECT_CONFIG) {
        Get-Content $PROJECT_CONFIG | ForEach-Object {
            if ($_ -match '^([A-Z_]+)="?([^"]+)"?$') {
                $key = $Matches[1]
                $value = $Matches[2]
                Set-Variable -Name $key -Value $value -Scope Script
            }
        }
    }

    # Environment variable override
    if ($env:GGA_PROVIDER) {
        $script:PROVIDER = $env:GGA_PROVIDER
    }
}

function Cmd-Init {
    Print-Banner
    
    $PROJECT_CONFIG = ".gga"
    
    if ((Test-Path $PROJECT_CONFIG) -and -not $Args -contains "-f" -and -not $Args -contains "--force") {
        Log-Error "Config file already exists: $PROJECT_CONFIG"
        Write-Host "Use 'gga init --force' to overwrite"
        exit 1
    }

    $config_content = @"
# GGA Configuration File
# See 'gga help' for all options

# AI provider to use (claude, gemini, codex, ollama:<model>, copilot:<model>)
PROVIDER="copilot:claude-haiku-4.5"

# File patterns to review (comma-separated)
FILE_PATTERNS="*"

# Patterns to exclude from review
EXCLUDE_PATTERNS="*.test.ts,*.spec.ts,*.test.tsx,*.spec.tsx,*.d.ts"

# File containing code review rules
RULES_FILE="REVIEW.md"

# Strict mode: fail if AI response is ambiguous
STRICT_MODE="true"
"@

    Set-Content -Path $PROJECT_CONFIG -Value $config_content -Encoding UTF8
    
    Log-Success "Created config file: $PROJECT_CONFIG"
    Write-Host ""
    Log-Info "Next steps:"
    Write-Host "  1. Edit $PROJECT_CONFIG to set your preferred provider"
    Write-Host "  2. Create $DEFAULT_RULES_FILE with your coding standards"
    Write-Host "  3. Run: gga install"
    Write-Host ""
}

function Cmd-Config {
    Print-Banner
    Load-Config

    Write-Host "Current Configuration:" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Config Files:" -ForegroundColor White
    $GLOBAL_CONFIG = "$env:USERPROFILE\.config\gga\config"
    $PROJECT_CONFIG = ".gga"
    
    if (Test-Path $GLOBAL_CONFIG) {
        Write-Host "  Global:  $GLOBAL_CONFIG" -ForegroundColor Gray
    } else {
        Write-Host "  Global:  (not found)" -ForegroundColor Gray
    }
    
    if (Test-Path $PROJECT_CONFIG) {
        Write-Host "  Project: $PROJECT_CONFIG" -ForegroundColor Gray
    } else {
        Write-Host "  Project: (not found)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Active Settings:" -ForegroundColor White
    Write-Host "  PROVIDER:         $PROVIDER" -ForegroundColor Gray
    Write-Host "  FILE_PATTERNS:    $FILE_PATTERNS" -ForegroundColor Gray
    Write-Host "  EXCLUDE_PATTERNS: $EXCLUDE_PATTERNS" -ForegroundColor Gray
    Write-Host "  RULES_FILE:       $RULES_FILE" -ForegroundColor Gray
    Write-Host "  STRICT_MODE:      $STRICT_MODE" -ForegroundColor Gray
    Write-Host ""
}

function Cmd-Version {
    Write-Host "Guardian Agent v$VERSION"
}

# Main command dispatcher
switch ($Command.ToLower()) {
    "init" { Cmd-Init }
    "config" { Cmd-Config }
    "version" { Cmd-Version }
    "help" { Print-Help }
    default {
        Log-Error "Unknown command: $Command"
        Write-Host "Run 'gga help' for usage information"
        exit 1
    }
}
