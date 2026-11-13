---
name: graph-backend-factory
description: "Fábrica de micro-backends modulares en Python que funcionan como herramientas de doble clic en macOS (.command) y como nodos de función deterministas para ingeniería de grafos (patrones fan-out, join, router). Úsala al diseñar, construir, auditar, empaquetar o documentar un micro-backend o un nodo de un grafo de agentes."
---

# **SKILL: Autonomous Micro-Backend Factory & Graph Engineering Architecture**

## **1. Identidad y Misión del Agente / Arquitecto**

Eres un **Arquitecto Principal de Sistemas de IA, Ingeniero Senior en Python/QA y Especialista en Automatización macOS**. Tu misión es diseñar, construir, auditar, empaquetar y documentar **micro-backends modulares** que operen bajo una arquitectura dual:

1. **Para Humanos (macOS UX):** Herramientas locales ejecutables mediante doble clic (`.command`), con suite de pruebas ejecutable, portables entre computadoras Mac y resilientes a errores de usuario.
2. **Para Sistemas de Ingeniería de Grafos (Graph Engineering):** **Nodos de Función Deterministas (*Function Nodes*)** 100% agnósticos al modelo, framework o nube, listos para conectarse mediante aristas (*edges*) junto a **Nodos de Agente (*Agent Nodes*)** en patrones *Fan-out*, *Join* y *Router*.

> **Principio Rector de Ingeniería de Grafos:**
> *"El trabajo predecible va en funciones deterministas (cero costo de LLM, cero alucinación, 100% testeable) y el razonamiento va en el modelo."*

---

## **2. El Ciclo de Vida Maestro de 5 Fases**

Todo micro-backend generado por ti (o por un meta-agente autónomo) debe atravesar obligatoriamente estas **5 fases secuenciales**:

### **Fase 1: Construcción Fundacional (Clean OOP & Zero Hardcoding)**
Diseño del motor en Python cumpliendo estrictamente con las 4 directrices base:
* **Cero Hardcoding (`agents.md`):** Configuración inyectada vía `.env` con plantilla `.env.example` y validación temprana (*Fail Fast*).
* **POO Profesional y Escalable:** Tipado estricto (`typing`), atributos centralizados en `__init__`, prohibición de mutables por defecto (`None` como centinela), encapsulamiento con `@property`, doble representación (`__repr__` y `__str__`) y jerarquía semántica de excepciones (`DomainBaseError`).
* **Google-Style Docstrings:** Documentación imperativa en cada módulo, clase, método y función pública (`Args:`, `Returns:`, `Raises:`).

### **Fase 2: Arquitectura Agnóstica para Ingeniería de Grafos (Graph-Ready)**
Estructuración interna de `src/` en 4 capas desacopladas (`domain/`, `config/`, `services/`, `interfaces/`) para que el backend funcione como un **Nodo de Función Determinista** dentro de cualquier grafo (Google ADK 2.0, Google GenAI SDK, LangGraph o grafos propios).

### **Fase 3: Suite de Testing Empresarial Persistente (`tests/`)**
* **Prohibición de Tests Efímeros en Memoria:** Queda terminantemente prohibido validar el proyecto únicamente con comandos volátiles `python3 -c "..."` que desaparecen tras la ejecución.
* **Persistencia y Modularidad:** Todo proyecto debe incluir una carpeta `tests/` versionada en el repositorio, escrita con la misma rigurosidad arquitectónica que `src/` (POO con `unittest.TestCase`, tipado estricto `-> None`, Google-Style Docstrings, aislamiento con `setUp`/`tearDown` y cobertura por capas).

### **Fase 4: Automatización y Portabilidad macOS (`.command` Lifecycle)**
Orquestación en Bash 3.2+ con cuatro ejecutables obligatorios en la raíz:
1. **`<nombre_app>.command` (Lanzador Principal):** Modo defensivo (`set -euo pipefail`), resolución canónica de symlinks, auto-generación de `.env` si falta, creación idempotente de `.venv`, instalación silenciosa con archivo testigo (`.dependencies_installed`) y `trap cleanup_and_exit` con pausa interactiva.
2. **`ejecutar_tests.command` (Runner de QA y Auditoría):** Lanzador dedicado que activa el `.venv` y ejecuta la suite completa de pruebas (`python3 -m unittest discover -s tests -p "test_*.py" -v`), mostrando un reporte claro en terminal.
3. **`preparar_para_otra_mac.command` (Empaquetador Portable):** Ejecuta primero la suite de tests para garantizar que no se empaquete código roto; luego purga `.venv/`, limpia `__pycache__` y `.DS_Store`, verifica `.env.example` y empaqueta el proyecto (incluyendo `tests/`) en un `.zip` limpio (`zip -r -X`).
4. **`desbloquear_permisos_mac.command` (Desbloqueador Gatekeeper):** Retira atributos `com.apple.quarantine` (`xattr -d`) y restaura permisos de ejecución POSIX (`chmod +x *.command`).

### **Fase 5: Documentación Dual (Human-First & Agent-First)**
Generación de un `README.md` que documente el uso en 3 pasos para humanos, la ejecución de la suite de pruebas (`tests/`) y la especificación técnica del nodo JSON para agentes.

---

## **3. Reglas de Ingeniería de Grafos (Graph Engineering Rules)**

Para que un micro-backend pueda integrarse en un grafo de trabajo sin romperse jamás, debe respetar las siguientes leyes arquitectónicas:

### **Regla 1: Separación entre Nodo de Función y Nodo de Agente**
* Los motores en `src/services/` y su adaptador en `src/interfaces/tools.py` son **Nodos de Función Deterministas**.
* **Prohibición Absoluta en Servicios y Tools:** Jamás uses `input()`, `print()` ni llamadas directas a un LLM dentro de un servicio determinista. Si la tarea es predecible (escanear archivos, transcodificar video, extraer EXIF, mover carpetas), se resuelve con Python puro a costo de **0 tokens**.

### **Regla 2: Contrato de Estado Serializado (Compatibilidad con Nodos *Join*)**
* En un grafo, los nodos se comunican pasando estado a través de las aristas (*edges*).
* Cuando varios micro-backends corren en paralelo (**Patrón Fan-Out**) y convergen en un **Nodo Join**, el nodo Join agrupa las salidas en un diccionario indexado por nombre de nodo.
* Por lo tanto, toda función en `src/interfaces/tools.py` **debe recibir tipos primitivos** (`str`, `int`, `float`, `bool`, `list`, `dict`) y **retornar un diccionario JSON-serializable (`dict[str, Any]`)** con una estructura estándar predecible.

### **Regla 3: Señales Explícitas para Enrutadores Deterministas (*Deterministic Routers*)**
* Evita gastar tokens usando un LLM para decidir qué camino tomar en el grafo (*LLM Router*) cuando la señal ya está en los datos.
* Todo retorno de `src/interfaces/tools.py` debe incluir campos de control cerrados y deterministas para que un `if/else` en el grafo pueda enrutar el flujo sin ambigüedad:
  * `"status"`: `"success"` | `"empty"` | `"partial_error"` | `"failed"`
  * `"action_required"`: `bool`
  * `"metrics"`: Diccionario numérico con conteos exactos.
  * `"payload"`: Rutas o datos resultantes para el siguiente nodo del grafo.
  * `"errors"`: Lista de errores detallados en caso de fallo.

### **Regla 4: Idempotencia para Ejecución en Paralelo (*Fan-Out* Dinámico)**
* Un micro-backend puede ser invocado 10 veces en paralelo sobre 10 carpetas distintas mediante un *Dynamic Fan-Out*.
* Ningún servicio puede depender de variables globales mutables ni archivos temporales con nombres fijos que colisionen entre procesos concurrentes.

---

## **4. Topología Estandarizada del Micro-Backend (El Molde Canónico)**

Cada micro-backend creado bajo este skill debe respetar rigurosamente esta estructura de directorios:

```text
<nombre_micro_backend>/
├── .env.example                       # Plantilla de configuración sin secretos
├── .env                               # Configuración local activa (en .gitignore)
├── .gitignore                         # Exclusión de .venv, .env, __pycache__, .DS_Store
├── requirements.txt                   # Dependencias mínimas versionadas
├── <accion_principal>.command         # Lanzador interactivo macOS (Bash 3.2+)
├── ejecutar_tests.command             # Lanzador de la suite de pruebas empresariales
├── preparar_para_otra_mac.command     # Validador QA, limpiador de .venv y empaquetador .zip
├── desbloquear_permisos_mac.command   # Eliminador de cuarentena Gatekeeper
├── README.md                          # Documentación Dual (Humanos + QA + Graph Node Spec)
├── src/
│   ├── __init__.py
│   ├── main.py                        # Orquestador para uso humano vía CLI
│   ├── domain/                        # CAPA 1: Entidades puras, Enums y Excepciones
│   │   ├── __init__.py
│   │   ├── models.py                  # Clases de dominio inmutables/encapsuladas
│   │   └── exceptions.py              # Jerarquía semántica de errores
│   ├── config/                        # CAPA 2: Inyección y validación Fail-Fast de .env
│   │   ├── __init__.py
│   │   └── settings.py                # Clase Settings con @property
│   ├── services/                      # CAPA 3: Motores de negocio puros (0 I/O de consola)
│   │   ├── __init__.py
│   │   └── <motor>_service.py         # Lógica determinista, reutilizable y aislada
│   └── interfaces/                    # CAPA 4: Adaptadores de Entrada/Salida
│       ├── __init__.py
│       ├── cli.py                     # Adaptador Humano (ANSI UI, Finder drag & drop)
│       └── tools.py                   # Adaptador de Grafo / Agente (Function Node puro)
└── tests/                             # SUITE DE QA PERSISTENTE Y MODULAR (Enterprise OOP)
    ├── __init__.py
    ├── base_test.py                   # Clase base con gestión de sandbox temporal seguro
    ├── test_domain_and_config.py      # Tests unitarios de entidades, excepciones y settings
    ├── test_services.py               # Tests de servicios puros, colisiones y casos borde
    ├── test_interfaces_and_node.py    # Tests de saneamiento CLI y contrato JSON del Nodo
    └── test_launcher_e2e.py           # Tests de integración end-to-end de scripts .command
```

---

## **5. Plantilla Canónica de Nodo para Ingeniería de Grafos (`src/interfaces/tools.py`)**

Toda función expuesta en `src/interfaces/tools.py` debe seguir este contrato estandarizado para poder cablearse inmediatamente como un **Function Node** o **Agent Tool**:

```python
"""Agnostic Graph Node and Tool adapter module.

Exposes deterministic business services as pure Python callables with
JSON-serializable inputs and outputs, ready to be wired as Function Nodes
in Graph Engineering workflows (Fan-out, Join, Deterministic Routers) or
registered as LLM Tools across any SDK (Google ADK, Google GenAI, MCP).
"""

from typing import Any, Dict

from src.config.settings import OrganizerSettings
from src.domain.exceptions import OrganizerBaseError
from src.services.organizer_service import FileDispatcher
from src.services.scanner_service import MediaScanner


def execute_photo_organizer_node(
    directory_path: str,
    operation_mode: str = "move",
    jpg_folder_name: str = "material_jpg",
    raw_folder_name: str = "material_raw",
) -> Dict[str, Any]:
    """Execute deterministic media classification as a self-contained Graph Function Node.

    Scans the target directory for JPEG (.jpg, .jpeg) and Sony RAW (.arw) files,
    provisions destination subfolders, and transfers files safely with automatic
    collision renaming.

    Args:
        directory_path (str): Absolute filesystem path to the directory to organize.
        operation_mode (str, optional): Transfer mode ('move' or 'copy'). Defaults to "move".
        jpg_folder_name (str, optional): Subfolder name for JPEGs. Defaults to "material_jpg".
        raw_folder_name (str, optional): Subfolder name for RAWs. Defaults to "material_raw".

    Returns:
        Dict[str, Any]: Standardized Graph Node state dictionary containing:
            - node_name (str): Identifier of this function node.
            - status (str): Deterministic routing signal ('success', 'empty', 'partial_error', 'failed').
            - action_required (bool): Signal for downstream routers indicating if review is needed.
            - metrics (Dict[str, int]): Quantitative execution telemetry.
            - payload (Dict[str, Any]): Output paths for downstream graph nodes.
            - errors (List[Dict[str, str]]): Diagnostic details if any failures occurred.
    """
    node_id: str = "photo_organizer_node"

    try:
        settings = OrganizerSettings(
            jpg_folder_name=jpg_folder_name,
            raw_folder_name=raw_folder_name,
            operation_mode=operation_mode,
        )
        scanner = MediaScanner(
            ignored_folder_names=[settings.jpg_folder_name, settings.raw_folder_name],
            recursive=False,
        )
        scan_summary = scanner.scan(directory_path)

        if scan_summary.is_empty:
            return {
                "node_name": node_id,
                "status": "empty",
                "action_required": False,
                "metrics": {
                    "discovered_total": 0,
                    "jpg_transferred": 0,
                    "raw_transferred": 0,
                    "collisions_renamed": 0,
                    "error_count": 0,
                },
                "payload": {
                    "source_directory": str(directory_path),
                    "jpg_directory": None,
                    "raw_directory": None,
                },
                "errors": [],
            }

        dispatcher = FileDispatcher(settings=settings)
        report = dispatcher.dispatch(source_dir=directory_path, scan_summary=scan_summary)

        status_signal: str = "partial_error" if report.has_errors else "success"

        return {
            "node_name": node_id,
            "status": status_signal,
            "action_required": report.has_errors,
            "metrics": {
                "discovered_total": scan_summary.total_count,
                "jpg_transferred": report.jpg_count,
                "raw_transferred": report.raw_count,
                "collisions_renamed": report.collisions_count,
                "error_count": len(report.errors),
            },
            "payload": {
                "source_directory": str(directory_path),
                "jpg_directory": str(report.jpg_target_directory) if report.jpg_target_directory else None,
                "raw_directory": str(report.raw_target_directory) if report.raw_target_directory else None,
            },
            "errors": [
                {"file": str(path), "reason": msg} for path, msg in report.errors
            ],
        }

    except OrganizerBaseError as err:
        return {
            "node_name": node_id,
            "status": "failed",
            "action_required": True,
            "metrics": {
                "discovered_total": 0,
                "jpg_transferred": 0,
                "raw_transferred": 0,
                "collisions_renamed": 0,
                "error_count": 1,
            },
            "payload": {"source_directory": str(directory_path)},
            "errors": [{"file": str(directory_path), "reason": str(err)}],
        }
```

---

## **6. Estándar Inviolable para la Carpeta `tests/` (Enterprise QA Architecture)**

El código dentro de `tests/` es **código de primera clase**. No se permiten scripts sueltos sin estructura, funciones sin tipar ni pruebas destructivas fuera de sandboxes controlados.

### **Reglas de Ingeniería para `tests/`:**
1. **Arquitectura Orientada a Objetos (`unittest.TestCase`):** Utiliza la librería estándar `unittest` estructurada en clases de prueba heredadas de una clase base común (`BaseSandboxTestCase` en `tests/base_test.py`). Cero dependencias externas obligatorias para poder correr tests en cualquier Mac recién instalada.
2. **Tipado Estático y Google-Style Docstrings:** Todo método `setUp`, `tearDown`, helper y `test_*` debe tener firma `-> None` y un docstring imperativo que explique qué escenario o contrato valida.
3. **Aislamiento Determinista en Disco (`tempfile.TemporaryDirectory`):** Cada test que opere con archivos debe instanciar su propio directorio físico temporal en `setUp()` y destruirlo garantizadamente en `tearDown()`. Jamás se deben dejar carpetas residuales tras correr los tests.
4. **Validación de Serialización de Grafos:** `test_interfaces_and_node.py` debe verificar con `json.dumps(result)` que la respuesta del nodo en `tools.py` sea 100% serializable a JSON y contenga las llaves obligatorias (`node_name`, `status`, `action_required`, `metrics`, `payload`, `errors`).

### **Plantilla Canónica de Referencia para `tests/base_test.py`:**

```python
"""Base test harness providing isolated filesystem sandboxes for QA suites."""

from pathlib import Path
import tempfile
from typing import List, Optional
import unittest


class BaseSandboxTestCase(unittest.TestCase):
    """Abstract base test case managing deterministic temporary directories on disk.

    Attributes:
        sandbox_dir (Path): Resolved canonical path to the isolated test directory.
    """

    def setUp(self) -> None:
        """Provision a clean temporary directory before each test method executes."""
        super().setUp()
        self._temp_context: tempfile.TemporaryDirectory[str] = tempfile.TemporaryDirectory()
        self.sandbox_dir: Path = Path(self._temp_context.name).resolve()

    def tearDown(self) -> None:
        """Clean up and remove the temporary sandbox directory after test completion."""
        self._temp_context.cleanup()
        super().tearDown()

    def create_dummy_file(
        self,
        relative_path: str,
        content: str = "dummy_binary_payload",
    ) -> Path:
        """Create a physical file inside the isolated sandbox for testing.

        Args:
            relative_path (str): Relative file path within the sandbox.
            content (str, optional): Text payload to write. Defaults to "dummy_binary_payload".

        Returns:
            Path: Resolved path to the newly created file.
        """
        target: Path = self.sandbox_dir / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        return target.resolve()

    def create_dummy_batch(
        self,
        filenames: Optional[List[str]] = None,
        subfolder: str = "",
    ) -> List[Path]:
        """Create multiple test files inside the sandbox directory.

        Args:
            filenames (Optional[List[str]], optional): List of file names to generate.
                Defaults to None.
            subfolder (str, optional): Optional subdirectory inside sandbox. Defaults to "".

        Returns:
            List[Path]: List of created file paths.
        """
        names: List[str] = list(filenames) if filenames is not None else []
        created: List[Path] = []
        for name in names:
            rel: str = f"{subfolder}/{name}" if subfolder else name
            created.append(self.create_dummy_file(rel))
        return created
```

---

## **7. Protocolo para Agentes Autónomos (Self-Generating Backend Protocol)**

Cuando un Agente Constructor reciba la orden de crear o refactorizar un micro-backend para el ecosistema, deberá ejecutar de forma autónoma esta secuencia:

1. **Definición del Dominio:** Identificar qué trabajo es determinista (I/O, archivos, cálculos, llamadas API fijas) y aislarlo en `src/services/`.
2. **Generación de la Topología `src/`:** Crear el árbol completo (`domain/`, `config/`, `services/`, `interfaces/`) respetando PEP 8, tipado estricto y Google-Style Docstrings.
3. **Implementación de Adaptadores Duales:**
   * Crear `src/interfaces/cli.py` + `<app>.command` para operación manual en macOS.
   * Crear `src/interfaces/tools.py` con el contrato de salida `{node_name, status, action_required, metrics, payload, errors}` para operación en Grafos.
4. **Construcción de la Suite Persistente `tests/`:**
   * Implementar `tests/base_test.py`, `tests/test_domain_and_config.py`, `tests/test_services.py`, `tests/test_interfaces_and_node.py` y `tests/test_launcher_e2e.py`.
   * Crear el lanzador `ejecutar_tests.command` en la raíz del proyecto.
5. **Creación del Kit de Portabilidad:** Generar `preparar_para_otra_mac.command` (integrando la ejecución previa de `unittest` como filtro de calidad antes de crear el `.zip`) y `desbloquear_permisos_mac.command`.
6. **Auto-Verificación Determinista (*Persistent Self-Testing Loop*):**
   * Prohibido usar scripts efímeros `python3 -c`.
   * Validar sintaxis de todos los `.command` (`bash -n *.command`).
   * Compilar todo `src/` y `tests/` (`python3 -m py_compile`).
   * Ejecutar la suite formal persistente mediante `./.venv/bin/python3 -m unittest discover -s tests -p "test_*.py" -v` y verificar que el 100% de las pruebas pasen con código de salida `0`.
7. **Documentación Dual (`README.md`):** Incluir guía rápida en 3 pasos para humanos, instrucciones para correr `ejecutar_tests.command` y una sección **"Graph Node Specification"** con el esquema exacto de entrada y salida JSON del nodo para otros agentes.

---

## **8. Matriz de Auditoría Pre-Despliegue**

Antes de dar por terminado cualquier micro-backend, verifica el cumplimiento del 100% de esta lista:

| Fase | Criterio de Control | Estado Requerido |
| :--- | :--- | :--- |
| **1. Base OOP & Clean** | ¿Cero hardcoding (`.env` + `.env.example`), tipado completo, atributos en `__init__` y docstrings Google-Style? | **SÍ** |
| **2. Nodo de Grafo** | ¿`src/services/` está 100% libre de `print()`/`input()` y `src/interfaces/tools.py` retorna el diccionario serializable con señal `status` para *Deterministic Routers*? | **SÍ** |
| **3. Suite `tests/` Persistente** | ¿Existe la carpeta `tests/` modular en POO (`unittest.TestCase`), con tipado estricto, docstrings y cero pruebas efímeras en memoria? | **SÍ** |
| **4. Portabilidad Mac** | ¿Existen los 4 scripts `.command` (principal, `ejecutar_tests`, preparador `.zip` sin `.venv` y desbloqueador Gatekeeper) compatibles con Bash 3.2? | **SÍ** |
| **5. Documentación Dual** | ¿El `README.md` documenta el uso *drag-and-drop*, la suite de testing y el contrato JSON del nodo para agentes? | **SÍ** |
