# ============================================================================
# Zen MCP Server - Script de Démarrage pour Windows 11
#
# Ce script PowerShell permet de démarrer facilement le serveur Zen MCP
# depuis Windows en l'exécutant dans WSL.
#
# Usage :
#   .\start-zen.ps1       # Démarrer le serveur
#   .\start-zen.ps1 -f    # Démarrer et suivre les logs
#   .\start-zen.ps1 -c    # Afficher la configuration
#   .\start-zen.ps1 -h    # Afficher l'aide
# ============================================================================

param(
    [switch]$f,      # Follow logs
    [switch]$c,      # Show config
    [switch]$h,      # Help
    [switch]$help    # Help (alias)
)

$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------------------
# Fonctions d'Affichage
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
# Aide
# ----------------------------------------------------------------------------

function Show-Help {
    Write-Header "Zen MCP Server - Aide"

    Write-Host "Usage :" -ForegroundColor Yellow
    Write-Host "  .\start-zen.ps1 [OPTIONS]"
    Write-Host ""

    Write-Host "Options :" -ForegroundColor Yellow
    Write-Host "  -f, -follow    Démarrer le serveur et suivre les logs en temps réel"
    Write-Host "  -c, -config    Afficher les instructions de configuration"
    Write-Host "  -h, -help      Afficher cette aide"
    Write-Host ""

    Write-Host "Exemples :" -ForegroundColor Yellow
    Write-Host "  .\start-zen.ps1          # Démarrer le serveur normalement"
    Write-Host "  .\start-zen.ps1 -f       # Démarrer et suivre les logs"
    Write-Host "  .\start-zen.ps1 -c       # Voir la configuration"
    Write-Host ""

    Write-Host "Documentation :" -ForegroundColor Yellow
    Write-Host "  WINDOWS_SETUP.md dans ce dossier"
    Write-Host "  https://github.com/BeehiveInnovations/zen-mcp-server"
    Write-Host ""
}

# ----------------------------------------------------------------------------
# Vérifications
# ----------------------------------------------------------------------------

function Test-WSLAvailable {
    try {
        $null = wsl --version 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Test-ProjectStructure {
    param([string]$ProjectPath)

    $wslPath = wsl wslpath -a "'$ProjectPath'" 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Impossible de convertir le chemin en chemin WSL"
        return $null
    }

    # Vérifier si run-server.sh existe
    $checkScript = wsl bash -c "test -f '$wslPath/run-server.sh' && echo 'exists'" 2>&1

    if ($checkScript -ne "exists") {
        Write-Error-Custom "Le projet n'est pas correctement installé"
        Write-Host ""
        Write-Host "Exécutez d'abord le script d'installation :"
        Write-Host "  .\setup-windows.ps1"
        Write-Host ""
        return $null
    }

    return $wslPath
}

# ----------------------------------------------------------------------------
# Démarrage du Serveur
# ----------------------------------------------------------------------------

function Start-ZenServer {
    param(
        [string]$WslPath,
        [string]$Mode = "normal"
    )

    Write-Header "Démarrage de Zen MCP Server"

    # Construire la commande
    $command = "cd '$WslPath' && "

    switch ($Mode) {
        "follow" {
            Write-Info "Mode : Suivre les logs (Ctrl+C pour arrêter)"
            $command += "./run-server.sh -f"
        }
        "config" {
            Write-Info "Mode : Afficher la configuration"
            $command += "./run-server.sh -c"
        }
        default {
            Write-Info "Mode : Démarrage normal"
            $command += "./run-server.sh"
        }
    }

    Write-Host ""

    # Exécuter dans WSL
    wsl bash -c $command

    if ($LASTEXITCODE -eq 0) {
        if ($Mode -eq "normal") {
            Write-Host ""
            Write-Success "Serveur démarré avec succès"
            Write-Host ""
            Write-Info "Pour suivre les logs : .\start-zen.ps1 -f"
        }
    }
    else {
        Write-Host ""
        Write-Error-Custom "Erreur lors du démarrage du serveur"
        Write-Host ""
        Write-Info "Consultez les logs pour plus de détails :"
        Write-Host "  .\start-zen.ps1 -f"
    }
}

# ----------------------------------------------------------------------------
# Fonction Principale
# ----------------------------------------------------------------------------

function Main {
    # Afficher l'aide si demandé
    if ($h -or $help) {
        Show-Help
        exit 0
    }

    # Obtenir le chemin du projet
    $projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

    # Vérifier WSL
    if (-not (Test-WSLAvailable)) {
        Write-Error-Custom "WSL n'est pas disponible"
        Write-Host ""
        Write-Host "Installez WSL en exécutant (en tant qu'administrateur) :"
        Write-Host "  wsl --install"
        Write-Host ""
        exit 1
    }

    # Vérifier la structure du projet
    $wslPath = Test-ProjectStructure -ProjectPath $projectPath

    if (-not $wslPath) {
        exit 1
    }

    # Déterminer le mode
    $mode = "normal"
    if ($f) {
        $mode = "follow"
    }
    elseif ($c) {
        $mode = "config"
    }

    # Démarrer le serveur
    Start-ZenServer -WslPath $wslPath -Mode $mode
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
    exit 1
}
