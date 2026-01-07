# GGA + SpecKit Bootstrap - Automated Setup

Este directorio contiene scripts de automatización para configurar **GGA (Guardian Anget)** y **SpecKit** en cualquier repositorio.

## ⚡ Instalación Rápida (Un Solo Comando)

### Windows (PowerShell)

```powershell
# Descargar y ejecutar automáticamente
irm https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto/quick-setup.ps1 | iex

# O con opciones personalizadas
irm https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto/quick-setup.ps1 | iex -Args "-SkipVSCode"
```

### Linux/macOS (Bash)

```bash
# Descargar y ejecutar automáticamente
curl -sSL https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto/quick-setup.sh | bash

# O con opciones personalizadas
curl -sSL https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto/quick-setup.sh | bash -s -- --skip-vscode
```

---

## 🚀 Uso Manual (Si ya clonaste el repo)

### Windows (PowerShell)

```powershell
# Configurar el repositorio actual
.\bootstrap.ps1

# Configurar otro repositorio
.\bootstrap.ps1 C:\ruta\al\proyecto

# Opciones avanzadas
.\bootstrap.ps1 -SkipVSCode -Force
```

### Linux/macOS (Bash)

```bash
# Configurar el repositorio actual
./bootstrap.sh

# Configurar otro repositorio
./bootstrap.sh /ruta/al/proyecto

# Opciones avanzadas
./bootstrap.sh --skip-vscode --force
```

## 📋 ¿Qué hace el script?

El script `bootstrap` realiza automáticamente:

1. **Verifica prerequisitos**: Git, Node.js, npm
2. **Instala herramientas**:
   - Copilot API (en `~/.local/share/yoizen/copilot-api` o `%LOCALAPPDATA%\yoizen\copilot-api`)
   - SpecKit (en `~/.local/share/yoizen/spec-kit` o `%LOCALAPPDATA%\yoizen\spec-kit`)
   - GGA system-wide
3. **Configura VS Code**:
   - Instala extensiones: Ultracite AI, GitHub Copilot, GitHub Copilot Chat
4. **Configura el repositorio objetivo**:
   - Copia `AGENTS.MD`, `REVIEW.md`, `CONSTITUTION.md`
   - Crea estructura de directorios (`.specify/memory`, `specs/`)
   - Inicializa GGA (`.gga`)

## 🎯 Opciones

### PowerShell

| Opción | Descripción |
|--------|-------------|
| `-SkipCopilotApi` | No instalar Copilot API |
| `-SkipSpecKit` | No instalar SpecKit |
| `-SkipGGA` | No instalar GGA |
| `-SkipVSCode` | No instalar extensiones de VS Code |
| `-Force` | Sobrescribir archivos de configuración existentes |

### Bash

| Opción | Descripción |
|--------|-------------|
| `--skip-copilot-api` | No instalar Copilot API |
| `--skip-speckit` | No instalar SpecKit |
| `--skip-gga` | No instalar GGA |
| `--skip-vscode` | No instalar extensiones de VS Code |
| `--force` | Sobrescribir archivos de configuración existentes |

## 📁 Estructura de archivos copiados

Después de ejecutar el bootstrap, tu repositorio tendrá:

```
tu-proyecto/
├── .gga                              # Configuración de GGA
├── AGENTS.MD                         # Directivas para el AI Agent
├── REVIEW.md                         # Checklist de revisión de código
├── .specify/
│   └── memory/
│       └── constitution.md           # Reglas arquitectónicas
└── specs/
    └── README.md                     # Guía de especificaciones
```

## 🔧 Personalización

### Para un proyecto específico

1. Edita los archivos en `auto/`:
   - `AGENTS.MD` - Comportamiento del AI
   - `REVIEW.md` - Criterios de revisión
   - `CONSTITUTION.md` - Reglas arquitectónicas

2. Ejecuta bootstrap en tus proyectos

### Para cambiar ubicaciones de instalación

Edita las variables al inicio de `bootstrap.ps1` o `bootstrap.sh`:

```powershell
# PowerShell
$Config = @{
    CopilotApiDir = "$env:LOCALAPPDATA\yoizen\copilot-api"
    SpecKitDir = "$env:LOCALAPPDATA\yoizen\spec-kit"
    GGADir = "$env:LOCALAPPDATA\yoizen\gga-copilot"
}
```

```bash
# Bash
COPILOT_API_DIR="$HOME/.local/share/yoizen/copilot-api"
SPEC_KIT_DIR="$HOME/.local/share/yoizen/spec-kit"
GGA_DIR="$HOME/.local/share/yoizen/gga-copilot"
```

## 🔄 Actualización

El script detecta automáticamente si las herramientas ya están instaladas y las actualiza con `git pull`.

Para actualizar manualmente:

```bash
# Actualizar GGA
cd ~/.local/share/yoizen/gga-copilot
git pull
./install.sh

# Actualizar Copilot API
cd ~/.local/share/yoizen/copilot-api
git pull
npm install

# Actualizar SpecKit
cd ~/.local/share/yoizen/spec-kit
git pull
```

## 📚 Uso después de la instalación

### 1. Configurar GGA

```bash
# Editar configuración
code .gga

# Ejemplo de .gga:
# PROVIDER=openai
# API_KEY=tu-api-key
# MODEL=gpt-4
```

### 2. Crear especificaciones

```bash
# Crear nueva feature spec
mkdir -p specs/features/nueva-feature
code specs/features/nueva-feature/spec.md
code specs/features/nueva-feature/plan.md
```

### 3. Usar GGA

```bash
# Revisar código antes de commit
gga review

# Generar código desde spec
gga generate

# Ver ayuda
gga --help
```

### 4. Usar SpecKit

```bash
# Crear nueva spec
spec create feature "User Authentication"

# Validar specs
spec validate

# Generar plan desde spec
spec plan
```

## 🛠 Troubleshooting

### "Git is not installed"
- **Windows**: Descarga desde https://git-scm.com/download/win
- **Linux**: `sudo apt install git` (Ubuntu/Debian) o `sudo yum install git` (RHEL/CentOS)
- **macOS**: `brew install git`

### "Node.js is not installed"
- Descarga desde https://nodejs.org/
- O usa nvm: https://github.com/nvm-sh/nvm

### "VS Code CLI not found"
- Abre VS Code → `Ctrl+Shift+P` → "Shell Command: Install 'code' command in PATH"

### "Permission denied"
- **Windows**: Ejecuta PowerShell como Administrador
- **Linux/macOS**: Usa `chmod +x bootstrap.sh` y considera `sudo` si es necesario

### Scripts no ejecutan
- **PowerShell**: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Bash**: `chmod +x *.sh`

## 📖 Documentación adicional

- [GGA README](../README.md)
- [SpecKit en GitHub](https://github.com/github/spec-kit)
- [Copilot API](https://github.com/Yoizen/copilot-api)

## 🤝 Contribuir

Para mejorar estos scripts:

1. Edita `bootstrap.ps1` o `bootstrap.sh`
2. Prueba en un repositorio de prueba
3. Actualiza este README si añades opciones
4. Comparte los cambios con tu equipo

## 📝 Ejemplos de uso

### Configurar un nuevo proyecto NestJS

```powershell
# Crear proyecto
nest new mi-proyecto
cd mi-proyecto

# Configurar GGA + SpecKit
C:\ruta\al\gga-copilot\auto\bootstrap.ps1

# Personalizar AGENTS.MD para NestJS
code AGENTS.MD

# Crear primera spec
mkdir specs\features\user-module
code specs\features\user-module\spec.md
```

### Configurar múltiples proyectos

```bash
#!/bin/bash
# setup-all-projects.sh

PROJECTS=(
    "/home/user/proyecto1"
    "/home/user/proyecto2"
    "/home/user/proyecto3"
)

for project in "${PROJECTS[@]}"; do
    echo "Configurando $project..."
    ./bootstrap.sh "$project"
done
```

### CI/CD Integration

```yaml
# .github/workflows/setup.yml
name: Setup GGA + SpecKit

on:
  push:
    branches: [ main ]

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup GGA + SpecKit
        run: |
          curl -o bootstrap.sh https://raw.githubusercontent.com/Yoizen/gga-copilot/main/auto/bootstrap.sh
          chmod +x bootstrap.sh
          ./bootstrap.sh --skip-vscode
      
      - name: Validate specs
        run: gga validate
```

## 🎓 Metodología Spec-First

Este setup implementa la metodología **Spec-First**:

1. **Especificar** antes de codificar
2. **Planificar** la implementación
3. **Implementar** siguiendo el plan
4. **Revisar** con checklist automatizado
5. **Validar** contra la spec

Ver `REVIEW.md` para el checklist completo.
