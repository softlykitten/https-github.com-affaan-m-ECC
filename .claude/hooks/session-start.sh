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

install_skill_dir() {
  local skilldir="$1" name="${2:-}"
  [ -f "$skilldir/SKILL.md" ] || return 0
  [ -n "$name" ] || name="$(basename "$skilldir")"
  [ -e "$DEST/$name" ] && return 0
  cp -r "$skilldir" "$DEST/$name"
}

# ES: repos "coleccion completa" -> se copian todos sus SKILL.md.
# EN: "full collection" repos -> every SKILL.md inside gets copied.
declare -A COLLECTION_REPOS=(
  [superpowers]="https://github.com/obra/superpowers.git"
  [garden-skills]="https://github.com/ConardLi/garden-skills.git"
  [marketingskills]="https://github.com/coreyhaines31/marketingskills.git"
  [ECC]="https://github.com/affaan-m/ECC.git"
  [claude-youtube]="https://github.com/AgriciDaniel/claude-youtube.git"
  [ai-video-generator-claude]="https://github.com/rediumvex/ai-video-generator-claude.git"
  [claude-skill-find-skill]="https://github.com/fockus/claude-skill-find-skill.git"
  [claude-seo]="https://github.com/AgriciDaniel/claude-seo.git"
)

for name in "${!COLLECTION_REPOS[@]}"; do
  git clone --depth 1 --quiet "${COLLECTION_REPOS[$name]}" "$TMP/$name" 2>/dev/null || true
done

# ES/EN: marketingskills, superpowers, garden-skills solo tienen skills bajo skills/.
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

# ES/EN: claude-youtube -> una sola skill compuesta en skills/claude-youtube.
[ -d "$TMP/claude-youtube/skills/claude-youtube" ] && \
  install_skill_dir "$TMP/claude-youtube/skills/claude-youtube" "claude-youtube"

# ES/EN: ai-video-generator-claude -> 10 skills; usar el nombre real del
# frontmatter (seedance-*) en vez del nombre numerado de la carpeta.
if [ -d "$TMP/ai-video-generator-claude/skills" ]; then
  for d in "$TMP/ai-video-generator-claude/skills"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    n="$(grep -m1 '^name:' "$d/SKILL.md" | sed 's/^name:[[:space:]]*//')"
    install_skill_dir "$d" "$n"
  done
fi

# ES/EN: find-skill -> SKILL.md en la raiz; se ignora adapters/ (es para Codex).
[ -f "$TMP/claude-skill-find-skill/SKILL.md" ] && \
  install_skill_dir "$TMP/claude-skill-find-skill" "find-skill"

# ES/EN: claude-seo -> skills/ + extensions/*/skills/*. "seo" y "seo-audit"
# colisionan con nombres ya usados por marketingskills; se renombran.
if [ -d "$TMP/claude-seo/skills" ]; then
  for d in "$TMP/claude-seo/skills"/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    case "$n" in
      seo) n="claude-seo" ;;
      seo-audit) n="seo-technical-audit" ;;
    esac
    install_skill_dir "$d" "$n"
  done
fi
if [ -d "$TMP/claude-seo/extensions" ]; then
  for d in "$TMP/claude-seo/extensions"/*/skills/*/; do
    [ -d "$d" ] && install_skill_dir "$d"
  done
fi

# ES/EN: este repo ES la skill (SKILL.md en la raiz), no una coleccion.
[ -f "$TMP/claude-deep-research-skill/SKILL.md" ] || \
  git clone --depth 1 --quiet "https://github.com/199-biotechnologies/claude-deep-research-skill.git" "$TMP/claude-deep-research-skill" 2>/dev/null || true
if [ -f "$TMP/claude-deep-research-skill/SKILL.md" ] && [ ! -e "$DEST/deep-research" ]; then
  cp -r "$TMP/claude-deep-research-skill" "$DEST/deep-research"
  rm -rf "$DEST/deep-research/.git"
fi

# ES/EN: skills sueltas dentro de repos grandes -> solo la subcarpeta pedida,
# no el repo completo (evita traer decenas de skills no solicitadas).
declare -A SINGLE_SKILLS=(
  ["https://github.com/anthropics/skills.git skills/mcp-builder"]="mcp-builder"
  ["https://github.com/anthropics/claude-code.git plugins/frontend-design/skills/frontend-design"]="frontend-design"
  ["https://github.com/vercel-labs/agent-skills.git skills/web-design-guidelines"]="vercel-web-design-guidelines"
  ["https://github.com/vercel-labs/agent-browser.git skills/agent-browser"]="agent-browser"
)

i=0
for key in "${!SINGLE_SKILLS[@]}"; do
  i=$((i+1))
  url="${key% *}"
  subpath="${key#* }"
  destname="${SINGLE_SKILLS[$key]}"
  [ -e "$DEST/$destname" ] && continue
  clonedir="$TMP/single$i"
  git clone --depth 1 --quiet "$url" "$clonedir" 2>/dev/null || continue
  [ -f "$clonedir/$subpath/SKILL.md" ] && install_skill_dir "$clonedir/$subpath" "$destname"
done

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$MARKER"
