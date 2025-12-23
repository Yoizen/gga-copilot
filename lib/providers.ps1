# ============================================================================
# Gentleman Guardian Angel - Windows PowerShell Providers
# ============================================================================

# ============================================================================
# Provider Validation
# ============================================================================

function Validate-Provider {
    param([string]$Provider)
    
    $base_provider = $Provider -split ":" | Select-Object -First 1
    
    switch ($base_provider) {
        "claude" {
            if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
                Write-Host "${RED}❌ Claude CLI not found${NC}"
                Write-Host ""
                Write-Host "Install Claude Code CLI:"
                Write-Host "  https://claude.ai/code"
                Write-Host ""
                return $false
            }
        }
        "gemini" {
            if (-not (Get-Command gemini -ErrorAction SilentlyContinue)) {
                Write-Host "${RED}❌ Gemini CLI not found${NC}"
                Write-Host ""
                Write-Host "Install Gemini CLI:"
                Write-Host "  npm install -g @anthropic-ai/gemini-cli"
                Write-Host ""
                return $false
            }
        }
        "codex" {
            if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
                Write-Host "${RED}❌ Codex CLI not found${NC}"
                Write-Host ""
                Write-Host "Install OpenAI Codex CLI:"
                Write-Host "  npm install -g @openai/codex"
                Write-Host ""
                return $false
            }
        }
        "ollama" {
            if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
                Write-Host "${RED}❌ Ollama not found${NC}"
                Write-Host ""
                Write-Host "Install Ollama:"
                Write-Host "  https://ollama.ai/download"
                Write-Host ""
                return $false
            }
            
            $model = $Provider -split ":" | Select-Object -Last 1
            if ($model -eq $Provider -or [string]::IsNullOrEmpty($model)) {
                Write-Host "${RED}❌ Ollama requires a model${NC}"
                Write-Host ""
                Write-Host "Specify model in provider config:"
                Write-Host "  `$PROVIDER = 'ollama:llama3.2'"
                Write-Host "  `$PROVIDER = 'ollama:codellama'"
                Write-Host ""
                return $false
            }
        }
        "copilot" {
            if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
                Write-Host "${RED}❌ curl not found${NC}"
                Write-Host ""
                Write-Host "Install curl or use Windows 10+ which includes it."
                Write-Host "Alternatively, ensure copilot-api proxy is running on localhost:4141"
                Write-Host ""
                return $false
            }
        }
        default {
            Write-Host "${RED}❌ Unknown provider: $Provider${NC}"
            Write-Host ""
            Write-Host "Supported providers:"
            Write-Host "  - claude"
            Write-Host "  - gemini"
            Write-Host "  - codex"
            Write-Host "  - ollama:<model>"
            Write-Host "  - copilot:<model>"
            Write-Host ""
            return $false
        }
    }
    
    return $true
}

# ============================================================================
# Provider Execution
# ============================================================================

function Execute-Provider {
    param(
        [string]$Provider,
        [string]$Prompt
    )
    
    $base_provider = $Provider -split ":" | Select-Object -First 1
    
    switch ($base_provider) {
        "claude" {
            Execute-Claude $Prompt
        }
        "gemini" {
            Execute-Gemini $Prompt
        }
        "codex" {
            Execute-Codex $Prompt
        }
        "ollama" {
            $model = $Provider -split ":" | Select-Object -Last 1
            Execute-Ollama $model $Prompt
        }
        "copilot" {
            $model = $Provider -split ":" | Select-Object -Last 1
            if ([string]::IsNullOrEmpty($model) -or $model -eq $Provider) {
                $model = "gpt-4o"
            }
            Execute-Copilot $model $Prompt
        }
    }
}

# ============================================================================
# Individual Provider Implementations
# ============================================================================

function Execute-Claude {
    param([string]$Prompt)
    
    $Prompt | & claude --print 2>&1
    return $LASTEXITCODE
}

function Execute-Gemini {
    param([string]$Prompt)
    
    $Prompt | & gemini 2>&1
    return $LASTEXITCODE
}

function Execute-Codex {
    param([string]$Prompt)
    
    & codex exec $Prompt 2>&1
    return $LASTEXITCODE
}

function Execute-Ollama {
    param(
        [string]$Model,
        [string]$Prompt
    )
    
    & ollama run $Model $Prompt 2>&1
    return $LASTEXITCODE
}

function Execute-Copilot {
    param(
        [string]$Model,
        [string]$Prompt
    )
    
    # Escape special characters for JSON
    $escaped_prompt = $Prompt -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n'
    
    $json = @{
        model = $Model
        messages = @(
            @{
                role = "user"
                content = $escaped_prompt
            }
        )
    } | ConvertTo-Json -Depth 2 -EscapeHandling EscapeNonAscii
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4141/v1/chat/completions" `
            -Method POST `
            -Headers @{ "Content-Type" = "application/json" } `
            -Body $json `
            -ErrorAction Stop
        
        $content = $response.Content | ConvertFrom-Json
        return $content.choices[0].message.content
    } catch {
        Write-Host "Error connecting to copilot-api. Is it running on port 4141?" -ForegroundColor Red
        return 1
    }
}

# ============================================================================
# Provider Info
# ============================================================================

function Get-ProviderInfo {
    param([string]$Provider)
    
    $base_provider = $Provider -split ":" | Select-Object -First 1
    
    switch ($base_provider) {
        "claude" {
            return "Anthropic Claude Code CLI"
        }
        "gemini" {
            return "Google Gemini CLI"
        }
        "codex" {
            return "OpenAI Codex CLI"
        }
        "ollama" {
            $model = $Provider -split ":" | Select-Object -Last 1
            return "Ollama (model: $model)"
        }
        "copilot" {
            $model = $Provider -split ":" | Select-Object -Last 1
            if ([string]::IsNullOrEmpty($model)) {
                $model = "gpt-4o"
            }
            return "GitHub Copilot (model: $model)"
        }
        default {
            return "Unknown provider"
        }
    }
}
