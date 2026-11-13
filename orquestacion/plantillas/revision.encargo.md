Rol: revisor

# Encargo de revisión {FASE} · {SUB}

- **Carpeta:** `{DIR}` (solo lectura: no edites, no comitees, no cambies de rama)
- **Commits a revisar:** `git -C {DIR} diff {BASE}..{HEAD}` y `git -C {DIR} log --format='%h %s%n%b' {BASE}..{HEAD}`
- **Encargo de la subtarea:** `{ENCARGO}`
- **Plan y decisiones:** `{PLAN}` y `{DECISIONES}` (manda el archivo de decisiones)
- **Reporte del operativo:** `{REPORTE}`
- **Salida:** `{SALIDA}`

## Qué revisas
1. Que el diff haga **lo que pide la subtarea y nada más**: sin refactors ni archivos extra, sin adelantar subtareas siguientes.
2. La sección 6 de `.agents/orquestacion/PROTOCOLO.md` y la lista de revisión de `.agents/PROYECTO.md`.
3. **Las pruebas**, como si la CI las ejecutara: importaciones correctas, datos de prueba que existen y una prueba por cada criterio de aceptación. Señala toda prueba que creas que **fallará**, y por qué.
4. Que el reporte coincida con el diff.

Escribe los hallazgos según `.agents/rules/orquestacion_planificador_revisor.md`, termina con `HALLAZGOS LISTOS: {SALIDA}` y detente.
