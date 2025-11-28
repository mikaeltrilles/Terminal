#!/bin/bash

# Active Verbose & Help
VERBOSE="> /dev/null 2>&1"
MOTD=0
ALLUSERS=0

for argument in "$@"; do
    case "$argument" in
        --verbose)
            echo " ✅ Verbose selected"
            VERBOSE=""
            ;;
        --help)
            echo 'This script installs different tools for the Shell (Check https://github.com/PAPAMICA/terminal).
Use "--verbose" to display the logs
Use "--motd" to update your motd
Use "--all-users" to apply all modifications to all users'
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

# Mise à jour système
echo ""
echo "-- Mise à jour système --"
apt-get update $VERBOSE
apt-get upgrade -y $VERBOSE

# Fonctions utilitaires
apt_install() {
    local pkg="$1"
    local count="$2"
    eval "apt-get install -y $pkg $VERBOSE"
    if [ $? -eq 0 ]; then
        echo "   ($count) ✅ $pkg"
    else
        echo "   ($count) ❌ $pkg"
    fi
}

get_users() {
    awk -F: '{if ($3 >= 1000 || $3 >= 500 && $1 != "nobody") print $1}' /etc/passwd
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
    echo "" >> /root/.zshrc
    echo "# $2" >> /root/.zshrc
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
    apt-get install -y neofetch figlet lolcat -y $VERBOSE
    
    mkdir -p /root/.config/neofetch /etc/neofetch
    curl -fsSL "https://raw.githubusercontent.com/PAPAMICA/terminal/main/neofetch.conf" -o /root/.config/neofetch/config.conf $VERBOSE
    cp /root/.config/neofetch/config.conf /etc/neofetch/config.conf $VERBOSE
    
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

# Fonction d'installation d'applications
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
    if eval "$install_cmd $VERBOSE"; then
        if [ -n "$zshrc_content" ]; then
            append_to_zshrc "$zshrc_content" "$app"
            echo " ✅ .zshrc mis à jour pour $app"
        fi
        echo " ✅ $app installé avec succès !"
    else
        echo " ❌ Échec installation $app"
    fi
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

# Atuin (historique intelligent)
app_install "atuin" \
"curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh -s -- -y && atuin import auto" \
'eval "$(atuin init zsh)"'

# Bat (cat amélioré)
app_install "batcat" \
"apt-get install -y bat" \
"alias cat='batcat --style=header --paging=never'
alias bat='batcat --style=header --paging=never'"

# Btop (htop moderne)
app_install "btop" \
"apt-get install -y btop" \
"alias top=btop
alias htop=btop"

# Cheat.sh (cheatsheets)
app_install "cheat" \
"curl -s https://api.github.com/repos/cheat/cheat/releases/latest | \
grep 'browser_download_url.*cheat-linux-amd64.gz' | \
cut -d : -f 2,4 | tr -d '\"' | wget -qi - && \
gzip -d cheat-linux-amd64.gz && \
chmod +x cheat-linux-amd64 && \
install -m 755 cheat-linux-amd64 /usr/local/bin/cheat && \
rm cheat-linux-amd64* && \
mkdir -p /root/.config/cheat/cheatsheets/{community,personal} && \
git clone https://github.com/cheat/cheatsheets.git /root/.config/cheat/cheatsheets/community" \
'alias ?="cheat"
alias ??="cheat --directory ~/.config/cheat/cheatsheets/personal"'

# Direnv
app_install "direnv" \
"apt-get install -y direnv" \
'eval "$(direnv hook zsh)"'

# Duf (df amélioré)
app_install "duf" \
"apt-get install -y duf" \
""

# Eza (ls moderne - remplace exa)
app_install "eza" \
"apt-get install -y eza" \
'alias ls="eza -a --icons"
alias ll="eza -1a --icons"
alias la="eza -lagh --icons"
alias lt="eza -a --tree --icons --level=2"'

# Micro (éditeur moderne)
app_install "micro" \
"curl https://getmic.ro | bash && mv micro /usr/local/bin/" \
""

# Ripgrep (grep ultra-rapide)
app_install "rg" \
"apt-get install -y ripgrep" \
"alias grep=rg"

# Z (navigateur de dossiers intelligent)
app_install "z" \
"apt-get install -y zoxide && zoxide init zsh --cmd z > /tmp/z_init.sh && cat /tmp/z_init.sh >> /root/.zshrc" \
""

# Plugins Zsh
app_install "zsh-autosuggestions" \
"git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
'source /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'

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
echo "   • Vérifiez ~/.zshrc pour les personnalisations"[web:1][web:2][web:7][web:9][web:10][web:21][web:27][web:31]
