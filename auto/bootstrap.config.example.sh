# ============================================================================
# GGA Bootstrap Configuration (Bash)
# ============================================================================
# Personaliza esta configuración para tu organización/equipo
#
# Copia este archivo como 'bootstrap.config.sh' para sobreescribir valores
# ============================================================================

# Repositorios de las herramientas
COPILOT_API_REPO_CONFIG="https://github.com/Yoizen/copilot-api.git"
SPEC_KIT_REPO_CONFIG="https://github.com/github/spec-kit.git"
GGA_REPO_CONFIG="https://github.com/Yoizen/gga-copilot.git"

# Ubicaciones de instalación (Linux/macOS)
COPILOT_API_DIR_CONFIG="$HOME/.local/share/yoizen/copilot-api"
SPEC_KIT_DIR_CONFIG="$HOME/.local/share/yoizen/spec-kit"
GGA_DIR_CONFIG="$HOME/.local/share/yoizen/gga-copilot"

# Extensiones de VS Code a instalar
VSCODE_EXTENSIONS_CONFIG=(
    "ultracite.ultracite-vscode"
    "github.copilot"
    "github.copilot-chat"
    # Añade más extensiones según tu stack:
    # "dbaeumer.vscode-eslint"
    # "esbenp.prettier-vscode"
    # "bradlc.vscode-tailwindcss"
)

# Archivos de configuración a copiar
# Formato: "origen:destino-relativo-al-repo"
CONFIG_FILES_CONFIG=(
    "AGENTS.MD:AGENTS.MD"
    "REVIEW.md:REVIEW.md"
    "CONSTITUTION.md:.specify/memory/constitution.md"
)

# Directorios a crear en el repositorio objetivo
DIRECTORIES_CONFIG=(
    ".specify/memory"
    "specs"
    "specs/features"
    "specs/bugs"
    "specs/architecture"
)

# Configuración por defecto de GGA
GGA_PROVIDER_DEFAULT="openai"  # openai, anthropic, local
GGA_MODEL_DEFAULT="gpt-4"
GGA_TEMPERATURE_DEFAULT="0.7"
GGA_MAX_TOKENS_DEFAULT="2000"

# Post-instalación: comandos a ejecutar después del setup
POST_INSTALL_NODE=(
    # "npm install -g @nestjs/cli"
    # "npm install -g typescript"
)

POST_INSTALL_PYTHON=(
    # "pip install black pylint"
)

# Personalización de mensajes
WELCOME_BANNER="GGA + SpecKit Bootstrap - Automated Setup"
SUCCESS_MESSAGE="Setup Complete! 🎉"
NEXT_STEPS_INTRO="Next steps:"
