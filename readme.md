# 🚀 install-terminal.sh

Script de provisioning production-grade pour configurer un terminal Linux moderne (Zsh, Oh My Zsh, Homebrew, outils CLI) sur Debian/Ubuntu.

## ✨ Fonctionnalités

- **Strict mode** : `set -euo pipefail` avec gestion d'erreurs centralisée (`trap ERR`).
- **Idempotent** : ré-exécutable sans effets secondaires néfastes (marqueurs dans `.zshrc`, check `dpkg -s`).
- **Sécurisé** : plus de `curl | sh` — tous les installers sont téléchargés dans un tmpdir et exécutés ensuite.
- **Vérification SHA-256** : helper `download_verify()` pour valider les scripts téléchargés (optionnel).
- **Rollback** : snapshot Git des dotfiles dans `~/.dotfiles-backup` avant toute mutation.
- **Mode non-root** : `--user-only` permet d'exécuter le script sans `apt-get` ni `sudo`.
- **Dry-run** : `--dry-run` affiche ce qui serait fait sans modifier le système.

## 📋 Prérequis

- Debian/Ubuntu (ou utiliser `--user-only` pour un mode sans apt)
- `bash`, `curl`, `git`
- `sudo` (sauf en mode `--user-only`)

## 🚀 Utilisation

### En une ligne (curl | bash)

```bash
# Installation complète (non-interactive, option 4 par défaut)
curl -fsSL https://raw.githubusercontent.com/mikaeltrilles/Terminal/main/install-terminal.sh | bash

# Avec arguments (nécessite bash -s --)
curl -fsSL https://raw.githubusercontent.com/mikaeltrilles/Terminal/main/install-terminal.sh | bash -s -- --dry-run
curl -fsSL https://raw.githubusercontent.com/mikaeltrilles/Terminal/main/install-terminal.sh | bash -s -- --user-only
curl -fsSL https://raw.githubusercontent.com/mikaeltrilles/Terminal/main/install-terminal.sh | bash -s -- --yes --backup
```

### Mode fichier local (recommandé pour review)

```bash
# Télécharger d'abord
curl -fsSL -o install-terminal.sh https://raw.githubusercontent.com/mikaeltrilles/Terminal/main/install-terminal.sh

# Vérifier le contenu (optionnel mais recommandé)
cat install-terminal.sh

# Exécuter
chmod +x install-terminal.sh
./install-terminal.sh --dry-run --yes   # preview
./install-terminal.sh --yes --backup    # install
```

## 🔧 Options CLI

| Option | Description |
|--------|-------------|
| `-y, --yes` | Mode non-interactif (sélectionne l'option 4) |
| `-n, --dry-run` | Affiche le plan sans exécuter |
| `-b, --backup` | Backup `.zshrc` etc. avant modification |
| `-u, --user-only` | Skip les paquets système (`apt-get`) |
| `-h, --help` | Affiche l'aide |

## 📦 Ce qui est installé

### Paquets système (apt)
- `zsh`, `git`, `curl`, `wget`, `build-essential`, `procps`, `file`, `locales-all`
- `less`, `btop`, `eza`, `ripgrep`, `zoxide`, `duf`, `direnv`

### Outils utilisateur
- **Oh My Zsh** — avec thème `jonathan`
- **Plugins OMZ** : `zsh-autosuggestions`, `zsh-syntax-highlighting`
- **Homebrew** (Linux)
- **Atuin** (shell history)
- **Micro** (éditeur)

### Aliases ajoutés
- `cat` → `bat` (ou `batcat`/`less` en fallback)
- `grep` → `rg`
- `relbash` → `source ~/.zshrc`
- `cls` → `clear`
- `maj()` → mise à jour complète (apt + brew)

## 🔐 Sécurité

- **Supporte `curl | bash`** : le script détecte un pipe (`[[ ! -t 0 ]]`) et force automatiquement `--yes` pour éviter que `read` ne consomme le contenu du script via stdin.
- Les installateurs internes (OMZ, Homebrew, Atuin, Micro) sont téléchargés dans un tmpdir, pas exécutés directement en pipe.
- L'installateur OMZ s'exécute en tant qu'utilisateur cible (`sudo -u`), pas en root.
- Les appends dans `.zshrc` sont idempotents (marqueur `# marker:<name>`).
- Les dotfiles sont snapshotés dans un repo Git avant modification.

## 🧪 Tests

```bash
# Syntaxe
bash -n install-terminal.sh

# Lint
shellcheck install-terminal.sh

# Format
shfmt -w -i 4 -ci install-terminal.sh

# Smoke tests (nécessite bats)
bats tests/smoke.bats

# Tests manuels
./install-terminal.sh --help
./install-terminal.sh --dry-run --yes
./install-terminal.sh --dry-run --yes --user-only
```

## 🔄 Rollback

Si un changement pose problème, restaurer depuis le snapshot Git :

```bash
cd ~/.dotfiles-backup
git log --oneline          # trouver le snapshot avant install
git checkout HEAD~1        # ou le hash du commit
cp .zshrc ~/.zshrc         # restaurer le fichier souhaité
```

## 🏗️ CI / GitHub Actions

Le workflow `.github/workflows/shell-lint.yml` s'exécute sur chaque push/PR :

- **shellcheck** — warnings et erreurs
- **shfmt** — vérification du formatage
- **integration** — `bash -n`, `--dry-run --yes`, `--help`

## 📝 Checksums des scripts téléchargés

Pour activer la vérification SHA-256, passer le hash attendu à `download_verify()` :

```bash
download_verify "https://example.com/install.sh" "/tmp/install.sh" "a1b2c3..."
```

Par défaut, le script affiche le hash calculé avec un warning s'il n'est pas vérifié.

## 📄 Licence

MIT — voir le repo.
