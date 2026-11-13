---
name: after-effects-extendscript
description: "Scripts de Adobe After Effects en ExtendScript (ES3) y automatización desatendida vía osascript: sin diálogos modales, no destructivos (UndoGroup), modulares y con JSDoc. Úsala al escribir, auditar o automatizar scripts .jsx de After Effects."
---

# **SKILL: Enterprise After Effects ExtendScript (ES3) & OSAScript Clean Architecture**

## **1. Rol y Misión del Agente / Desarrollador**

Actúas como un **Senior Pipeline Technical Director (TD) e Ingeniero de Software especializado en Adobe ExtendScript (ECMAScript 3) y Automatización IPC vía `osascript`**. Tu objetivo es diseñar, estructurar, escribir y refactorizar scripts para Adobe After Effects bajo los principios de **Clean Architecture**, **Programación Defensiva No-Destructiva** y **Ejecución Desatendida Silenciosa**.

Todo código generado o auditado bajo este skill debe ser:

> * **100% Compatible con el Motor ES3 (ISO/IEC 16262 Ed. 3):** Respeta estrictamente las limitaciones del motor JavaScript clásico de After Effects sin contaminar el espacio de nombres global (`$.global`).
> * **Silencioso y Determinista en IPC (`osascript`):** Jamás bloquea la interfaz gráfica con cuadros de diálogo modales (`alert`, errores no capturados) y garantiza trazabilidad completa mediante logs estructurados.
> * **No-Destructivo (*Human-in-the-Loop Safe*):** Protege siempre el trabajo manual del artista validando estados sucios (`dirty`), evitando sobrescrituras accidentales y encapsulando mutaciones en grupos de deshacer (`UndoGroup`).
> * **Modular, DRY y Documentado:** Separa la configuración inyectada, las utilidades del DOM, la lógica de negocio y la exportación, documentando cada función con **Google-Style JSDoc**.

---

## **2. Los 8 Mandamientos de Calidad en ExtendScript + OSAScript**

1. **Estricto Estándar ECMAScript 3 (ES3) y Aislamiento IIFE:**
   * Queda **estrictamente prohibido** el uso de sintaxis ES5/ES6+: nada de `let`, `const`, *arrow functions* (`=>`), *template literals* (`` `...` ``), destructuring, `.forEach()`, `.map()`, `.filter()` ni `JSON.parse` / `JSON.stringify` nativos.
   * Todo script debe encapsularse en una **IIFE** (*Immediately Invoked Function Expression*) `(function () { ... })();` para evitar colisiones de variables en el motor persistente de After Effects.
2. **Cero Hardcoding e Inyección de Configuración:**
   * Prohibido quemar rutas absolutas del sistema de archivos, nombres de composiciones específicas o parámetros de negocio dentro de la lógica.
   * Toda ruta o parámetro externo debe inyectarse desde el orquestador (`osascript` / `.sh` / `.env`) en la cabecera de configuración o calcularse dinámicamente de forma relativa (`new Folder(...).parent.fsName`).
3. **Garantía de Cero Diálogos (*Zero-Dialog Guarantee*) y `try/catch` Global:**
   * Una excepción no capturada en ExtendScript abre la ventana modal *"Unable to execute script at line..."*, congelando After Effects y haciendo que futuras llamadas de `osascript` fallen con código `1`.
   * Todo el flujo principal dentro de la IIFE **debe** estar envuelto en un bloque `try { ... } catch (err) { ... }` que capture el mensaje, la línea (`err.line`) y el archivo (`err.fileName`), devolviendo un string estructurado al runner sin bloquear la UI.
4. **Guardas No-Destructivas (*Fail-Fast Guards*):**
   * **Dirty Guard:** Antes de crear un proyecto nuevo, cerrar o importar destructivamente, verificar `if (app.project && app.project.dirty)` y abortar con prefijo `"DETENIDO:"` para que el usuario guarde sus cambios manuales.
   * **Overwrite Guard:** En scripts generadores de proyectos (`.aep`), verificar si el archivo de destino o la composición maestra ya existe (`file.exists`) y detener la ejecución antes de destruir ajustes manuales previos.
5. **Principio DRY y Abstracción del DOM (Índices Base-1):**
   * Las colecciones de After Effects (`app.project.items`, `comp.layers`, `renderQueue.items`) usan **indexación base-1** (`1` hasta `numItems`).
   * Prohibido repetir bucles `for` en línea para buscar composiciones, apagar capas o limpiar la cola de render. Deben abstraerse en funciones auxiliares reutilizables.
6. **Principio *Do One Thing* (Responsabilidad Única / SRP):**
   * Desacopla el script en capas claras:
     1. **Configuración y Validación de Entorno (*Guards*)**.
     2. **Helpers de Infraestructura y DOM** (búsqueda, importación, gestión de color).
     3. **Operaciones de Dominio / Composición** (ensamblaje de capas, animación).
     4. **Persistencia y Cola de Exportación** (guardado en disco, envío a Media Encoder).
7. **Consistencia de Color y Desacoplamiento de Render (AME):**
   * Un proyecto creado mediante `app.newProject()` hereda preferencias volátiles de la estación de trabajo (ej. 32 bpc, espacio linealizado), alterando los colores corporativos. Siempre se debe normalizar explícitamente la gestión de color al inicializar un proyecto.
   * Dado que Adobe Media Encoder (AME) lee una instantánea en disco del archivo `.aep` (`*.aep_AME`), es **obligatorio ejecutar `app.project.save()`** inmediatamente antes de invocar `renderQueue.queueInAME()`.
8. **Google-Style JSDoc Obligatorio:**
   * Toda función debe incluir un bloque `/** ... */` especificando descripción en modo imperativo, `@param {Tipo} nombre - Descripción`, `@returns {Tipo}` y `@throws {Error}`.

---

## **3. Mitigación de Peculiaridades del DOM de After Effects (*DOM Quirks*)**

Cualquier código que manipule capas, formas o animaciones debe aplicar las siguientes reglas preventivas:

### **A. Invalidación de Referencias en Capas de Formas (*Shape Layers*)**
* **Problema:** Al invocar `.addProperty()` sobre un grupo vectorial (`ADBE Vector Group`), After Effects reconstruye el árbol de memoria y todas las referencias a propiedades hermanas guardadas previamente en variables quedan inválidas (*"Object is invalid"*).
* **Regla:** Nunca reutilices variables de propiedades de shapes tras añadir un nuevo elemento; vuelve a resolver la ruta jerárquica usando *Match Names* (`property("ADBE Root Vectors Group")...`).

### **B. Compensación de Escala al Emparentar (`layer.parent`)**
* **Problema:** Al asignar `childLayer.parent = parentLayer`, After Effects recalcula la escala de la capa hija en función de la escala actual del padre.
* **Regla:** Asigna el parentesco primero y aplica o resetea explícitamente la propiedad `Scale` (`ADBE Scale`) **después** de establecer `.parent`.

### **C. Dimensionalidad y Restricciones de `KeyframeEase`**
* **Problema:** Las propiedades espaciales (`Position`) requieren arreglos de `KeyframeEase` de **1 sola dimensión** `[ease]`, mientras que las propiedades de valor (`Scale`, `Opacity`) requieren tantos objetos `KeyframeEase` como dimensiones tenga el valor (`[easeX, easeY]` o `[ease]`). Además, un valor de `influence` igual a `0` lanza una excepción en tiempo de ejecución.
* **Regla:** Clampa siempre la influencia a un mínimo seguro (`Math.max(0.1, influence)`) y verifica `prop.isSpatial` antes de construir los arreglos de curvas.

### **D. Compatibilidad de *Track Mattes* (AE 2023+ vs. Legacy)**
* **Regla:** Encapsula la asignación de mates en un helper que verifique la existencia del método moderno `layer.setTrackMatte(matteLayer, TrackMatteType)` y apague explícitamente la visibilidad (`matteLayer.enabled = false`) de la capa usada como mate.

---

## **4. Estándares de Nomenclatura y Estructura de Archivos**

* **Constantes e Inyecciones Externas:** `UPPER_SNAKE_CASE` (ej. `DEFAULT_FPS`, `INPUT_COMP_NAME`).
* **Funciones y Variables Locales:** `camelCase` (ej. `findCompByName`, `configureColorSpace`).
* **Constructores / Clases Prototípicas (si aplican):** `PascalCase` (ej. `PipelineLogger`).
* **Prefijos de Estado de Retorno (Contrato con `osascript`):**
  * `"OK: ..."` -> Ejecución completada sin errores.
  * `"DETENIDO: ..."` -> Aborto preventivo seguro (proyecto sucio, archivo ya existente).
  * `"ERROR [Línea X]: ..."` -> Fallo capturado de ejecución o validación.

---

## **5. Plantilla Canónica de Referencia (`.jsx`)**

A continuación se presenta la estructura estándar que debe seguir cualquier script de After Effects bajo este skill:

```javascript
/**
 * @fileoverview Plantilla canónica para automatización de After Effects vía osascript.
 * Cumple con compatibilidad estricta ES3, arquitectura limpia, ejecución silenciosa
 * y guardas no-destructivas.
 */
(function () {
    // =========================================================================
    // 1. CONFIGURACIÓN E INYECCIÓN DE ENTORNO (Cero Hardcoding)
    // =========================================================================
    var CONFIG = {
        compName: typeof EXT_COMP_NAME !== "undefined" ? EXT_COMP_NAME : null,
        outputPath: typeof EXT_OUTPUT_PATH !== "undefined" ? EXT_OUTPUT_PATH : null,
        outputTemplate: typeof EXT_OM_TEMPLATE !== "undefined" ? EXT_OM_TEMPLATE : "High Quality",
        autoStartAME: typeof EXT_AUTO_START !== "undefined" ? Boolean(EXT_AUTO_START) : false,
        colorDepth: 8,
        workingSpace: "None"
    };

    var LOG_BUFFER = [];

    /**
     * Registra un mensaje técnico en el buffer de trazabilidad.
     *
     * @param {string} message - Mensaje descriptivo del evento.
     * @returns {void}
     */
    function logInfo(message) {
        LOG_BUFFER.push("[INFO] " + message);
    }

    // =========================================================================
    // 2. GUARDAS DE SEGURIDAD Y VALIDACIÓN (Fail-Fast)
    // =========================================================================

    /**
     * Valida que los parámetros inyectados obligatorios estén presentes.
     *
     * @param {Object} cfg - Diccionario de configuración del script.
     * @throws {Error} Si falta algún parámetro requerido.
     */
    function validateConfig(cfg) {
        if (!cfg.compName) {
            throw new Error("Parámetro obligatorio faltante: 'EXT_COMP_NAME'.");
        }
        if (!cfg.outputPath) {
            throw new Error("Parámetro obligatorio faltante: 'EXT_OUTPUT_PATH'.");
        }
    }

    /**
     * Verifica que el proyecto activo exista y no tenga cambios manuales sin guardar.
     *
     * @param {Project} proj - Instancia del proyecto de After Effects.
     * @returns {string|null} Mensaje de bloqueo si debe detenerse, o null si es seguro continuar.
     */
    function checkProjectSafety(proj) {
        if (!proj) {
            return "DETENIDO: No hay un proyecto activo en After Effects.";
        }
        if (proj.dirty) {
            return "DETENIDO: El proyecto abierto tiene cambios sin guardar. Guarda (Cmd+S) y vuelve a ejecutar.";
        }
        return null;
    }

    // =========================================================================
    // 3. UTILIDADES REUTILIZABLES DEL DOM (DRY & SRP)
    // =========================================================================

    /**
     * Busca una composición por su nombre exacto dentro del proyecto.
     *
     * @param {Project} proj - Instancia del proyecto activo.
     * @param {string} targetName - Nombre exacto de la composición buscada.
     * @returns {CompItem|null} La composición encontrada o null si no existe.
     */
    function findCompByName(proj, targetName) {
        for (var i = 1; i <= proj.numItems; i++) {
            var item = proj.item(i);
            if (item instanceof CompItem && item.name === targetName) {
                return item;
            }
        }
        return null;
    }

    /**
     * Elimina de la cola de render cualquier elemento previo asociado a una composición.
     *
     * @param {RenderQueue} rq - Cola de render del proyecto.
     * @param {string} compName - Nombre de la composición a limpiar.
     * @returns {number} Cantidad de elementos obsoletos eliminados.
     */
    function purgeRenderQueueByComp(rq, compName) {
        var removedCount = 0;
        for (var i = rq.numItems; i >= 1; i--) {
            var rqItem = rq.item(i);
            if (rqItem.comp && rqItem.comp.name === compName) {
                rqItem.remove();
                removedCount++;
            }
        }
        return removedCount;
    }

    /**
     * Encola una composición en el Render Queue y la transfiere a Adobe Media Encoder.
     *
     * @param {Project} proj - Proyecto activo (debe guardarse antes de transferir a AME).
     * @param {CompItem} comp - Composición a exportar.
     * @param {string} destFilePath - Ruta de archivo de salida.
     * @param {string} templateName - Nombre del preset del módulo de salida.
     * @param {boolean} startImmediately - True para iniciar la codificación en AME automáticamente.
     * @returns {void}
     * @throws {Error} Si Media Encoder no está disponible para recibir la cola.
     */
    function enqueueInMediaEncoder(proj, comp, destFilePath, templateName, startImmediately) {
        var rq = proj.renderQueue;
        var purged = purgeRenderQueueByComp(rq, comp.name);
        if (purged > 0) {
            logInfo("Items previos limpiados de Render Queue: " + purged);
        }

        var rqItem = rq.items.add(comp);
        var outModule = rqItem.outputModule(1);

        try {
            outModule.applyTemplate(templateName);
        } catch (templateErr) {
            logInfo("Aviso: Plantilla '" + templateName + "' no disponible (" + templateErr.message + ").");
        }

        outModule.file = new File(destFilePath);

        // Regla crítica: Guardar el proyecto antes de enviar a AME para actualizar la copia *.aep_AME
        proj.save();

        if (!rq.canQueueInAME) {
            throw new Error("Adobe Media Encoder no está disponible para recibir la cola.");
        }

        rq.queueInAME(startImmediately);
        logInfo("Enviado a AME: " + comp.name + " -> " + destFilePath);
    }

    // =========================================================================
    // 4. ORQUESTADOR PRINCIPAL CON CAPTURA SILENCIOSA DE ERRORES
    // =========================================================================
    try {
        validateConfig(CONFIG);

        var project = app.project;
        var safetyCheck = checkProjectSafety(project);
        if (safetyCheck !== null) {
            return safetyCheck;
        }

        var targetComp = findCompByName(project, CONFIG.compName);
        if (!targetComp) {
            throw new Error("No se encontró la composición '" + CONFIG.compName + "' en el proyecto.");
        }

        enqueueInMediaEncoder(
            project,
            targetComp,
            CONFIG.outputPath,
            CONFIG.outputTemplate,
            CONFIG.autoStartAME
        );

        return "OK\n" + LOG_BUFFER.join("\n");
    } catch (err) {
        var lineInfo = err.line ? " [Línea " + err.line + "]" : "";
        return "ERROR" + lineInfo + ": " + err.message + "\n" + LOG_BUFFER.join("\n");
    }
})();
```

---

## **6. Patrón de Inyección para el Runner Bash / `osascript` (`run_*.sh`)**

Para mantener el `.jsx` puro, testeable y libre de rutas quemadas, el script de shell calcula las rutas relativas a su ubicación (`$(dirname "$0")`), inyecta únicamente las variables necesarias antes de evaluar el archivo `.jsx` y escribe siempre el resultado en un archivo de log:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSX_FILE="${SCRIPT_DIR}/mi_script.jsx"
LOG_FILE="${SCRIPT_DIR}/mi_script_log.txt"

COMP_NAME="${1:?Error: Debes proporcionar el nombre de la composición}"
OUTPUT_PATH="${2:?Error: Debes proporcionar la ruta de salida}"

osascript -e "tell application id \"com.adobe.AfterEffects\"
    DoScript \"var EXT_COMP_NAME = '${COMP_NAME}'; var EXT_OUTPUT_PATH = '${OUTPUT_PATH}'; $.evalFile(new File('${JSX_FILE}'));\"
end tell" > "${LOG_FILE}" 2>&1

cat "${LOG_FILE}"
```

---

## **7. Matriz de Auditoría Rápida para Agentes y Desarrolladores**

Antes de dar por válida cualquier creación o refactorización de un script de After Effects, verifica cada criterio de la siguiente tabla:

| Criterio | Pregunta de Control | Estado Requerido |
| :--- | :--- | :--- |
| **Compatibilidad ES3** | ¿El código está libre de `let`, `const`, `=>`, template strings, `.forEach()` y `JSON` nativo? | **SÍ** |
| **Aislamiento IIFE** | ¿Todo el archivo está envuelto en `(function () { ... })();` sin fugas globales? | **SÍ** |
| **Cero Diálogos (`try/catch`)** | ¿Existe un `try / catch (err)` de nivel superior que reporte `err.line` y `err.message` sin usar `alert()`? | **SÍ** |
| **Cero Hardcoding** | ¿Las rutas y configuraciones provienen de un bloque `CONFIG` parametrizable o rutas relativas dinámicas? | **SÍ** |
| **Protección No-Destructiva** | ¿Se verifica `app.project.dirty` y la existencia previa de archivos `.aep` antes de sobrescribir? | **SÍ** |
| **Principio DRY en DOM** | ¿Las búsquedas en `app.project.items`, `comp.layers` y `renderQueue` están abstraídas en funciones? | **SÍ** |
| **Consistencia de Color** | Si se usa `app.newProject()`, ¿se fijan inmediatamente `bitsPerChannel`, `linearizeWorkingSpace` y `workingSpace`? | **SÍ** |
| **Sincronización con AME** | ¿Se invoca `project.save()` justo antes de `renderQueue.queueInAME()` limpiando duplicados previos? | **SÍ** |
| **Google-Style JSDoc** | ¿Todas las funciones internas tienen docstrings `/** ... */` con `@param`, `@returns` y `@throws`? | **SÍ** |
