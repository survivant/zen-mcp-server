# ============================================================================
# Zen MCP Server - Script d'Installation pour Windows 11
#
# Ce script PowerShell facilite l'installation de Zen MCP Server sur
# Windows 11 en automatisant :
# - Vérification de WSL
# - Téléchargement et configuration du projet
# - Lancement de l'installation dans WSL
# - Configuration de Claude Desktop
# ============================================================================

# Définir les préférences
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'  # Accélérer les téléchargements

# ----------------------------------------------------------------------------
# Couleurs pour l'affichage
# ----------------------------------------------------------------------------

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "! " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# ----------------------------------------------------------------------------
# Vérification de WSL
# ----------------------------------------------------------------------------

function Test-WSLInstalled {
    Write-Header "Vérification de WSL"

    try {
        $wslVersion = wsl --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WSL est installé"
            return $true
        }
    }
    catch {
        # WSL n'est pas installé ou commande non reconnue
    }

    Write-Error-Custom "WSL n'est pas installé"
    Write-Host ""
    Write-Host "Pour installer WSL :"
    Write-Host "  1. Ouvrez PowerShell en tant qu'administrateur"
    Write-Host "  2. Exécutez : wsl --install"
    Write-Host "  3. Redémarrez votre ordinateur"
    Write-Host "  4. Relancez ce script"
    Write-Host ""

    $response = Read-Host "Voulez-vous installer WSL maintenant ? (O/n)"
    if ($response -match "^[Oo]$" -or $response -eq "") {
        Write-Info "Tentative d'installation de WSL (nécessite les droits administrateur)..."

        # Vérifier si on a les droits admin
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (-not $isAdmin) {
            Write-Warning-Custom "Droits administrateur requis pour installer WSL"
            Write-Host ""
            Write-Host "Relancez PowerShell en tant qu'administrateur et exécutez :"
            Write-Host "  wsl --install"
            Write-Host ""
            exit 1
        }

        # Installer WSL
        wsl --install
        Write-Success "WSL installé"
        Write-Warning-Custom "Redémarrage requis. Relancez ce script après le redémarrage."
        exit 0
    }

    return $false
}

function Test-WSLRunning {
    Write-Info "Vérification de l'état de WSL..."

    try {
        $distributions = wsl --list --quiet 2>&1
        if ($LASTEXITCODE -eq 0 -and $distributions) {
            Write-Success "Distribution WSL trouvée"
            return $true
        }
    }
    catch {
        # Aucune distribution installée
    }

    Write-Error-Custom "Aucune distribution WSL installée"
    Write-Host ""
    Write-Host "Installation d'Ubuntu..."
    wsl --install -d Ubuntu
    Write-Success "Ubuntu installé"
    Write-Warning-Custom "Configurez votre compte utilisateur Ubuntu, puis relancez ce script"
    exit 0
}

# ----------------------------------------------------------------------------
# Téléchargement et Configuration
# ----------------------------------------------------------------------------

function Get-ZenMCPServer {
    Write-Header "Téléchargement de Zen MCP Server"

    $projectPath = Join-Path $HOME "zen-mcp-server"

    if (Test-Path $projectPath) {
        Write-Warning-Custom "Le dossier $projectPath existe déjà"
        $response = Read-Host "Voulez-vous le supprimer et réinstaller ? (o/N)"

        if ($response -match "^[Oo]$") {
            Remove-Item -Path $projectPath -Recurse -Force
            Write-Success "Ancien dossier supprimé"
        }
        else {
            Write-Info "Utilisation du dossier existant"
            return $projectPath
        }
    }

    # Créer le dossier
    New-Item -ItemType Directory -Force -Path $projectPath | Out-Null

    # Télécharger les fichiers essentiels
    Write-Info "Téléchargement des fichiers depuis GitHub..."

    $files = @(
        "setup-windows-wsl.sh",
        "WINDOWS_SETUP.md",
        "start-zen.ps1"
    )

    $baseUrl = "https://raw.githubusercontent.com/BeehiveInnovations/zen-mcp-server/main"

    foreach ($file in $files) {
        $url = "$baseUrl/$file"
        $destination = Join-Path $projectPath $file

        try {
            Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
            Write-Success "Téléchargé : $file"
        }
        catch {
            Write-Warning-Custom "Impossible de télécharger $file : $_"
        }
    }

    Write-Success "Fichiers téléchargés dans : $projectPath"
    return $projectPath
}

# ----------------------------------------------------------------------------
# Installation dans WSL
# ----------------------------------------------------------------------------

function Install-InWSL {
    param([string]$ProjectPath)

    Write-Header "Installation dans WSL"

    # Convertir le chemin Windows en chemin WSL
    $wslPath = wsl wslpath -a "'$ProjectPath'"

    Write-Info "Chemin WSL : $wslPath"

    # Vérifier si le script d'installation existe
    $setupScript = Join-Path $ProjectPath "setup-windows-wsl.sh"

    if (-not (Test-Path $setupScript)) {
        Write-Error-Custom "Script d'installation WSL non trouvé"
        Write-Host ""
        Write-Host "Téléchargement manuel requis depuis :"
        Write-Host "  https://github.com/BeehiveInnovations/zen-mcp-server"
        exit 1
    }

    # Rendre le script exécutable et l'exécuter
    Write-Info "Lancement de l'installation dans WSL..."
    Write-Host ""

    # Exécuter dans WSL
    wsl bash -c "cd '$wslPath' && chmod +x setup-windows-wsl.sh && ./setup-windows-wsl.sh"

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Installation WSL terminée"
        return $true
    }
    else {
        Write-Error-Custom "Erreur lors de l'installation WSL"
        return $false
    }
}

# ----------------------------------------------------------------------------
# Création du Script de Démarrage
# ----------------------------------------------------------------------------

function New-StartupScript {
    param([string]$ProjectPath)

    Write-Header "Création du Script de Démarrage"

    $startScript = Join-Path $ProjectPath "start-zen.ps1"

    # Si le script a été téléchargé, pas besoin de le créer
    if (Test-Path $startScript) {
        Write-Success "Script de démarrage déjà présent"
        return
    }

    $scriptContent = @'
# Script de Démarrage Zen MCP Server pour Windows

$ErrorActionPreference = "Stop"

# Obtenir le chemin du projet
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Convertir en chemin WSL
$wslPath = wsl wslpath -a "'$projectPath'"

Write-Host "Démarrage de Zen MCP Server..." -ForegroundColor Cyan
Write-Host ""

# Options
$follow = $false
if ($args.Count -gt 0 -and $args[0] -eq "-f") {
    $follow = $true
}

# Exécuter dans WSL
if ($follow) {
    wsl bash -c "cd '$wslPath' && ./run-server.sh -f"
}
else {
    wsl bash -c "cd '$wslPath' && ./run-server.sh"
}
'@

    Set-Content -Path $startScript -Value $scriptContent
    Write-Success "Script de démarrage créé : start-zen.ps1"
}

# ----------------------------------------------------------------------------
# Affichage du Résumé
# ----------------------------------------------------------------------------

function Show-Summary {
    param([string]$ProjectPath)

    Write-Header "Installation Terminée !"

    Write-Success "Zen MCP Server est installé et configuré"
    Write-Host ""

    Write-Host "Emplacement : $ProjectPath" -ForegroundColor White
    Write-Host ""

    Write-Host "Prochaines étapes :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Si vous avez configuré Claude Desktop, redémarrez-le maintenant"
    Write-Host ""
    Write-Host "  2. Pour démarrer le serveur :"
    Write-Host "     cd '$ProjectPath'" -ForegroundColor Cyan
    Write-Host "     .\start-zen.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Pour suivre les logs :"
    Write-Host "     .\start-zen.ps1 -f" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  4. Documentation complète :"
    Write-Host "     $ProjectPath\WINDOWS_SETUP.md" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " Bon codage avec Zen MCP Server ! 🎉" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
}

# ----------------------------------------------------------------------------
# Fonction Principale
# ----------------------------------------------------------------------------

function Main {
    Clear-Host

    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                   ║" -ForegroundColor Cyan
    Write-Host "║   Zen MCP Server - Installation pour Windows 11  ║" -ForegroundColor Cyan
    Write-Host "║                                                   ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Vérifier WSL
    if (-not (Test-WSLInstalled)) {
        exit 1
    }

    if (-not (Test-WSLRunning)) {
        exit 1
    }

    # Télécharger le projet
    $projectPath = Get-ZenMCPServer

    # Installer dans WSL
    $installed = Install-InWSL -ProjectPath $projectPath

    if (-not $installed) {
        Write-Error-Custom "L'installation a échoué"
        exit 1
    }

    # Créer le script de démarrage
    New-StartupScript -ProjectPath $projectPath

    # Afficher le résumé
    Show-Summary -ProjectPath $projectPath
}

# ----------------------------------------------------------------------------
# Point d'Entrée
# ----------------------------------------------------------------------------

try {
    Main
}
catch {
    Write-Host ""
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace :" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace
    exit 1
}
