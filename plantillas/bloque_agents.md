<!-- agent-orchestrator:inicio (bloque gestionado: no lo edites a mano) -->
## Cómo trabajar en este repositorio

1. Lee `.agents/PROYECTO.md`: stack, comandos, ramas, formato de commits y lista de revisión de este proyecto.
2. Las skills están en `.agents/skills/` (y enlazadas en `.claude/skills/`). Usa la que cubra el tipo de trabajo antes de escribir código.
3. Todo el desarrollo sale de la rama base y vuelve a ella por PR. Nunca hagas push directo a las ramas protegidas (`.agents/proyecto.conf`).
4. Si trabajas dentro de herdr (`HERDR_ENV=1`):
   - Si diriges el trabajo, eres el **orquestador**: sigue `.agents/orquestacion/PROTOCOLO.md`.
   - Si te pasan un encargo, sigue `.agents/rules/orquestacion_operador.md`; si el encargo empieza con `Rol: planificador` o `Rol: revisor`, sigue `.agents/rules/orquestacion_planificador_revisor.md`.
5. No edites `.agents/orquestacion/` ni las skills instaladas: se actualizan desde [agent-orchestrator](https://github.com/lpilco/agent-orchestrator). Si una regla o una skill debe cambiar, propón el cambio allí.
<!-- agent-orchestrator:fin -->
