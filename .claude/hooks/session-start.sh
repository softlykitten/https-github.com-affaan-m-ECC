#!/bin/bash
# ES: Reinstala las Agent Skills personales en ~/.claude/skills al iniciar
#     una sesion remota, ya que el contenedor es efimero y no persiste entre
#     sesiones. Se salta el trabajo si ya existe el marcador de instalacion.
# EN: Reinstalls personal Agent Skills into ~/.claude/skills at the start of
#     a remote session, since the container is ephemeral and doesn't persist
#     between sessions. Skips work if the install marker already exists.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

DEST="$HOME/.claude/skills"
MARKER="$DEST/.agent-skills-installer-marker"

if [ -f "$MARKER" ]; then
  exit 0
fi

mkdir -p "$DEST"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

declare -A REPOS=(
  [superpowers]="https://github.com/obra/superpowers.git"
  [garden-skills]="https://github.com/ConardLi/garden-skills.git"
  [marketingskills]="https://github.com/coreyhaines31/marketingskills.git"
  [claude-deep-research-skill]="https://github.com/199-biotechnologies/claude-deep-research-skill.git"
  [ECC]="https://github.com/affaan-m/ECC.git"
)

for name in "${!REPOS[@]}"; do
  git clone --depth 1 --quiet "${REPOS[$name]}" "$TMP/$name" 2>/dev/null || true
done

install_skill_dir() {
  local skilldir="$1"
  local skillname
  skillname="$(basename "$skilldir")"
  [ -f "$skilldir/SKILL.md" ] || return 0
  [ -e "$DEST/$skillname" ] && return 0
  cp -r "$skilldir" "$DEST/$skillname"
}

# ES/EN: estas 3 solo tienen skills bajo skills/ en la raiz del repo.
for repo in marketingskills superpowers garden-skills; do
  [ -d "$TMP/$repo/skills" ] || continue
  for d in "$TMP/$repo/skills"/*/; do
    [ -d "$d" ] && install_skill_dir "$d"
  done
done

# ES/EN: ECC duplica cada skill para otras herramientas (.cursor, .agents,
# .kiro); solo tomamos la carpeta skills/ que es la que usa Claude Code.
if [ -d "$TMP/ECC/skills" ]; then
  for d in "$TMP/ECC/skills"/*/; do
    [ -d "$d" ] && install_skill_dir "$d"
  done
fi

# ES/EN: este repo ES la skill (SKILL.md en la raiz), no una coleccion.
if [ -f "$TMP/claude-deep-research-skill/SKILL.md" ] && [ ! -e "$DEST/deep-research" ]; then
  cp -r "$TMP/claude-deep-research-skill" "$DEST/deep-research"
  rm -rf "$DEST/deep-research/.git"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$MARKER"
