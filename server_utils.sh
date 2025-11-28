#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 TERMINAL SETUP SCRIPT - Installation complète d'outils Shell modernes
# ═══════════════════════════════════════════════════════════════════════════════

# Active Verbose & Help
VERBOSE=""
MOTD=0
ALLUSERS=0
IS_VERBOSE=0

clear
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
echo "           🚀 TERMINAL SETUP - Installation complète"
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"

for argument in "$@"; do
    case "$argument" in
        --verbose)
            echo " ✅ Mode Verbose activé"
            IS_VERBOSE=1
            VERBOSE="2>&1"
            ;;
        --help)
            cat << 'EOF'
┌──────────────────────────────────────────────────────────────────────────────┐
│ Ce script installe un terminal moderne complet !                              │
├──────────────────────────────────────────────────────────────────────────────┤
│ Options :                                                                     │
│   --verbose     📢 Affiche les logs détaillés                                 │
│   --motd        🎨 Configure le MOTD personnalisé                            │
│   --all-users   👥 Applique à tous les utilisateurs                          │
└──────────────────────────────────────────────────────────────────────────────┘
EOF
            exit 0
            ;;
        --motd)
            echo " ✅ MOTD activé"
            MOTD=1
            ;;
        --all-users)
            echo " ✅ Mode multi-utilisateurs"
            ALLUSERS=1
            ;;
        *)
            if [ -n "$argument" ]; then
                echo "❌ Argument inconnu: $argument"
                exit 1
            fi
            ;;
    esac
done

# Vérifications préalables
echo ""
echo "🔍 VÉRIFICATIONS PRÉALABLES"
if [ "$EUID" -ne 0 ]; then
    echo " ❌ Erreur: Exécutez en tant que root (sudo)"
    exit 1
fi
echo " ✅ Root OK"

if ! command -v apt-get >/dev/null 2>&1; then
    echo " ❌ Erreur: Compatible Debian/Ubuntu uniquement"
    exit 1
fi
echo " ✅ Debian/Ubuntu détecté"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 MISE À JOUR SYSTÈME
# ═══════════════════════════════════════════════════════════════════════════════
echo "📦 ═══════════════════════════════════════════════════════════════════════════════"
echo "📦                           MISE À JOUR SYSTÈME"
echo "📦 ═══════════════════════════════════════════════════════════════════════════════"
if [ "$IS_VERBOSE" = 1 ]; then
    echo "   (1/2) 🔄 apt-get update..."
    apt-get update $VERBOSE
    echo "   (2/2) 🔄 apt-get upgrade..."
    apt-get upgrade -y $VERBOSE
else
    echo "   (1/2) 🔄 Mise à jour des sources... ✅"
    apt-get update >/dev/null 2>&1
    echo "   (2/2) 🔄 Mise à niveau des paquets... ✅"
    apt-get upgrade -y >/dev/null 2>&1
fi
echo " ✅ Système à jour !"
echo ""

# Fonctions utilitaires
apt_install() {
    local pkg="$1" count="$2" total="$3"
    if [ "$IS_VERBOSE" = 1 ]; then
        echo "   ($count/$total) 📥 Installation $pkg..."
        apt-get install -y $pkg $VERBOSE
    else
        echo "   ($count/$total) 📦 $pkg..."
        apt-get install -y $pkg >/dev/null 2>&1
    fi
    if [ $? -eq 0 ]; then
        echo "   ($count/$total) ✅ $pkg"
    else
        echo "   ($count/$total) ❌ $pkg"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🛠️ PRÉREQUIS (9 paquets)
# ═══════════════════════════════════════════════════════════════════════════════
echo "🛠️  ═══════════════════════════════════════════════════════════════════════════════"
echo "🛠️                           PRÉREQUIS (9 paquets)"
echo "🛠️  ═══════════════════════════════════════════════════════════════════════════════"
PACKAGES="curl wget gzip lsb-release locales-all python3-pip make bzip2 git"
i=0; total=9
for pkg in $PACKAGES; do
    i=$((i+1))
    apt_install "$pkg" "$i" "$total"
done
echo " ✅ Tous les prérequis installés !"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 🍺 HOMEBREW
# ═══════════════════════════════════════════════════════════════════════════════
echo "🍺 ═══════════════════════════════════════════════════════════════════════════════"
echo "🍺                                HOMEBREW"
echo "🍺 ═══════════════════════════════════════════════════════════════════════════════"
if command -v brew >/dev/null 2>&1; then
    echo " ✅ Homebrew déjà installé"
else
    echo " 🤖 Installation Homebrew..."
    if [ "$IS_VERBOSE" = 1 ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" $VERBOSE
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1
    fi
    echo " ✅ Homebrew installé !"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 🐚 ZSH + OHMYZSH
# ═══════════════════════════════════════════════════════════════════════════════
echo "🐚 ═══════════════════════════════════════════════════════════════════════════════"
echo "🐚                        ZSH + OH MY ZSH + PLUGINS"
echo "🐚 ═══════════════════════════════════════════════════════════════════════════════"

app_install() {
    local app="$1" install_cmd="$2" zshrc_content="$3"
    echo ""
    echo "  🟢 $app"
    echo "  ──────────────────────────────"
    
    if command -v "$app" >/dev/null 2>&1; then
        echo "  ✅ Déjà installé"
        return 0
    fi
    
    echo "  🤖 Installation..."
    if [ "$IS_VERBOSE" = 1 ]; then
        if eval "$install_cmd $VERBOSE"; then
            [ -n "$zshrc_content" ] && append_to_zshrc "$zshrc_content" "$app" && echo "  ✅ .zshrc mis à jour"
            echo "  ✅ Succès !"
        else
            echo "  ❌ Échec"
        fi
    else
        if eval "$install_cmd >/dev/null 2>&1"; then
            [ -n "$zshrc_content" ] && append_to_zshrc "$zshrc_content" "$app" && echo "  ✅ .zshrc mis à jour"
            echo "  ✅ Succès !"
        else
            echo "  ❌ Échec"
        fi
    fi
}

append_to_zshrc() {
    local content="$1" comment="$2"
    echo "" >> /root/.zshrc
    echo "# $comment" >> /root/.zshrc
    echo "$content" >> /root/.zshrc
}

get_users() {
    awk -F: '{if ($3 >= 1000 || ($3 >= 500 && $1 != "nobody")) print $1}' /etc/passwd
}

copy_to_usershome() {
    local src="$1" dest="$2" users=$(get_users)
    for user in $users; do
        local dir="/home/$user"
        [ -d "$dir" ] || continue
        mkdir -p "$dir/$dest"
        echo "  📂 Copie → $user/$dest"
        cp -r "$src" "$dir/$dest/" 2>/dev/null || true
        chown -R "$user":"$(id -gn "$user")" "$dir/$dest" 2>/dev/null || true
    done
}

zsh_all_users() {
    local users=$(get_users)
    for user in $users; do
        chsh -s /bin/zsh "$user" 2>/dev/null || true
    done
}

# Git
app_install "git" \
"apt-get install -y git" \
"gic() { git add . && git commit -m \"\$@\" && git push; }
gbc() { git pull && git checkout -b \"\$@\" && git push --set-upstream origin \"\$@\"; }
alias gaa='git add *'
alias ga='git add'
alias gps='git push'
alias gpl='git pull'"

# Zsh + Oh My Zsh (install complet)
app_install "zsh" \
"apt-get install -y zsh && \
sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" && \
sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' /root/.zshrc" \
""

# Atuin
echo ""
echo "  🟢 atuin"
echo "  ──────────────────────────────"
echo "  🤖 Installation..."
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
append_to_zshrc 'eval "$(atuin init zsh)"' "atuin"
echo "  ✅ Succès !"
echo ""

# Autres outils APT
for app in bat btop direnv duf eza ripgrep zoxide; do
    app_install "$app" "apt-get install -y $app" \
    "$( [ "$app" = "bat" ] && echo "alias cat='bat --style=header --paging=never'; alias bat='bat --style=header --paging=never'" ||
       [ "$app" = "rg" ] && echo "alias grep=rg" ||
       [ "$app" = "zoxide" ] && echo 'eval "$(zoxide init zsh)"' ||
       [ "$app" = "direnv" ] && echo 'eval "$(direnv hook zsh)"' ||
       echo "" )"
done

# Micro
app_install "micro" "cd /usr/local/bin && curl https://getmic.ro | bash" ""

# Plugins Zsh
app_install "zsh-autosuggestions" \
"git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
'source /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"'

app_install "zsh-syntax-highlighting" \
"git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" \
'source /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 MOTD OPTIONNEL
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MOTD" = 1 ]; then
    echo ""
    echo "🎨 ═══════════════════════════════════════════════════════════════════════════════"
    echo "🎨                                MOTD PERSONNALISÉ"
    echo "🎨 ═══════════════════════════════════════════════════════════════════════════════"
    apt-get install -y neofetch figlet lolcat >/dev/null 2>&1
    
    mkdir -p /root/.config/neofetch /etc/neofetch
    curl -fsSL "https://raw.githubusercontent.com/PAPAMICA/terminal/main/neofetch.conf" -o /root/.config/neofetch/config.conf >/dev/null 2>&1
    cp /root/.config/neofetch/config.conf /etc/neofetch/config.conf
    
    [ "$ALLUSERS" = 1 ] && copy_to_usershome "/root/.config/neofetch" ".config"
    
    rm -rf /etc/motd /etc/update-motd.d/*
    cat > /etc/update-motd.d/00-motd << 'EOF'
#!/bin/sh
hostname=$(uname -n | cut -d '.' -f 1)
figlet "$hostname" | lolcat
neofetch --config /etc/neofetch/config.conf
EOF
    chmod +x /etc/update-motd.d/00-motd
    echo " ✅ MOTD configuré !"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 👥 MULTI-UTILISATEURS
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$ALLUSERS" = 1 ]; then
    echo "👥 ═══════════════════════════════════════════════════════════════════════════════"
    echo "👥                        APPLICATION AUX AUTRES UTILISATEURS"
    echo "👥 ═══════════════════════════════════════════════════════════════════════════════"
    copy_to_usershome "/root/.zshrc" ""
    copy_to_usershome "/root/.oh-my-zsh" ".oh-my-zsh"
    copy_to_usershome "/root/.config" ".config"
    zsh_all_users
    echo " ✅ Appliqué à tous les utilisateurs !"
    echo ""
fi

# Finalisation
chsh -s /bin/zsh root 2>/dev/null || true
localedef -i en_US -c -f UTF-8 en_US.UTF-8 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# 🎉 TERMINÉ !
# ═══════════════════════════════════════════════════════════════════════════════
echo "🎉 ═══════════════════════════════════════════════════════════════════════════════"
echo "🎉                        INSTALLATION TERMINÉE !"
echo "🎉 ═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "✅ Homebrew installé → brew --version"
echo "✅ Zsh + Oh My Zsh → zsh"
echo "✅ Atuin → atuin register (sync)"
echo ""
echo "🔥 Relancez votre session ou tapez : exec zsh"
echo "🔥 ═══════════════════════════════════════════════════════════════════════════════"
