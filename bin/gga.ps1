# ============================================================================
# Gentleman Guardian Angel - Windows PowerShell Version
# ============================================================================
# Provider-agnostic code review using AI
# ============================================================================

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Version
$VERSION = "2.2.x-windows"

# Resolve script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR

# Resolve LIB_DIR
if (Test-Path "$PROJECT_DIR/lib") {
    $LIB_DIR = "$PROJECT_DIR/lib"
} else {
    $LIB_DIR = "$env:USERPROFILE\.local\share\gga\lib"
}

# Source library functions
. "$LIB_DIR\providers.ps1"
. "$LIB_DIR\cache.ps1"

# Colors (ANSI codes work in Windows 10+ with flag)
$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[1;33m"
$BLUE = "`e[0;34m"
$CYAN = "`e[0;36m"
$BOLD = "`e[1m"
$NC = "`e[0m"

# Defaults
$DEFAULT_FILE_PATTERNS = "*"
$DEFAULT_PROVIDER = "copilot:claude-haiku-4.5"
$DEFAULT_RULES_FILE = "REVIEW.md"
$DEFAULT_STRICT_MODE = "true"

# ============================================================================
# Helper Functions
# ============================================================================

function Print-Banner {
    Write-Host ""
    Write-Host "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    Write-Host "${CYAN}${BOLD}  Gentleman Guardian Angel v${VERSION}${NC}"
    Write-Host "${CYAN}  Provider-agnostic code review using AI${NC}"
    Write-Host "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    Write-Host ""
}

function Print-Help {
    Print-Banner
    Write-Host "${BOLD}USAGE:${NC}"
    Write-Host "  gga <command> [options]"
    Write-Host ""
    Write-Host "${BOLD}COMMANDS:${NC}"
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
    Write-Host "${BOLD}CONFIGURATION:${NC}"
    Write-Host "  Create a ${CYAN}.gga${NC} file in your project root or"
    Write-Host "  ${CYAN}$env:USERPROFILE\.config\gga\config${NC} for global settings."
    Write-Host ""
}

function Log-Success {
    param([string]$Message)
    Write-Host "${GREEN}✅ ${Message}${NC}"
}

function Log-Error {
    param([string]$Message)
    Write-Host "${RED}❌ ${Message}${NC}"
}

function Log-Warning {
    param([string]$Message)
    Write-Host "${YELLOW}⚠️  ${Message}${NC}"
}

function Log-Info {
    param([string]$Message)
    Write-Host "${BLUE}ℹ️  ${Message}${NC}"
}

# ============================================================================
# Config Loading
# ============================================================================

function Load-Config {
    # Reset to defaults
    $script:PROVIDER = $DEFAULT_PROVIDER
    $script:FILE_PATTERNS = $DEFAULT_FILE_PATTERNS
    $script:EXCLUDE_PATTERNS = ""
    $script:RULES_FILE = $DEFAULT_RULES_FILE
    $script:STRICT_MODE = $DEFAULT_STRICT_MODE

    # Load global config if exists
    $GLOBAL_CONFIG = "$env:USERPROFILE\.config\gga\config"
    if (Test-Path $GLOBAL_CONFIG) {
        . $GLOBAL_CONFIG
    }

    # Load project config (overrides global)
    $PROJECT_CONFIG = ".gga"
    if (Test-Path $PROJECT_CONFIG) {
        . $PROJECT_CONFIG
    }

    # Environment variable overrides
    if ($env:GGA_PROVIDER) {
        $script:PROVIDER = $env:GGA_PROVIDER
    }
}

# ============================================================================
# Commands
# ============================================================================

function Cmd-Init {
    Print-Banner
    
    $PROJECT_CONFIG = ".gga"
    
    if (Test-Path $PROJECT_CONFIG) {
        Log-Warning "Config file already exists: $PROJECT_CONFIG"
        $confirm = Read-Host "Overwrite? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Aborted."
            exit 0
        }
    }

    $config_content = @"
# Gentleman Guardian Angel Configuration
# https://github.com/Gentleman-Programming/gentleman-guardian-angel

# AI Provider (required)
# Options: claude, gemini, codex, ollama:<model>, copilot:<model>
# Examples:
#   PROVIDER="claude"
#   PROVIDER="gemini"
#   PROVIDER="copilot:claude-haiku-4.5"
#   PROVIDER="copilot:gpt-4o"
#   PROVIDER="ollama:llama3.2"
`$PROVIDER = "copilot:claude-haiku-4.5"

# File patterns to include in review (comma-separated)
`$FILE_PATTERNS = "*.ts,*.tsx,*.js,*.jsx"

# File patterns to exclude from review (comma-separated)
`$EXCLUDE_PATTERNS = "*.test.ts,*.spec.ts,*.test.tsx,*.spec.tsx,*.d.ts"

# File containing code review rules
`$RULES_FILE = "REVIEW.md"

# Strict mode: fail if AI response is ambiguous
`$STRICT_MODE = "true"
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

    Write-Host "${BOLD}Current Configuration:${NC}"
    Write-Host ""
    
    $GLOBAL_CONFIG = "$env:USERPROFILE\.config\gga\config"
    $PROJECT_CONFIG = ".gga"
    
    Write-Host "${BOLD}Config Files:${NC}"
    if (Test-Path $GLOBAL_CONFIG) {
        Write-Host "  Global:  ${GREEN}$GLOBAL_CONFIG${NC}"
    } else {
        Write-Host "  Global:  ${YELLOW}Not found${NC}"
    }
    
    if (Test-Path $PROJECT_CONFIG) {
        Write-Host "  Project: ${GREEN}$PROJECT_CONFIG${NC}"
    } else {
        Write-Host "  Project: ${YELLOW}Not found${NC}"
    }
    
    Write-Host ""
    Write-Host "${BOLD}Values:${NC}"
    Write-Host "  PROVIDER:          $PROVIDER"
    Write-Host "  FILE_PATTERNS:     $FILE_PATTERNS"
    Write-Host "  EXCLUDE_PATTERNS:  $EXCLUDE_PATTERNS"
    Write-Host "  RULES_FILE:        $RULES_FILE"
    Write-Host "  STRICT_MODE:       $STRICT_MODE"
    Write-Host ""
    
    if (Test-Path $RULES_FILE) {
        Write-Host "  Rules File:        ${GREEN}Found${NC}"
    } else {
        Write-Host "  Rules File:        ${YELLOW}Not found${NC}"
    }
}

function Cmd-Version {
    Write-Host "gga v$VERSION"
}

function Cmd-Help {
    Print-Help
}

# ============================================================================
# Main Command Router
# ============================================================================

try {
    switch ($Command.ToLower()) {
        "init" {
            Cmd-Init
        }
        "config" {
            Cmd-Config
        }
        "version" {
            Cmd-Version
        }
        "help" {
            Cmd-Help
        }
        default {
            Write-Host "${RED}Unknown command: $Command${NC}"
            Write-Host ""
            Cmd-Help
            exit 1
        }
    }
} catch {
    Log-Error "Error: $_"
    exit 1
}
