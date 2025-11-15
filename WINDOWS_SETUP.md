# Guide d'Installation Zen MCP Server pour Windows 11 + WSL

Ce guide vous aidera à installer et configurer automatiquement le serveur Zen MCP sur Windows 11 avec WSL, en utilisant vos comptes Claude et Gemini Pro.

## Table des Matières

- [Prérequis](#prérequis)
- [Installation Rapide (Automatisée)](#installation-rapide-automatisée)
- [Installation Manuelle](#installation-manuelle)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Dépannage](#dépannage)

## Prérequis

### 1. Windows 11

Assurez-vous d'avoir Windows 11 avec les dernières mises à jour installées.

### 2. WSL (Windows Subsystem for Linux)

Si WSL n'est pas déjà installé, suivez ces étapes :

#### Option A : Installation Rapide (Recommandée)

Ouvrez PowerShell en tant qu'administrateur et exécutez :

```powershell
wsl --install
```

Cela installera WSL 2 avec Ubuntu par défaut. Redémarrez votre ordinateur lorsque demandé.

#### Option B : Installation Manuelle

1. Ouvrez PowerShell en tant qu'administrateur
2. Activez WSL :
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```
3. Activez la plateforme de machine virtuelle :
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
4. Redémarrez votre ordinateur
5. Téléchargez et installez le [package de mise à jour du noyau Linux WSL 2](https://aka.ms/wsl2kernel)
6. Définissez WSL 2 comme version par défaut :
   ```powershell
   wsl --set-default-version 2
   ```
7. Installez Ubuntu depuis le Microsoft Store

### 3. Configuration Initiale de WSL

Lors du premier lancement d'Ubuntu, créez un nom d'utilisateur et un mot de passe.

### 4. Clés API

Vous aurez besoin d'au moins une des clés API suivantes :

- **Gemini API Key** : Obtenez-la sur [Google AI Studio](https://makersuite.google.com/app/apikey)
- **Claude API Key** : Obtenez-la sur [Anthropic Console](https://console.anthropic.com/)

## Installation Rapide (Automatisée)

### Étape 1 : Téléchargement du Script

Depuis PowerShell (pas besoin d'être administrateur) :

```powershell
# Créer un dossier pour le projet
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\zen-mcp-server"
cd "$env:USERPROFILE\zen-mcp-server"

# Télécharger le script d'installation PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BeehiveInnovations/zen-mcp-server/main/setup-windows.ps1" -OutFile "setup-windows.ps1"
```

### Étape 2 : Exécution du Script

```powershell
# Autoriser l'exécution du script (si nécessaire)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Lancer l'installation automatique
.\setup-windows.ps1
```

Le script vous demandera :
- Vos clés API (Gemini et/ou Claude)
- Si vous souhaitez configurer Claude Desktop automatiquement
- Confirmation de l'installation

### Étape 3 : Vérification

Une fois l'installation terminée, le script affichera :
- ✓ État de l'installation WSL
- ✓ État de l'environnement Python
- ✓ Configuration des clés API
- ✓ Intégration avec Claude Desktop

## Installation Manuelle

Si vous préférez installer manuellement ou si le script automatique ne fonctionne pas :

### Étape 1 : Cloner le Dépôt

Ouvrez Ubuntu (WSL) et exécutez :

```bash
cd ~
git clone https://github.com/BeehiveInnovations/zen-mcp-server.git
cd zen-mcp-server
```

### Étape 2 : Lancer le Script d'Installation WSL

```bash
chmod +x setup-windows-wsl.sh
./setup-windows-wsl.sh
```

Le script vous guidera à travers :
1. Installation de Python 3.10+ (si nécessaire)
2. Création de l'environnement virtuel Python
3. Installation des dépendances
4. Configuration du fichier .env
5. Configuration de Claude Desktop (si installé)

### Étape 3 : Configurer les Clés API

Éditez le fichier `.env` :

```bash
nano .env
```

Modifiez les lignes suivantes avec vos vraies clés API :

```bash
# Remplacez par votre vraie clé Gemini
GEMINI_API_KEY=AIza...votre-clé-ici

# Optionnel : Ajoutez votre clé Claude si vous l'avez
OPENAI_API_KEY=sk-ant-...votre-clé-ici
```

Sauvegardez avec `Ctrl+O`, puis `Enter`, et quittez avec `Ctrl+X`.

## Configuration

### Configuration de Claude Desktop

Le script d'installation configurera automatiquement Claude Desktop. Le fichier de configuration se trouve à :

```
C:\Users\VOTRE_NOM\AppData\Roaming\Claude\claude_desktop_config.json
```

Configuration typique :

```json
{
  "mcpServers": {
    "zen": {
      "command": "/home/VOTRE_USER_WSL/.zen_venv/bin/python",
      "args": ["/home/VOTRE_USER_WSL/zen-mcp-server/server.py"],
      "env": {
        "GEMINI_API_KEY": "votre-clé-gemini",
        "OPENAI_API_KEY": "votre-clé-claude"
      }
    }
  }
}
```

**Important** : Redémarrez Claude Desktop après la configuration.

### Configuration de Claude Code (CLI)

Si vous utilisez Claude Code CLI, exécutez depuis WSL :

```bash
cd ~/zen-mcp-server
./run-server.sh
```

Le script détectera Claude Code et proposera de l'intégrer automatiquement.

### Outils Disponibles

Par défaut, les outils essentiels sont activés :

- **chat** : Conversations avec différents modèles AI
- **thinkdeep** : Raisonnement approfondi avec mode de pensée étendue
- **planner** : Planification de projets et tâches
- **consensus** : Validation croisée entre plusieurs modèles
- **codereview** : Révision de code
- **precommit** : Vérifications avant commit
- **debug** : Aide au débogage
- **challenge** : Validation critique des idées

Pour activer d'autres outils, modifiez `DISABLED_TOOLS` dans `.env` :

```bash
# Activer tous les outils
DISABLED_TOOLS=

# Désactiver seulement certains outils
DISABLED_TOOLS=docgen,tracer
```

## Utilisation

### Démarrer le Serveur

Depuis WSL :

```bash
cd ~/zen-mcp-server
./run-server.sh
```

### Suivre les Logs

```bash
./run-server.sh -f
```

### Vérifier la Configuration

```bash
./run-server.sh -c
```

### Depuis Windows PowerShell

Vous pouvez aussi utiliser le wrapper PowerShell :

```powershell
cd $env:USERPROFILE\zen-mcp-server
.\start-zen.ps1
```

## Dépannage

### Problème : WSL ne démarre pas

**Solution** :
1. Vérifiez que WSL est installé : `wsl --status` dans PowerShell
2. Vérifiez la version : `wsl --list --verbose`
3. Mettez à jour WSL : `wsl --update`
4. Redémarrez le service LxssManager :
   ```powershell
   Restart-Service LxssManager
   ```

### Problème : Python non trouvé dans WSL

**Solution** :

```bash
# Installer Python 3.10+
sudo apt update
sudo apt install python3.10 python3.10-venv python3-pip -y
```

### Problème : Erreur de permission

**Solution** :

```bash
# Donner les permissions d'exécution
chmod +x setup-windows-wsl.sh
chmod +x run-server.sh
```

### Problème : Claude Desktop ne voit pas le serveur

**Solutions** :

1. Vérifiez que le chemin dans `claude_desktop_config.json` est correct
2. Vérifiez que les chemins WSL sont au format Unix (`/home/user/...`) et non Windows (`C:\...`)
3. Redémarrez Claude Desktop complètement
4. Vérifiez les logs :
   ```bash
   tail -f ~/zen-mcp-server/logs/mcp_server.log
   ```

### Problème : Clés API non reconnues

**Solution** :

1. Vérifiez le fichier `.env` :
   ```bash
   cat ~/zen-mcp-server/.env | grep API_KEY
   ```
2. Assurez-vous qu'il n'y a pas d'espaces autour du `=`
3. Les clés ne doivent pas contenir de guillemets
4. Format correct : `GEMINI_API_KEY=AIzaSyAbc123...`

### Problème : Erreurs d'importation Python

**Solution** :

```bash
cd ~/zen-mcp-server
./run-server.sh --clear-cache
```

### Obtenir de l'Aide

Si vous rencontrez d'autres problèmes :

1. Consultez les logs détaillés :
   ```bash
   cat ~/zen-mcp-server/logs/mcp_server.log
   ```

2. Vérifiez les issues GitHub :
   [https://github.com/BeehiveInnovations/zen-mcp-server/issues](https://github.com/BeehiveInnovations/zen-mcp-server/issues)

3. Exécutez les vérifications de qualité :
   ```bash
   cd ~/zen-mcp-server
   ./code_quality_checks.sh
   ```

## Mise à Jour

Pour mettre à jour vers la dernière version :

```bash
cd ~/zen-mcp-server
git pull
./run-server.sh
```

Le script réinstallera automatiquement les dépendances si nécessaire.

## Désinstallation

Pour supprimer complètement Zen MCP Server :

### Depuis WSL :

```bash
cd ~
rm -rf zen-mcp-server
```

### Configuration Claude Desktop :

Éditez `C:\Users\VOTRE_NOM\AppData\Roaming\Claude\claude_desktop_config.json` et supprimez la section `"zen"`.

### Depuis PowerShell :

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\zen-mcp-server"
```

## Ressources Supplémentaires

- **Documentation Claude Code** : [https://docs.anthropic.com/en/docs/claude-code](https://docs.anthropic.com/en/docs/claude-code)
- **Documentation WSL** : [https://learn.microsoft.com/fr-fr/windows/wsl/](https://learn.microsoft.com/fr-fr/windows/wsl/)
- **Dépôt GitHub** : [https://github.com/BeehiveInnovations/zen-mcp-server](https://github.com/BeehiveInnovations/zen-mcp-server)
- **Guide de Développement** : Voir `CLAUDE.md` dans le dépôt

## Support et Contribution

- **Issues** : [GitHub Issues](https://github.com/BeehiveInnovations/zen-mcp-server/issues)
- **Discussions** : [GitHub Discussions](https://github.com/BeehiveInnovations/zen-mcp-server/discussions)
- **Pull Requests** : Les contributions sont les bienvenues !

## Licence

Voir le fichier `LICENSE` dans le dépôt pour les détails de la licence.

---

**Bon codage avec Zen MCP Server ! 🎉**
