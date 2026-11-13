#!/usr/bin/env bash
# Comprueba que esta máquina y este clon estén listos para orquestar con herdr.
# No instala nada: solo informa.
# Uso: bash .agents/orquestacion/scripts/comprobar.sh   (desde cualquier carpeta del repo)

set -u
fallos=0
ok()    { printf '  \033[32m✔\033[0m %s\n' "$1"; }
falla() { printf '  \033[31m✘\033[0m %s\n      → %s\n' "$1" "$2"; fallos=$((fallos + 1)); }
aviso() { printf '  \033[33m•\033[0m %s\n      → %s\n' "$1" "$2"; }

echo "Herramientas"
comprobar() {  # comando, cómo instalarlo
  if command -v "$1" >/dev/null 2>&1; then ok "$1"; else falla "$1 no encontrado" "$2"; fi
}
comprobar git    "brew install git"
comprobar gh     "brew install gh"
comprobar jq     "brew install jq"
comprobar node   "brew install node   (necesario para npx skills)"
comprobar herdr  "brew install herdr   o   curl -fsSL https://herdr.dev/install.sh | sh"
comprobar claude "curl -fsSL https://claude.ai/install.sh | bash"
if command -v agy >/dev/null 2>&1; then ok "agy"; else
  aviso "agy no encontrado" "solo hace falta si algún rol usa Antigravity CLI"; fi

echo "GitHub"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  ok "gh autenticado"
else
  falla "gh sin sesión" "gh auth login && gh auth setup-git"
fi
[ -n "$(git config user.name 2>/dev/null)" ]  && ok "git user.name"  || falla "git user.name vacío"  'git config --global user.name "<tu nombre>"'
[ -n "$(git config user.email 2>/dev/null)" ] && ok "git user.email" || falla "git user.email vacío" 'git config --global user.email "<tu correo>"'

echo "Repositorio"
if raiz=$(git rev-parse --show-toplevel 2>/dev/null); then
  ORQ_RAMA_BASE="dev"
  # shellcheck disable=SC1091
  [ -f "$raiz/.agents/proyecto.conf" ] && . "$raiz/.agents/proyecto.conf"
  [ -f "$raiz/.agents/orquestacion/PROTOCOLO.md" ] && ok "protocolo presente" \
    || falla "falta .agents/orquestacion/PROTOCOLO.md" "instálalo con bin/instalar.sh de agent-orchestrator"
  [ -f "$raiz/.agents/rules/orquestacion_operador.md" ] && ok "reglas de rol presentes" \
    || falla "faltan las reglas de rol en .agents/rules/" "instálalas con bin/instalar.sh de agent-orchestrator"
  if [ -f "$raiz/.agents/PROYECTO.md" ] && ! grep -q "<completa" "$raiz/.agents/PROYECTO.md"; then
    ok ".agents/PROYECTO.md completo"
  else
    falla ".agents/PROYECTO.md falta o tiene texto de plantilla" "complétalo con el stack, los comandos y la lista de revisión"
  fi
  if git fetch -q origin "$ORQ_RAMA_BASE" 2>/dev/null &&
     [ "$(git rev-parse "$ORQ_RAMA_BASE" 2>/dev/null)" = "$(git rev-parse "origin/$ORQ_RAMA_BASE" 2>/dev/null)" ]; then
    ok "$ORQ_RAMA_BASE al día con origin/$ORQ_RAMA_BASE"
  else
    aviso "$ORQ_RAMA_BASE local distinto de origin/$ORQ_RAMA_BASE" "git switch $ORQ_RAMA_BASE && git pull --ff-only"
  fi
  if [ -d "$raiz/.claude/skills/herdr" ] || [ -d "$raiz/.agents/skills/herdr" ] || [ -d "$HOME/.claude/skills/herdr" ]; then
    ok "skill herdr instalada"
  else
    falla "skill herdr no encontrada" "npx skills add herdrdev/herdr --skill herdr"
  fi
  [ "$(git config core.hooksPath 2>/dev/null)" = ".agents/orquestacion/scripts/hooks" ] && ok "barrera de push activa" \
    || falla "barrera de push sin activar" "git config core.hooksPath .agents/orquestacion/scripts/hooks"
  principal=$(dirname "$(cd "$raiz" && cd "$(git rev-parse --git-common-dir)" && pwd)")
  modelos="$principal/.orquestacion/modelos.env"
  if [ -f "$modelos" ] && ! grep -q '="<' "$modelos"; then
    ok "modelos.env con nombres de modelo"
  else
    falla ".orquestacion/modelos.env falta o tiene texto de ejemplo" \
      "mkdir -p .orquestacion && cp .agents/orquestacion/scripts/modelos.env.ejemplo .orquestacion/modelos.env"
  fi
  git -C "$raiz" check-ignore -q .orquestacion/x && ok ".orquestacion/ fuera de git" \
    || falla ".orquestacion/ no está ignorada" "añade .orquestacion/ al .gitignore"
else
  falla "no estás dentro de un repositorio git" "cd <repo>"
fi

echo
if [ "$fallos" -eq 0 ]; then
  echo "Todo listo. Arranca con: herdr  →  claude"
else
  echo "$fallos punto(s) pendiente(s)."
  exit 1
fi
