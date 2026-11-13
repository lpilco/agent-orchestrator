---
name: illustrator-extendscript
description: "Scripts de Adobe Illustrator en ExtendScript (ES3) y automatización vía osascript o Python: geometría con el eje Y invertido, ejecución silenciosa, no destructiva y con JSDoc. Úsala al escribir, auditar o automatizar scripts .jsx de Illustrator."
---

# **SKILL: Enterprise Adobe Illustrator ExtendScript (ES3) & OSAScript Clean Architecture**

## **1. Rol y Misión del Agente / Desarrollador**

Actúas como un **Senior Pipeline Technical Director (TD) e Ingeniero de Software especializado en Adobe Illustrator ExtendScript (ECMAScript 3) y Automatización IPC vía `osascript` / Python**. Tu objetivo es diseñar, estructurar, escribir y refactorizar scripts para Adobe Illustrator bajo los principios de **Clean Architecture**, **Geometría Cartesiana Determinista**, **Programación Defensiva No-Destructiva** y **Ejecución Desatendida Silenciosa**.

Todo código generado o auditado bajo este skill debe ser:

> * **100% Compatible con ECMAScript 3 (ES3) y Codificación Segura (ASCII/Unicode Escape):** Cumple estrictamente con el motor clásico de Adobe sin contaminar el ámbito global (`$.global`) y previene la corrupción de caracteres acentuados o tipográficos al cruzar el puente `osascript`.
> * **Silencioso y Atómico (`UserInteractionLevel`):** Suprime los cuadros de diálogo nativos de Illustrator durante la ejecución y garantiza la restauración del estado de la aplicación mediante bloques `try / catch / finally`.
> * **Consciente del Espacio Cartesiano Invertido:** Maneja explícitamente el eje $Y$ negativo hacia abajo propio de Illustrator (`[left, top, right, bottom]`) mediante helpers geométricos desacoplados.
> * **Modular, DRY y Documentado:** Separa la validación del payload inyectado, los helpers de DOM/geometría, el motor de maquetación y la exportación, documentando cada función con **Google-Style JSDoc**.

---

## **2. Los 8 Mandamientos de Calidad en Illustrator ExtendScript**

1. **Encapsulamiento Total en IIFE y Estándar ES3 Estricto:**
   * **Prohibido declarar variables o funciones fuera de la IIFE:** Toda constante, configuración y función auxiliar debe vivir dentro de `(function () { ... })();`. Declarar `var W = ...` en la raíz del archivo contamina el motor de Illustrator y puede fallar antes de entrar al bloque `try/catch`.
   * **Prohibido ES5/ES6+:** Nada de `let`, `const`, *arrow functions* (`=>`), *template literals*, `.forEach()`, `.map()`, ni `JSON` nativo.
2. **Cero Hardcoding y Contrato de Payload Inyectado:**
   * Los datos dinámicos (dimensiones, textos, rutas, paletas de color, listas de escenas/assets) deben inyectarse mediante un objeto global de entrada (ej. `PAYLOAD` o `CONFIG_DATA`) preparado por el orquestador externo (Python / Bash) y validarse al inicio del script (*Fail-Fast*).
   * Las métricas de diseño (márgenes, columnas, escalas, grosores de línea) deben centralizarse en un diccionario `LAYOUT_CONSTANTS` en la cabecera del script, eliminando los *"números mágicos"* dispersos en las funciones de dibujo.
3. **Supresión Segura de Diálogos con `try / catch / finally`:**
   * Todo script automatizado debe silenciar las alertas nativas de Illustrator (`UserInteractionLevel.DONTDISPLAYALERTS`) y **restaurar obligatoriamente** el nivel previo en el bloque `finally`.
   * Nunca uses `try ... finally` sin `catch (err)`: cualquier excepción debe capturarse y devolverse como texto estructurado (`"ERROR [Línea X]: ..."`) para que el proceso padre en Python o Bash registre el fallo sin colgar Illustrator.
4. **Dominio Estricto del Sistema de Coordenadas Cartesiano de Illustrator:**
   * En Illustrator, el origen `[0, 0]` es cartesiano: **el eje $X$ crece hacia la derecha, pero el eje $Y$ crece hacia arriba y decrece hacia abajo**.
   * Todo `artboardRect` o `geometricBounds` sigue el contrato `[left, top, right, bottom]`, donde `bottom = top - height`.
   * El método `pathItems.rectangle(top, left, width, height)` recibe **`top` ($Y$) como primer argumento y `left` ($X$) como segundo argumento**. Toda creación de primitivas debe encapsularse en helpers con firmas semánticas claras.
5. **Iteración Base-0 e Iteración Inversa en Mutaciones de Colección:**
   * A diferencia de After Effects, las colecciones de Illustrator (`documents`, `artboards`, `layers`, `pageItems`, `placedItems`) son **indexadas en base-0** (`0` hasta `length - 1`).
   * **Regla Crítica de Mutación:** Al incrustar imágenes (`placedItems[i].embed()`), cerrar documentos (`documents[i].close()`) o eliminar elementos, la colección muta su longitud en tiempo real. **Siempre se debe iterar en orden inverso** (`for (var i = col.length - 1; i >= 0; i--)`).
6. **Protección del Trabajo Manual y Ciclo de Vida de Documentos:**
   * Un script lector o exportador de activos creados a mano por un diseñador **jamás debe guardar cambios sobre el `.ai` original**; debe cerrarlo con `SaveOptions.DONOTSAVECHANGES`.
   * Un script generador que crea un `.ai` desde cero debe cerrar el documento generado al finalizar la exportación para liberar memoria RAM en lotes grandes.
7. **Higiene Tipográfica y Codificación ASCII Segura:**
   * Para evitar errores de codificación entre Python, `osascript` y ExtendScript, el código fuente `.jsx` debe mantenerse en **ASCII puro**, utilizando secuencias de escape Unicode explícitas para signos tipográficos (ej. `\u00B7` para `·`, `\u2013` para `–`, `\u2014` para `—`, `\u201C` y `\u201D` para `“”`, `\u00AB` y `\u00BB` para `«»`).
8. **Google-Style JSDoc Obligatorio:**
   * Toda función debe incluir documentación `/** ... */` detallando propósito en modo imperativo, `@param {Tipo} nombre - Descripción (especificando unidades o sistema de coordenadas)`, `@returns {Tipo}` y `@throws {Error}`.

---

## **3. Mitigación de Peculiaridades del DOM de Illustrator (*DOM Quirks*)**

### **A. Limitación de `preserveAspectRatio` en Archivos SVG Importados**
* **Problema:** Illustrator ignora el atributo `preserveAspectRatio="slice"` de los SVG exportados externamente, provocando desalineaciones al importarlos con `groupItems.createFromFile()`.
* **Regla:** Implementar siempre una estrategia doble al colocar gráficos externos:
  1. Buscar recursivamente un rectángulo guía con nombre acordado (ej. `"MARCO"` o `"BOUNDS"`), alinear el grupo respecto a su `geometricBounds` y eliminar el rectángulo guía.
  2. Si no existe guía (o es un archivo raster PNG/JPG vía `placedItems`), calcular un factor de escala *Cover* $\text{scale} = \max\left(\frac{W}{w_{\text{actual}}}, \frac{H}{h_{\text{actual}}}\right) \times 100$, redimensionar desde `Transformation.TOPLEFT` y centrar matemáticamente.

### **B. Orden de Apilamiento en Máscaras de Recorte (`GroupItem.clipped`)**
* **Problema:** Si se asigna `group.clipped = true` sin que el trazado recortador esté en la cima de la jerarquía interna del grupo, Illustrator recorta con el objeto equivocado o lanza error.
* **Regla:** Crear el rectángulo de recorte, moverlo explícitamente al principio del grupo mediante `clipPath.move(targetGroup, ElementPlacement.PLACEATBEGINNING)` y **solo entonces** activar `targetGroup.clipped = true`.

### **C. Resolución Resiliente de Fuentes (`app.textFonts`)**
* **Problema:** `app.textFonts.getByName(fontName)` lanza una excepción inmediata si el nombre PostScript de la fuente no está instalado en el sistema operativo.
* **Regla:** Nunca invocar `getByName` directamente en la lógica de dibujo. Utilizar una función resolvedora que reciba una lista priorizada de candidatos (`Array<string>`), capture la excepción en cada intento y devuelva `app.textFonts[0]` como respaldo seguro.

### **D. Exportación por Mesa de Trabajo (`artBoardClipping`)**
* **Problema:** `doc.exportFile()` exporta siempre la mesa de trabajo que esté activa en ese instante.
* **Regla:** Iterar sobre `doc.artboards`, invocar explícitamente `doc.artboards.setActiveArtboardIndex(i)` antes de cada `doc.exportFile()` y activar `exportOptions.artBoardClipping = true`.

---

## **4. Plantilla Canónica de Referencia (`.jsx`)**

```javascript
/**
 * @fileoverview Plantilla canónica para automatización de Adobe Illustrator vía osascript/Python.
 * Cumple con estándar ES3, aislamiento IIFE, manejo cartesiano seguro y arquitectura limpia.
 */
(function () {
    // =========================================================================
    // 1. CONSTANTES DE DISEÑO Y VALIDACIÓN DE PAYLOAD (Cero Hardcoding)
    // =========================================================================
    var LAYOUT_DEFAULTS = {
        gridGap: 240,
        exportScale: 100
    };

    /**
     * Valida que el payload global inyectado por el orquestador externo exista y sea íntegro.
     *
     * @param {Object} payload - Objeto de datos inyectado en el entorno global.
     * @returns {Object} El payload validado.
     * @throws {Error} Si el payload o sus propiedades obligatorias faltan.
     */
    function validatePayload(payload) {
        if (typeof payload === "undefined" || !payload) {
            throw new Error("Payload de entrada no definido en el entorno global.");
        }
        if (!payload.width || !payload.height || !payload.outputAiPath) {
            throw new Error("El payload carece de dimensiones o ruta de salida obligatoria.");
        }
        return payload;
    }

    // =========================================================================
    // 2. HELPERS DE DOM, COLOR, TIPOGRAFÍA Y GEOMETRÍA (DRY & SRP)
    // =========================================================================

    /**
     * Convierte un código hexadecimal (#RRGGBB) en una instancia nativa RGBColor.
     *
     * @param {string} hexString - Color en formato hexadecimal (ej. "#FDB913").
     * @returns {RGBColor} Objeto de color RGB de Illustrator.
     */
    function createRgbColor(hexString) {
        var cleanHex = hexString.charAt(0) === "#" ? hexString.substring(1) : hexString;
        var color = new RGBColor();
        color.red = parseInt(cleanHex.substr(0, 2), 16);
        color.green = parseInt(cleanHex.substr(2, 2), 16);
        color.blue = parseInt(cleanHex.substr(4, 2), 16);
        return color;
    }

    /**
     * Resuelve la primera fuente disponible en el sistema a partir de una lista de candidatos PostScript.
     *
     * @param {Array<string>} fontCandidates - Nombres PostScript ordenados por prioridad.
     * @returns {TextFont} La fuente encontrada o la primera fuente del sistema por defecto.
     */
    function resolveFont(fontCandidates) {
        if (fontCandidates && fontCandidates.length) {
            for (var i = 0; i < fontCandidates.length; i++) {
                try {
                    return app.textFonts.getByName(fontCandidates[i]);
                } catch (fontErr) {
                    // Continúa probando con el siguiente candidato
                }
            }
        }
        return app.textFonts[0];
    }

    /**
     * Cierra un documento si ya se encuentra abierto en Illustrator para permitir su regeneración limpia.
     *
     * @param {string} targetFilePath - Ruta del archivo .ai a verificar.
     * @returns {void}
     */
    function closeDocumentIfOpen(targetFilePath) {
        var targetFsName = new File(targetFilePath).fsName;
        for (var i = app.documents.length - 1; i >= 0; i--) {
            var doc = app.documents[i];
            try {
                if (doc.fullName.fsName === targetFsName) {
                    doc.close(SaveOptions.DONOTSAVECHANGES);
                }
            } catch (err) {
                // Ignora documentos nuevos aún no guardados en disco (sin fullName)
            }
        }
    }

    /**
     * Aplica una máscara de recorte rectangular (Clipping Mask) a un GroupItem existente.
     *
     * @param {GroupItem} group - Grupo vectorial o raster que será recortado.
     * @param {number} left - Coordenada X izquierda.
     * @param {number} top - Coordenada Y superior (cartesiana).
     * @param {number} width - Ancho del recorte.
     * @param {number} height - Alto del recorte.
     * @returns {void}
     */
    function applyRectangularClip(group, left, top, width, height) {
        var clipPath = group.pathItems.rectangle(top, left, width, height);
        clipPath.move(group, ElementPlacement.PLACEATBEGINNING);
        group.clipped = true;
    }

    /**
     * Incrusta de forma segura todos los archivos enlazados (PlacedItems) del documento iterando en reversa.
     *
     * @param {Document} doc - Documento activo de Illustrator.
     * @returns {void}
     */
    function embedAllPlacedItems(doc) {
        for (var i = doc.placedItems.length - 1; i >= 0; i--) {
            try {
                doc.placedItems[i].embed();
            } catch (embedErr) {
                // Continúa si un elemento individual ya fue convertido
            }
        }
    }

    // =========================================================================
    // 3. ORQUESTADOR DE CONSTRUCCIÓN Y CICLO DE VIDA SILENCIOSO
    // =========================================================================

    /**
     * Ejecuta el flujo principal de generación del documento Illustrator.
     *
     * @param {Object} data - Payload validado.
     * @returns {string} Mensaje de éxito para el orquestador externo.
     */
    function executePipeline(data) {
        closeDocumentIfOpen(data.outputAiPath);

        var doc = app.documents.add(DocumentColorSpace.RGB, data.width, data.height);
        // Lógica de maquetación desacoplada...
        embedAllPlacedItems(doc);

        var outFile = new File(data.outputAiPath);
        doc.saveAs(outFile, new IllustratorSaveOptions());
        var totalArtboards = doc.artboards.length;
        doc.close(SaveOptions.DONOTSAVECHANGES);

        return "OK artboards=" + totalArtboards;
    }

    var previousInteractionLevel = app.userInteractionLevel;
    app.userInteractionLevel = UserInteractionLevel.DONTDISPLAYALERTS;

    try {
        var validData = validatePayload(typeof EXT_PAYLOAD !== "undefined" ? EXT_PAYLOAD : null);
        return executePipeline(validData);
    } catch (err) {
        var lineStr = err.line ? " [Linea " + err.line + "]" : "";
        return "ERROR" + lineStr + ": " + err.message;
    } finally {
        app.userInteractionLevel = previousInteractionLevel;
    }
})();
```

---

## **5. Matriz de Auditoría Rápida para Agentes y Desarrolladores**

| Criterio | Pregunta de Control | Estado Requerido |
| :--- | :--- | :--- |
| **Aislamiento IIFE Total** | ¿Todas las variables (`W`, `H`, constantes) y funciones están **dentro** de `(function () { ... })()`? | **SÍ** |
| **Compatibilidad ES3 + ASCII** | ¿El código usa solo sintaxis ES3 y secuencias `\uXXXX` en lugar de caracteres no-ASCII directos? | **SÍ** |
| **Gestión de Alertas Segura** | ¿Se silencia `UserInteractionLevel.DONTDISPLAYALERTS` y se restaura en `finally` junto con un `catch (err)`? | **SÍ** |
| **Coordenadas Cartesianas** | ¿Se respeta `rectangle(top, left, w, h)` y `[left, top, right, bottom]` donde `bottom = top - height`? | **SÍ** |
| **Iteración Inversa en Mutaciones** | ¿Los bucles sobre `placedItems` (para `.embed()`) y `documents` (para `.close()`) iteran de atrás hacia adelante? | **SÍ** |
| **Orden de Clipping Mask** | ¿El trazado de recorte se mueve con `ElementPlacement.PLACEATBEGINNING` antes de `group.clipped = true`? | **SÍ** |
| **Cero Números Mágicos** | ¿Los márgenes, columnas, escalas y tamaños tipográficos están centralizados en un bloque de constantes? | **SÍ** |
| **Google-Style JSDoc** | ¿Todas las funciones cuentan con bloque `/** ... */` con `@param`, `@returns` y `@throws`? | **SÍ** |
