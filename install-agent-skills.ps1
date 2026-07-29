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
  "$HOME\Documents\GitHub\superpowers",                  # obra
  "$HOME\Documents\GitHub\claude-youtube",               # AgriciDaniel
  "$HOME\Documents\GitHub\ai-video-generator-claude",    # rediumvex
  "$HOME\Documents\GitHub\claude-skill-find-skill",      # fockus
  "$HOME\Documents\GitHub\claude-seo",                   # AgriciDaniel
  # ES: Estos 4 son subcarpetas de repos grandes (Anthropic/Vercel); si los
  #     clonas completos, el script solo instala la skill pedida, no todo el repo.
  # EN: These 4 are subfolders of large repos (Anthropic/Vercel); if you clone
  #     them fully, the script only installs the requested skill, not everything.
  "$HOME\Documents\GitHub\skills",                       # anthropics (mcp-builder)
  "$HOME\Documents\GitHub\claude-code",                  # anthropics (frontend-design)
  "$HOME\Documents\GitHub\agent-skills",                 # vercel-labs (web-design-guidelines)
  "$HOME\Documents\GitHub\agent-browser",                # vercel-labs (agent-browser)
  "$HOME\Documents\GitHub\awesome-claude-corporate-skills", # w95 (166 skills: finanzas/RRHH/legal/etc.)
  "$HOME\Documents\GitHub\skills-n8n",                   # n8n-io (clona n8n-io/skills como "skills-n8n")
  "$HOME\Documents\GitHub\startup-skills",               # bwerneckm
  "$HOME\Documents\GitHub\logo-designer-skill",          # neonwatty
  "$HOME\Documents\GitHub\claude-skills"                 # rampstackco (branding/producto)
  # ES: Anade aqui otras rutas si tienes mas repos con SKILL.md
  # EN: Add more paths here if you have other repos with SKILL.md
)

$Dest = Join-Path $HOME ".claude\skills"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$found = 0
$skipped = 0

function Install-Skill {
    param($SkillDir, $Name)

    if (-not (Test-Path (Join-Path $SkillDir "SKILL.md"))) { return }
    if (-not $Name) { $Name = Split-Path $SkillDir -Leaf }
    $destPath = Join-Path $Dest $Name

    if (Test-Path $destPath) {
        Write-Warning "'$Name' ya existe en destino -> se omite (revisa manualmente si son distintas)"
        Write-Warning "'$Name' already exists at destination -> skipping (check manually if they differ)"
        $script:skipped++
        return
    }

    Copy-Item -Path $SkillDir -Destination $destPath -Recurse
    Write-Host "Instalada / Installed: $Name   <-   $SkillDir"
    $script:found++
}

foreach ($repo in $RepoPaths) {
    if (-not (Test-Path $repo)) {
        Write-Warning "No existe: $repo  (corrige RepoPaths con la ruta real)"
        Write-Warning "Does not exist: $repo  (fix RepoPaths with the real path)"
        continue
    }

    $repoName = Split-Path $repo -Leaf

    # ES/EN: repos grandes de Anthropic/Vercel -> solo la skill pedida, no todo.
    switch ($repoName) {
        "skills" {
            $p = Join-Path $repo "skills\mcp-builder"
            Install-Skill $p "mcp-builder"
            continue
        }
        "claude-code" {
            $p = Join-Path $repo "plugins\frontend-design\skills\frontend-design"
            Install-Skill $p "frontend-design"
            continue
        }
        "agent-skills" {
            $p = Join-Path $repo "skills\web-design-guidelines"
            Install-Skill $p "vercel-web-design-guidelines"
            continue
        }
        "agent-browser" {
            $p = Join-Path $repo "skills\agent-browser"
            Install-Skill $p "agent-browser"
            continue
        }
        "ai-video-generator-claude" {
            # ES/EN: usar el nombre real del frontmatter (seedance-*).
            Get-ChildItem -Path (Join-Path $repo "skills") -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $skillMd = Join-Path $_.FullName "SKILL.md"
                if (Test-Path $skillMd) {
                    $content = Get-Content $skillMd -Raw
                    if ($content -match '(?m)^name:\s*(.+)$') {
                        Install-Skill $_.FullName $Matches[1].Trim()
                    }
                }
            }
            continue
        }
        "claude-seo" {
            # ES/EN: "seo" y "seo-audit" colisionan con marketingskills; se renombran.
            $dirs = @(Get-ChildItem -Path (Join-Path $repo "skills") -Directory -ErrorAction SilentlyContinue)
            $dirs += Get-ChildItem -Path (Join-Path $repo "extensions\*\skills\*") -Directory -ErrorAction SilentlyContinue
            foreach ($d in $dirs) {
                $n = $d.Name
                if ($n -eq "seo") { $n = "claude-seo" }
                elseif ($n -eq "seo-audit") { $n = "seo-technical-audit" }
                Install-Skill $d.FullName $n
            }
            continue
        }
        "claude-skill-find-skill" {
            Install-Skill $repo "find-skill"
            continue
        }
        "claude-youtube" {
            $p = Join-Path $repo "skills\claude-youtube"
            Install-Skill $p "claude-youtube"
            continue
        }
        "claude-deep-research-skill" {
            Install-Skill $repo "deep-research"
            continue
        }
        "skills-n8n" {
            # ES/EN: repo n8n-io/skills clonado como "skills-n8n" para no chocar
            # con la carpeta "skills" de anthropics/skills (mcp-builder).
            Get-ChildItem -Path (Join-Path $repo "skills") -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
                Install-Skill $_.Directory.FullName $null
            }
            continue
        }
        "claude-skills" {
            # ES/EN: rampstackco/claude-skills -> solo skills/, "dist/" es un duplicado compilado.
            Get-ChildItem -Path (Join-Path $repo "skills") -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
                Install-Skill $_.Directory.FullName $null
            }
            continue
        }
        default {
            # ES/EN: resto de repos (coleccion generica de skills bajo skills/).
            Get-ChildItem -Path $repo -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
                Install-Skill $_.Directory.FullName $null
            }
        }
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
