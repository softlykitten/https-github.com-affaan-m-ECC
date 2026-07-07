# ES: Instala Agent Skills locales (Claude Code) desde tus repos clonados.
#     Busca cualquier carpeta que contenga un SKILL.md dentro de cada
#     repo y la copia a $HOME\.claude\skills\<nombre-skill>\ (skills
#     "personales", disponibles en todos tus proyectos).
#
# EN: Installs local Claude Code Agent Skills from your cloned repos.
#     Finds any folder containing a SKILL.md inside each repo and
#     copies it to $HOME\.claude\skills\<skill-name>\ (personal skills,
#     available across all your projects).
#
# Uso / Usage:
#   powershell -ExecutionPolicy Bypass -File install-agent-skills.ps1

# ES: 1) AJUSTA esta lista con las rutas locales reales de tus repos.
#     Ruta tipica por defecto de GitHub Desktop: $HOME\Documents\GitHub\<repo>
# EN: 1) EDIT this list with the real local paths of your repos.
#     Typical GitHub Desktop default path: $HOME\Documents\GitHub\<repo>
$RepoPaths = @(
  "$HOME\Documents\GitHub\claude-deep-research-skill",   # 199-biotechnologies
  "$HOME\Documents\GitHub\garden-skills",                # ConardLi
  "$HOME\Documents\GitHub\ECC",                          # affaan-m
  "$HOME\Documents\GitHub\marketingskills",              # coreyhaines31
  "$HOME\Documents\GitHub\superpowers"                   # obra
  # ES: Anade aqui otras rutas si tienes mas repos con SKILL.md
  # EN: Add more paths here if you have other repos with SKILL.md
)

$Dest = Join-Path $HOME ".claude\skills"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$found = 0
$skipped = 0

foreach ($repo in $RepoPaths) {
    if (-not (Test-Path $repo)) {
        Write-Warning "No existe: $repo  (corrige RepoPaths con la ruta real)"
        Write-Warning "Does not exist: $repo  (fix RepoPaths with the real path)"
        continue
    }

    Get-ChildItem -Path $repo -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $skillDir = $_.Directory
        $skillName = $skillDir.Name
        $destPath = Join-Path $Dest $skillName

        if (Test-Path $destPath) {
            Write-Warning "'$skillName' ya existe en destino -> se omite (revisa manualmente si son distintas)"
            Write-Warning "'$skillName' already exists at destination -> skipping (check manually if they differ)"
            $script:skipped++
            return
        }

        Copy-Item -Path $skillDir.FullName -Destination $destPath -Recurse
        Write-Host "Instalada / Installed: $skillName   <-   $($skillDir.FullName)"
        $script:found++
    }
}

Write-Host ""
Write-Host "Skills copiadas / copied: $found   |   Omitidas / skipped: $skipped"
Write-Host "Destino / Destination: $Dest"
Write-Host "Reinicia Claude Code (o abre una sesion nueva) para que las detecte."
Write-Host "Restart Claude Code (or open a new session) so it picks them up."
Write-Host ""
Write-Host "IMPORTANTE: revisa el SKILL.md (y cualquier script asociado) de cada"
Write-Host "skill antes de confiar en ella - se cargan automaticamente en TODAS"
Write-Host "tus sesiones de Claude Code a partir de ahora."
Write-Host "IMPORTANT: review the SKILL.md (and any associated scripts) of each"
Write-Host "skill before trusting it - they load automatically in ALL your"
Write-Host "Claude Code sessions from now on."
