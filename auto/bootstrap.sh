#!/bin/bash
# ============================================================================
# GGA + SpecKit Bootstrap - Automated Setup Script
# ============================================================================
# This script automatically configures GGA and SpecKit for any repository
# Usage: ./bootstrap.sh [target-directory]
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================

COPILOT_API_REPO="https://github.com/Yoizen/copilot-api.git"
SPEC_KIT_REPO="https://github.com/github/spec-kit.git"
GGA_REPO="https://github.com/Yoizen/gga-copilot.git"

# Permanent locations
COPILOT_API_DIR="$HOME/.local/share/yoizen/copilot-api"
SPEC_KIT_DIR="$HOME/.local/share/yoizen/spec-kit"
GGA_DIR="$HOME/.local/share/yoizen/gga-copilot"

# VS Code Extensions
VSCODE_EXTENSIONS=(
    "ultracite.ultracite-vscode"
    "github.copilot"
    "github.copilot-chat"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Flags
SKIP_COPILOT_API=false
SKIP_SPECKIT=false
SKIP_GGA=false
SKIP_VSCODE=false
FORCE=false

USE_OPENSPEC=false

# ============================================================================
# Helper Functions
# ============================================================================

print_banner() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  GGA + SpecKit Bootstrap - Automated Setup${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${GREEN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_info() {
    echo -e "${CYAN}  ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

command_exists() {
    command -v "$1" &> /dev/null
}

install_or_update_repo() {
    local repo_url="$1"
    local target_path="$2"
    local name="$3"
    
    if [ -d "$target_path/.git" ]; then
        print_info "Updating $name..."
        (cd "$target_path" && git fetch origin && (git pull origin main 2>/dev/null || git pull origin master 2>/dev/null))
        print_success "$name updated"
    else
        print_info "Cloning $name..."
        mkdir -p "$(dirname "$target_path")"
        git clone "$repo_url" "$target_path" 2>/dev/null
        print_success "$name cloned to $target_path"
    fi
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

test_prerequisites() {
    print_step "Checking prerequisites..."
    
    local all_ok=true
    
    # Check Git
    if command_exists git; then
        print_success "Git is installed"
    else
        print_error "Git is NOT installed"
        echo "    Install with: sudo apt install git (Ubuntu/Debian) or brew install git (macOS)"
        all_ok=false
    fi
    
    # Check Node.js
    if command_exists node; then
        local node_version=$(node --version)
        print_success "Node.js is installed ($node_version)"
    else
        print_error "Node.js is NOT installed"
        echo "    Install from: https://nodejs.org/"
        all_ok=false
    fi
    
    # Check npm
    if command_exists npm; then
        local npm_version=$(npm --version)
        print_success "npm is installed ($npm_version)"
    else
        print_error "npm is NOT installed"
        all_ok=false
    fi
    
    # Check VS Code (optional)
    if command_exists code; then
        print_success "VS Code CLI is available"
    else
        print_warning "VS Code CLI not found (extensions will be skipped)"
    fi
    
    if [ "$all_ok" = false ]; then
        echo ""
        print_error "Prerequisites not met. Please install missing tools."
        exit 1
    fi
}

# ============================================================================
# Installation Steps
# ============================================================================

install_copilot_api() {
    if [ "$SKIP_COPILOT_API" = true ]; then
        print_info "Skipping Copilot API (--skip-copilot-api)"
        return
    fi
    
    print_step "Setting up Copilot API..."
    install_or_update_repo "$COPILOT_API_REPO" "$COPILOT_API_DIR" "copilot-api"
    
    print_info "Installing npm dependencies..."
    (cd "$COPILOT_API_DIR" && npm install 2>/dev/null)
    print_success "Copilot API ready"
}

install_speckit() {
    if [ "$SKIP_SPECKIT" = true ]; then
        print_info "Skipping SpecKit (--skip-speckit)"
        return
    fi

    if [ "$USE_OPENSPEC" = true ]; then
        print_step "Setting up OpenSpec..."
        
        # Ensure package.json exists
        if [ ! -f "package.json" ]; then
            print_info "Initializing package.json..."
            npm init -y >/dev/null
        fi

        print_info "Installing OpenSpec locally..."
        npm install @fission-ai/openspec --save-dev >/dev/null

        if [ $? -eq 0 ]; then
            print_success "OpenSpec installed successfully in project"
            
            # Create bin directory and openspec wrapper
            mkdir -p "$TARGET_DIR/bin"
            local openspec_wrapper="$TARGET_DIR/bin/openspec"
            if [ ! -f "$openspec_wrapper" ]; then
                print_info "Creating openspec wrapper..."
                cat > "$openspec_wrapper" << 'OPENSPEC_WRAPPER'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"
exec npm exec openspec -- "$@"
OPENSPEC_WRAPPER
                chmod +x "$openspec_wrapper"
                print_success "Created openspec wrapper"
            fi
            
            # Always init openspec to generate structure
            print_info "Initializing OpenSpec structure..."
            npm exec openspec init -- --tools "github-copilot" >/dev/null 2>&1
            
            # Always copy CONSTITUTION.md to project.md
            local constitution_src="$script_dir/CONSTITUTION.md"
            local project_md="$TARGET_DIR/openspec/project.md"
            
            if [ -f "$constitution_src" ]; then
                mkdir -p "$(dirname "$project_md")"
                print_info "Copying CONSTITUTION.md content to openspec/project.md..."
                cat "$constitution_src" > "$project_md"
                print_success "Updated openspec/project.md"
            else
                print_warning "CONSTITUTION.md not found in auto/ directory"
            fi
        else
            print_warning "Could not install OpenSpec"
        fi
        return
    fi
    
    print_step "Setting up SpecKit..."
    
    # Local environment setup
    local venv_dir="$TARGET_DIR/.spec-kit-env"
    
    if [ ! -d "$venv_dir" ]; then
        print_info "Creating virtual environment at .spec-kit-env..."
        uv venv "$venv_dir" >/dev/null
    fi
    
    print_info "Installing/Updating specify-cli in local environment..."
    uv pip install "git+https://github.com/github/spec-kit.git" --python "$venv_dir" >/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "SpecKit installed successfully in project"
    else
        print_warning "Could not install SpecKit"
    fi
}

install_gga() {
    if [ "$SKIP_GGA" = true ]; then
        print_info "Skipping GGA (--skip-gga)"
        return
    fi
    
    print_step "Setting up GGA..."
    install_or_update_repo "$GGA_REPO" "$GGA_DIR" "gga-copilot"
    
    # Always ensure GGA is properly installed
    print_info "Installing GGA system-wide..."
    if (cd "$GGA_DIR" && bash install.sh >/dev/null 2>&1); then
        print_success "GGA installed"
    else
        print_warning "GGA installation had issues, but may still work"
    fi
}

install_vscode_extensions() {
    if [ "$SKIP_VSCODE" = true ]; then
        print_info "Skipping VS Code extensions (--skip-vscode)"
        return
    fi
    
    if ! command_exists code; then
        print_warning "VS Code CLI not available, skipping extensions"
        return
    fi
    
    print_step "Installing VS Code extensions..."
    
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        print_info "Installing $ext..."
        if code --install-extension "$ext" --force 2>/dev/null; then
            print_success "$ext installed"
        else
            print_warning "Could not install $ext"
        fi
    done
}

configure_target_repository() {
    local repo_path="$1"
    
    print_step "Configuring target repository..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Initialize OpenSpec if selected
    if [ "$USE_OPENSPEC" = true ]; then
        if [ -d "$repo_path/openspec" ]; then
            print_info "OpenSpec initialized and configured"
        fi
    else
        # Create necessary directories for SpecKit
        mkdir -p "$repo_path/.specify/memory"
        print_success "Created .specify/memory directory"
        
        mkdir -p "$repo_path/specs"
        print_success "Created specs directory"
        
        # Create bin directory and wrappers
        mkdir -p "$repo_path/bin"
        
        # Initialize SpecKit in repository (DO THIS BEFORE COPYING FILES)
        if [ "$SKIP_SPECKIT" != true ]; then
             # Create specify wrapper if it doesn't exist
             local specify_bin="$repo_path/bin/specify"
             if [ ! -f "$specify_bin" ]; then
                 print_info "Creating specify wrapper..."
                 cat > "$specify_bin" << 'WRAPPER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_DIR="$PROJECT_ROOT/.spec-kit-env"

if [ ! -d "$VENV_DIR" ]; then
    echo "Error: SpecKit environment not found at $VENV_DIR"
    echo "Run bootstrap again or install manually."
    exit 1
fi

source "$VENV_DIR/bin/activate"
exec specify "$@"
WRAPPER_EOF
                 chmod +x "$specify_bin"
                 print_success "Created specify wrapper"
             fi
             
             # Always initialize SpecKit in repository
             print_info "Initializing SpecKit in repository..."
             
             if [ -f "$specify_bin" ]; then
                 # Run with timeout and send 'y' to any prompts
                 (echo "y" | timeout 30s "$specify_bin" init --here --ai copilot --no-git) >/dev/null 2>&1
                 local exit_code=$?
                 if [ $exit_code -eq 0 ]; then
                     print_success "SpecKit initialized for Copilot"
                 elif [ $exit_code -eq 124 ]; then
                     print_warning "SpecKit initialization timed out (this is OK - structure may already exist)"
                 else
                     print_warning "SpecKit initialization failed. Run './bin/specify init --here --ai copilot' manually if needed."
                 fi
             else
                 print_warning "Could not find specify wrapper at $specify_bin"
             fi
        fi

        # Copy configuration files
        # Override REVIEW.md source if using OpenSpec (though we are in the else block here, keeping logic generic if needed)
        local review_source="REVIEW.md"
        local base_url="https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto"
        
        # Always copy configuration files (overwrite if exists)
        for file_key in "AGENTS.MD" "REVIEW.md" "CONSTITUTION.md"; do
            local source_file="$file_key"
            local target_relative=""
            
            if [ "$file_key" == "AGENTS.MD" ]; then target_relative="AGENTS.MD"; fi
            if [ "$file_key" == "CONSTITUTION.md" ]; then target_relative=".specify/memory/constitution.md"; fi
            if [ "$file_key" == "REVIEW.md" ]; then 
                source_file="$review_source"
                target_relative="REVIEW.md"
            fi
            
            local source="$script_dir/$source_file"
            local target="$repo_path/$target_relative"
            
            # Skip if source and target are the same file
            if [ "$source" -ef "$target" ]; then
                print_info "$target_relative already in place (same file)"
                continue
            fi
            
            if [ -f "$source" ]; then
                mkdir -p "$(dirname "$target")"
                cp "$source" "$target"
                print_success "Copied $source_file → $target_relative"
            else
                # Try to download from GitHub if local file not found
                print_info "Downloading $source_file from GitHub..."
                mkdir -p "$(dirname "$target")"
                if curl -fsSL "$base_url/$source_file" -o "$target" 2>/dev/null; then
                    print_success "Downloaded $source_file → $target_relative"
                else
                    print_warning "Could not download $source_file from GitHub"
                fi
            fi
        done
        
        # Create a sample spec if specs/ is empty
        if [ -z "$(ls -A "$repo_path/specs" 2>/dev/null)" ]; then
            cat > "$repo_path/specs/README.md" << 'EOF'
# Specifications

This directory contains project specifications following the Spec-First methodology.

## Structure

- `features/` - Feature specifications
- `bugs/` - Bug fix specifications
- `architecture/` - Architecture decision records (ADRs)

## Spec Template

Each feature should have:
- `spec.md` - The specification document
- `plan.md` - Implementation plan

## Example

```
specs/
  features/
    user-authentication/
      spec.md
      plan.md
```

Refer to REVIEW.md in the root for the review checklist.
EOF
            print_success "Created specs/README.md template"
        fi
    fi
    
    # Initialize GGA in repository (common for both) - ALWAYS run
    if [ "$SKIP_GGA" != true ]; then
        print_info "Initializing GGA in repository..."
        if (cd "$repo_path" && gga init >/dev/null 2>&1); then
            print_success "GGA initialized successfully"
            
            # Install GGA hooks in the repository
            print_info "Installing GGA hooks..."
            if (cd "$repo_path" && gga install >/dev/null 2>&1); then
                print_success "GGA hooks installed"
            else
                print_warning "GGA hook installation had issues (run 'gga install' manually if needed)"
            fi
        else
            print_warning "Failed to initialize GGA (run 'gga init' manually)"
        fi
    fi
    
    # Copy REVIEW.md and AGENTS.MD for OpenSpec if they weren't copied above (since we split the block)
    # Always copy REVIEW.md and AGENTS.MD for OpenSpec (overwrite if exists)
    if [ "$USE_OPENSPEC" = true ]; then
         local review_source="REVIEW_OPENSPEC.md"
         local base_url="https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto"
         
         for file_key in "AGENTS.MD" "REVIEW.md"; do
            local source_file="$file_key"
            local target_relative=""
            if [ "$file_key" == "AGENTS.MD" ]; then target_relative="AGENTS.MD"; fi
            if [ "$file_key" == "REVIEW.md" ]; then 
                source_file="$review_source"
                target_relative="REVIEW.md"
            fi
            
            local source="$script_dir/$source_file"
            local target="$repo_path/$target_relative"
            
            # Skip if source and target are the same file
            if [ "$source" -ef "$target" ]; then
                print_info "$target_relative already in place (same file)"
                continue
            fi
            
            if [ -f "$source" ]; then
                cp "$source" "$target"
                print_success "Copied $source_file → $target_relative"
            else
                # Try to download from GitHub if local file not found
                print_info "Downloading $source_file from GitHub..."
                if curl -fsSL "$base_url/$source_file" -o "$target" 2>/dev/null; then
                    print_success "Downloaded $source_file → $target_relative"
                else
                    print_warning "Could not download $source_file from GitHub"
                fi
            fi
         done
    fi
}

show_next_steps() {
    local repo_path="$1"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Setup Complete! 🎉${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Your repository is now configured with:${NC}"
    echo -e "${CYAN}  • GGA (Gentleman Guardian Angel)${NC}"
    
    if [ "$USE_OPENSPEC" = true ]; then
        echo -e "${CYAN}  • OpenSpec (Spec-First methodology)${NC}"
    else
        echo -e "${CYAN}  • SpecKit (Spec-First methodology)${NC}"
    fi

    echo -e "${CYAN}  • Copilot API${NC}"
    echo -e "${CYAN}  • Development standards (AGENTS.MD, REVIEW.md)${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "${WHITE}  1. Review .gga config (provider: copilot:claude-haiku-4.5)${NC}"
    echo -e "${WHITE}  2. Customize AGENTS.MD for your project${NC}"
    echo -e "${WHITE}  3. Start creating specs in specs/ directory${NC}"
    echo -e "${WHITE}  4. Run 'gga review' before committing code${NC}"
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo -e "${WHITE}  • GGA: $GGA_DIR/README.md${NC}"
    
    if [ "$USE_OPENSPEC" = true ]; then
         echo -e "${WHITE}  • OpenSpec: https://github.com/Fission-AI/OpenSpec${NC}"
    else
         echo -e "${WHITE}  • SpecKit: https://github.com/github/spec-kit${NC}"
    fi

    echo ""
    echo -e "${CYAN}Repository path: $repo_path${NC}"
    echo ""
}

# ============================================================================
# Parse Arguments
# ============================================================================

TARGET_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-copilot-api)
            SKIP_COPILOT_API=true
            shift
            ;;
        --skip-speckit)
            SKIP_SPECKIT=true
            shift
            ;;
        --use-openspec)
            USE_OPENSPEC=true
            shift
            ;;
        --skip-gga)
            SKIP_GGA=true
            shift
            ;;
        --skip-vscode)
            SKIP_VSCODE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [target-directory]"
            echo ""
            echo "Options:"
            echo "  --skip-copilot-api    Skip Copilot API installation"
            echo "  --skip-speckit        Skip SpecKit installation"
            echo "  --use-openspec        Use OpenSpec instead of SpecKit"
            echo "  --skip-gga            Skip GGA installation"
            echo "  --skip-vscode         Skip VS Code extensions"
            echo "  --force               Overwrite existing configuration files"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# ============================================================================
# Main Execution
# ============================================================================

print_banner

# Validate target directory
if [ ! -d "$TARGET_DIR" ]; then
    print_error "Directory not found: $TARGET_DIR"
    exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
print_info "Target repository: $TARGET_DIR"

# Check if target is a git repository and initialize if needed
if [ ! -d "$TARGET_DIR/.git" ]; then
    print_info "Initializing git repository..."
    if (cd "$TARGET_DIR" && git init >/dev/null 2>&1); then
        print_success "Git repository initialized"
    else
        print_error "Failed to initialize git repository"
        exit 1
    fi
fi

# Run setup steps
test_prerequisites
install_copilot_api
install_speckit
install_gga
install_vscode_extensions
configure_target_repository "$TARGET_DIR"
show_next_steps "$TARGET_DIR"
