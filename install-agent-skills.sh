#!/usr/bin/env bash
# ES: Instala Agent Skills locales (Claude Code) desde tus repos clonados.
#     Busca cualquier carpeta que contenga un SKILL.md dentro de cada
#     repo y la copia a ~/.claude/skills/<nombre-skill>/ (skills
#     "personales", disponibles en todos tus proyectos).
#
# EN: Installs local Claude Code Agent Skills from your cloned repos.
#     Finds any folder containing a SKILL.md inside each repo and
#     copies it to ~/.claude/skills/<skill-name>/ (personal skills,
#     available across all your projects).
# ============================================================
set -euo pipefail

# ES: 1) AJUSTA esta lista con las rutas locales reales de tus repos.
#     Ruta típica por defecto de GitHub Desktop: ~/Documents/GitHub/<repo>
# EN: 1) EDIT this list with the real local paths of your repos.
#     Typical GitHub Desktop default path: ~/Documents/GitHub/<repo>
REPO_PATHS=(
  "$HOME/Documents/GitHub/claude-deep-research-skill"   # 199-biotechnologies
  "$HOME/Documents/GitHub/garden-skills"                # ConardLi
  "$HOME/Documents/GitHub/ECC"                          # affaan-m
  "$HOME/Documents/GitHub/marketingskills"              # coreyhaines31
  "$HOME/Documents/GitHub/superpowers"                  # obra
  "$HOME/Documents/GitHub/claude-youtube"                # AgriciDaniel
  "$HOME/Documents/GitHub/ai-video-generator-claude"    # rediumvex
  "$HOME/Documents/GitHub/claude-skill-find-skill"      # fockus
  "$HOME/Documents/GitHub/claude-seo"                   # AgriciDaniel
  # ES: Estos 3 son subcarpetas de repos grandes (Anthropic/Vercel); si los
  #     clonas completos, el script solo instala la skill pedida, no todo el repo.
  # EN: These 3 are subfolders of large repos (Anthropic/Vercel); if you clone
  #     them fully, the script only installs the requested skill, not everything.
  "$HOME/Documents/GitHub/skills"                       # anthropics (mcp-builder)
  "$HOME/Documents/GitHub/claude-code"                  # anthropics (frontend-design)
  "$HOME/Documents/GitHub/agent-skills"                 # vercel-labs (web-design-guidelines)
  "$HOME/Documents/GitHub/agent-browser"                # vercel-labs (agent-browser)
  # ES: Añade aquí las rutas reales de "repository" y "superpowers-main (1)"
  #     si también contienen SKILL.md
  # EN: Add here the real paths for "repository" and "superpowers-main (1)"
  #     if they also contain SKILL.md
)

TARGET_DIR="$HOME/.claude/skills"
mkdir -p "$TARGET_DIR"

found=0
skipped=0

install_skill() {
  local skilldir="$1" name="${2:-}"
  [ -f "$skilldir/SKILL.md" ] || return 0
  [ -n "$name" ] || name="$(basename "$skilldir")"
  local dest="$TARGET_DIR/$name"

  if [[ -e "$dest" ]]; then
    echo "⚠️  '$name' ya existe en destino -> se omite (revisa manualmente si son distintas)"
    echo "⚠️  '$name' already exists at destination -> skipping (check manually if they differ)"
    skipped=$((skipped+1))
    return
  fi

  cp -r "$skilldir" "$dest"
  echo "✅ Instalada / Installed: $name   <-   $skilldir"
  found=$((found+1))
}

for repo in "${REPO_PATHS[@]}"; do
  if [[ ! -d "$repo" ]]; then
    echo "⚠️  No existe: $repo  (corrige REPO_PATHS con la ruta real)" >&2
    echo "⚠️  Does not exist: $repo  (fix REPO_PATHS with the real path)" >&2
    continue
  fi

  reponame="$(basename "$repo")"

  # ES/EN: repos grandes de Anthropic/Vercel -> solo la skill pedida, no todo.
  case "$reponame" in
    skills)
      [ -f "$repo/skills/mcp-builder/SKILL.md" ] && install_skill "$repo/skills/mcp-builder" "mcp-builder"
      continue ;;
    claude-code)
      [ -f "$repo/plugins/frontend-design/skills/frontend-design/SKILL.md" ] && \
        install_skill "$repo/plugins/frontend-design/skills/frontend-design" "frontend-design"
      continue ;;
    agent-skills)
      [ -f "$repo/skills/web-design-guidelines/SKILL.md" ] && \
        install_skill "$repo/skills/web-design-guidelines" "vercel-web-design-guidelines"
      continue ;;
    agent-browser)
      [ -f "$repo/skills/agent-browser/SKILL.md" ] && install_skill "$repo/skills/agent-browser" "agent-browser"
      continue ;;
  esac

  # ES/EN: ai-video-generator-claude -> usar el nombre real del frontmatter.
  if [ "$reponame" = "ai-video-generator-claude" ]; then
    for d in "$repo/skills"/*/; do
      [ -f "$d/SKILL.md" ] || continue
      n="$(grep -m1 '^name:' "$d/SKILL.md" | sed 's/^name:[[:space:]]*//')"
      install_skill "$d" "$n"
    done
    continue
  fi

  # ES/EN: claude-seo -> "seo" y "seo-audit" colisionan con marketingskills;
  # se renombran para no perder ninguna de las dos versiones.
  if [ "$reponame" = "claude-seo" ]; then
    for d in "$repo/skills"/*/ "$repo"/extensions/*/skills/*/; do
      [ -d "$d" ] || continue
      n="$(basename "$d")"
      case "$n" in
        seo) n="claude-seo" ;;
        seo-audit) n="seo-technical-audit" ;;
      esac
      install_skill "$d" "$n"
    done
    continue
  fi

  # ES/EN: claude-skill-find-skill -> solo el SKILL.md raiz (adapters/ es para Codex).
  if [ "$reponame" = "claude-skill-find-skill" ]; then
    [ -f "$repo/SKILL.md" ] && install_skill "$repo" "find-skill"
    continue
  fi

  # ES/EN: claude-youtube -> una sola skill compuesta.
  if [ "$reponame" = "claude-youtube" ] && [ -d "$repo/skills/claude-youtube" ]; then
    install_skill "$repo/skills/claude-youtube" "claude-youtube"
    continue
  fi

  # ES/EN: este repo ES la skill (SKILL.md en la raiz), no una coleccion.
  if [ "$reponame" = "claude-deep-research-skill" ]; then
    [ -f "$repo/SKILL.md" ] && install_skill "$repo" "deep-research"
    continue
  fi

  # ES/EN: resto de repos (coleccion generica de skills bajo skills/).
  while IFS= read -r -d '' skillmd; do
    install_skill "$(dirname "$skillmd")"
  done < <(find "$repo" -type f -iname "SKILL.md" -print0)
done

echo ""
echo "Skills copiadas / copied: $found   |   Omitidas / skipped: $skipped"
echo "Destino / Destination: $TARGET_DIR"
echo "Reinicia Claude Code (o abre una sesion nueva) para que las detecte."
echo "Restart Claude Code (or open a new session) so it picks them up."
echo ""
echo "IMPORTANTE: revisa el SKILL.md (y cualquier script asociado) de cada"
echo "skill antes de confiar en ella — se cargan automaticamente en TODAS"
echo "tus sesiones de Claude Code a partir de ahora."
echo "IMPORTANT: review the SKILL.md (and any associated scripts) of each"
echo "skill before trusting it — they load automatically in ALL your"
echo "Claude Code sessions from now on."
