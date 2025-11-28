#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 TERMINAL SETUP SCRIPT - Installation pour utilisateur actif
# ═══════════════════════════════════════════════════════════════════════════════

clear
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
echo "           🚀 TERMINAL SETUP - Menu d'installation"
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
echo ""

# Détection utilisateur actif
CURRENT_USER=$(logname 2>/dev/null || whoami)
HOME_DIR="/home/$CURRENT_USER"
if [ "$CURRENT_USER" = "root" ]; then
    HOME_DIR="/root"
fi

echo "👤 Utilisateur détecté : $CURRENT_USER"
echo "🏠 Home : $HOME_DIR"
echo ""

# Menu interactif
echo "📋 Choisissez une option :"
echo "   1) 🛠️  Installation de base (Zsh + outils essentiels)"
echo "   2) 🐚 Installation Oh My Zsh (sh -c .../install.sh)"
echo "   3) 🍺 Installation Homebrew (Linux non-root)"
echo "   4) 🔥 Installation complète (1+2+3)"
echo ""
read -p "Votre choix (1-4) [1] : " CHOICE
CHOICE=${CHOICE:-1}

case $CHOICE in
    1) BASE=1 ;;
    2) OMZ=1 ;;
    3) BREW=1 ;;
    4) BASE=1; OMZ=1; BREW=1 ;;
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
    sudo apt-get update >/dev/null 2>&1
    if sudo apt-get install -y "$pkg" >/dev/null 2>&1; then
        echo "   ($count/$total) ✅ $pkg"
    else
        echo "   ($count/$total) ❌ $pkg"
    fi
}

append_to_rc() {
    local file="$HOME_DIR/.$(basename "$1")"
    echo "# $(date): $2" >> "$file"
    echo "$3" >> "$file"
    sudo chown "$CURRENT_USER:$CURRENT_USER" "$file"
    echo "✅ $file mis à jour"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PRÉREQUIS ✅ COMPTEURS (7 paquets)
# ═══════════════════════════════════════════════════════════════════════════════
section "PRÉREQUIS (7 paquets)"
PACKAGES="curl wget git zsh build-essential procps file locales-all"
i=0; total=7
for pkg in $PACKAGES; do
    i=$((i+1))
    apt_install "$pkg" "$i" "$total"
done
echo " ✅ Tous les prérequis installés !"
echo ""

# 1. Installation de base
if [ "$BASE" = 1 ]; then
    section "INSTALLATION DE BASE"
    apt_install "bat" "1" "7"
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
        echo 'alias cat="bat --style=header --paging=never"'
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

# Shell par défaut
sudo chsh -s /bin/zsh "$CURRENT_USER" 2>/dev/null || true

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
