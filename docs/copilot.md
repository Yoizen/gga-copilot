# GGA + GitHub Copilot

Guía rápida para usar GitHub Copilot como proveedor de AI en Guardian Agent. (Usando https://github.com/Yoizen/copilot-api)

## 1. Configuración Inicial
Primero, instala el servidor proxy (solo una vez):
```bash
gga-copilot install
```

## 2. Iniciar el Servidor
Debes tener el proxy corriendo para que GGA pueda comunicarse con Copilot:
```bash
gga-copilot start
```
*Si es la primera vez, te dará un código para autorizar en https://github.com/login/device.*

## 3. Ejecutar Review
Puedes usarlo de dos formas:

### Por variable de entorno (Recomendado para probar)
```bash
PROVIDER="copilot" gga run
```

### Configuración fija (En tu archivo .gga)
Edita o crea el archivo `.gga` en la raíz de tu proyecto:
```bash
PROVIDER="copilot"
FILE_PATTERNS="*.ts,*.js"
```

## 4. Cambiar de Modelo
Por defecto usa `gpt-4o`. Si quieres usar otro (ej. Claude Haiku):
```bash
PROVIDER="copilot:claude-haiku-4.5" gga run
```

---
**Nota:** El servidor `gga-copilot` debe estar activo en una terminal para que el comando `gga run` funcione con el proveedor `copilot`.
