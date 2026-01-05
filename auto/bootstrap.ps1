# GGA + SpecKit Bootstrap Script
# Automated setup for any repository

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$TargetPath = $PWD,
    
    [switch]$SkipCopilotApi,
    [switch]$SkipSpecKit,
    [switch]$UseOpenSpec,
    [switch]$SkipGGA,
    [switch]$SkipVSCode,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Define script path
$autoPath = Split-Path -Parent $PSCommandPath

# Colors
function Write-Success { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Warning { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }

# Banner
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  GGA + SpecKit Bootstrap" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Info "Starting bootstrap process..."
Write-Host ""

# Resolve target path
$TargetPath = Resolve-Path $TargetPath -ErrorAction SilentlyContinue
if (-not $TargetPath) {
    Write-Error "Target path does not exist"
    exit 1
}

# Check prerequisites
Write-Info "Checking prerequisites..."

$gitVersion = git --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "git is not installed. Please install Git first."
    exit 1
}
Write-Success "git is available ($gitVersion)"

$nodeVersion = node --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "node is not installed. Please install Node.js first."
    exit 1
}
Write-Success "node is available ($nodeVersion)"

$npmVersion = npm --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "npm is not installed. Please install npm first."
    exit 1
}
Write-Success "npm is available ($npmVersion)"

$uvVersion = uv --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "uv is not installed. SpecKit installation will be skipped."
    Write-Info "Install uv from: https://docs.astral.sh/uv/"
    $script:SkipSpecKit = $true
} else {
    Write-Success "uv is available ($uvVersion)"
}

Write-Host ""

# Install or update Copilot API
if (-not $SkipCopilotApi) {
    Write-Info "Installing Copilot API..."
    
    $copilotPath = Join-Path $env:USERPROFILE ".copilot-api"
    
    if (Test-Path $copilotPath) {
        if ($Force) {
            Write-Info "Updating existing installation..."
            Push-Location $copilotPath
            git pull --quiet 2>&1 | Out-Null
            npm install --silent 2>&1 | Out-Null
            Pop-Location
            Write-Success "Copilot API updated successfully"
        } else {
            Write-Warning "Copilot API already installed (use -Force to update)"
        }
    } else {
        git clone https://github.com/Yoizen/copilot-api.git $copilotPath --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not clone Copilot API repository"
        } else {
            Push-Location $copilotPath
            npm install --silent 2>&1 | Out-Null
            Pop-Location
            Write-Success "Copilot API installed successfully"
        }
    }
    if ($UseOpenSpec) {
        $projectMdPath = Join-Path $TargetPath "openspec\project.md"
        # Removed redundant copy logic here as it is now done during installation
    }

    Write-Host ""
}

# Install or update SpecKit (or OpenSpec)
if (-not $SkipSpecKit -and -not $UseOpenSpec) {
    Write-Info "Installing SpecKit (specify-cli) locally..."
    
    $specKitVenv = Join-Path $TargetPath ".spec-kit-env"
    
    # Create venv if needed
    if (-not (Test-Path $specKitVenv)) {
        Write-Info "Creating virtual environment at $specKitVenv..."
        uv venv $specKitVenv | Out-Null
    }

    # Install/Update
    Write-Info "Installing/Updating specify-cli in local environment..."
    uv pip install "git+https://github.com/github/spec-kit.git" --python $specKitVenv | Out-String | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "SpecKit installed successfully in project"
    } else {
        Write-Warning "Could not install SpecKit"
    }
    
    # Add local venv scripts to PATH for this session
    $venvScripts = Join-Path $specKitVenv "Scripts"
    if ($env:PATH -notlike "*$venvScripts*") {
        $env:PATH = "$venvScripts;$env:PATH"
        Write-Info "Added $venvScripts to PATH for this session"
    }
    
    Write-Host ""
} elseif ($UseOpenSpec) {
    Write-Info "Installing OpenSpec locally..."
    
    # Ensure package.json exists
    if (-not (Test-Path "package.json")) {
        Write-Info "Initializing package.json..."
        npm init -y | Out-Null
    }
    
    # Install OpenSpec
    Write-Info "Installing @fission-ai/openspec..."
    npm install @fission-ai/openspec --save-dev | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "OpenSpec installed successfully in project"
        
        # Create bin directory and openspec wrapper
        $binDir = Join-Path $TargetPath "bin"
        if (-not (Test-Path $binDir)) {
            New-Item -ItemType Directory -Path $binDir -Force | Out-Null
        }
        
        $openspecWrapper = Join-Path $binDir "openspec.ps1"
        if (-not (Test-Path $openspecWrapper)) {
            Write-Info "Creating openspec wrapper..."
            $wrapperContent = @'
# OpenSpec Wrapper for Windows
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Push-Location $ProjectRoot
try {
    & npm exec openspec -- @args
} finally {
    Pop-Location
}
'@
            Set-Content -Path $openspecWrapper -Value $wrapperContent -Force
            Write-Success "Created openspec wrapper"
        }
        
        # Init openspec to generate structure (non-interactive default)
        Write-Info "Initializing OpenSpec structure..."
        
        # Ensure we are in the target directory for npm execution
        Push-Location $TargetPath
        try {
             & npm exec openspec init -- --tools "github-copilot" | Out-Null
        } catch {
             Write-Warning "Could not run openspec init: $_"
        }
        Pop-Location
        
        # Copy CONSTITUTION.md to project.md
        $constitutionSrc = Join-Path $autoPath "CONSTITUTION.md"
        $projectMd = Join-Path $TargetPath "openspec\project.md"
        
        if (Test-Path $constitutionSrc) {
            # Ensure openspec dir exists (it should after init, but good to be safe)
            $openspecDir = Split-Path $projectMd -Parent
            if (-not (Test-Path $openspecDir)) {
                 New-Item -ItemType Directory -Path $openspecDir -Force | Out-Null
            }

            Write-Info "Copying CONSTITUTION.md content to openspec/project.md..."
            $constitutionContent = Get-Content $constitutionSrc -Raw
            Set-Content -Path $projectMd -Value $constitutionContent -Force
            Write-Success "Updated openspec/project.md"
        } else {
            # Try to download from GitHub if local file not found
            Write-Info "Downloading CONSTITUTION.md from GitHub..."
            $baseUrl = "https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto"
            $downloadUrl = "$baseUrl/CONSTITUTION.md"
            
            $openspecDir = Split-Path $projectMd -Parent
            if (-not (Test-Path $openspecDir)) {
                New-Item -ItemType Directory -Path $openspecDir -Force | Out-Null
            }
            
            try {
                $constitutionContent = Invoke-WebRequest -Uri $downloadUrl -ErrorAction Stop | Select-Object -ExpandProperty Content
                Set-Content -Path $projectMd -Value $constitutionContent -Force
                Write-Success "Downloaded CONSTITUTION.md -> openspec/project.md"
            } catch {
                Write-Warning "Could not download CONSTITUTION.md from GitHub"
            }
        }
    } else {
        Write-Warning "Could not install OpenSpec"
    }
    
    Write-Host ""
}

# Install or update GGA
if (-not $SkipGGA) {
    Write-Info "Installing GGA..."
    
    $ggaPath = Join-Path $env:USERPROFILE ".local\share\yoizen\gga-copilot"
    
    if (Test-Path $ggaPath) {
        Write-Info "Updating existing GGA installation..."
        Push-Location $ggaPath
        git fetch origin --quiet 2>&1 | Out-Null
        git pull origin main --quiet 2>&1 | Out-Null
        Pop-Location
    } else {
        Write-Info "Cloning GGA repository..."
        $ggaDir = Split-Path -Parent $ggaPath
        New-Item -ItemType Directory -Path $ggaDir -Force | Out-Null
        git clone https://github.com/Yoizen/gga-copilot.git $ggaPath --quiet 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0 -or (Test-Path $ggaPath)) {
        Write-Info "Installing GGA system-wide..."
        Push-Location $ggaPath
        & .\install.ps1 2>&1 | Out-Null
        Pop-Location
        Write-Success "GGA installed successfully"
    } else {
        Write-Warning "Could not install GGA"
    }
    Write-Host ""
}

# Configure target repository
Write-Info "Configuring repository: $TargetPath"

Push-Location $TargetPath

# Initialize git if not already initialized
if (-not (Test-Path ".git")) {
    Write-Info "Initializing git repository..."
    git init --quiet 2>&1 | Out-Null
    Write-Success "Git repository initialized"
}

# Initialize SpecKit or OpenSpec in repository
if (-not $SkipSpecKit -and -not $UseOpenSpec) {
    # Create bin directory if needed
    $binDir = Join-Path $TargetPath "bin"
    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }
    
    # Create specify wrapper if it doesn't exist
    $specifyBin = Join-Path $TargetPath "bin\specify.ps1"
    if (-not (Test-Path $specifyBin)) {
        Write-Info "Creating specify wrapper..."
        $wrapperContent = @'
# SpecKit Wrapper for Windows
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VenvDir = Join-Path $ProjectRoot ".spec-kit-env"

if (-not (Test-Path $VenvDir)) {
    Write-Error "SpecKit environment not found at $VenvDir"
    Write-Host "Run bootstrap again or install manually."
    exit 1
}

$activateScript = Join-Path $VenvDir "Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    & $activateScript
    & specify @args
} else {
    Write-Error "Cannot find activation script at $activateScript"
    exit 1
}
'@
        Set-Content -Path $specifyBin -Value $wrapperContent -Force
        Write-Success "Created specify wrapper"
    }
    
    # Always initialize SpecKit in repository
    Write-Info "Initializing SpecKit in repository..."
    
    if (Test-Path $specifyBin) {
        & $specifyBin init --here --ai copilot --no-git | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "SpecKit initialized for Copilot"
        } else {
            Write-Warning "SpecKit initialization failed. Run '.\bin\specify.ps1 init --here --ai copilot' manually."
        }
    } else {
             Write-Warning "Could not find specify wrapper at $specifyBin"
        }
} elseif ($UseOpenSpec) {
    # OpenSpec is initialized during the installation phase (see above)
    $openspecConfigPath = Join-Path $TargetPath "openspec"
    if (Test-Path $openspecConfigPath) {
        Write-Info "OpenSpec initialized and configured"
    }
}

# Initialize GGA in repository - ALWAYS run
if (-not $SkipGGA) {
    Write-Info "Initializing GGA in repository..."
    try {
        # Run gga init in the target directory
        $ggaInitOutput = & gga init 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GGA initialized successfully"
            
            # Install GGA hooks in the repository
            Write-Info "Installing GGA hooks..."
            $ggaInstallOutput = & gga install 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "GGA hooks installed"
            } else {
                Write-Warning "GGA hook installation had issues (run 'gga install' manually if needed)"
            }
        } else {
            Write-Warning "GGA init returned exit code $LASTEXITCODE"
        }
    } catch {
        Write-Warning "Could not run 'gga init': $_"
        Write-Info "You can run 'gga init' and 'gga install' manually later"
    }
}

# Ensure directory structure exists
$specifyPath = Join-Path $TargetPath ".specify\memory"
$specsPath = Join-Path $TargetPath "specs"

if (-not (Test-Path $specifyPath)) {
    New-Item -ItemType Directory -Path $specifyPath -Force | Out-Null
    Write-Success "Created .specify/memory/ directory"
}

if (-not (Test-Path $specsPath)) {
    New-Item -ItemType Directory -Path $specsPath -Force | Out-Null
    Write-Success "Created specs/ directory"
}

# Copy configuration files (variable $autoPath already defined at top)
# $autoPath = Split-Path -Parent $PSCommandPath

$reviewSource = "REVIEW.md"
if ($UseOpenSpec) {
    $reviewSource = "REVIEW_OPENSPEC.md"
}

$filesToCopy = @(
    @{Source = "AGENTS.MD"; Dest = "AGENTS.MD"},
    @{Source = $reviewSource; Dest = "REVIEW.md"}
)

if (-not $UseOpenSpec) {
    $filesToCopy += @{Source = "CONSTITUTION.md"; Dest = ".specify\memory\constitution.md"}
}

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $autoPath $file.Source
    $destPath = Join-Path $TargetPath $file.Dest
    
    # Normalize paths for comparison
    $sourcePathNorm = [System.IO.Path]::GetFullPath($sourcePath)
    $destPathNorm = [System.IO.Path]::GetFullPath($destPath)
    
    # Skip if source and dest are the same file
    if ($sourcePathNorm -eq $destPathNorm) {
        Write-Info "$($file.Dest) already in place (same file)"
        continue
    }
    
    if (Test-Path $sourcePath) {
        $destDir = Split-Path -Parent $destPath
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Always copy (overwrite if exists)
        Copy-Item $sourcePath $destPath -Force
        Write-Success "Copied $($file.Dest)"
    } else {
        # Try to download from GitHub if local file not found
        Write-Info "Downloading $($file.Source) from GitHub..."
        $baseUrl = "https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto"
        $downloadUrl = "$baseUrl/$($file.Source)"
        
        $destDir = Split-Path -Parent $destPath
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath -ErrorAction Stop | Out-Null
            Write-Success "Downloaded $($file.Source) -> $($file.Dest)"
        } catch {
            Write-Warning "Could not download $($file.Source) from GitHub"
        }
    }
}

Write-Host ""

# Install VS Code extensions
if (-not $SkipVSCode) {
    Write-Info "Installing VS Code extensions..."
    
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $extensions = @(
            "GitHub.copilot",
            "GitHub.copilot-chat"
        )
        
        foreach ($ext in $extensions) {
            code --install-extension $ext --force 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$ext extension installed"
            } else {
                Write-Warning "Could not install $ext extension"
            }
        }
    } else {
        Write-Warning "VS Code CLI not found. Install VS Code and add to PATH."
    }
    Write-Host ""
}

Pop-Location

# Summary
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your repository is now configured with:" -ForegroundColor White
Write-Host "  - GGA (Gentleman Guardian Angel)" -ForegroundColor Gray
    if ($UseOpenSpec) {
        Write-Host "  - OpenSpec (Spec-First methodology)" -ForegroundColor Gray
    } else {
        Write-Host "  - SpecKit (Spec-First Development)" -ForegroundColor Gray
    }
Write-Host "  - Copilot API" -ForegroundColor Gray
Write-Host "  - VS Code extensions" -ForegroundColor Gray
Write-Host "  - Configuration files (AGENTS.MD, REVIEW.md)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. cd $TargetPath" -ForegroundColor Gray
Write-Host "  2. Review .gga config (provider: copilot:claude-haiku-4.5)" -ForegroundColor Gray
Write-Host "  3. Customize AGENTS.MD for your project" -ForegroundColor Gray
Write-Host "  4. code . (open in VS Code)" -ForegroundColor Gray
Write-Host "  5. Start creating specs in specs/ directory" -ForegroundColor Gray
Write-Host "  6. Run 'gga review' before committing code" -ForegroundColor Gray
Write-Host ""
