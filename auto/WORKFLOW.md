# Workflow: Configuración Automatizada de Repositorios

## 🎯 Objetivo

Configurar automáticamente **cualquier repositorio** con:
- GGA (Guardian Anget) para code review automatizado
- SpecKit para metodología Spec-First
- Copilot API para integración con AI
- Estándares de código (AGENTS.MD, REVIEW.md)
- Pre-commit hooks
- VS Code extensions

## 📋 Escenarios de Uso

### 1. Setup de un Proyecto Nuevo

```powershell
# 1. Crear proyecto
mkdir mi-nuevo-proyecto
cd mi-nuevo-proyecto
git init

# 2. Ejecutar bootstrap
C:\ruta\al\gga-copilot\auto\bootstrap.ps1

# 3. Personalizar configuración
code .gga              # Configurar provider y API key
code AGENTS.MD         # Adaptar directivas del AI
code REVIEW.md         # Personalizar checklist

# 4. Empezar a trabajar
mkdir specs\features\auth
code specs\features\auth\spec.md
gga generate           # Generar código desde spec
git add . && git commit -m "feat: authentication"
```

### 2. Setup de un Proyecto Existente

```powershell
# 1. Ir al proyecto
cd C:\proyectos\mi-app-existente

# 2. Ejecutar bootstrap con Force (sobrescribe configs)
C:\ruta\al\gga-copilot\auto\bootstrap.ps1 -Force

# 3. Revisar configs existentes
code .gga              # Asegurarse de no sobrescribir settings importantes

# 4. Validar setup
C:\ruta\al\gga-copilot\auto\validate.ps1

# 5. Migrar código gradualmente
# - Empezar con specs para nuevas features
# - Ir migrando código legacy a nuevos estándares
```

### 3. Setup de Múltiples Proyectos (Batch)

```powershell
# crear-script-batch.ps1

$proyectos = @(
    "C:\proyectos\backend-api",
    "C:\proyectos\frontend-app",
    "C:\proyectos\mobile-app"
)

$ggaBootstrap = "C:\ruta\al\gga-copilot\auto\bootstrap.ps1"

foreach ($proyecto in $proyectos) {
    Write-Host "Configurando $proyecto..." -ForegroundColor Cyan
    
    if (Test-Path $proyecto) {
        & $ggaBootstrap $proyecto -Force
        Write-Host "✓ $proyecto configurado" -ForegroundColor Green
    } else {
        Write-Host "✗ $proyecto no existe" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Batch setup completado!" -ForegroundColor Green
```

### 4. Setup con Configuración Personalizada

```powershell
# 1. Copiar configuración de ejemplo
cp C:\ruta\al\gga-copilot\auto\bootstrap.config.example.ps1 .\mi-config.ps1

# 2. Personalizar mi-config.ps1
code .\mi-config.ps1

# 3. Ejecutar con configuración personalizada
# (Modificar bootstrap.ps1 para leer mi-config.ps1)
```

### 5. Setup de Equipo/Organización

```powershell
# Setup centralizado para toda la organización

# 1. Fork gga-copilot a tu organización
# git clone https://github.com/tu-org/gga-copilot-custom.git

# 2. Personalizar archivos en auto/
# - AGENTS.MD: Estándares de tu empresa
# - REVIEW.md: Checklist específico
# - CONSTITUTION.md: Arquitectura de tu stack

# 3. Distribuir a los devs
# Cada dev ejecuta:
git clone https://github.com/tu-org/gga-copilot-custom.git
cd gga-copilot-custom/auto
.\bootstrap.ps1

# 4. Updates automáticos
# Los devs hacen git pull en gga-copilot-custom
# Y re-ejecutan bootstrap.ps1 -Force
```

## 🔄 Workflow Diario

### Desarrollo con Spec-First

```bash
# 1. Crear spec para nueva feature
mkdir specs/features/user-notifications
code specs/features/user-notifications/spec.md

# spec.md:
# - Descripción de la feature
# - Casos de uso
# - Aceptación criteria

# 2. Crear plan de implementación
code specs/features/user-notifications/plan.md

# plan.md:
# - Arquitectura
# - Componentes a crear
# - Pasos de implementación
# - Tests a escribir

# 3. Implementar con asistencia de AI
# El AI lee AGENTS.MD y sabe:
# - Qué patrones usar
# - Qué evitar
# - Cómo estructurar el código

# 4. Pre-commit review automático
git add .
git commit -m "feat: user notifications"
# GGA ejecuta automáticamente y valida contra REVIEW.md

# 5. Si falla la review
gga review --verbose
# Corregir issues
git add .
git commit --amend

# 6. Push
git push origin feature/user-notifications
```

### Code Review Manual

```bash
# Ver diff con contexto
gga diff

# Review manual con GGA
gga review --interactive

# Ver específicamente qué validaciones fallan
gga review --detailed

# Review de archivos específicos
gga review src/services/UserService.ts
```

### Validación de Setup

```powershell
# Verificar que todo esté configurado
.\validate.ps1

# Verificar en otro proyecto
.\validate.ps1 C:\otro-proyecto
```

## 🏢 Setup CI/CD

### GitHub Actions

```yaml
# .github/workflows/gga-review.yml
name: GGA Code Review

on:
  pull_request:
    branches: [ main, develop ]

jobs:
  review:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup GGA
        run: |
          curl -sSL https://raw.githubusercontent.com/tu-org/gga-copilot/main/auto/bootstrap.sh | bash
          echo "GGA_PROVIDER=openai" >> .gga
          echo "GGA_API_KEY=${{ secrets.OPENAI_API_KEY }}" >> .gga
      
      - name: Run GGA Review
        run: gga review --ci
        
      - name: Validate Specs
        run: spec validate
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - validate

gga-review:
  stage: validate
  image: node:18
  before_script:
    - apt-get update && apt-get install -y git
    - bash <(curl -sSL https://raw.githubusercontent.com/tu-org/gga-copilot/main/auto/bootstrap.sh)
    - echo "GGA_PROVIDER=openai" >> .gga
    - echo "GGA_API_KEY=$OPENAI_API_KEY" >> .gga
  script:
    - gga review --ci
    - spec validate
  only:
    - merge_requests
```

### Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: Bash@3
    displayName: 'Setup GGA'
    inputs:
      targetType: 'inline'
      script: |
        curl -sSL https://raw.githubusercontent.com/tu-org/gga-copilot/main/auto/bootstrap.sh | bash
        echo "GGA_PROVIDER=openai" >> .gga
        echo "GGA_API_KEY=$(OPENAI_API_KEY)" >> .gga
  
  - task: Bash@3
    displayName: 'Run GGA Review'
    inputs:
      targetType: 'inline'
      script: gga review --ci
```

## 📊 Métricas y Monitoreo

### Tracking de Adopción

```powershell
# Script para verificar qué proyectos tienen GGA instalado

$proyectos = Get-ChildItem "C:\proyectos" -Directory

foreach ($p in $proyectos) {
    $hasGGA = Test-Path "$($p.FullName)\.gga"
    $hasSpecs = Test-Path "$($p.FullName)\specs"
    $hasReview = Test-Path "$($p.FullName)\REVIEW.md"
    
    [PSCustomObject]@{
        Proyecto = $p.Name
        GGA = $hasGGA
        Specs = $hasSpecs
        Review = $hasReview
        Completo = ($hasGGA -and $hasSpecs -and $hasReview)
    }
}
```

### Dashboard de Calidad

```bash
# Generar reporte de calidad del código

echo "# Code Quality Report" > quality-report.md
echo "Generated: $(date)" >> quality-report.md
echo "" >> quality-report.md

# GGA stats
echo "## GGA Reviews" >> quality-report.md
gga stats --last-month >> quality-report.md

# Spec coverage
echo "## Spec Coverage" >> quality-report.md
spec coverage >> quality-report.md

# Lint stats
echo "## Linter Results" >> quality-report.md
npm run lint -- --format json | jq '.summary' >> quality-report.md
```

## 🔐 Seguridad

### Manejo de API Keys

```powershell
# NO hacer esto:
echo "GGA_API_KEY=sk-123456789" > .gga

# Hacer esto:
# 1. Usar variables de entorno
$env:GGA_API_KEY = "sk-123456789"
echo "GGA_API_KEY=$env:GGA_API_KEY" > .gga

# 2. Agregar .gga al .gitignore
echo ".gga" >> .gitignore

# 3. Usar secretos del sistema
# Windows Credential Manager
# Linux/Mac: keyring, pass, etc.
```

### .gitignore Recomendado

```gitignore
# GGA
.gga
.gga-cache/

# Secrets
.env
.env.local
*.key
*.pem

# Specs locales (opcional)
specs/.drafts/
```

## 🎓 Training del Equipo

### Workshop de Onboarding

```markdown
# Workshop: GGA + SpecKit

## Día 1: Instalación y Configuración (2 horas)
- Ejecutar bootstrap.ps1 en proyecto personal
- Personalizar AGENTS.MD para el stack del equipo
- Crear primera spec simple

## Día 2: Spec-First Methodology (3 horas)
- Escribir spec completa para una feature
- Implementar siguiendo el spec
- Ver cómo GGA valida automáticamente

## Día 3: AI-Assisted Development (2 horas)
- Usar Copilot con AGENTS.MD
- Generar código desde specs
- Debugging con AI context

## Día 4: Code Review & Quality (2 horas)
- Entender REVIEW.md
- Personalizar checklist del equipo
- Integrar con PR workflow

## Día 5: CI/CD Integration (1 hora)
- Setup en GitHub Actions / GitLab CI
- Validaciones automáticas
- Métricas y reportes
```

### Recursos de Aprendizaje

```markdown
# Recursos para el equipo

## Documentación
- [GGA README](../README.md)
- [SpecKit Guide](https://github.com/github/spec-kit)
- [AI Code Review Best Practices](...)

## Videos (crear internamente)
- Setup rápido (5 min)
- Spec-First methodology (15 min)
- Personalización avanzada (20 min)

## Ejemplos
- Ver specs/ en gga-copilot para ejemplos
- Proyectos de referencia del equipo

## Soporte
- Canal de Slack: #gga-support
- Wiki interno: confluence.empresa.com/gga
- Office hours: Viernes 15:00-16:00
```

## 🚀 Next Steps

1. **Para empezar hoy**: Ejecuta `bootstrap.ps1` en un proyecto de prueba
2. **Para el equipo**: Personaliza AGENTS.MD y REVIEW.md para tu stack
3. **Para la organización**: Fork el repo y crea tu versión customizada
4. **Para CI/CD**: Integra GGA en tu pipeline

## 📞 Support

- Issues: https://github.com/tu-org/gga-copilot/issues
- Docs: [auto/README.md](README.md)
- Slack: #gga-support
