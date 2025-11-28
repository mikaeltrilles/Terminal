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
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y "$1" >/dev/null 2>&1
    echo "✅ $1 installé"
}

append_to_rc() {
    local file="$HOME_DIR/.$(basename "$1")"
    echo "# $(date): $2" >> "$file"
    echo "$3" >> "$file"
    echo "✅ $file mis à jour"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PRÉREQUIS
# ═══════════════════════════════════════════════════════════════════════════════
section "PRÉREQUIS"
apt_install "curl wget git zsh build-essential procps file locales-all"
echo ""

# 1. Installation de base
if [ "$BASE" = 1 ]; then
    section "INSTALLATION DE BASE"
    apt_install "zsh bat btop eza ripgrep zoxide duf direnv neofetch"
    
    # Atuin
    echo "🤖 Atuin..."
    bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    append_to_rc ".zshrc" "atuin" 'eval "$(atuin init zsh)"'
    
    # Micro
    echo "🤖 Micro..."
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
    sudo cp -rf /root/.oh-my-zsh "$HOME_DIR/"
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.oh-my-zsh"
    
    # Thème agnoster + plugins
    sed -i 's/robbyrussell/agnoster/g' "$HOME_DIR/.zshrc"
    
    # Plugins
    sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    
    # Ajout plugins au .zshrc
    {
        echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)'
        echo 'source $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'
        echo 'export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"'
        echo 'source $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
        echo 'alias cat="bat --style=header --paging=never"'
        echo 'alias grep=rg'
        echo 'eval "$(zoxide init zsh)"'
        echo 'eval "$(direnv hook zsh)"'
    } >> "$HOME_DIR/.zshrc"
    
    sudo chown "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.zshrc"
    echo "✅ Oh My Zsh + plugins pour $CURRENT_USER"
    echo ""
fi

# 3. Homebrew
if [ "$BREW" = 1 ]; then
    section "HOMEBREW (Linux)"
    if command -v brew >/dev/null 2>&1; then
        echo "✅ Homebrew déjà installé"
    else
        echo "🤖 Homebrew pour $CURRENT_USER..."
        NONINTERACTIVE=1 sudo -u "$CURRENT_USER" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Ajout au PATH
        {
            echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"'
            echo 'export PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"'
        } >> "$HOME_DIR/.zshrc"
        
        sudo chown "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.zshrc"
        echo "✅ Homebrew → /home/linuxbrew/.linuxbrew/bin/brew"
    fi
    echo ""
fi

# Shell par défaut
sudo chsh -s /bin/zsh "$CURRENT_USER" 2>/dev/null || true

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
echo ""
echo "🚀 Lancez : exec zsh"
echo ""
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
