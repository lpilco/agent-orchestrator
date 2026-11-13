---
name: macos-command-launchers
description: "Lanzadores .command de doble clic para macOS y scripting defensivo en bash/zsh: rutas canónicas, fail fast, traps de limpieza, entornos virtuales idempotentes y logs legibles. Úsala al crear o revisar un .command o un script de shell para usuarios de Mac."
---

# **SKILL: Enterprise macOS .command Launcher & Shell Scripting**

## **1. Identidad y Misión del Agente / Ingeniero**

Eres un **Ingeniero Senior de Infraestructura y Automatización en macOS**, especializado en scripting defensivo en shell (`bash` / `zsh`) para entornos UNIX y empaquetado de ejecutables de doble clic mediante el subsistema `.command`.

Tu objetivo es diseñar y escribir lanzadores `.command` con nivel de confiabilidad empresarial (*production-grade*), garantizando:

> * **Determinismo de Ejecución:** Cero asunciones sobre el directorio de trabajo activo (*working directory*); resolución canónica de rutas relativas y enlaces simbólicos.
> * **Programación Defensiva (Fail Fast & Traps):** Interrupción controlada ante errores, gestión de señales del sistema (`INT`, `TERM`, `EXIT`) y limpieza de recursos temporales.
> * **Aislamiento de Entorno y Auto-Provisioning:** Detección, creación y activación idempotente de entornos virtuales (`venv`), verificación de dependencias y ejecución segura de runtimes (Python, Node, Go, `osascript`).
> * **Experiencia de Usuario de Terminal (macOS UX):** Prevención del cierre abrupto de la ventana de Terminal al finalizar o fallar, y logging limpio con colores ANSI direccionado correctamente a `stdout` y `stderr`.

---

## **2. Los 7 Mandamientos de Calidad para `.command`**

> 1. **Modo Defensivo Inviolable (`set -euo pipefail`):** Todo lanzador debe comenzar con banderas estrictas:
>    - `-e`: Detener ejecución inmediata ante cualquier comando con código de salida distinto de 0.
>    - `-u`: Tratar variables no declaradas como errores fatales.
>    - `-o pipefail`: Propagar el código de fallo a lo largo de cualquier tubería (`pipeline`).
> 2. **Resolución Determinista del Directorio de Origen:** Queda terminantemente prohibido asumir que el script corre desde la carpeta del proyecto. Al abrir un archivo `.command` desde Finder, macOS inicia el proceso en `$HOME`. El script **debe** resolver y mutar su contexto al directorio físico donde reside el propio script.
> 3. **Quoting Absoluto de Rutas:** Ninguna variable de ruta puede expandirse sin comillas dobles (`"$DIR"`). Los sistemas de archivos en macOS utilizan frecuentemente espacios en blanco (ej. `Google Drive`, `Application Support`, nombres de carpetas de usuario).
> 4. **Ciclo de Vida Idempotente del Entorno (`.venv`):** Si el script orquesta una herramienta de backend (como Python), debe verificar si el entorno virtual existe. Si no existe, debe crearlo e instalar dependencias silenciosamente antes de invocar la lógica principal, sin duplicar trabajo en ejecuciones subsecuentes.
> 5. **Captura Obligatoria de Salida (Pause-on-Exit):** macOS cierra la ventana de Terminal inmediatamente al completar un `.command`. El script debe atrapar (`trap`) el cierre tanto por éxito como por fallo, solicitando confirmación al usuario (`read -r`) antes de finalizar la sesión.
> 6. **Separación de Flujos de Mensajes (Logging vs. Payloads):** Mensajes informativos de progreso van a `stdout`; mensajes de advertencia, diagnósticos y errores van exclusivamente a `stderr` (`>&2`). Los códigos de escape ANSI deben reservarse para la terminal interactiva.
> 7. **Modularidad y Responsabilidad Única (SRP):** El script debe descomponerse en funciones independientes: validación de requisitos, preparación de entorno, ejecución del proceso principal y rutinas de salida. Prohibidos los scripts lineales monolíticos sin funciones.

---

## **3. Compatibilidad de Shell en macOS (Bash vs. Zsh)**

Al seleccionar el intérprete para scripts `.command`, considera las particularidades de macOS:

1. **Bash (`#!/usr/bin/env bash`):**
   - macOS incluye por defecto GNU Bash 3.2 (congelado por licenciamiento GPLv3).
   - **Regla:** Si usas Bash, **no utilices características de Bash 4+** (como arrays asociativos `declare -A` o `globstar`). Mantén el código compatible con Bash 3.2 o utiliza utilidades POSIX universales.
2. **Zsh (`#!/bin/zsh` o `#!/usr/bin/env zsh`):**
   - Es el shell interactivo por defecto desde macOS Catalina (10.15).
   - Soporta sintaxis moderna nativa y manejo avanzado de arrays y cadenas sin dependencias externas.

---

## **4. Estructura y Estándares de Documentación (ShellDoc)**

Toda función dentro de un archivo `.command` debe incluir un bloque de documentación descriptivo:

```bash
# ==============================================================================
# Purpose:    Verify and provision the local Python virtual environment.
# Arguments:  None.
# Returns:    0 if environment is ready; 1 if Python 3 is missing.
# Outputs:    Logs setup status to stdout/stderr.
# ==============================================================================
```

---

## **5. Plantilla Canónica de Referencia: `launcher.command`**

Patrón de arquitectura de nivel empresarial para orquestar la ejecución de un backend modular (Python / `osascript`):

```bash
#!/usr/bin/env bash
# ==============================================================================
# Script:       run_safari_inspector.command
# Description:  Deterministic, resilient macOS launcher for Safari Inspector.
# Target OS:    macOS 10.15+
# Compatibility: Bash 3.2+ / POSIX
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuración y Constantes
# ------------------------------------------------------------------------------
readonly COLOR_RESET="\033[0m"
readonly COLOR_GREEN="\033[1;32m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_RED="\033[1;31m"
readonly COLOR_BLUE="\033[1;34m"

readonly VENV_DIR=".venv"
readonly REQUIREMENTS_FILE="requirements.txt"
readonly ENTRYPOINT_SCRIPT="src/main.py"

# Estado de salida para el trap final
EXIT_STATUS=0

# ------------------------------------------------------------------------------
# Funciones Utilitarias de Logging (SRP)
# ------------------------------------------------------------------------------
log_info() {
    printf "${COLOR_BLUE}[INFO]${COLOR_RESET} %s\n" "$1"
}

log_success() {
    printf "${COLOR_GREEN}[ÉXITO]${COLOR_RESET} %s\n" "$1"
}

log_warn() {
    printf "${COLOR_YELLOW}[ADVERTENCIA]${COLOR_RESET} %s\n" "$1" >&2
}

log_error() {
    printf "${COLOR_RED}[ERROR]${COLOR_RESET} %s\n" "$1" >&2
}

# ------------------------------------------------------------------------------
# Manejo de Salida y Pausa en Terminal
# ------------------------------------------------------------------------------
cleanup_and_exit() {
    local code=$?
    if [[ $code -ne 0 && $EXIT_STATUS -eq 0 ]]; then
        EXIT_STATUS=$code
    fi

    printf "\n"
    if [[ $EXIT_STATUS -eq 0 ]]; then
        printf "${COLOR_GREEN}✔ Proceso finalizado correctamente.${COLOR_RESET}\n"
    else
        printf "${COLOR_RED}✘ El script finalizó con errores (código de salida: %s).${COLOR_RESET}\n" "$EXIT_STATUS"
    fi

    # Pausa obligatoria para evitar que macOS cierre la ventana de Terminal
    printf "${COLOR_YELLOW}Presiona [ENTER] para cerrar esta ventana...${COLOR_RESET}"
    read -r _
    exit "$EXIT_STATUS"
}

# Atrapar señales de salida y corte del sistema
trap cleanup_and_exit EXIT INT TERM

# ------------------------------------------------------------------------------
# Resolución Canónica de Directorio (Inmune a Enlaces Simbólicos)
# ------------------------------------------------------------------------------
resolve_script_directory() {
    local source="${BASH_SOURCE[0]}"
    local dir=""

    # Resolver enlaces simbólicos iterativamente
    while [ -h "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done

    cd -P "$(dirname "$source")" && pwd
}

# ------------------------------------------------------------------------------
# Verificación de Dependencias del Sistema
# ------------------------------------------------------------------------------
check_system_prerequisites() {
    log_info "Verificando dependencias del sistema operativo..."

    if ! command -v python3 >/dev/null 2>&1; then
        log_error "Python 3 no está instalado en este sistema."
        log_error "Instálalo vía https://www.python.org o mediante: brew install python"
        EXIT_STATUS=1
        exit 1
    fi

    local py_version
    py_version="$(python3 --version 2>&1)"
    log_info "Intérprete detectado: $py_version"
}

# ------------------------------------------------------------------------------
# Aprovisionamiento Idempotente del Entorno Virtual (.venv)
# ------------------------------------------------------------------------------
provision_environment() {
    if [[ ! -d "$VENV_DIR" ]]; then
        log_warn "Entorno virtual no detectado. Creando '$VENV_DIR'..."
        python3 -m venv "$VENV_DIR" || {
            log_error "Fallo al inicializar el entorno virtual."
            EXIT_STATUS=2
            exit 2
        }
        log_success "Entorno virtual inicializado."
    fi

    # Activar venv de forma segura
    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"

    # Actualizar pip e instalar dependencias si requirements.txt existe
    if [[ -f "$REQUIREMENTS_FILE" ]]; then
        local marker_file="$VENV_DIR/.dependencies_installed"
        if [[ ! -f "$marker_file" || "$REQUIREMENTS_FILE" -nt "$marker_file" ]]; then
            log_info "Instalando / actualizando dependencias de $REQUIREMENTS_FILE..."
            pip install --quiet --upgrade pip
            pip install --quiet -r "$REQUIREMENTS_FILE" || {
                log_error "Error instalando paquetes requeridos."
                EXIT_STATUS=3
                exit 3
            }
            touch "$marker_file"
            log_success "Dependencias sincronizadas correctamente."
        fi
    fi
}

# ------------------------------------------------------------------------------
# Ejecución del Proceso Principal (Orquestador)
# ------------------------------------------------------------------------------
run_application() {
    if [[ ! -f "$ENTRYPOINT_SCRIPT" ]]; then
        log_error "No se encontró el punto de entrada principal: $ENTRYPOINT_SCRIPT"
        EXIT_STATUS=4
        exit 4
    fi

    log_info "Iniciando ejecución de $ENTRYPOINT_SCRIPT..."
    printf "------------------------------------------------------------\n"

    # Ejecutar pasando todos los argumentos recibidos por el launcher
    python3 "$ENTRYPOINT_SCRIPT" "$@"
    local run_code=$?

    printf "------------------------------------------------------------\n"
    if [[ $run_code -eq 0 ]]; then
        log_success "Ejecución completada con éxito."
    else
        log_error "El backend retornó un código de fallo: $run_code"
        EXIT_STATUS=$run_code
        exit "$run_code"
    fi
}

# ------------------------------------------------------------------------------
# Entrypoint del Launcher
# ------------------------------------------------------------------------------
main() {
    local project_root
    project_root="$(resolve_script_directory)"
    cd "$project_root"

    log_info "Directorio de trabajo: $project_root"

    check_system_prerequisites
    provision_environment
    run_application "$@"
}

main "$@"
```

---

## **6. Gestión de Permisos macOS (TCC & Ejecución)**

Para que un archivo `.command` opere de manera autónoma, debe cumplir con dos capas de seguridad del sistema macOS:

### 1. Bit de Ejecución POSIX (`chmod`)
El archivo creado no podrá abrirse con doble clic hasta asignarle permisos explícitos:
```bash
chmod +x ruta/al/archivo.command
```

### 2. Atributos Extendidos de Cuarentena (Gatekeeper)
Si el script fue descargado de internet o transferido mediante AirDrop/ZIP, macOS le asignará el flag `com.apple.quarantine`, impidiendo su apertura directa:
```bash
# Retirar bandera de cuarentena si el sistema bloquea la apertura
xattr -d com.apple.quarantine ruta/al/archivo.command 2>/dev/null || true
```

### 3. Permisos de Automatización (TCC)
Si el script invoca `osascript`, `Terminal.app` solicitará autorización al usuario la primera vez. El script debe prever fallos y orientar al usuario hacia:
> **Ajustes del Sistema > Privacidad y Seguridad > Automatización > Terminal**

---

## **7. Matriz de Auditoría Pre-Despliegue para el Agente**

Antes de dar por finalizado cualquier archivo `.command`, verifica los siguientes puntos:

> 1. [ ] **¿Banderas estrictas activas?** Se incluye `set -euo pipefail` inmediatamente después del *shebang*.
> 2. [ ] **¿Rutas protegidas con comillas?** Todas las variables que contienen rutas están envueltas en comillas dobles (`"$DIR"`).
> 3. [ ] **¿Cambio de contexto garantizado?** El script resuelve su propia carpeta física con `dirname` / `readlink` y hace `cd` antes de operar.
> 4. [ ] **¿Pausa final garantizada?** Existe una rutina `trap` o bloque `read` que evita el cierre automático de la ventana de Terminal de macOS.
> 5. [ ] **¿Aprovisionamiento idempotente?** El `.venv` se crea y activa sin fallar si ya existía previamente.
> 6. [ ] **¿Salida legible y diferenciada?** Los mensajes de error se emiten por `stderr` (`>&2`) y los informativos por `stdout`.
> 7. [ ] **¿Sin comandos de Bash 4+ en entornos Bash 3.2?** El script no utiliza construcciones incompatibles con el intérprete por defecto de macOS.
