---
name: js-clean-architecture
description: "Arquitectura limpia y refactorización de JavaScript moderno (ES6+, ES Modules) con JSDoc estilo Google. Úsala al escribir, auditar o refactorizar JavaScript de frontend: separar estado, I/O asíncrono, lógica pura y DOM, eliminar estado global mutable, anidamiento profundo y código espagueti."
---

# **SKILL: JavaScript Clean Architecture, JSDoc & Anti-Spaghetti Engineering (ES6+)**

## **1. Rol y Misión del Agente / Programador**

Actúas como un **Ingeniero de Software Senior especializado en JavaScript Moderno (ES6+ / ES Modules) y Clean Frontend Architecture**. Tu misión es diseñar, escribir, auditar y refactorizar código JavaScript garantizando que sea:

* **Modular y Desacoplado:** Separa estrictamente el enrutamiento/estado, la adquisición de datos (I/O asíncrono), la lógica de negocio (funciones puras) y la manipulación del DOM (presentación).
* **Predecible y Encapsulado:** Elimina las variables globales mutables sueltas (`let`) en la raíz del módulo y prohíbe las pirámides de anidamiento (`if/else` anidados).
* **Autodocumentado y Tipado sin Compilación:** Cumple rigurosamente con el estándar **Google-Style JSDoc** (`@fileoverview`, `@typedef`, `@param`, `@returns`, `@throws`), proporcionando contratos de datos estrictos tanto para humanos como para motores de inferencia (LSP/TypeScript Checkers) y agentes de IA.

---

## **2. Los 7 Mandamientos Anti-Spaghetti en JavaScript**

> 1. **Cero Estado Mutable Global en el Módulo:** Queda prohibido declarar variables mutables sueltas (`let vista; let migas; let titulo;`) en el nivel superior del archivo. El estado y las referencias al DOM deben encapsularse dentro de una clase controladora (usando campos privados `#`) o un objeto de contexto inyectado.
> 2. **Principio *Do One Thing* (SRP Estricto):** Una función jamás debe leer la URL (`window.location`), hacer peticiones de red (`fetch`/`leer`), transformar reglas de negocio y mutar el DOM (`replaceChildren`) todo al mismo tiempo. Cada paso debe vivir en una función o método con una única razón para cambiar.
> 3. **Cláusulas de Guarda (*Early Returns*) y Despacho Limpio:** Prohibido anidar bloques `if / else` a más de un nivel de profundidad. Utiliza retornos tempranos (*Guard Clauses*) y delega cada caso de uso o ruta a funciones resolutoras específicas.
> 4. **Tipado y Contratos Explícitos con JSDoc:** Toda función, método, clase y estructura de datos compleja debe estar documentada con JSDoc válido (`/** ... */`). Usa `@typedef` al inicio del módulo para definir las estructuras de objetos (`Proyecto`, `PasoMiga`, `ResultadoVista`).
> 5. **Asincronía Consistente (`async/await` Puro):** Nunca mezcles `async/await` con cadenas `.then()` flotantes (*fire-and-forget*) dentro del mismo flujo. Toda operación asíncrona debe ser esperada (`await`) o paralelizada explícitamente con `Promise.all()`.
> 6. **Cacheo Único y Seguro del DOM:** Prohibido repetir verificaciones defensivas como `if (!vista) vista = document.getElementById("vista")` en múltiples funciones. Las referencias al DOM se capturan una sola vez al inicializar la aplicación.
> 7. **Manejo Centralizado de Errores (*Fail Fast & Error Boundary*):** Las funciones de negocio o resolución lanzan excepciones semánticas (`throw new DatosError(...)`) de inmediato cuando un dato es inválido. Un único bloque `try/catch` en el orquestador de ruta captura el error y decide cómo presentarlo en la interfaz.

---

## **3. Estándar Mandatorio: Documentación JSDoc (Google Style)**

En JavaScript moderno sin TypeScript, **JSDoc es el contrato arquitectónico**. Todo archivo y función debe respetar esta estructura:

### **A. Cabecera de Módulo (`@fileoverview` y `@module`)**
Debe aparecer en las primeras líneas del archivo usando asteriscos estándar (`*`, nunca guiones `-` sueltos que rompen el parser de JSDoc):

```javascript
/**
 * @fileoverview Punto de entrada del portal: coordina el enrutador SPA,
 * la carga de datos y la actualización del DOM.
 * @module app
 */
```

### **B. Definición de Tipos de Dominio (`@typedef`)**
En lugar de pasar objetos anónimos indocumentados, declara tus contratos debajo de los `import`:

```javascript
/**
 * @typedef {Object} PasoMiga
 * @property {string} texto - Etiqueta visible en la barra de navegación.
 * @property {string} href - Ruta relativa o absoluta del enlace.
 */
```

### **C. Funciones y Métodos (`@param`, `@returns`, `@throws`)**
1. **Descripción en Modo Imperativo:** Inicia con un verbo directo (*"Resuelve el proyecto activo..."*, *"Renderiza las migas de pan..."*).
2. **Parámetros (`@param`):** Especifica el tipo entre llaves `{Tipo}`, el nombre del parámetro (entre corchetes `[param=default]` si es opcional) y su descripción.
3. **Retorno (`@returns`):** Especifica el tipo exacto devuelto (incluyendo `Promise<Tipo>` para funciones `async` o `{void}` si no retorna valor).
4. **Excepciones (`@throws`):** Documenta qué errores personalizados o nativos puede disparar la función.

---

## **4. Guía Operativa y Patrones de Refactorización**

### **Regla 1: Separación entre Lógica Pura y Efectos Secundarios (DOM / Red)**

* ❌ **Antipatrón (Spaghetti):** Leer `window.location.pathname` dentro de la misma función que hace `await leer(...)` y llama a `vista.replaceChildren(...)`. Imposible de testear sin navegador.
* ✔️ **Patrón Limpio:** Extraer funciones puras que reciben datos por parámetro y devuelven estructuras simples.

```javascript
/**
 * Extrae y decodifica los segmentos limpios de un pathname URL.
 *
 * @param {string} pathname - Ruta cruda del navegador (ej. '/cliente/2026/demo/').
 * @returns {string[]} Lista de segmentos decodificados sin cadenas vacías.
 */
function extraerSegmentosRuta(pathname) {
  return pathname.split("/").filter(Boolean).map(decodeURIComponent);
}
```

### **Regla 2: Eliminación de Pirámides `if/else` mediante Resolución de Vistas**

* ❌ **Antipatrón:** Un bloque `if (partes.length === 0) { ... } else { if (resto.length === 0) { ... } else { ... } }` donde cada rama muta variables externas y el DOM.
* ✔️ **Patrón Limpio:** Cada ruta tiene su propia función constructora que devuelve un contrato uniforme `{ nodoVista, migas }` y el orquestador simplemente pinta el resultado:

```javascript
/**
 * @typedef {Object} ResultadoRuta
 * @property {HTMLElement} nodoVista - Árbol DOM listo para inyectar en el contenedor principal.
 * @property {PasoMiga[]} migas - Lista de pasos para actualizar el breadcrumb.
 */
```

### **Regla 3: Encapsulamiento del Estado y Referencias DOM**

* ❌ **Antipatrón:** Variables globales `let vista; let migas; let sitio = "";` modificadas desde cualquier función del archivo.
* ✔️ **Patrón Limpio:** Encapsular las referencias DOM y el estado de configuración en una clase controladora con atributos privados (`#`) inicializados en el `constructor`.

---

## **5. Diagnóstico y Refactorización del Caso Real (`app.js`)**

Al auditar el código original de `app.js` bajo este Skill, se detectaron y corrigieron **5 problemas estructurales**:

| Problema en el `app.js` original | Impacto ("Spaghetti") | Solución Aplicada en la Refactorización |
| :--- | :--- | :--- |
| **1. Estado global suelto (`let vista, migas, sitio, titulo`)** | Cualquier función puede mutar el estado en orden impredecible; acoplamiento oculto. | Encapsulado dentro de la clase `PortalApp` usando propiedades privadas (`#vista`, `#migas`, `#sitio`, `#motion`). |
| **2. Función monolítica `mostrar()`** | Mezclaba parseo de URL, llamadas a API (`leer`), búsqueda de proyectos, actualización de migas, renderizado DOM y carga diferida de configuración. | Dividida en un despachador (`#resolverRuta`) y 3 métodos dedicados (`#cargarVistaRaiz`, `#cargarVistaCliente`, `#cargarVistaProyecto`). |
| **3. Pirámide de `if/else` anidados** | Dificulta la lectura y el mantenimiento al agregar nuevas rutas. | Reemplazada por *Early Returns* (cláusulas de guarda) lineales. |
| **4. Mezcla de `async/await` con `.then()`** | `if (!sitio) leerConfig().then(...)` generaba una promesa huérfana fuera del flujo de errores. | Convertido en un método `async #asegurarConfigSitio()` integrado limpiamente en el ciclo de vida. |
| **5. JSDoc roto con guiones `-`** | Los motores de autocompletado e IA no podían parsear `@param` ni `@returns`, y faltaban contratos en funciones clave. | Estandarizado al 100% con **Google-Style JSDoc**, incluyendo `@typedef`, `@param`, `@returns` y `@throws`. |

---

## **6. Matriz de Autoevaluación para Agentes y Desarrolladores**

Antes de dar por válido cualquier archivo `.js`, verifica el cumplimiento estricto de esta tabla:

| Criterio | Pregunta de Control | Estado Requerido |
| :--- | :--- | :--- |
| **Cero Globales Mutables** | ¿Se eliminaron todas las variables `let` sueltas en la raíz del módulo? | **SÍ** |
| **JSDoc Estándar** | ¿Todos los comentarios usan `*` (sin `-` iniciales) y definen `@param`, `@returns` y `@throws`? | **SÍ** |
| **Contratos `@typedef`** | ¿Los objetos complejos devueltos o recibidos están tipados con `@typedef`? | **SÍ** |
| **Responsabilidad Única (SRP)** | ¿Están separadas las funciones que calculan datos de las que mutan el DOM (`replaceChildren`)? | **SÍ** |
| **Cero Pirámides `if/else`** | ¿Se usaron cláusulas de guarda (`if (...) return ...`) en lugar de `else` anidados? | **SÍ** |
| **Asincronía Pura** | ¿Se evitó mezclar `async/await` con `.then()` sueltos? | **SÍ** |
| **Fail Fast & Error Boundary** | ¿Los errores de negocio lanzan instancias tipadas (`DatosError`) capturadas en un único punto? | **SÍ** |
