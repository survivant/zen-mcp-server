# Zen MCP Server pour Windows 11

Guide rapide d'installation pour Windows 11 + WSL

## Installation Rapide

### Depuis PowerShell (Recommandé)

```powershell
# 1. Télécharger le script d'installation
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BeehiveInnovations/zen-mcp-server/main/setup-windows.ps1" -OutFile "$env:USERPROFILE\Downloads\setup-windows.ps1"

# 2. Naviguer vers le dossier de téléchargement
cd $env:USERPROFILE\Downloads

# 3. Lancer l'installation
.\setup-windows.ps1
```

Le script vous guidera à travers :
- ✓ Vérification de WSL
- ✓ Installation des dépendances
- ✓ Configuration des clés API (Gemini, Claude)
- ✓ Intégration avec Claude Desktop

### Depuis WSL (Alternative)

Si vous avez déjà WSL installé :

```bash
# Cloner le dépôt
git clone https://github.com/BeehiveInnovations/zen-mcp-server.git
cd zen-mcp-server

# Lancer l'installation
chmod +x setup-windows-wsl.sh
./setup-windows-wsl.sh
```

## Prérequis

- **Windows 11** avec les dernières mises à jour
- **WSL 2** (le script peut l'installer pour vous)
- Au moins **une clé API** :
  - [Gemini API Key](https://makersuite.google.com/app/apikey)
  - [Claude API Key](https://console.anthropic.com/)

## Utilisation

### Démarrer le Serveur

```powershell
cd $env:USERPROFILE\zen-mcp-server
.\start-zen.ps1
```

### Suivre les Logs

```powershell
.\start-zen.ps1 -f
```

### Voir la Configuration

```powershell
.\start-zen.ps1 -c
```

## Configuration Claude Desktop

Le fichier de configuration se trouve ici :
```
C:\Users\VOTRE_NOM\AppData\Roaming\Claude\claude_desktop_config.json
```

**Important** : Redémarrez Claude Desktop après la configuration initiale.

## Outils Disponibles

Par défaut, ces outils sont activés :

- **chat** - Conversations avec différents modèles AI
- **thinkdeep** - Raisonnement approfondi
- **planner** - Planification de projets
- **consensus** - Validation croisée entre modèles
- **codereview** - Révision de code
- **precommit** - Vérifications avant commit
- **debug** - Aide au débogage
- **challenge** - Validation critique

Pour activer d'autres outils, éditez le fichier `.env` dans WSL.

## Dépannage

### WSL ne démarre pas ?

```powershell
# Vérifier l'état
wsl --status

# Mettre à jour WSL
wsl --update

# Redémarrer le service
Restart-Service LxssManager
```

### Claude Desktop ne voit pas le serveur ?

1. Vérifiez que les chemins dans `claude_desktop_config.json` sont corrects
2. Redémarrez Claude Desktop **complètement**
3. Vérifiez les logs depuis WSL :
   ```bash
   tail -f ~/zen-mcp-server/logs/mcp_server.log
   ```

### Erreurs de clés API ?

Vérifiez votre fichier `.env` depuis WSL :
```bash
cat ~/zen-mcp-server/.env | grep API_KEY
```

Format correct : `GEMINI_API_KEY=AIzaSyAbc123...` (sans guillemets, sans espaces)

## Documentation Complète

Pour plus de détails, consultez :
- **WINDOWS_SETUP.md** - Guide complet d'installation et dépannage
- **CLAUDE.md** - Guide de développement et commandes

## Support

- GitHub Issues : [Signaler un problème](https://github.com/BeehiveInnovations/zen-mcp-server/issues)
- Documentation : [Voir le wiki](https://github.com/BeehiveInnovations/zen-mcp-server)

---

**Bon codage avec Zen MCP Server ! 🎉**
