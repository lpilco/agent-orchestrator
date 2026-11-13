#!/usr/bin/env bash
# Arranca (o reinicia) un agente (Antigravity o Claude Code) en un panel de herdr con el modelo de la tarea.
#
# Uso, desde el panel del orquestador:
#   bash .agents/orquestacion/scripts/iniciar_agente.sh <nombre> <tipo> [carpeta]
#
#   nombre   operador | revisor | planificador | operador-b | ...  (minúsculas, números, - o _)
#   tipo     planificador   → ORQ_MODELO_PLANIFICADOR (parte la tarea en subtareas)
#            revisor        → ORQ_MODELO_REVISOR (primera revisión, solo lectura)
#            revisor_ligero → ORQ_MODELO_REVISOR_LIGERO (revisiones de subtareas pequeñas)
#            acotado        → ORQ_MODELO_ACOTADO (implementa una subtarea)
#            complejo       → ORQ_MODELO_COMPLEJO (correcciones tras dos rondas fallidas)
#            Un valor «claude:<modelo>[:<esfuerzo>]» arranca Claude Code en vez de Antigravity;
#            el resto son nombres de `agy models`.
#   carpeta  checkout donde trabaja (por defecto, la raíz de este repo). Para frentes en
#            paralelo, un worktree.
#
# Cada llamada deja una sesión nueva del agente: contexto limpio y el modelo que pide el encargo.

set -euo pipefail

nombre="${1:-}"
tipo="${2:-}"
raiz=$(git rev-parse --show-toplevel)
carpeta="${3:-$raiz}"
estado="$raiz/.orquestacion"
archivo_panel="$estado/$nombre.pane"
modelos="$estado/modelos.env"

uso() { echo "Uso: $0 <nombre> <planificador|revisor|revisor_ligero|acotado|complejo> [carpeta]" >&2; exit 1; }
[[ "$nombre" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || uso
[ "${HERDR_ENV:-}" = "1" ] || { echo "✘ Ejecuta esto dentro de herdr (HERDR_ENV no es 1)." >&2; exit 1; }
[ -d "$carpeta" ] || { echo "✘ No existe la carpeta $carpeta (¿falta git worktree add?)." >&2; exit 1; }
[ -f "$modelos" ] || {
  echo "✘ Falta .orquestacion/modelos.env (copia .agents/orquestacion/scripts/modelos.env.ejemplo y pon los nombres)." >&2
  exit 1; }
# shellcheck disable=SC1090
source "$modelos"

# Los nombres AGY_MODELO_* son los de versiones anteriores y siguen valiendo.
case "$tipo" in
  planificador)   modelo="${ORQ_MODELO_PLANIFICADOR:-${AGY_MODELO_PLANIFICADOR:-}}"; rol="planificador" ;;
  revisor)        modelo="${ORQ_MODELO_REVISOR:-${AGY_MODELO_REVISOR:-}}"; rol="revisor" ;;
  revisor_ligero) modelo="${ORQ_MODELO_REVISOR_LIGERO:-${AGY_MODELO_REVISOR_LIGERO:-${ORQ_MODELO_REVISOR:-${AGY_MODELO_REVISOR:-}}}}"; rol="revisor" ;;
  acotado)        modelo="${ORQ_MODELO_ACOTADO:-${AGY_MODELO_ACOTADO:-}}"; rol="operador" ;;
  complejo)       modelo="${ORQ_MODELO_COMPLEJO:-${AGY_MODELO_COMPLEJO:-}}"; rol="operador" ;;
  *) uso ;;
esac
case "$modelo" in ""|"<"*) echo "✘ modelos.env no tiene un nombre de modelo para '$tipo'." >&2; exit 1 ;; esac

mkdir -p "$estado"
existe() { herdr agent list 2>/dev/null | grep -qw "$nombre"; }

# 1. Cerrar la sesión anterior con ese nombre, si existe
if existe; then
  herdr agent prompt "$nombre" "/exit" >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do existe || break; sleep 1; done
  if existe; then
    echo "✘ La sesión anterior de '$nombre' no se cerró. Ciérrala a mano (/exit) y repite." >&2
    exit 1
  fi
fi

# 2. Reutilizar el panel de ese agente o crear uno con ORQ_ROL puesto (el hook bloquea todo push suyo)
panel=""
if [ -f "$archivo_panel" ]; then
  panel=$(cat "$archivo_panel")
  herdr pane get "$panel" >/dev/null 2>&1 || panel=""
fi
if [ -z "$panel" ]; then
  panel=$(herdr pane split --current --direction right --no-focus \
            --cwd "$carpeta" --env "ORQ_ROL=$rol" | jq -r '.result.pane.pane_id')
  [ -n "$panel" ] && [ "$panel" != "null" ] || { echo "✘ herdr no devolvió el id del panel." >&2; exit 1; }
  echo "$panel" > "$archivo_panel"
fi

# 3. Arrancar el agente con su modelo
# En un worktree, la carpeta de encargos (.orquestacion/ del repo principal) se añade al espacio de trabajo
extra=()
[ "$carpeta" != "$raiz" ] && extra=(--add-dir "$estado")
if [[ "$modelo" == claude:* ]]; then
  # Claude Code: claude:<modelo>[:<esfuerzo>], p. ej. claude:claude-opus-5-5:low
  IFS=: read -r _ modelo_claude esfuerzo <<< "$modelo"
  esf=()
  [ -n "${esfuerzo:-}" ] && esf=(--effort "$esfuerzo")
  herdr agent start "$nombre" --kind claude --pane "$panel" -- \
    --model "$modelo_claude" ${esf[@]+"${esf[@]}"} --permission-mode acceptEdits ${extra[@]+"${extra[@]}"}
else
  herdr agent start "$nombre" --kind agy --pane "$panel" -- \
    --model "$modelo" --dangerously-skip-permissions ${extra[@]+"${extra[@]}"}
fi

echo "✔ $nombre listo en el panel $panel ($carpeta) con $modelo ($tipo)."
