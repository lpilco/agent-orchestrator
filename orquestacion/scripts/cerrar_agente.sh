#!/usr/bin/env bash
# Cierra la sesión de un agente de herdr al terminar su tarea.
#
# Uso, desde el panel del orquestador:
#   bash .agents/orquestacion/scripts/cerrar_agente.sh <nombre>
#
# Envía /exit al agente, espera a que su sesión desaparezca y cierra su panel (como Ctrl+b x).
# Al terminar una fase solo queda abierto el panel del orquestador.
# Una tarea = una sesión: así cada encargo arranca sin el contexto (ni los tokens) de la anterior.

set -euo pipefail

nombre="${1:-}"
[[ "$nombre" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || { echo "Uso: $0 <nombre>" >&2; exit 1; }
[ "${HERDR_ENV:-}" = "1" ] || { echo "✘ Ejecuta esto dentro de herdr (HERDR_ENV no es 1)." >&2; exit 1; }

existe() { herdr agent list 2>/dev/null | grep -qw "$nombre"; }
archivo_panel="$(git rev-parse --show-toplevel)/.orquestacion/$nombre.pane"

# Cierra el panel del agente (lo mismo que Ctrl+b x); nunca el del orquestador que llama
cerrar_panel() {
  [ -f "$archivo_panel" ] || return 0
  panel=$(cat "$archivo_panel")
  if [ -n "$panel" ] && [ "$panel" != "${HERDR_PANE_ID:-}" ]; then
    herdr pane close "$panel" >/dev/null 2>&1 || true
    echo "✔ Panel $panel cerrado."
  fi
  rm -f "$archivo_panel"
}

if ! existe; then
  echo "✔ $nombre no tiene sesión abierta."
  cerrar_panel
  exit 0
fi

estado=$(herdr agent get "$nombre" 2>/dev/null | jq -r '.result.agent.agent_status // empty')
if [ "$estado" = "working" ]; then
  echo "✘ $nombre sigue trabajando; espera su reporte antes de cerrarlo." >&2
  exit 1
fi

herdr agent prompt "$nombre" "/exit" >/dev/null 2>&1 || true
for _ in $(seq 1 30); do existe || break; sleep 1; done
if existe; then
  echo "✘ La sesión de '$nombre' no se cerró. Ciérrala a mano (/exit)." >&2
  exit 1
fi
echo "✔ Sesión de $nombre cerrada."
cerrar_panel
