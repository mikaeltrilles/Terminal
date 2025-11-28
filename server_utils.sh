#!/bin/bash

# Active Verbose & Help
VERBOSE=""
MOTD=0
ALLUSERS=0
IS_VERBOSE=0

for argument in "$@"; do
    case "$argument" in
        --verbose)
            echo " ✅ Verbose selected"
            IS_VERBOSE=1
            VERBOSE="2>&1"
            ;;
        --help)
            cat << 'EOF'
Ce script installe différents outils pour le Shell (https://github.com/PAPAMICA/terminal).
Options :
  --verbose     Affiche les logs détaillés
  --motd        Configure le MOTD personnalisé
  --all-users   Applique à tous les utilisateurs
EOF
            exit 0
            ;;
        --motd)
            echo " ✅ MOTD selected"
            MOTD=1
            ;;
        --all-users)
            echo " ✅ All users selected"
            ALLUSERS=1
            ;;
        *)
            if [ -n "$argument" ]; then
                echo "Argument non reconnu: $argument"
                exit 1
            fi
            ;;
    esac
done

# Vérification root et Debian/Ubuntu
if [ "$EUID" -ne 0 ]; then
    echo " ❌ Veuillez exécuter en tant que root"
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo " ❌ Ce script est uniquement compatible avec Debian et Ubuntu"
    exit 1
fi

# Mise à jour système ✅ CORRIGÉ
echo ""
echo "-- Mise à jour système --"
if [ "$IS_VERBOSE" = 1 ]; then
    apt-get update $VERBOSE
    apt-get upgrade -y $VERBOSE
else
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y >/dev/null 2>&1
fi

# Fonctions utilitaires ✅ CORRIGÉES
apt_install() {
    local pkg="$1"
    local count="$2"
    if [ "$IS_VERBOSE" = 1 ]; then
        apt-get install -y $pkg $VERBOSE
    else
        apt-get install -y $pkg >/dev/null 2>&1
    fi
    if [ $? -eq 0 ]; then
        echo "   ($count) ✅ $pkg"
    else
        echo "   ($count) ❌ $pkg"
    fi
}

get_users() {
    awk -F: '{if ($3 >= 1000 || ($3 >= 500 && $1 != "nobody")) print $1}' /etc/passwd
}

copy_to_usershome() {
    local src="$1"
    local dest="$2"
    local users=$(get_users)
    
    for user in $users; do
        local dir="/home/$user"
        if [ -d "$dir" ]; then
            mkdir -p "$dir/$dest"
            echo " ✅ Copie $src vers $user/$dest"
            cp -r "$src" "$dir/$dest/" 2>/dev/null || true
            chown -R "$user":"$(id -gn "$user")" "$dir/$dest" 2>/dev/null || true
        fi
    done
}

zsh_all_users() {
    local users=$(get_users)
    for user in $users; do
        chsh -s /bin/zsh "$user" 2>/dev/null || true
    done
}

append_to_zshrc() {
    local content="$1"
    local comment="$2"
    echo "" >> /root/.zshrc
    echo "# $comment" >> /root/.zshrc
    echo "$content" >> /root/.zshrc
}

# Prérequis
echo ""
echo "-- Prérequis --"
PACKAGES="curl wget gzip lsb-release locales-all python3-pip make bzip2 git"
i=0
for pkg in $PACKAGES; do
    i=$((i+1))
    apt_install "$pkg" "$i"
done

# MOTD optionnel
if [ "$MOTD" = 1 ]; then
    echo ""
    echo "-- MOTD --"
    if [ "$IS_VERBOSE" = 1 ]; then
        apt-get install -y neofetch figlet lolcat $VERBOSE
    else
        apt-get install -y neofetch figlet lolcat >/dev/null 2>&1
    fi
    
    mkdir -p /root/.config/neofetch /etc/neofetch
    if [ "$IS_VERBOSE" = 1 ]; then
        curl -fsSL "https://raw.githubusercontent.com/PAPAMICA/terminal/main/neofetch.conf" -o /root/.config/neofetch/config.conf $VERBOSE
    else
        curl -fsSL "https://raw.githubusercontent.com/PAPAMICA/terminal/main/neofetch.conf" -o /root/.config/neofetch/config.conf >/dev/null 2>&1
    fi
    cp /root/.config/neofetch/config.conf /etc/neofetch/config.conf
    
    if [ "$ALLUSERS" = 1 ]; then
        copy_to_usershome "/root/.config/neofetch" ".config"
    fi
    
    rm -rf /etc/motd /etc/update-motd.d/*
    cat > /etc/update-motd.d/00-motd << 'EOF'
#!/bin/sh
# By Mickael (PAPAMICA) Asseline
hostname=$(uname -n | cut -d '.' -f 1)
figlet "$hostname" | lolcat
neofetch --config /etc/neofetch/config.conf
EOF
    chmod +x /etc/update-motd.d/00-motd
    echo " ✅ MOTD configuré !"
fi

# Fonction d'installation d'applications ✅ CORRIGÉE
app_install() {
    local app="$1"
    local install_cmd="$2"
    local zshrc_content="$3"
    
    echo ""
    echo "-- $app --"
    
    if command -v "$app" >/dev/null 2>&1; then
        echo " ✅ $app déjà installé"
        return 0
    fi
    
    echo " 🤖 Installation de $app ..."
    if [ "$IS_VERBOSE" = 1 ]; then
        if eval "$install_cmd $VERBOSE"; then
            if [ -n "$zshrc_content" ]; then
                append_to_zshrc "$zshrc_content" "$app"
                echo " ✅ .zshrc mis à jour pour $app"
            fi
            echo " ✅ $app installé avec succès !"
            return 0
        fi
    else
        if eval "$install_cmd >/dev/null 2>&1"; then
            if [ -n "$zshrc_content" ]; then
                append_to_zshrc "$zshrc_content" "$app"
                echo " ✅ .zshrc mis à jour pour $app"
            fi
            echo " ✅ $app installé avec succès !"
            return 0
        fi
    fi
    echo " ❌ Échec installation $app"
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

# Zsh + Oh My Zsh
app_install "zsh" \
"apt-get install -y zsh && \
sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) \"\" --unattended\" && \
sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' /root/.zshrc" \
""

# Atuin ✅ CORRIGÉ - ne vérifie PAS command -v (install user-local)
echo ""
echo "-- atuin --"
echo " 🤖 Installation de atuin ..."
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
append_to_zshrc 'eval "$(atuin init zsh)"' "atuin"
echo " ✅ atuin installé avec succès !"

# Bat (cat amélioré)
app_install "bat" \
"apt-get install -y bat" \
"alias cat='bat --style=header --paging=never'
alias bat='bat --style=header --paging=never'"

# Btop (htop moderne)
app_install "btop" \
"apt-get install -y btop" \
"alias top=btop
alias htop=btop"

# Cheat.sh ✅ CORRIGÉ (ARM64 + wget direct)
echo ""
echo "-- cheat --"
echo " 🤖 Installation de cheat ..."
if curl -s https://api.github.com/repos/cheat/cheat/releases/latest | \
grep 'browser_download_url.*cheat-linux-aarch64.gz' | \
head -1 | cut -d : -f 2,4 | tr -d '"' | xargs wget -qO- | \
gzip -d | chmod +x > /usr/local/bin/cheat && \
mkdir -p /root/.config/cheat/cheatsheets/{community,personal} && \
git clone https://github.com/cheat/cheatsheets.git /root/.config/cheat/cheatsheets/community; then
    append_to_zshrc 'alias ?="cheat"
alias ??="cheat --directory ~/.config/cheat/cheatsheets/personal"' "cheat"
    echo " ✅ cheat installé avec succès !"
else
    echo " ❌ Échec installation cheat (essayez manuellement)"
fi

# Direnv
app_install "direnv" \
"apt-get install -y direnv" \
'eval "$(direnv hook zsh)"'

# Duf (df amélioré)
app_install "duf" \
"apt-get install -y duf" \
""

# Eza (ls moderne)
app_install "eza" \
"apt-get install -y eza" \
'alias ls="eza -a --icons"
alias ll="eza -1a --icons"
alias la="eza -lagh --icons"
alias lt="eza -a --tree --icons --level=2"'

# Micro (éditeur moderne) ✅ CORRIGÉ
app_install "micro" \
"cd /usr/local/bin && curl https://getmic.ro | bash" \
""

# Ripgrep (grep ultra-rapide)
app_install "rg" \
"apt-get install -y ripgrep" \
"alias grep=rg"

# Zoxide (navigateur de dossiers intelligent)
app_install "zoxide" \
"apt-get install -y zoxide" \
'eval "$(zoxide init zsh)"'

# Plugins Zsh
app_install "zsh-autosuggestions" \
"git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
'source /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"'

app_install "zsh-syntax-highlighting" \
"git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" \
'source /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'

# Copie vers autres utilisateurs
if [ "$ALLUSERS" = 1 ]; then
    echo ""
    echo "-- Autres utilisateurs --"
    copy_to_usershome "/root/.zshrc" ""
    copy_to_usershome "/root/.oh-my-zsh" ".oh-my-zsh"
    copy_to_usershome "/root/.config" ".config"
    zsh_all_users
fi

# Finalisation
chsh -s /bin/zsh root 2>/dev/null || true
localedef -i en_US -c -f UTF-8 en_US.UTF-8 2>/dev/null || true

echo ""
echo "🎉 Installation terminée ! Redémarrez votre session pour charger Zsh."
echo "   • Lancez 'zsh' pour tester immédiatement"
echo "   • Vérifiez ~/.zshrc pour les personnalisations"
echo "   • Atuin: 'atuin register' pour synchroniser"