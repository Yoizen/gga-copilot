#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== GGA Copilot Setup Script ===${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    exit 1
fi

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
    echo -e "${YELLOW}Warning: VS Code CLI 'code' command not found${NC}"
    echo "You may need to install extensions manually"
fi

# Variables
PROJECT_NAME="gga-copilot"
COPILOT_API_REPO="https://github.com/Yoizen/copilot-api.git"
GGA_COPILOT_REPO="https://github.com/Yoizen/gga-copilot.git"
SPEC_KIT_REPO="https://github.com/github/spec-kit.git"

# Get current directory where scripts are located and where we'll configure GGA
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_REPO=$(pwd)

echo -e "${GREEN}Step 1: Setting up directories and cloning repositories...${NC}"

# Create permanent directory for copilot-api
COPILOT_API_DIR="$HOME/.local/share/yoizen/copilot-api"
if [ ! -d "$COPILOT_API_DIR" ]; then
    echo "Creating copilot-api directory..."
    mkdir -p "$COPILOT_API_DIR"
fi

# Clone or update copilot-api in permanent location
if [ ! -d "$COPILOT_API_DIR/.git" ]; then
    echo "Cloning copilot-api to permanent location..."
    git clone "$COPILOT_API_REPO" "$COPILOT_API_DIR"
else
    echo "Copilot-api already exists, updating..."
    cd "$COPILOT_API_DIR"
    git pull
    cd "$CURRENT_REPO"
fi

# Create temp directory for other repos
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone gga-copilot
if [ ! -d "$PROJECT_NAME" ]; then
    echo "Cloning gga-copilot..."
    git clone "$GGA_COPILOT_REPO" "$PROJECT_NAME"
else
    echo "gga-copilot already exists, skipping..."
fi

# Clone spec-kit
if [ ! -d "spec-kit" ]; then
    echo "Cloning spec-kit..."
    git clone "$SPEC_KIT_REPO" spec-kit
else
    echo "spec-kit already exists, skipping..."
fi

echo ""
echo -e "${GREEN}Step 2: Installing dependencies...${NC}"

# Install copilot-api dependencies
cd "$COPILOT_API_DIR"
echo "Installing copilot-api dependencies..."
npm install

# Return to original directory
cd "$CURRENT_REPO"

echo ""
echo -e "${GREEN}Step 3: Configuring project files in current repository...${NC}"

# Create .specify/memory directory in current repo
mkdir -p "$CURRENT_REPO/.specify/memory"

# Copy configuration files from script directory to current repo (only if different locations)
if [ -f "$SCRIPT_DIR/AGENTS.MD" ]; then
    if [ "$SCRIPT_DIR/AGENTS.MD" != "$CURRENT_REPO/AGENTS.MD" ]; then
        echo "Copying AGENTS.MD to repository root..."
        cp "$SCRIPT_DIR/AGENTS.MD" "$CURRENT_REPO/AGENTS.MD"
    else
        echo "AGENTS.MD already in place"
    fi
else
    echo -e "${YELLOW}Warning: AGENTS.MD not found in $SCRIPT_DIR${NC}"
fi

if [ -f "$SCRIPT_DIR/REVIEW.md" ]; then
    if [ "$SCRIPT_DIR/REVIEW.md" != "$CURRENT_REPO/REVIEW.md" ]; then
        echo "Copying REVIEW.md to repository root..."
        cp "$SCRIPT_DIR/REVIEW.md" "$CURRENT_REPO/REVIEW.md"
    else
        echo "REVIEW.md already in place"
    fi
else
    echo -e "${YELLOW}Warning: REVIEW.md not found in $SCRIPT_DIR${NC}"
fi

if [ -f "$SCRIPT_DIR/CONSTITUTION.md" ]; then
    if [ "$SCRIPT_DIR/CONSTITUTION.md" != "$CURRENT_REPO/.specify/memory/constitution.md" ]; then
        echo "Copying CONSTITUTION.md to .specify/memory/..."
        cp "$SCRIPT_DIR/CONSTITUTION.md" "$CURRENT_REPO/.specify/memory/constitution.md"
    else
        echo "CONSTITUTION.md already in place"
    fi
else
    echo -e "${YELLOW}Warning: CONSTITUTION.md not found in $SCRIPT_DIR${NC}"
fi

echo ""
echo -e "${GREEN}Step 4: Installing VS Code extensions...${NC}"

if command -v code &> /dev/null; then
    echo "Installing Ultracite AI extension..."
    code --install-extension ultracite.ultracite-vscode
    
    echo "Installing GitHub Copilot (if not already installed)..."
    code --install-extension github.copilot
    
    echo "Installing GitHub Copilot Chat (if not already installed)..."
    code --install-extension github.copilot-chat
else
    echo -e "${YELLOW}VS Code CLI not available. Please install extensions manually:${NC}"
    echo "  1. Ultracite AI: https://marketplace.visualstudio.com/items?itemName=ultracite.ultracite-vscode"
    echo "  2. GitHub Copilot: https://marketplace.visualstudio.com/items?itemName=GitHub.copilot"
    echo "  3. GitHub Copilot Chat: https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat"
fi

echo ""
echo -e "${GREEN}Step 5: Installing GGA (Gentleman Guardian Angel)...${NC}"

# Install GGA to user's local bin directory
GGA_INSTALL_DIR="$HOME/.local/gga"
GGA_BIN_DIR="$GGA_INSTALL_DIR/bin"
GGA_LIB_DIR="$GGA_INSTALL_DIR/lib"

# Create directories
echo "Creating GGA directories..."
mkdir -p "$GGA_BIN_DIR"
mkdir -p "$GGA_LIB_DIR"

# Copy GGA files
echo "Copying GGA files..."
cp -r "$TEMP_DIR/gga-copilot/bin/"* "$GGA_BIN_DIR/"
cp -r "$TEMP_DIR/gga-copilot/lib/"* "$GGA_LIB_DIR/"

# Make scripts executable
chmod +x "$GGA_BIN_DIR/"*

# Add GGA to PATH if not already there
if [[ ":$PATH:" != *":$GGA_BIN_DIR:"* ]]; then
    echo "Adding GGA to PATH..."
    
    # Detect shell and add to appropriate rc file
    if [ -n "$BASH_VERSION" ]; then
        RC_FILE="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        RC_FILE="$HOME/.zshrc"
    else
        RC_FILE="$HOME/.profile"
    fi
    
    echo "" >> "$RC_FILE"
    echo "# GGA (Gentleman Guardian Angel)" >> "$RC_FILE"
    echo "export PATH=\"\$PATH:$GGA_BIN_DIR\"" >> "$RC_FILE"
    
    export PATH="$PATH:$GGA_BIN_DIR"
    echo -e "${GREEN}GGA added to PATH successfully${NC}"
else
    echo "GGA already in PATH"
fi

echo ""
echo -e "${GREEN}Step 6: Configuring GGA in current repository...${NC}"

# Initialize GGA in the current repository
if [ -d "$CURRENT_REPO/.git" ]; then
    echo "Initializing GGA configuration..."
    
    # Copy the template config
    if [ -f "$TEMP_DIR/gga-copilot/.gga.copilot-claude-haiku-template" ]; then
        cp "$TEMP_DIR/gga-copilot/.gga.copilot-claude-haiku-template" "$CURRENT_REPO/.gga"
        echo "Created .gga configuration file"
    fi
    
    # Create pre-commit hook
    mkdir -p "$CURRENT_REPO/.git/hooks"
    
    cat > "$CURRENT_REPO/.git/hooks/pre-commit" << 'EOF'
#!/bin/sh
# GGA Pre-commit Hook
# Auto-generated by setup script

# Find GGA executable
if command -v gga >/dev/null 2>&1; then
    gga run
elif [ -f "$HOME/.local/gga/bin/gga" ]; then
    "$HOME/.local/gga/bin/gga" run
else
    echo "Warning: GGA not found. Skipping code review."
    exit 0
fi
EOF
    
    chmod +x "$CURRENT_REPO/.git/hooks/pre-commit"
    echo -e "${GREEN}Pre-commit hook installed${NC}"
else
    echo -e "${YELLOW}Warning: Not a git repository. Skipping GGA hook installation.${NC}"
    echo "Run 'git init' first, then manually run: gga install"
fi

echo ""
echo -e "${GREEN}Step 7: Creating symlink for copilot-api...${NC}"

# Create node_modules/@yoizen if it doesn't exist in current repo
mkdir -p "$CURRENT_REPO/node_modules/@yoizen"

# Create symlink to copilot-api
if [ -L "$CURRENT_REPO/node_modules/@yoizen/copilot-api" ]; then
    echo "Removing existing symlink..."
    rm "$CURRENT_REPO/node_modules/@yoizen/copilot-api"
fi

echo "Creating symlink to copilot-api (permanent location)..."
ln -s "$COPILOT_API_DIR" "$CURRENT_REPO/node_modules/@yoizen/copilot-api"

echo ""
echo -e "${GREEN}Step 8: Configuring package.json scripts and spec-kit integration...${NC}"

# Create or update package.json with GGA scripts
if [ -f "$CURRENT_REPO/package.json" ]; then
    echo "Updating existing package.json..."
    # Backup original
    cp "$CURRENT_REPO/package.json" "$CURRENT_REPO/package.json.bak"
    
    # Use node to update package.json
    node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('$CURRENT_REPO/package.json', 'utf8'));
    if (!pkg.scripts) pkg.scripts = {};
    pkg.scripts['copilot:start'] = 'cd node_modules/@yoizen/copilot-api && npm start';
    pkg.scripts['copilot:login'] = 'cd node_modules/@yoizen/copilot-api && npm run login';
    pkg.scripts['gga:run'] = 'gga run';
    pkg.scripts['gga:config'] = 'gga config';
    pkg.scripts['spec:setup'] = 'echo Setting up spec-kit workflow... && npm run copilot:login';
    pkg.scripts['spec:review'] = 'npm run copilot:start & sleep 5 && npm run gga:run';
    pkg.scripts['spec:validate'] = 'npm run gga:run';
    fs.writeFileSync('$CURRENT_REPO/package.json', JSON.stringify(pkg, null, 2));
    "
else
    echo "Creating new package.json..."
    cat > "$CURRENT_REPO/package.json" << 'EOF'
{
  "name": "project",
  "version": "1.0.0",
  "description": "",
  "scripts": {
    "copilot:start": "cd node_modules/@yoizen/copilot-api && npm start",
    "copilot:login": "cd node_modules/@yoizen/copilot-api && npm run login",
    "gga:run": "gga run",
    "gga:config": "gga config",
    "spec:setup": "echo 'Setting up spec-kit workflow...' && npm run copilot:login",
    "spec:review": "npm run copilot:start & sleep 5 && npm run gga:run",
    "spec:validate": "npm run gga:run"
  }
}
EOF
fi

echo -e "${GREEN}Package.json configured with GGA + spec-kit integration${NC}"

# Create spec-kit integration documentation
echo "Creating spec-kit workflow configuration..."
cat > "$CURRENT_REPO/SPEC_WORKFLOW.md" << 'EOF'
# Spec-Kit + GGA Workflow Configuration

This project uses spec-kit for specification-driven development integrated with GGA (Gentleman Guardian Angel) for automated code review.

## Workflow Steps

### 1. Initial Setup (First Time Only)
```bash
npm run spec:setup
```
This will authenticate with GitHub Copilot.

### 2. Start Development Session
```bash
# Terminal 1: Start Copilot API (keep running)
npm run copilot:start

# Terminal 2: Your development work
```

### 3. Before Committing
```bash
# Validate your changes with GGA
npm run spec:validate
```

### 4. Commit (Automatic Review)
```bash
git add .
git commit -m "feat: your feature"
# GGA will automatically review on pre-commit hook
```

## Spec-Kit Commands

- `npm run spec:setup` - First time authentication
- `npm run spec:review` - Run full review (starts API + GGA)
- `npm run spec:validate` - Quick validation with GGA
- `npm run copilot:start` - Start Copilot API server
- `npm run copilot:login` - Login to GitHub Copilot
- `npm run gga:run` - Run GGA code review manually
- `npm run gga:config` - Show GGA configuration

## Files to Review

- `REVIEW.md` - Your code review standards and rules
- `AGENTS.MD` - AI agent directives and behavior
- `.specify/memory/constitution.md` - Project constitution and guidelines
- `.gga` - GGA configuration file

## Troubleshooting

**GGA not found:**
Restart your terminal or run: `source ~/.bashrc` (or ~/.zshrc)

**Copilot API not responding:**
Make sure `npm run copilot:start` is running in a separate terminal

**Authentication issues:**
Run `npm run copilot:login` again
EOF

echo -e "${GREEN}Spec-kit workflow documentation created${NC}"

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "✅ GGA installed to: $GGA_INSTALL_DIR"
echo "✅ Copilot API installed to: $COPILOT_API_DIR"
echo "✅ Configuration files copied to: $CURRENT_REPO"
echo "✅ Pre-commit hook installed in: $CURRENT_REPO/.git/hooks"
echo "✅ Copilot API linked to node_modules"
echo ""
echo "Repository configured: $CURRENT_REPO"
echo ""
echo -e "${GREEN}📋 Spec-Kit Workflow Integrated!${NC}"
echo ""
echo "Quick Start:"
echo "  1. First time: npm run spec:setup"
echo "  2. Start API:  npm run copilot:start (keep running)"
echo "  3. Validate:   npm run spec:validate"
echo "  4. Commit:     git commit (auto-review with GGA)"
echo ""
echo "All Commands:"
echo "  📦 Spec-Kit Integration:"
echo "    - npm run spec:setup     : Initial authentication"
echo "    - npm run spec:review    : Full review (API + GGA)"
echo "    - npm run spec:validate  : Quick GGA validation"
echo ""
echo "  🤖 Copilot API:"
echo "    - npm run copilot:start  : Start API server"
echo "    - npm run copilot:login  : Authenticate"
echo ""
echo "  🛡️ GGA Commands:"
echo "    - npm run gga:run        : Run code review"
echo "    - npm run gga:config     : Show configuration"
echo ""
echo "📖 Documentation: See SPEC_WORKFLOW.md for detailed workflow"
echo ""
echo "GGA Commands:"
echo "  - gga run          : Run code review on staged files"
echo "  - gga config       : Show current configuration"
echo "  - gga help         : Show all available commands"
echo ""
echo "For Ultracite AI usage, visit: https://www.ultracite.ai/editors/vscode"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""
echo -e "${YELLOW}Note: Restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to use 'gga' command${NC}"
