# Bootstrap Configuration Example
# Copy this file and customize for your organization

# Repository URLs (customize these)
$COPILOT_API_REPO = "https://github.com/YourOrg/copilot-api.git"
$SPECKIT_REPO = "https://github.com/YourOrg/speckit.git"
$GGA_REPO = "https://github.com/YourOrg/gga-copilot.git"

# Installation paths
$COPILOT_API_PATH = Join-Path $env:USERPROFILE ".copilot-api"
$SPECKIT_PATH = Join-Path $env:USERPROFILE ".speckit"
$GGA_PATH = Join-Path $env:USERPROFILE ".gga"

# VS Code extensions
$VSCODE_EXTENSIONS = @(
    "GitHub.copilot",
    "GitHub.copilot-chat",
    "YourOrg.speckit"
)

# Configuration files to copy
$CONFIG_FILES = @(
    @{Source = "AGENTS.MD"; Dest = "AGENTS.MD"},
    @{Source = "REVIEW.md"; Dest = "REVIEW.md"},
    @{Source = "CONSTITUTION.md"; Dest = ".specify\memory\constitution.md"}
)

# Default options
$DEFAULT_SKIP_COPILOT_API = $false
$DEFAULT_SKIP_SPECKIT = $false
$DEFAULT_SKIP_GGA = $false
$DEFAULT_SKIP_VSCODE = $false
$DEFAULT_FORCE = $false
