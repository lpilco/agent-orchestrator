# agent-orchestrator

Base común para trabajar con varios agentes de código (Claude Code, Antigravity y cualquier otro que lea `AGENTS.md` y skills) en cualquier repositorio:

- **Skills** reutilizables en el formato estándar (`skills/<nombre>/SKILL.md`): el agente las carga solo cuando el trabajo las necesita.
- **Protocolo de orquestación** con [herdr](https://herdr.dev): roles (orquestador, planificador, revisor, operativo), encargos, reportes, revisiones, scripts y una barrera de push.
- **Un instalador** que copia todo dentro de tu proyecto, para que viaje con su git a worktrees, CI y otras máquinas.

## Empezar

```bash
git clone https://github.com/lpilco/agent-orchestrator.git ~/agent-orchestrator
```

```bash
~/agent-orchestrator/bin/instalar.sh --lista
```

### En un proyecto

```bash
~/agent-orchestrator/bin/instalar.sh ~/ruta/a/mi-proyecto --skills universal-qa-architect,js-clean-architecture
```

Qué deja en el proyecto:

| Ruta | Qué es | ¿Lo editas? |
|---|---|---|
| `.agents/orquestacion/` | Protocolo, plantillas y scripts | No: se actualiza desde aquí |
| `.agents/rules/orquestacion_*.md` | Reglas de cada rol | No |
| `.agents/skills/<nombre>/` | Skills elegidas (enlazadas en `.claude/skills/`) | No |
| `.agents/PROYECTO.md` | Stack, comandos, commits y lista de revisión del proyecto | **Sí, complétalo** |
| `.agents/proyecto.conf` | Rama base y ramas protegidas | **Sí** |
| `AGENTS.md`, `CLAUDE.md` | Entrada para los agentes; solo se gestiona un bloque marcado | Sí, fuera del bloque |

Después: completa `.agents/PROYECTO.md`, haz commit y comprueba la máquina con

```bash
bash .agents/orquestacion/scripts/comprobar.sh
```

Para **actualizar** un proyecto, trae los cambios de este repositorio (`git pull`) y vuelve a ejecutar `instalar.sh <proyecto>`: actualiza lo instalado y no toca tus archivos.

Solo skills, sin herdr: añade `--sin-orquestacion`.

### Skills para todos tus proyectos

```bash
~/agent-orchestrator/bin/instalar.sh --global
```

Enlaza las skills en `~/.agents/skills` y `~/.claude/skills`. Al ser enlaces a tu clon, un `git pull` las actualiza.

## Skills disponibles

| Skill | Para qué |
|---|---|
| `universal-qa-architect` | Estrategia de pruebas, revisión de código y quality gates en cualquier stack |
| `python-coding-standards` | Estilo base de Python: sin hardcoding, DRY, una responsabilidad, docstrings |
| `python-oop-clean-architecture` | POO y Clean Architecture en Python |
| `python-oop-enterprise` | POO avanzada: descriptores, MRO, ABCs, iteradores, Factory Method |
| `js-clean-architecture` | JavaScript moderno sin espagueti, con JSDoc |
| `frontend-html-js-standards` | HTML semántico, accesibilidad y módulos ESM |
| `gsap-animation-architecture` | Animación web con GSAP |
| `dashboard-design-refactoring` | Diseño y revisión de dashboards y gráficos |
| `sql-database-engineering` | Esquemas, consultas y migraciones SQL |
| `graph-backend-factory` | Micro-backends Python como nodos de grafos de agentes |
| `macos-command-launchers` | Lanzadores `.command` y shell defensivo en macOS |
| `after-effects-extendscript` | Scripts y automatización de After Effects |
| `illustrator-extendscript` | Scripts y automatización de Illustrator |
| `certified-financial-planner` | Planificación financiera personal y evaluación de créditos |

## Orquestación con herdr

El protocolo completo está en [orquestacion/PROTOCOLO.md](orquestacion/PROTOCOLO.md). En corto: un orquestador parte el trabajo y escribe encargos; un planificador los divide en subtareas; un operativo implementa cada una en una sesión nueva y entrega un reporte; un revisor da la primera revisión; solo el orquestador hace push, y todo llega a la rama base por PR.

Regla de ramas por defecto: **todo el desarrollo vive en `dev`; a `main` solo sube lo que se publica**. Cada proyecto lo ajusta en `.agents/proyecto.conf`.

## Aportar

### Una skill nueva

1. Crea `skills/<nombre>/SKILL.md`. El nombre va en minúsculas con guiones y coincide con la carpeta.
2. Empieza el archivo con:
   ```markdown
   ---
   name: <nombre>
   description: "Qué hace y cuándo usarla, en una o dos frases."
   ---
   ```
   La descripción es lo único que el agente ve antes de cargar la skill: di **qué hace** y **cuándo usarla**.
3. Mantén `SKILL.md` por debajo de unas 500 líneas. El material largo va en `skills/<nombre>/references/` y se cita desde `SKILL.md`.
4. Añádela a la tabla de arriba y abre un PR.

### Antes de subir cualquier cosa

Este repositorio es **público**. No subas correos, nombres de clientes, rutas de tu máquina, claves, cifras personales ni detalles internos de un proyecto. Lo propio de un proyecto va en su `.agents/PROYECTO.md`, no aquí.

### Cambios al protocolo

Edita `orquestacion/` aquí y abre un PR; nunca dentro de un proyecto, porque la siguiente actualización lo pisaría.

## Licencia

[MIT](LICENSE).
