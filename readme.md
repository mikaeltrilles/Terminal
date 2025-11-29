# 🚀 Terminal Setup Script

Transformez votre terminal en 1 clic ! 🛠️🐚🍺
Script d'installation moderne pour Debian/Ubuntu avec menu interactif et thème Jonathan par défaut ✨

## 🎯 Installation en 1 ligne

```bash
curl -sSL https://raw.githubusercontent.com/mikaeltrilles/Terminal/refs/heads/main/server_utils.sh | bash
```

## 📋 Menu interactif (4 options)

```text
1) 🛠️  Installation de base (Zsh + outils essentiels)
2) 🐚 Installation Oh My Zsh (sh -c .../install.sh)
3) 🍺 Installation Homebrew (Linux non-root)
4) 🔥 Installation complète (1+2+3)
```

## 📦 Paquets installés

### 🛠️ Prérequis (7 paquets)

| Paquet          | Description                  |
| --------------- | ---------------------------- |
| curl            | 📥 Téléchargements sécurisés |
| wget            | ⬇️ Téléchargeur robuste      |
| git             | 🐘 Gestionnaire de versions  |
| zsh             | 🐚 Shell moderne & rapide    |
| build-essential | 🔨 Compilateurs C/C++        |
| procps          | ⚙️ Outils système            |
| file            | 🔍 Détection de types MIME   |

### 🛠️ Base (7 outils CLI modernes)

| Outil   | Remplace | Description                    |
| ------- | -------- | ------------------------------ |
| bat     | cat      | 📄 cat avec syntaxe & git      |
| btop    | htop     | 📊 Moniteur système moderne    |
| eza     | ls       | 🌈 ls coloré & icons           |
| ripgrep | grep     | ⚡ Recherche ultra-rapide      |
| zoxide  | cd       | 🧠 Navigation intelligente     |
| duf     | df       | 📊 Disques avec style          |
| direnv  | -        | 🌍 Variables d'env par dossier |

### 🤖 Outils additionnels

| Outil | Description                 |
| ----- | --------------------------- |
| atuin | 📝 Historique synchronisé   |
| micro | ✏️ Éditeur moderne (nano++) |

### 🐚 Oh My Zsh + Plugins

| Composant               | Description                 |
| ----------------------- | --------------------------- |
| Thème                   | 🎨 jonathan (par défaut)    |
| zsh-autosuggestions     | 💡 Suggestions automatiques |
| zsh-syntax-highlighting | 🌈 Syntaxe colorée          |

### ✨ Aliases & Fonctions intégrés

#### 🔄 Relâche config

alias relbash="source ~/.zshrc"

#### ✏️ Éditer config

alias zshconfig="nano ~/.zshrc"

#### 🍓 Mise à jour complète (RPi)

alias maj="maj"  # APT + Brew + Firmware + Nettoyage

🚀 Utilisation rapide
Option 1 - Base uniquement

```bash
curl -sSL https://raw.githubusercontent.com/mikaeltrilles/Terminal/refs/heads/main/server_utils.sh | bash
# Entrez : 1
```

Option 4 - Installation complète

```bash
curl -sSL https://raw.githubusercontent.com/mikaeltrilles/Terminal/refs/heads/main/server_utils.sh | bash
# Entrez : 4 (défaut)
```

#### ⚙️ Fonctionnalités avancées

✅ Utilisateur actif détecté automatiquement
✅ Compteurs progressifs 1/7 → 7/7
✅ Installation silencieuse (logs propres)
✅ Shell Zsh par défaut (chsh)
✅ Lancement auto Oh My Zsh à la fin
✅ Homebrew Linux non-root (/home/linuxbrew)
✅ Gestion sudo transparente

#### 🛡️ Prérequis

✅ Debian/Ubuntu/Raspberry Pi OS
✅ sudo installé
✅ Accès internet

#### 🔧 Personnalisation

```bash
# Thème personnalisé
sed -i 's/jonathan/votre-theme/g' ~/.zshrc
relbash

# Ajout plugins OMZ
git clone https://github.com/zsh-users/zsh-plugin ~/.oh-my-zsh/custom/plugins/
```

#### 📊 Performances

| Opération   | Temps estimé |
| ----------- | ------------ |
| Prérequis   | 30s          |
| Base outils | 45s          |
| Oh My Zsh   | 20s          |
| Homebrew    | 2min         |
| Complet     | ~3min        |

#### 📄 Licence

MIT License - Free & Open Source ✨

🤝 Contribuer

```bash
git clone https://github.com/mikaeltrilles/Terminal.git
cd Terminal
# Testez, modifiez, PR !
```
