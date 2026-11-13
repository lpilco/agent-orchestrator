# Protocolo de orquestación entre agentes con herdr

Cómo trabaja un equipo de agentes en un mismo repositorio, cada uno en un panel de [herdr](https://herdr.dev). Este archivo es igual en todos los proyectos: lo instala y lo actualiza [agent-orchestrator](https://github.com/lpilco/agent-orchestrator). **No lo edites dentro del proyecto**; lo propio de cada proyecto va en `.agents/PROYECTO.md` y `.agents/proyecto.conf`.

| Rol | Qué hace | Quién suele serlo |
|---|---|---|
| **Orquestador** | Parte el trabajo en tareas, revisa el plan de subtareas, escribe los encargos, valida los hallazgos del revisor, revisa lo delicado, hace push, abre el PR, vigila la CI y actualiza el plan. | Claude Code, con el modelo más capaz |
| **Planificador** | Parte cada tarea en subtareas pequeñas. No escribe código. | Un modelo de razonamiento medio |
| **Revisor** | Primera revisión de cada subtarea. Solo lectura. | Un modelo de razonamiento medio |
| **Operativo** | Implementa una subtarea, escribe las pruebas, hace commits locales y entrega un reporte. | Un modelo rápido y barato |
| **Persona** | Aprueba el plan, responde a los agentes bloqueados y autoriza los merges. | Tú |

Qué programa y qué modelo ocupa cada rol en esta máquina lo dice `.orquestacion/modelos.env` (sección 5). Las reglas del operativo están en `.agents/rules/orquestacion_operador.md` y las del planificador y el revisor en `.agents/rules/orquestacion_planificador_revisor.md`.

---

## 1. Preparación (una vez por máquina y por clon)

1. Herramientas: `git`, `gh`, `jq`, `node`, `herdr`, y los agentes que uses (`claude`, `agy`).
2. `gh auth login && gh auth setup-git`, y la identidad de git (`user.name`, `user.email`).
3. Clona el repositorio en su rama base (la que indica `.agents/proyecto.conf`).
4. Skill de herdr para los agentes: `npx skills add herdrdev/herdr --skill herdr`. Solo actúa si `HERDR_ENV=1`.
5. Integraciones de estado de herdr para cada agente (<https://herdr.dev/docs/agents/>), para que herdr sepa cuándo trabajan, terminan o se bloquean.
6. **Barrera de push** (obligatoria si los agentes trabajan sin avisos de permiso):
   ```bash
   git config core.hooksPath .agents/orquestacion/scripts/hooks
   ```
7. Modelos: copia `.agents/orquestacion/scripts/modelos.env.ejemplo` a `.orquestacion/modelos.env` y pon los nombres exactos.
8. Comprueba todo con `bash .agents/orquestacion/scripts/comprobar.sh`. No instala nada: dice qué falta.

Lo que **no** viaja entre máquinas: la memoria de cada agente y la carpeta `.orquestacion/` (está fuera de git). Todo el contexto necesario debe estar en el repositorio.

## 2. Arranque de una sesión

```bash
cd <repo>
git switch <rama base> && git pull --ff-only     # o la rama de la fase en curso
herdr                                            # abre el espacio de trabajo
claude                                           # panel 1: orquestador
```

Desde el panel del orquestador se arranca cada agente con el modelo que pide la tarea:

```bash
bash .agents/orquestacion/scripts/iniciar_agente.sh planificador planificador
bash .agents/orquestacion/scripts/iniciar_agente.sh revisor revisor
bash .agents/orquestacion/scripts/iniciar_agente.sh operador acotado
bash .agents/orquestacion/scripts/iniciar_agente.sh operador complejo             # correcciones tras dos rondas
bash .agents/orquestacion/scripts/iniciar_agente.sh operador-b acotado <worktree> # otro operativo en un worktree
```

El script abre (o reutiliza) un panel a la derecha con `ORQ_ROL` puesto, cierra la sesión anterior de ese agente si la hay y arranca una nueva. **Cada tarea empieza con una sesión nueva**: contexto limpio y el modelo que dice el encargo.

### 2.1 Trabajar sin avisos de permiso

Si los agentes trabajan sin pedir permiso para cada acción, eso se compensa con:

- **Aislamiento**: una máquina, una VM o un usuario donde un error no cueste caro.
- **La barrera de push**: nadie empuja directo a las ramas protegidas y ningún agente con `ORQ_ROL` distinto de `orquestador` empuja nada.
- **Protección de ramas en GitHub** y CI obligatoria en los PR, si el proyecto las tiene.
- **Las reglas escritas** de cada rol, que siguen vigentes aunque no haya avisos.
- **El merge a la rama base es de la persona**, o del orquestador solo cuando la persona lo diga en el chat.

## 3. Ciclo de una fase

```
Orquestador                                   Otros agentes
───────────                                   ─────────────
1. Lee el plan del proyecto y .agents/PROYECTO.md
2. Rama feat/<fase>-<tema> desde la rama base
3. Plan corto de la fase → la persona aprueba
4. PR en borrador hacia la rama base
5. Encargo de planificación T1 ───────────▶ planificador: T1.plan.md (subtareas T1.1…T1.n)
   El orquestador revisa y corrige el plan antes de repartirlo.
6. Encargo T1.1 ──── herdr agent prompt ──▶ operativo: implementa, prueba,
                                            commits locales, reporte y se detiene
7. Encargo de revisión ───────────────────▶ revisor: T1.1.hallazgos.md
8. El orquestador valida los hallazgos (y revisa él mismo lo delicado)
   ├─ CAMBIOS  → encargo de corrección ───▶ (vuelve a 6, en sesión nueva)
   └─ APROBADO → push → CI del PR
9. Siguiente subtarea … hasta cerrar la fase
10. CI en verde + visto bueno de la persona → merge a la rama base
11. Actualiza el plan del proyecto
```

Reglas del ciclo:

- **Una tarea = una sesión nueva.** `iniciar_agente.sh` al empezar y `cerrar_agente.sh` al recibir el reporte. Las correcciones también van en sesión nueva.
- **El agente lee solo lo que cita el encargo.** Un encargo debe poder ejecutarse sin contexto previo.
- **Pruebas en verde antes del reporte**, con el comando de `.agents/PROYECTO.md`.
- **Tras dos rondas de corrección fallidas**, la subtarea pasa al modelo `complejo` o la toma el orquestador.

### 3.1 Archivos de intercambio

Viven en `.orquestacion/<fase>/`, fuera de git. La historia que importa queda en los commits, el PR y el plan del proyecto.

| Archivo | Lo escribe | Plantilla (`.agents/orquestacion/plantillas/`) |
|---|---|---|
| `T<k>.plan.encargo.md` | Orquestador | — (pide el plan de subtareas) |
| `T<k>.plan.md` | Planificador | `plan_tarea.md` |
| `T<k>.<s>.encargo.md` | Orquestador | `encargo.md` |
| `T<k>.<s>.reporte.md` | Operativo | `reporte.md` |
| `T<k>.<s>.revision.encargo.md` | Orquestador | `revision.encargo.md` |
| `T<k>.<s>.hallazgos.md` | Revisor | ver las reglas del revisor |
| `T<k>.<s>.revision.md` | Orquestador | `revision.md` |

Las correcciones se numeran `T<k>.<s>.r1.encargo.md`, `T<k>.<s>.r1.reporte.md`, etc.

### 3.2 Comandos del orquestador

```bash
# Enviar un encargo y esperar a que termine o se bloquee (hasta 45 min)
herdr agent prompt operador "Ejecuta .orquestacion/<fase>/T1.1.encargo.md según tus reglas de operativo." \
  --wait --until done --until blocked --timeout 2700000

bash .agents/orquestacion/scripts/cerrar_agente.sh operador      # al recibir el reporte
herdr agent get operador                                          # estado actual
herdr agent read operador --source recent-unwrapped --lines 120   # qué dice la pantalla
herdr notification show "Operativo bloqueado" --body "T1.1 necesita tu respuesta" --sound request
```

**Si un agente queda `blocked`**, el orquestador **no aprueba nada por su cuenta**: lee la pantalla, avisa a la persona con una notificación y espera. Si la pregunta es de diseño y está resuelta en el plan, se responde con un encargo nuevo, no tecleando en su panel.

## 4. Reglas de convivencia

1. **Un solo escritor de código por carpeta.** Cada operativo tiene su checkout (el repo o un worktree) y nadie más escribe en él. Mientras un operativo trabaja, el orquestador solo lee (`git diff`, `git log`).
2. **Solo el orquestador hace `push`, abre PRs y fusiona.** Los demás nunca tocan el remoto.
3. **Ramas:** todo el desarrollo sale de la rama base y vuelve a ella por PR. Las ramas de publicación solo reciben lo que se va a publicar. Los nombres están en `.agents/proyecto.conf`.
4. **Trabajo en paralelo:** cada frente en un `git worktree` aparte con su propio operativo. Los encargos viven siempre en `.orquestacion/` del repositorio principal y se pasan con ruta absoluta. Antes de abrir o actualizar su PR, la rama del frente incorpora la rama base con `git merge` (no rebase).
5. **Pruebas en local y en la CI:** el agente ejecuta la suite en local antes de dar la tarea por hecha; si hay CI, es la que manda para fusionar.
6. **Una sola máquina por rama** a la vez. Antes de cambiar de máquina: push desde una, pull en la otra.
7. **Commits** pequeños, por tema, con el formato y la firma que indica `.agents/PROYECTO.md`.

## 5. Qué modelo usar

| Trabajo | Tipo en `iniciar_agente.sh` | Revisión |
|---|---|---|
| Partir una tarea en subtareas | `planificador` | el orquestador revisa y corrige el plan |
| Cada subtarea normal | `acotado` | `revisor` → el orquestador valida |
| Subtarea delicada (seguridad, dinero, datos personales, lógica central) | `acotado`, con un encargo más detallado | `revisor` + revisión completa del orquestador |
| Revisión de una subtarea pequeña | `revisor_ligero` | — |
| Corrección tras dos rondas fallidas | `complejo` | orquestador |

`.orquestacion/modelos.env` asigna un modelo a cada tipo. Un valor normal es un nombre de `agy models`; un valor `claude:<modelo>[:<esfuerzo>]` arranca Claude Code en vez de Antigravity. Cuando falta cuota de un proveedor, se cambia ese archivo y nada más. El planificador y el revisor también pueden ser subagentes del orquestador en vez de paneles.

## 6. Qué se revisa en cada entrega

- El diff hace **lo que pide el encargo y nada más**: sin refactors ni archivos extra, sin adelantar subtareas.
- Cada criterio de aceptación tiene su prueba, y las pruebas pasarían en la CI.
- Sin secretos, rutas absolutas de una máquina ni datos personales en el código.
- Commits pequeños, con el formato y la firma del proyecto.
- El reporte coincide con el diff.
- **La lista de revisión propia del proyecto**, en `.agents/PROYECTO.md`.
