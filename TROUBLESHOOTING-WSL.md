# Guide de Dépannage Rapide - Installation Windows WSL

## Problème : Environnement virtuel corrompu

Si vous obtenez l'erreur :
```
./setup-windows-wsl.sh: line 211: .zen_venv/bin/activate: No such file or directory
```

### Solution Rapide

```bash
# 1. Supprimer l'environnement virtuel corrompu
rm -rf .zen_venv

# 2. Relancer le script d'installation
./setup-windows-wsl.sh
```

Le script amélioré détectera maintenant automatiquement les environnements virtuels corrompus et les recréera.

## Alternative : Installation Manuelle

Si le problème persiste :

```bash
# 1. Supprimer l'ancien environnement virtuel
rm -rf .zen_venv

# 2. Créer un nouvel environnement virtuel
python3.12 -m venv .zen_venv

# 3. Activer l'environnement virtuel
source .zen_venv/bin/activate

# 4. Mettre à jour pip
python -m pip install --upgrade pip

# 5. Installer les dépendances
pip install -r requirements.txt

# 6. Copier le fichier .env.example
cp .env.example .env

# 7. Éditer le fichier .env pour ajouter vos clés API
nano .env
```

## Configuration des Clés API

Éditez `.env` et remplacez les valeurs par vos vraies clés :

```bash
# Gemini API Key (obtenir sur https://makersuite.google.com/app/apikey)
GEMINI_API_KEY=AIza...votre-clé-ici

# Claude/OpenAI API Key (obtenir sur https://console.anthropic.com/)
OPENAI_API_KEY=sk-ant-...votre-clé-ici
```

## Démarrer le Serveur

```bash
# Depuis WSL
./run-server.sh

# Suivre les logs
./run-server.sh -f
```

## Configuration de Claude Desktop

Le fichier de configuration se trouve à :
```
C:\Users\VOTRE_NOM\AppData\Roaming\Claude\claude_desktop_config.json
```

Ajoutez cette configuration (remplacez `VOTRE_USER_WSL` par votre nom d'utilisateur WSL) :

```json
{
  "mcpServers": {
    "zen": {
      "command": "/home/VOTRE_USER_WSL/zen-mcp-server/.zen_venv/bin/python",
      "args": ["/home/VOTRE_USER_WSL/zen-mcp-server/server.py"],
      "env": {
        "GEMINI_API_KEY": "votre-clé-gemini",
        "OPENAI_API_KEY": "votre-clé-claude"
      }
    }
  }
}
```

**Important** : Redémarrez Claude Desktop après la modification.

## Vérifier le Nom d'Utilisateur WSL

Pour trouver votre nom d'utilisateur WSL :

```bash
whoami
```

Ou voir le chemin complet :

```bash
pwd
```

## Problèmes Courants

### Python non trouvé

```bash
# Installer Python 3.12
sudo apt update
sudo apt install python3.12 python3.12-venv python3-pip -y
```

### Permission denied

```bash
# Donner les permissions d'exécution
chmod +x setup-windows-wsl.sh
chmod +x run-server.sh
```

### Git non trouvé

```bash
# Installer Git
sudo apt update
sudo apt install git -y
```

## Mise à Jour du Script

Pour obtenir la dernière version du script (avec le correctif) :

```bash
# Récupérer les dernières modifications
git pull origin claude/windows-wsl-setup-guide-01DFNfTL6KTbjEi9yqMdayTP

# Ou télécharger directement
curl -O https://raw.githubusercontent.com/survivant/zen-mcp-server/claude/windows-wsl-setup-guide-01DFNfTL6KTbjEi9yqMdayTP/setup-windows-wsl.sh
chmod +x setup-windows-wsl.sh
```

## Support

Si vous rencontrez d'autres problèmes :

1. Vérifiez les logs :
   ```bash
   tail -f logs/mcp_server.log
   ```

2. Consultez la documentation complète :
   - `WINDOWS_SETUP.md` - Guide complet
   - `README-WINDOWS.md` - Guide rapide
   - `CLAUDE.md` - Commandes de développement

3. Ouvrez une issue sur GitHub :
   https://github.com/survivant/zen-mcp-server/issues
