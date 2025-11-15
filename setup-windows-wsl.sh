#!/bin/bash
set -euo pipefail

# ============================================================================
# Zen MCP Server - Script d'Installation Automatisé pour Windows + WSL
#
# Ce script configure automatiquement le serveur Zen MCP sur Windows 11
# avec WSL (Windows Subsystem for Linux), incluant :
# - Vérification et installation de Python
# - Configuration de l'environnement virtuel
# - Installation des dépendances
# - Configuration des clés API
# - Intégration avec Claude Desktop
# ============================================================================

# ----------------------------------------------------------------------------
# Couleurs pour l'affichage
# ----------------------------------------------------------------------------
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ----------------------------------------------------------------------------
# Fonctions Utilitaires
# ----------------------------------------------------------------------------

print_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1" >&2
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# ----------------------------------------------------------------------------
# Détection de l'Environnement
# ----------------------------------------------------------------------------

detect_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        return 0
    fi
    return 1
}

get_windows_user() {
    if detect_wsl; then
        # Récupérer le nom d'utilisateur Windows depuis WSL
        local win_user
        if command -v wslvar &> /dev/null; then
            win_user=$(wslvar USERNAME 2>/dev/null)
        fi

        if [[ -z "${win_user:-}" ]]; then
            # Fallback : extraire depuis le chemin Windows
            win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        fi

        echo "$win_user"
    fi
}

get_windows_appdata() {
    if detect_wsl; then
        local appdata
        if command -v wslvar &> /dev/null; then
            appdata=$(wslvar APPDATA 2>/dev/null)
        fi

        if [[ -z "${appdata:-}" ]]; then
            # Fallback : construire le chemin
            local win_user=$(get_windows_user)
            appdata="C:\\Users\\${win_user}\\AppData\\Roaming"
        fi

        # Convertir le chemin Windows en chemin WSL
        if [[ -n "$appdata" ]]; then
            wslpath "$appdata" 2>/dev/null || echo ""
        fi
    fi
}

# ----------------------------------------------------------------------------
# Vérification des Prérequis
# ----------------------------------------------------------------------------

check_prerequisites() {
    print_header "Vérification des Prérequis"

    # Vérifier WSL
    if ! detect_wsl; then
        print_error "Ce script doit être exécuté depuis WSL (Windows Subsystem for Linux)"
        echo ""
        echo "Pour installer WSL sur Windows 11 :"
        echo "  1. Ouvrez PowerShell en tant qu'administrateur"
        echo "  2. Exécutez : wsl --install"
        echo "  3. Redémarrez votre ordinateur"
        echo "  4. Lancez Ubuntu depuis le menu Démarrer"
        echo ""
        exit 1
    fi
    print_success "WSL détecté"

    # Vérifier git
    if ! command -v git &> /dev/null; then
        print_warning "Git n'est pas installé. Installation..."
        sudo apt update &>/dev/null
        sudo apt install -y git &>/dev/null
        print_success "Git installé"
    else
        print_success "Git disponible"
    fi

    # Vérifier curl
    if ! command -v curl &> /dev/null; then
        print_warning "Curl n'est pas installé. Installation..."
        sudo apt update &>/dev/null
        sudo apt install -y curl &>/dev/null
        print_success "Curl installé"
    else
        print_success "Curl disponible"
    fi
}

# ----------------------------------------------------------------------------
# Installation de Python
# ----------------------------------------------------------------------------

install_python() {
    print_header "Configuration de Python"

    # Vérifier si Python 3.10+ est disponible
    local python_cmd=""
    local python_version=""

    for cmd in python3.12 python3.11 python3.10 python3; do
        if command -v "$cmd" &> /dev/null; then
            python_version=$($cmd --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
            if [[ -n "$python_version" ]]; then
                local major=$(echo "$python_version" | cut -d. -f1)
                local minor=$(echo "$python_version" | cut -d. -f2)

                if [[ $major -ge 3 ]] && [[ $minor -ge 10 ]]; then
                    python_cmd=$cmd
                    break
                fi
            fi
        fi
    done

    if [[ -z "$python_cmd" ]]; then
        print_warning "Python 3.10+ non trouvé. Installation..."

        # Mettre à jour les paquets
        print_info "Mise à jour des paquets système..."
        sudo apt update &>/dev/null

        # Installer Python 3.10
        print_info "Installation de Python 3.10..."
        sudo apt install -y python3.10 python3.10-venv python3-pip &>/dev/null

        python_cmd="python3.10"
        print_success "Python 3.10 installé"
    else
        print_success "Python $python_version disponible ($python_cmd)"
    fi

    echo "$python_cmd"
}

# ----------------------------------------------------------------------------
# Configuration de l'Environnement
# ----------------------------------------------------------------------------

setup_environment() {
    local python_cmd="$1"
    local project_dir="$2"

    print_header "Configuration de l'Environnement Python"

    cd "$project_dir"

    # Créer l'environnement virtuel s'il n'existe pas
    if [[ ! -d ".zen_venv" ]]; then
        print_info "Création de l'environnement virtuel..."
        $python_cmd -m venv .zen_venv
        print_success "Environnement virtuel créé"
    else
        print_success "Environnement virtuel déjà existant"
    fi

    # Activer l'environnement virtuel
    source .zen_venv/bin/activate

    # Mettre à jour pip
    print_info "Mise à jour de pip..."
    python -m pip install --upgrade pip &>/dev/null
    print_success "Pip mis à jour"

    # Installer les dépendances
    if [[ -f "requirements.txt" ]]; then
        print_info "Installation des dépendances..."
        pip install -r requirements.txt &>/dev/null
        print_success "Dépendances installées"
    else
        print_error "Fichier requirements.txt non trouvé"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Configuration des Clés API
# ----------------------------------------------------------------------------

configure_api_keys() {
    local project_dir="$1"

    print_header "Configuration des Clés API"

    cd "$project_dir"

    # Copier .env.example vers .env si nécessaire
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            print_success "Fichier .env créé depuis .env.example"
        else
            print_error "Fichier .env.example non trouvé"
            return 1
        fi
    else
        print_success "Fichier .env déjà existant"
    fi

    # Demander les clés API
    echo ""
    echo "Configuration des clés API :"
    echo ""
    print_info "Vous avez besoin d'au moins une clé API pour utiliser Zen MCP Server."
    echo ""

    # Gemini API Key
    echo -n "Entrez votre clé Gemini API (ou laissez vide pour ignorer) : "
    read -r gemini_key

    if [[ -n "$gemini_key" ]]; then
        sed -i "s/GEMINI_API_KEY=.*/GEMINI_API_KEY=${gemini_key}/" .env
        print_success "Clé Gemini API configurée"
    fi

    # Claude/OpenAI API Key
    echo -n "Entrez votre clé Claude/OpenAI API (ou laissez vide pour ignorer) : "
    read -r openai_key

    if [[ -n "$openai_key" ]]; then
        sed -i "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=${openai_key}/" .env
        print_success "Clé OpenAI API configurée"
    fi

    # Vérifier qu'au moins une clé a été configurée
    if [[ -z "$gemini_key" ]] && [[ -z "$openai_key" ]]; then
        print_warning "Aucune clé API configurée."
        print_info "Vous pouvez les ajouter plus tard en éditant le fichier .env"
        return 0
    fi

    print_success "Configuration des clés API terminée"
}

# ----------------------------------------------------------------------------
# Configuration de Claude Desktop
# ----------------------------------------------------------------------------

configure_claude_desktop() {
    local python_cmd="$1"
    local project_dir="$2"

    print_header "Configuration de Claude Desktop"

    # Récupérer le chemin AppData Windows
    local appdata=$(get_windows_appdata)

    if [[ -z "$appdata" ]]; then
        print_warning "Impossible de détecter le répertoire AppData Windows"
        print_info "Vous devrez configurer Claude Desktop manuellement"
        return 0
    fi

    local config_dir="$appdata/Claude"
    local config_file="$config_dir/claude_desktop_config.json"

    # Vérifier si Claude Desktop est installé
    if [[ ! -d "$config_dir" ]]; then
        print_warning "Claude Desktop ne semble pas être installé"
        print_info "Installez Claude Desktop et exécutez à nouveau ce script"
        return 0
    fi

    echo ""
    echo -n "Voulez-vous configurer automatiquement Claude Desktop ? (O/n) : "
    read -r response

    if [[ "$response" =~ ^[Nn] ]]; then
        print_info "Configuration de Claude Desktop ignorée"
        print_info "Configuration manuelle : $config_file"
        return 0
    fi

    # Obtenir le chemin absolu du Python venv
    local venv_python="$project_dir/.zen_venv/bin/python"
    local server_path="$project_dir/server.py"

    # Lire les clés API depuis .env
    local gemini_key=""
    local openai_key=""

    if [[ -f "$project_dir/.env" ]]; then
        gemini_key=$(grep "^GEMINI_API_KEY=" "$project_dir/.env" | cut -d= -f2)
        openai_key=$(grep "^OPENAI_API_KEY=" "$project_dir/.env" | cut -d= -f2)
    fi

    # Créer la configuration JSON
    local json_config
    json_config=$(cat <<EOF
{
  "mcpServers": {
    "zen": {
      "command": "$venv_python",
      "args": ["$server_path"],
      "env": {
EOF
)

    # Ajouter les clés API si elles existent
    local first_key=true
    if [[ -n "$gemini_key" ]] && [[ "$gemini_key" != "your_gemini_api_key_here" ]]; then
        if [[ "$first_key" == true ]]; then
            json_config+=$'\n        "GEMINI_API_KEY": "'"$gemini_key"'"'
            first_key=false
        else
            json_config+=','$'\n        "GEMINI_API_KEY": "'"$gemini_key"'"'
        fi
    fi

    if [[ -n "$openai_key" ]] && [[ "$openai_key" != "your_openai_api_key_here" ]]; then
        if [[ "$first_key" == true ]]; then
            json_config+=$'\n        "OPENAI_API_KEY": "'"$openai_key"'"'
            first_key=false
        else
            json_config+=','$'\n        "OPENAI_API_KEY": "'"$openai_key"'"'
        fi
    fi

    json_config+=$'\n      }'
    json_config+=$'\n    }'
    json_config+=$'\n  }'
    json_config+=$'\n}'

    # Créer une sauvegarde si le fichier existe
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${config_file}.backup_$(date +%Y%m%d_%H%M%S)"
        print_success "Sauvegarde de la configuration existante créée"
    fi

    # Écrire la nouvelle configuration
    echo "$json_config" > "$config_file"
    print_success "Configuration Claude Desktop mise à jour"

    echo ""
    print_warning "IMPORTANT : Redémarrez Claude Desktop pour appliquer les changements"
}

# ----------------------------------------------------------------------------
# Affichage du Résumé
# ----------------------------------------------------------------------------

display_summary() {
    local project_dir="$1"

    print_header "Installation Terminée !"

    echo ""
    print_success "Zen MCP Server est installé et configuré"
    echo ""

    echo "Répertoire d'installation : $project_dir"
    echo ""

    echo "Prochaines étapes :"
    echo ""
    echo "  1. Si vous avez configuré Claude Desktop, redémarrez-le maintenant"
    echo ""
    echo "  2. Pour démarrer le serveur manuellement :"
    echo "     cd $project_dir"
    echo "     ./run-server.sh"
    echo ""
    echo "  3. Pour suivre les logs :"
    echo "     cd $project_dir"
    echo "     ./run-server.sh -f"
    echo ""
    echo "  4. Pour voir la configuration :"
    echo "     cd $project_dir"
    echo "     ./run-server.sh -c"
    echo ""

    print_info "Documentation complète : $project_dir/WINDOWS_SETUP.md"
    echo ""

    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} Bon codage avec Zen MCP Server ! 🎉${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# ----------------------------------------------------------------------------
# Fonction Principale
# ----------------------------------------------------------------------------

main() {
    # Afficher le titre
    clear
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                   ║${NC}"
    echo -e "${BLUE}║     Zen MCP Server - Installation Windows WSL    ║${NC}"
    echo -e "${BLUE}║                                                   ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""

    # Déterminer le répertoire du projet
    local project_dir
    if [[ -f "server.py" ]] && [[ -f "requirements.txt" ]]; then
        # Script exécuté depuis le répertoire du projet
        project_dir=$(pwd)
    elif [[ -f "zen-mcp-server/server.py" ]]; then
        # Script exécuté depuis le répertoire parent
        project_dir="$(pwd)/zen-mcp-server"
    else
        # Cloner le dépôt
        print_header "Clonage du Dépôt"

        local install_dir="$HOME/zen-mcp-server"

        if [[ -d "$install_dir" ]]; then
            print_warning "Le répertoire $install_dir existe déjà"
            echo -n "Voulez-vous le supprimer et réinstaller ? (o/N) : "
            read -r response

            if [[ "$response" =~ ^[Oo] ]]; then
                rm -rf "$install_dir"
                print_success "Ancien répertoire supprimé"
            else
                print_info "Utilisation du répertoire existant"
                project_dir="$install_dir"
            fi
        fi

        if [[ ! -d "$install_dir" ]]; then
            print_info "Clonage depuis GitHub..."
            git clone https://github.com/BeehiveInnovations/zen-mcp-server.git "$install_dir" &>/dev/null
            print_success "Dépôt cloné"
            project_dir="$install_dir"
        fi
    fi

    # Vérifier les prérequis
    check_prerequisites

    # Installer Python
    local python_cmd
    python_cmd=$(install_python)

    # Configurer l'environnement
    setup_environment "$python_cmd" "$project_dir"

    # Configurer les clés API
    configure_api_keys "$project_dir"

    # Configurer Claude Desktop
    configure_claude_desktop "$python_cmd" "$project_dir"

    # Afficher le résumé
    display_summary "$project_dir"
}

# ----------------------------------------------------------------------------
# Point d'Entrée
# ----------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
