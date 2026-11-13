#!/usr/bin/env bash
# Instala o actualiza en un proyecto el protocolo de orquestación y las skills de este repositorio.
#
# Uso:
#   bin/instalar.sh <proyecto> [--skills a,b,c | --skills todas] [--sin-orquestacion]
#   bin/instalar.sh --global [--skills a,b,c | --skills todas]
#   bin/instalar.sh --lista
#
#   <proyecto>          carpeta de un repositorio git. Los archivos se COPIAN dentro del proyecto
#                       y van en su git: así llegan a los worktrees, a la CI y a otras máquinas.
#   --skills            skills a instalar. Sin esta opción solo se actualizan las ya instaladas.
#   --sin-orquestacion  instala solo skills (para proyectos que no usan herdr).
#   --global            enlaza las skills en ~/.agents/skills y ~/.claude/skills (todas por defecto).
#   --lista             muestra las skills disponibles.
#
# Volver a ejecutarlo actualiza lo instalado. Nunca pisa los archivos propios del proyecto
# (.agents/PROYECTO.md, .agents/proyecto.conf, CLAUDE.md, ni el texto de AGENTS.md fuera del bloque gestionado).

set -euo pipefail

ORQ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INICIO="<!-- agent-orchestrator:inicio"
FIN="<!-- agent-orchestrator:fin -->"

uso() { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-1}"; }
info() { printf '  \033[32m✔\033[0m %s\n' "$1"; }
aviso() { printf '  \033[33m•\033[0m %s\n' "$1"; }
error() { printf '\033[31m✘\033[0m %s\n' "$1" >&2; exit 1; }

disponibles() { for d in "$ORQ"/skills/*/; do [ -f "$d/SKILL.md" ] && basename "$d"; done; }

destino=""; skills=""; global=0; orquestacion=1
while [ $# -gt 0 ]; do
  case "$1" in
    --lista)
      for s in $(disponibles); do
        printf '%-32s %s\n' "$s" "$(sed -n 's/^description: *"\{0,1\}//p' "$ORQ/skills/$s/SKILL.md" | cut -c1-90)…"
      done
      exit 0 ;;
    --global) global=1 ;;
    --sin-orquestacion) orquestacion=0 ;;
    --skills) shift; skills="${1:-}"; [ -n "$skills" ] || uso ;;
    -h|--help) uso 0 ;;
    -*) uso ;;
    *) [ -z "$destino" ] || uso; destino="$1" ;;
  esac
  shift
done

# Convierte la lista pedida en nombres validados, uno por línea
resolver_skills() {  # $1: lista con comas o «todas»
  if [ "$1" = "todas" ]; then disponibles; return; fi
  echo "$1" | tr ',' '\n' | while read -r s; do
    [ -z "$s" ] && continue
    [ -f "$ORQ/skills/$s/SKILL.md" ] || error "No existe la skill '$s'. Mira las disponibles con --lista."
    echo "$s"
  done
}

# ── Modo global: enlaces a este clon ────────────────────────────────────────────────────────────
if [ "$global" -eq 1 ]; then
  [ -z "$destino" ] || uso
  echo "Skills globales (enlaces a $ORQ/skills)"
  for s in $(resolver_skills "${skills:-todas}"); do
    for base in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
      mkdir -p "$base"
      if [ -e "$base/$s" ] && [ ! -L "$base/$s" ]; then
        aviso "$base/$s ya existe y no es un enlace: no se toca"
      else
        ln -sfn "$ORQ/skills/$s" "$base/$s"
      fi
    done
    info "$s"
  done
  exit 0
fi

# ── Modo proyecto: copias dentro del repositorio ────────────────────────────────────────────────
[ -n "$destino" ] || uso
[ -d "$destino" ] || error "No existe la carpeta $destino"
raiz=$(git -C "$destino" rev-parse --show-toplevel 2>/dev/null) || error "$destino no es un repositorio git"
[ "$raiz" != "$ORQ" ] || error "El destino es este mismo repositorio"
cd "$raiz"
version="$(git -C "$ORQ" rev-parse --short HEAD 2>/dev/null || echo sin-commit)"
[ -z "$(git -C "$ORQ" status --porcelain 2>/dev/null)" ] || version="$version+cambios"

echo "Proyecto: $raiz"

if [ "$orquestacion" -eq 1 ]; then
  echo "Orquestación"
  mkdir -p .agents/orquestacion .agents/rules
  rsync -a --delete --exclude VERSION --exclude reglas "$ORQ/orquestacion/" .agents/orquestacion/
  cp "$ORQ"/orquestacion/reglas/*.md .agents/rules/
  printf '%s\n' "$version" > .agents/orquestacion/VERSION
  info "protocolo, plantillas, scripts y reglas de rol ($version)"

  for f in PROYECTO.md proyecto.conf; do
    if [ -f ".agents/$f" ]; then info ".agents/$f ya existe: no se toca"
    else cp "$ORQ/plantillas/$f" ".agents/$f"; aviso ".agents/$f creado: complétalo"; fi
  done

  # AGENTS.md: se crea, o se reemplaza solo el bloque gestionado
  if [ ! -f AGENTS.md ]; then
    cat "$ORQ/plantillas/AGENTS.md" "$ORQ/plantillas/bloque_agents.md" > AGENTS.md
    aviso "AGENTS.md creado: completa la cabecera"
  elif grep -qF "$INICIO" AGENTS.md; then
    awk -v ini="$INICIO" -v fin="$FIN" -v bloque="$ORQ/plantillas/bloque_agents.md" '
      index($0, ini) { while ((getline l < bloque) > 0) print l; dentro = 1; next }
      index($0, fin) { dentro = 0; next }
      !dentro' AGENTS.md > AGENTS.md.tmp && mv AGENTS.md.tmp AGENTS.md
    info "AGENTS.md: bloque gestionado actualizado"
  else
    { echo; cat "$ORQ/plantillas/bloque_agents.md"; } >> AGENTS.md
    info "AGENTS.md: bloque gestionado añadido al final"
  fi

  if [ ! -f CLAUDE.md ]; then
    cp "$ORQ/plantillas/CLAUDE.md" CLAUDE.md
    info "CLAUDE.md creado (importa AGENTS.md)"
  elif ! grep -q "AGENTS.md" CLAUDE.md; then
    aviso "CLAUDE.md existe y no menciona AGENTS.md: añade una línea «@AGENTS.md»"
  fi

  if git check-ignore -q .orquestacion/x; then :; else
    printf '\n# Encargos y reportes entre agentes (agent-orchestrator)\n.orquestacion/\n' >> .gitignore
    info ".orquestacion/ añadida al .gitignore"
  fi

  ganchos="$(git config core.hooksPath 2>/dev/null || true)"
  if [ -z "$ganchos" ]; then
    git config core.hooksPath .agents/orquestacion/scripts/hooks
    info "barrera de push activada (core.hooksPath)"
  elif [ "$ganchos" != ".agents/orquestacion/scripts/hooks" ]; then
    aviso "core.hooksPath ya vale '$ganchos': la barrera de push nueva NO está activa"
  fi
fi

# Skills: las pedidas más las que ya estaban instaladas y existen en este repositorio
echo "Skills"
pedidas=""
[ -z "$skills" ] || pedidas="$(resolver_skills "$skills")"
instaladas="$(for s in $(disponibles); do if [ -d ".agents/skills/$s" ]; then echo "$s"; fi; done)"
lista="$(printf '%s\n%s\n' "$pedidas" "$instaladas" | sort -u | sed '/^$/d')"
if [ -z "$lista" ]; then
  aviso "ninguna instalada. Elige con --skills a,b,c (o --skills todas); mira --lista"
else
  mkdir -p .agents/skills .claude/skills
  for s in $lista; do
    rsync -a --delete "$ORQ/skills/$s/" ".agents/skills/$s/"
    if [ -e ".claude/skills/$s" ] && [ ! -L ".claude/skills/$s" ]; then
      aviso "$s: .claude/skills/$s ya existe y no es un enlace: no se toca"
    else
      ln -sfn "../../.agents/skills/$s" ".claude/skills/$s"
    fi
    info "$s"
  done
  if git check-ignore -q .claude/skills/x; then
    aviso ".claude/ está en el .gitignore: los enlaces para Claude Code no viajan a worktrees ni a otras máquinas."
    aviso "  Para que viajen, cambia «.claude/» por «.claude/*» y añade «!.claude/skills/» en el .gitignore."
  fi
fi

echo
echo "Listo. Revisa con «git status» y haz commit de .agents/, .claude/skills/, AGENTS.md y CLAUDE.md."
