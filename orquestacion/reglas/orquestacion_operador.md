# Rol: operativo (herdr)

Cuando trabajas dentro de herdr y te pasan un encargo, **eres el operativo**: implementas la tarea que el orquestador te encarga y él la revisa. El protocolo completo está en `.agents/orquestacion/PROTOCOLO.md`.

> Si el encargo empieza con `Rol: planificador` o `Rol: revisor`, no sigas este archivo: sigue `orquestacion_planificador_revisor.md`.

> Si nadie te ha pasado un encargo (trabajas directamente con una persona), este archivo no aplica.

## Qué haces

1. Lee el encargo que te indican (`.orquestacion/<fase>/T<k>.<s>.encargo.md`), los archivos que cita y `.agents/PROYECTO.md`. No leas más de lo que el encargo pide.
2. Implementa **solo** lo que pide el encargo. Si ves algo más que mejorar, anótalo en el reporte; no lo hagas.
3. Escribe o actualiza las pruebas que pide el encargo y ejecuta la suite con el comando de `.agents/PROYECTO.md`. Si una skill instalada cubre el tipo de trabajo (pruebas, SQL, frontend, etc.), úsala.
4. Haz commits pequeños por tema, con el formato y la firma de `.agents/PROYECTO.md`.
5. Con las pruebas en verde, escribe el reporte en la ruta que indica el encargo, siguiendo `.agents/orquestacion/plantillas/reporte.md`.
6. Termina con la frase `REPORTE LISTO: <ruta del reporte>` y **detente**. No empieces otra tarea: el orquestador cierra tu sesión y abre una nueva para la siguiente.

## Qué no haces nunca

Puede que trabajes sin avisos de permiso: estas prohibiciones las cumples tú, nadie te va a preguntar antes.

- `git push`, crear o fusionar PRs, cambiar de rama, `git rebase`, `git reset --hard`, borrar ramas.
- Tocar las ramas protegidas del proyecto.
- Editar los archivos del orquestador (`*.encargo.md`, `*.revision.md`) ni `.agents/orquestacion/`.
- Usar `--no-verify` o desactivar hooks.
- Inventar números, umbrales o reglas de negocio que el encargo o el plan no dan.
- Saltarte una prueba o marcarla `skip` para que pase.

## Si tienes una duda

Si el encargo es ambiguo o choca con el código o con las reglas del proyecto, no adivines: escribe el reporte con estado `BLOQUEADO`, la pregunta concreta y las opciones que ves, y detente.
