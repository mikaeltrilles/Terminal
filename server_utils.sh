#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 TERMINAL SETUP SCRIPT - Installation pour utilisateur actif
# ═══════════════════════════════════════════════════════════════════════════════

clear
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
echo "           🚀 TERMINAL SETUP - Menu d'installation"
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
echo ""

set -euo pipefail
IFS=$'\n\t'
trap 'echo "Erreur sur la ligne $LINENO"; exit 1' ERR

# Détection utilisateur actif (favorise SUDO_USER si présent)
if [ -n "${SUDO_USER:-}" ]; then
    CURRENT_USER="$SUDO_USER"
else
    CURRENT_USER=$(logname 2>/dev/null || whoami)
fi

# Détecter le répertoire home réel via getent si possible
HOME_DIR=$(getent passwd "$CURRENT_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$HOME_DIR" ]; then
    if [ "$CURRENT_USER" = "root" ]; then
        HOME_DIR="/root"
    else
        HOME_DIR="/home/$CURRENT_USER"
    fi
fi

echo "👤 Utilisateur détecté : $CURRENT_USER"
echo "🏠 Home : $HOME_DIR"
echo ""

# Fonctions utilitaires pour affichage des versions
section() {
    echo ""
    echo "📦 ═══════════════════════════════════════════════════════════════════════════════"
    echo "📦                           $1"
    echo "📦 ═══════════════════════════════════════════════════════════════════════════════"
}

try_version() {
    local cmd="$1"
    # Couleurs
    local RESET="\033[0m"
    local BOLD="\033[1m"
    local GREEN="\033[32m"
    local RED="\033[31m"
    local CYAN="\033[36m"

    local path_found=""
    if command -v "$cmd" >/dev/null 2>&1; then
        path_found=$(command -v "$cmd")
    else
        # Cherche dans emplacements communs (user-local et Homebrew)
        local candidates=("$HOME_DIR/.local/bin/$cmd" "$HOME_DIR/.cargo/bin/$cmd" "$HOME_DIR/.atuin/bin/$cmd" "$HOME_DIR/.linuxbrew/bin/$cmd" "/home/linuxbrew/.linuxbrew/bin/$cmd" "/usr/local/bin/$cmd" "/snap/bin/$cmd")
        for p in "${candidates[@]}"; do
            if [ -x "$p" ]; then
                path_found="$p"
                break
            fi
        done
        # Si toujours pas trouvé, essayer en tant que user détecté (utile si script lancé avec sudo)
        if [ -z "$path_found" ] && command -v sudo >/dev/null 2>&1 && [ -n "${CURRENT_USER:-}" ] && [ "$CURRENT_USER" != "$(whoami)" ]; then
            local user_path
            user_path=$(sudo -u "$CURRENT_USER" command -v "$cmd" 2>/dev/null || true)
            if [ -n "$user_path" ]; then
                path_found="$user_path"
            fi
        fi
    fi

    if [ -z "$path_found" ]; then
        # icône et couleur pour absence
        local icon_absent="❌"
        # Tentative : exécuter la commande via un shell de l'utilisateur (bash/zsh)
        if command -v sudo >/dev/null 2>&1 && [ -n "${CURRENT_USER:-}" ]; then
            local shells=(bash zsh)
            for sh in "${shells[@]}"; do
                if sudo -H -u "$CURRENT_USER" command -v "$sh" >/dev/null 2>&1; then
                    local s_out
                    # Source les fichiers de config usuels de l'utilisateur avant d'exécuter la commande
                    if [ "$sh" = "zsh" ]; then
                        s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.zshrc\" 2>/dev/null || true; source \"\$HOME/.zprofile\" 2>/dev/null || true; $cmd --version" 2>&1) || s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.zshrc\" 2>/dev/null || true; source \"\$HOME/.zprofile\" 2>/dev/null || true; $cmd -v" 2>&1) || s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.zshrc\" 2>/dev/null || true; source \"\$HOME/.zprofile\" 2>/dev/null || true; $cmd version" 2>&1) || s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.zshrc\" 2>/dev/null || true; source \"\$HOME/.zprofile\" 2>/dev/null || true; $cmd -V" 2>&1) || s_out=""
                    else
                        s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.bashrc\" 2>/dev/null || true; source \"\$HOME/.profile\" 2>/dev/null || true; $cmd --version" 2>&1) || s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.bashrc\" 2>/dev/null || true; source \"\$HOME/.profile\" 2>/dev/null || true; $cmd -v" 2>&1) || s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.bashrc\" 2>/dev/null || true; source \"\$HOME/.profile\" 2>/dev/null || true; $cmd version" 2>&1) || s_out=$(sudo -H -u "$CURRENT_USER" "$sh" -lc "source \"\$HOME/.bashrc\" 2>/dev/null || true; source \"\$HOME/.profile\" 2>/dev/null || true; $cmd -V" 2>&1) || s_out=""
                    fi
                    if [ -n "$(echo "$s_out" | sed -n '1p' | sed -e '/not found/d' -e '/command not found/d')" ]; then
                        out=$(echo "$s_out" | head -n1)
                        # Found via user's shell
                        local icon="🔹"
                        local col_cmd="$CYAN"
                        case "$cmd" in
                            curl) icon="🌊"; col_cmd="\033[36m" ;;
                            wget) icon="⬇️"; col_cmd="\033[35m" ;;
                            git) icon="🐙"; col_cmd="\033[34m" ;;
                            zsh) icon="💠"; col_cmd="\033[35m" ;;
                            bat) icon="📚"; col_cmd="\033[33m" ;;
                            btop) icon="📈"; col_cmd="\033[33m" ;;
                            eza) icon="📁"; col_cmd="\033[36m" ;;
                            rg|ripgrep) icon="🔎"; col_cmd="\033[36m" ;;
                            zoxide) icon="🧭"; col_cmd="\033[36m" ;;
                            duf) icon="📊"; col_cmd="\033[36m" ;;
                            direnv) icon="🛡️"; col_cmd="\033[36m" ;;
                            atuin) icon="🛰️"; col_cmd="\033[36m" ;;
                            micro) icon="✍️"; col_cmd="\033[32m" ;;
                            brew) icon="🍺"; col_cmd="\033[33m" ;;
                            gcc) icon="🔧"; col_cmd="\033[33m" ;;
                            apt-get) icon="📦"; col_cmd="\033[33m" ;;
                            *) icon="🔹"; col_cmd="$CYAN" ;;
                        esac
                        echo -e "   ${icon} ${BOLD}${col_cmd}${cmd}${RESET} : ${GREEN}${out}${RESET}"
                        return
                    fi
                fi
            done
        fi

        echo -e "   ${icon_absent} ${BOLD}${cmd}${RESET} : ${RED}non installé${RESET}"
        return
    fi

    local out=""
    # Tenter d'exécuter la commande directement; si le binaire appartient à l'utilisateur détecté, exécuter via sudo -u
    if [ "${path_found}" != "$(command -v "$cmd" 2>/dev/null || true)" ] && command -v sudo >/dev/null 2>&1 && [ -n "${CURRENT_USER:-}" ] && [ "$CURRENT_USER" != "$(whoami)" ]; then
        out=$(sudo -u "$CURRENT_USER" "$path_found" --version 2>&1) || out=$(sudo -u "$CURRENT_USER" "$path_found" -v 2>&1) || out=$(sudo -u "$CURRENT_USER" "$path_found" version 2>&1) || out=$(sudo -u "$CURRENT_USER" "$path_found" -V 2>&1) || out="version inconnue"
    else
        out=$("$path_found" --version 2>&1) || out=$("$path_found" -v 2>&1) || out=$("$path_found" version 2>&1) || out=$("$path_found" -V 2>&1) || out="version inconnue"
    fi
    out=$(echo "$out" | head -n1)

    # icônes et couleurs par outil
    local icon="🔹"
    local col_cmd="$CYAN"
    case "$cmd" in
        curl) icon="🌊"; col_cmd="\033[36m" ;;
        wget) icon="⬇️"; col_cmd="\033[35m" ;;
        git) icon="🐙"; col_cmd="\033[34m" ;;
        zsh) icon="💠"; col_cmd="\033[35m" ;;
        bat) icon="📚"; col_cmd="\033[33m" ;;
        btop) icon="📈"; col_cmd="\033[33m" ;;
        eza) icon="📁"; col_cmd="\033[36m" ;;
        rg|ripgrep) icon="🔎"; col_cmd="\033[36m" ;;
        zoxide) icon="🧭"; col_cmd="\033[36m" ;;
        duf) icon="📊"; col_cmd="\033[36m" ;;
        direnv) icon="🛡️"; col_cmd="\033[36m" ;;
        atuin) icon="🛰️"; col_cmd="\033[36m" ;;
        micro) icon="✍️"; col_cmd="\033[32m" ;;
        brew) icon="🍺"; col_cmd="\033[33m" ;;
        gcc) icon="🔧"; col_cmd="\033[33m" ;;
        apt-get) icon="📦"; col_cmd="\033[33m" ;;
        *) icon="🔹"; col_cmd="$CYAN" ;;
    esac

    echo -e "   ${icon} ${BOLD}${col_cmd}${cmd}${RESET} : ${GREEN}${out}${RESET}"
}

show_versions() {
    # Header stylé (avec couleur si le terminal le supporte)
    local RESET="\033[0m"
    local BLUE="\033[34m"
    if declare -f section >/dev/null 2>&1; then
        # utilise la fonction section (déjà stylée)
        section "VERSIONS INSTALLÉES"
    else
        echo -e "${BLUE}📦 ═══════════════════════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BLUE}📦                           VERSIONS INSTALLÉES${RESET}"
        echo -e "${BLUE}📦 ═══════════════════════════════════════════════════════════════════════════════${RESET}"
    fi

    local cmds=(curl wget git zsh bat btop eza rg zoxide duf direnv atuin micro brew gcc apt-get)
    for c in "${cmds[@]}"; do
        try_version "$c"
    done

    if [ -d "$HOME_DIR/.oh-my-zsh" ]; then
        echo -e "   📂 \033[1moh-my-zsh\033[0m : \033[32minstallé dans $HOME_DIR/.oh-my-zsh\033[0m"
    else
        echo -e "   📂 \033[1moh-my-zsh\033[0m : \033[31mnon installé\033[0m"
    fi
    echo ""
}

# Menu interactif
echo "📋 Choisissez une option :"
echo "   1) 🛠️  Installation de base (Zsh + outils essentiels)"
echo "   2) 🐚 Installation Oh My Zsh (sh -c .../install.sh)"
echo "   3) 🍺 Installation Homebrew (Linux non-root)"
echo "   4) 🔥 Installation complète (1+2+3)"
echo "   5) 🔍 Afficher les versions des éléments installés (contrôle)"
echo "   6) ❌ Quitter sans exécuter le script"
echo ""
read -p "Votre choix (1-6) [1] : " CHOICE
CHOICE=${CHOICE:-1}

case $CHOICE in
    1) BASE=1 ;;
    2) OMZ=1 ;;
    3) BREW=1 ;;
    4) BASE=1; OMZ=1; BREW=1 ;;
    5)
        # Affiche les versions et quitte sans lancer d'installation
        show_versions
        exit 0
        ;;
    6)
        echo "⚠️  Sortie demandée : le script ne sera pas exécuté."
        exit 0
        ;;
    *) echo "❌ Option invalide. Quit."; exit 1 ;;
esac

echo ""
echo "🚀 Début installation... ($CHOICE sélectionné)"
echo ""

# Vérifications
if ! command -v apt-get >/dev/null 2>&1; then
    echo " ❌ Compatible Debian/Ubuntu uniquement"
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo " ❌ Installez sudo d'abord"
    exit 1
fi

# Fonctions
section() {
    echo ""
    echo "📦 ═══════════════════════════════════════════════════════════════════════════════"
    echo "📦                           $1"
    echo "📦 ═══════════════════════════════════════════════════════════════════════════════"
}

apt_install() {
    local pkg="$1" count="$2" total="$3"
    if sudo apt-get install -y "$pkg" >/dev/null 2>&1; then
        echo "   ($count/$total) ✅ $pkg"
    else
        echo "   ($count/$total) ❌ $pkg"
    fi
}

append_to_rc() {
    local base file
    base=$(basename "$1")
    if [[ "$base" != .* ]]; then
        base=".$base"
    fi
    file="$HOME_DIR/$base"
    echo "# $(date): $2" >> "$file"
    echo "$3" >> "$file"
    sudo chown "$CURRENT_USER:$CURRENT_USER" "$file" 2>/dev/null || true
    echo "✅ $file mis à jour"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PRÉREQUIS ✅ COMPTEURS (7 paquets)
# ═══════════════════════════════════════════════════════════════════════════════
section "PRÉREQUIS (7 paquets)"
PACKAGES="curl wget git zsh build-essential procps file locales-all"
i=0; total=7

# Update once before installing packages
sudo apt-get update -y >/dev/null 2>&1
for pkg in $PACKAGES; do
    i=$((i+1))
    apt_install "$pkg" "$i" "$total"
done
echo " ✅ Tous les prérequis installés !"
echo ""

# 1. Installation de base
if [ "$BASE" = 1 ]; then
    section "INSTALLATION DE BASE"
    apt_install "less" "1" "7"
    apt_install "btop" "2" "7"
    apt_install "eza" "3" "7"
    apt_install "ripgrep" "4" "7"
    apt_install "zoxide" "5" "7"
    apt_install "duf" "6" "7"
    apt_install "direnv" "7" "7"
    
    # Atuin
    echo "🤖 Atuin..."
    bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    append_to_rc ".zshrc" "atuin" 'eval "$(atuin init zsh)"'
    
    # Micro
    echo "🤖 Micro..."
    sudo mkdir -p /usr/local/bin
    cd /usr/local/bin && curl https://getmic.ro | bash
    echo "✅ Micro installé"
    echo ""
fi

# 2. Oh My Zsh
if [ "$OMZ" = 1 ]; then
    section "OH MY ZSH"
    echo "🤖 Oh My Zsh (officiel)..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Copie vers utilisateur actif
    sudo cp -rf /root/.oh-my-zsh "$HOME_DIR/" 2>/dev/null || true
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.oh-my-zsh" 2>/dev/null || true
    
    # Thème JONATHAN par défaut ✅
    sudo -u "$CURRENT_USER" bash -c "mkdir -p '$HOME_DIR/.oh-my-zsh/custom/plugins'"
    sed -i 's/robbyrussell/jonathan/g' "$HOME_DIR/.zshrc" 2>/dev/null || true
    
    # Plugins
    sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    
    # Ajout plugins au .zshrc
    {
        echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting sudo)'
        echo 'source $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'
        echo 'export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"'
        echo 'source $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
        echo 'if command -v bat >/dev/null 2>&1; then'
        echo '  alias cat="bat --style=header --paging=never"'
        echo 'elif command -v batcat >/dev/null 2>&1; then'
        echo '  alias cat="batcat --style=header --paging=never"'
        echo 'elif command -v less >/dev/null 2>&1; then'
        echo '  alias cat="less -R"'
        echo 'else'
        echo '  alias cat="cat"'
        echo 'fi'
        echo 'alias grep=rg'
        echo 'eval "$(zoxide init zsh)"'
        echo 'eval "$(direnv hook zsh)"'
        echo 'alias relbash="source ~/.zshrc"'
        echo 'alias zshconfig="sudo nano ~/.zshrc"'
        echo 'alias cls="clear"'
        echo 'maj() { echo "🍓  Mise à jour complète Raspberry Pi OS 🍀"; echo "──────────────────────────────────────────"; echo -e "\n📦  Mise à jour des dépôts APT..."; sudo apt-get update -y; echo -e "\n⚙️  Installation des mises à jour disponibles..."; sudo apt-get upgrade -y; echo -e "\n🚀  Mise à niveau de la distribution..."; sudo apt-get dist-upgrade -y; echo -e "\n🔧  Mise à jour du firmware Raspberry Pi..."; sudo rpi-update; echo -e "\n🧹  Nettoyage des paquets obsolètes..."; sudo apt-get autoremove -y; sudo apt-get autoclean -y; sudo apt-get clean; echo -e "\n☕️  Mise à jour Homebrew..."; brew update; echo -e "\n📦  Mise à niveau des paquets Homebrew..."; brew upgrade; echo -e "\n🧹  Nettoyage Homebrew..."; brew autoremove; echo -e "\n🏁  Mise à jour terminée avec succès ! 🎉"; echo "──────────────────────────────────────────"; }'
    } >> "$HOME_DIR/.zshrc"
    
    sudo chown "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.zshrc"
    echo "✅ Oh My Zsh + thème JONATHAN + plugins + aliases pour $CURRENT_USER"
    echo ""
fi

# 3. Homebrew ✅ OFFICIEL
if [ "$BREW" = 1 ]; then
    section "HOMEBREW (Linux)"
    if command -v brew >/dev/null 2>&1; then
        echo "✅ Homebrew déjà installé"
    else
        echo "🤖 Homebrew pour $CURRENT_USER..."
        NONINTERACTIVE=1 sudo -u "$CURRENT_USER" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Next steps OFFICIELS
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME_DIR/.zshrc"
        sudo chown "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.zshrc"
        
        # Dépendances + GCC
        sudo apt-get install -y build-essential
        if command -v brew >/dev/null 2>&1; then
            brew install gcc
        fi
        
        echo "✅ Homebrew → /home/linuxbrew/.linuxbrew/bin/brew"
    fi
    echo ""
fi

# Shell par défaut (changer uniquement si zsh présent)
ZSH_BIN=$(command -v zsh || true)
if [ -n "$ZSH_BIN" ]; then
    sudo chsh -s "$ZSH_BIN" "$CURRENT_USER" 2>/dev/null || true
else
    echo "⚠️  zsh introuvable, chsh ignoré"
fi

# Lancement OMZ automatique
echo "🚀 Lancement Oh My Zsh..."
sudo -u "$CURRENT_USER" zsh -l

# ═══════════════════════════════════════════════════════════════════════════════
# 🎉 TERMINÉ !
# ═══════════════════════════════════════════════════════════════════════════════
section "INSTALLATION TERMINÉE !"
echo "✅ Configuration appliquée pour : $CURRENT_USER"
echo ""
echo "📋 Vérifications :"
echo "   • Zsh : zsh --version"
echo "   • OMZ : ls ~/.oh-my-zsh"
echo "   • Brew: brew --version"
echo "   • Atuin: atuin register"
echo "   • Alias: relbash, zshconfig, maj"
echo ""
echo "🚀 Déjà lancé dans Oh My Zsh avec thème JONATHAN ! (Ctrl+D pour quitter)"
echo ""
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
