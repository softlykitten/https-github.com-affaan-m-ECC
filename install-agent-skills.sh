#!/usr/bin/env bash
# ============================================================
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
  # ES: Añade aquí las rutas reales de "repository" y "superpowers-main (1)"
  #     si también contienen SKILL.md
  # EN: Add here the real paths for "repository" and "superpowers-main (1)"
  #     if they also contain SKILL.md
)

TARGET_DIR="$HOME/.claude/skills"
mkdir -p "$TARGET_DIR"

found=0
skipped=0

for repo in "${REPO_PATHS[@]}"; do
  if [[ ! -d "$repo" ]]; then
    echo "⚠️  No existe: $repo  (corrige REPO_PATHS con la ruta real)" >&2
    echo "⚠️  Does not exist: $repo  (fix REPO_PATHS with the real path)" >&2
    continue
  fi

  while IFS= read -r -d '' skillmd; do
    skilldir="$(dirname "$skillmd")"
    skillname="$(basename "$skilldir")"
    dest="$TARGET_DIR/$skillname"

    if [[ -e "$dest" ]]; then
      echo "⚠️  '$skillname' ya existe en destino -> se omite (revisa manualmente si son distintas)"
      echo "⚠️  '$skillname' already exists at destination -> skipping (check manually if they differ)"
      skipped=$((skipped+1))
      continue
    fi

    cp -r "$skilldir" "$dest"
    echo "✅ Instalada: $skillname   <-   $skilldir"
    echo "✅ Installed: $skillname   <-   $skilldir"
    found=$((found+1))
  done < <(find "$repo" -type f -iname "SKILL.md" -print0)
done

echo ""
echo "Skills copiadas: $found   |   Omitidas por conflicto de nombre: $skipped"
echo "Skills copied: $found   |   Skipped due to name conflict: $skipped"
echo "Destino / Destination: $TARGET_DIR"
echo "Reinicia Claude Code (o abre una sesión nueva) para que las detecte."
echo "Restart Claude Code (or open a new session) so it picks them up."
echo ""
echo "IMPORTANTE: revisa el SKILL.md (y cualquier script asociado) de cada"
echo "skill antes de confiar en ella — se cargan automáticamente en TODAS"
echo "tus sesiones de Claude Code a partir de ahora."
echo "IMPORTANT: review the SKILL.md (and any associated scripts) of each"
echo "skill before trusting it — they load automatically in ALL your"
echo "Claude Code sessions from now on."
