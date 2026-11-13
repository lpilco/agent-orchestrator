---
name: sql-database-engineering
description: "Ingeniería SQL y diseño de bases de datos: DDL, DML, consultas con CTEs, índices y migraciones idempotentes, defensivas y parametrizadas contra inyección. Úsala al diseñar esquemas, escribir o revisar consultas y migraciones SQL."
---

# 📘 SKILL: Enterprise SQL Engineering & Clean Database Architecture

## 1. Rol y Misión del Agente / Database Engineer

Actúas como un **Principal Database Engineer y Data Architect**. Todo código SQL (DDL, DML, consultas complejas, índices y migraciones) debe ser:

* **Declarativo y Legible:** Formateado para facilitar auditorías y revisiones en git (diferencias línea por línea limpias).
* **Defensivo e Idempotente:** Diseñado para evitar bloqueos innecesarios, pérdidas accidentales de datos o fallos ante reejecuciones.
* **Modular y Desacoplado:** Uso de CTEs (*Common Table Expressions*) como funciones puras en lugar de subconsultas monolíticas anidadas.
* **Seguro:** Parametrizado al 100% contra inyección SQL y consciente de las barreras transaccionales (ACID).



---

## 2. Los 7 Mandamientos del SQL Limpio y Profesional

### 1. Idempotencia Mandatoria en DDL

Toda sentencia de definición de datos debe poder ejecutarse múltiples veces sin lanzar errores:

```sql
-- ✔️ Correcto: Idempotente y seguro
CREATE TABLE IF NOT EXISTS asset_catalogs ( ... );
CREATE INDEX IF NOT EXISTS idx_asset_catalogs_checksum ON asset_catalogs(checksum);
DROP TABLE IF EXISTS temp_migration_records;

```

### 2. Prohibición Absoluta de `SELECT *`

* **Regla:** En código de aplicación o vistas de producción, nombra explícitamente cada columna requerida.
* **Razón:** `SELECT *` rompe la compatibilidad hacia atrás si cambian las columnas, anula la optimización por índice cubierto (*Covering Index*) y genera amplificación innecesaria de I/O de red y memoria.



### 3. Modularidad con CTEs (*Common Table Expressions*) en vez de Subqueries

Trata las consultas complejas como flujos de datos funcionales:

* ❌ **Antipatrón (Spaghetti anidado):** Subconsultas dentro del `FROM` o `JOIN` de varios niveles.
* ✔️ **Patrón Canónico (Pipeline de CTEs):**

```sql
WITH normalized_query AS (
    -- Paso 1: Preparación y filtrado inicial de bajo costo
    SELECT id, name, relative_path, size_bytes
    FROM records
    WHERE is_deleted = 0
),
ranked_assets AS (
    -- Paso 2: Cálculo analítico o función de ventana
    SELECT 
        id,
        name,
        relative_path,
        size_bytes,
        ROW_NUMBER() OVER (PARTITION BY relative_path ORDER BY size_bytes DESC) AS rank_index
    FROM normalized_query
)
-- Paso 3: Proyección final limpia
SELECT id, name, relative_path, size_bytes
FROM ranked_assets
WHERE rank_index = 1;

```

### 4. Estándar Riguroso de Nomenclatura

* **Palabras reservadas de SQL:** Siempre en **MAYÚSCULAS** (`SELECT`, `INSERT`, `FROM`, `WHERE`, `JOIN`, `ON`, `GROUP BY`, `ORDER BY`, `CREATE VIRTUAL TABLE`).
* **Tablas, Vistas y Columnas:** Siempre en **`snake_case`**, minúsculas y nombres en plural para entidades/tablas (`records`, `disks`, `tags`) y singular para atributos/columnas (`created_at`, `disk_label`).
* **Sufijos semánticos para tipos de datos temporales y booleanos:**
* Fechas/horas: `_at` para timestamps completos (`modified_at`, `indexed_at`), `_date` para fechas puras (`scan_date`).
* Banderas booleanas: `is_`, `has_`, `can_` (`is_active`, `has_proxy`).
* Claves foráneas: `<tabla_singular>_id` (ej. `catalog_id`, `disk_id`).



### 5. Formato Visual "Leading Commas" o Columnas por Línea

Alinea las columnas verticalmente para que un cambio en una columna no altere las líneas de las demás en `git diff`:

```sql
SELECT
    r.id,
    r.name,
    r.relative_path,
    r.size_bytes,
    r.category
FROM records AS r
WHERE r.disk_label = :disk_label
  AND r.size_bytes > 0;

```

### 6. Relaciones Explícitas con `INNER/LEFT JOIN ... ON`

* ❌ **Prohibido:** Joins implícitos tipo `FROM records r, disks d WHERE r.disk_id = d.id`.
* ✔️ **Obligatorio:** Declarar la semántica exacta del join y siempre usar alias claros (`FROM records AS r INNER JOIN disks AS d ON d.id = r.disk_id`).

### 7. Parámetros Nombrados (Anti-Inyección)

* Ninguna consulta de aplicación debe concatenar cadenas de Python o JavaScript (`f"SELECT * FROM records WHERE name = '{name}'"`).
* Usar siempre bindings parametrizados (`:param_name` o `?`).

---

## 3. Bloques de Documentación Estándar (SQL Header Docstring)

Todo archivo `.sql`, vista o procedimiento complejo debe iniciar con un encabezado descriptivo:

```sql
-- ============================================================================
-- OBJECT NAME : sp_rebuild_fts_catalogs
-- ARCHITECTURE: Clean Storage / DiskCataloger Enterprise
-- PURPOSE     : Atomic reconstruction of external FTS5 inverted index.
-- INPUTS      : None (Runs on staging database)
-- OUTPUTS     : Returns 1 on success, raises exception on integrity check failure.
-- STANDARDS   : POSIX fsync, Write-Ahead Logging (WAL), ARIES Recovery.
-- AUTHOR      : Database Engineering Team
-- ============================================================================

BEGIN IMMEDIATE TRANSACTION;

-- Paso 1: Purgar y reconstruir
INSERT INTO records_fts(records_fts) VALUES('rebuild');

-- Paso 2: Optimización de segmentos de índice B-Tree
INSERT INTO records_fts(records_fts) VALUES('optimize');

-- Paso 3: Verificación formal de integridad física
INSERT INTO records_fts(records_fts) VALUES('integrity-check');

COMMIT;

```

---

## 4. Patrones de Transaccionalidad y Manejo Defensivo (ACID)

Al ejecutar scripts de migración o mutaciones masivas:

1. **Transacción Explícita Inmediata:** Usar `BEGIN IMMEDIATE TRANSACTION;` para bloquear el archivo de escritura desde el primer milisegundo y evitar errores `SQLITE_BUSY` por contención concurrente.


2. **Modo Seguro de Borrado:** Si se hace un `DELETE` o `UPDATE` masivo, usar siempre una condición `WHERE` afirmativa. En scripts de prueba, estructurarlo con guardas condicionales.

---

## 5. Checklist de Verificación de Calidad SQL (Para el Agente / Auditor)

Antes de considerar listo un script o consulta SQL generada por IA, valida la siguiente lista:

* [ ] **1. Formato y Palabras Clave:** ¿Todas las palabras reservadas de SQL están en mayúsculas (`SELECT`, `JOIN`, `WHERE`) y los identificadores en `snake_case`?
* [ ] **2. Cero `SELECT *`:** ¿Se nombraron todas las columnas requeridas explícitamente?
* [ ] **3. Parametrización Total:** ¿La consulta utiliza *placeholders* (`?` o `:named_param`) en lugar de interpolación/formato de texto directo?
* [ ] **4. Modularidad con CTEs:** ¿Las lógicas anidadas de más de un nivel están descompuestas en bloques `WITH ... AS (...)` legibles?
* [ ] **5. Idempotencia en DDL:** ¿Los `CREATE TABLE`, `CREATE INDEX` y `DROP` cuentan con `IF NOT EXISTS` o `IF EXISTS`?
* [ ] **6. Joins Explícitos:** ¿Se usa la sintaxis estándar `INNER JOIN ... ON` evitando joins implícitos en el `WHERE`?
* [ ] **7. Soporte de Índices:** Si la consulta filtra por múltiples columnas (`disk_label`, `category`), ¿existen índices B-Tree correspondientes para evitar barridos completos de tabla (*Full Table Scans*)?


* [ ] **8. Atomicidad Transaccional:** ¿Las mutaciones masivas están protegidas dentro de bloques transaccionales explícitos (`BEGIN TRANSACTION` / `COMMIT`)?


* [ ] **9. Comentarios Contextuales:** ¿Se documentó el objetivo técnico, las precondiciones y el comportamiento de rendimiento esperado al inicio del script?
