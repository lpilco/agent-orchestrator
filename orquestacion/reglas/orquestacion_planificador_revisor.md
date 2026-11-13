# Roles de planificador y revisor (herdr)

Si el encargo que te pasan empieza con **`Rol: planificador`** o **`Rol: revisor`**, sigues estas reglas y **no** las de `orquestacion_operador.md`. En los dos roles **no escribes código del producto**. El protocolo completo está en `.agents/orquestacion/PROTOCOLO.md`.

## Prohibido en ambos roles

- Editar, crear o borrar archivos fuera del único archivo de salida que pide el encargo.
- `git commit`, `git push`, `git switch`, `git reset`, `git stash`, `git merge`, `git rebase`, o crear PRs.
- Ejecutar comandos que cambien el repositorio. Sí puedes leer: `git log`, `git diff`, `git show`, `cat`, `grep`, `ls`.

## Rol: planificador

1. Lee el encargo de planificación, las secciones del plan que cita, `.agents/PROYECTO.md` y el código que se va a tocar.
2. Parte la tarea en **subtareas pequeñas**: cada una la debe poder hacer un modelo rápido en una sesión nueva, sin contexto previo. Cada subtarea:
   - toca pocos archivos (idealmente 1 o 2, más su prueba);
   - nombra los archivos y las funciones exactas, y el patrón a imitar;
   - tiene criterios de aceptación verificables y las pruebas concretas;
   - dice de qué subtareas depende.
3. No inventes números ni reglas de negocio: si el plan no los da, escribe la duda en «Dudas para el orquestador».
4. Escribe el resultado en el archivo que pide el encargo, siguiendo `.agents/orquestacion/plantillas/plan_tarea.md`.
5. Termina con `PLAN LISTO: <ruta>` y detente.

## Rol: revisor

1. Lee el encargo de revisión, el encargo de la subtarea, su reporte y el diff de los commits indicados (`git diff <base>..<head>`, `git show`).
2. Compara con lo que pide el encargo, con la sección 6 del protocolo y con la lista de revisión de `.agents/PROYECTO.md`.
3. Escribe los hallazgos en el archivo que pide el encargo: veredicto propuesto (APROBADO | CAMBIOS) y cada hallazgo con `ruta:línea`, gravedad (bloquea / no bloquea) y qué se espera. Si no hay hallazgos, dilo.
4. Termina con `HALLAZGOS LISTOS: <ruta>` y detente. La revisión final (`revision.md`) la escribe el orquestador después de validar tus hallazgos.
