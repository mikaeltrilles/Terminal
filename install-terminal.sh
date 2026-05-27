#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 install-terminal.sh — Terminal setup script (production-grade)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# ─── Pipe Detection ───────────────────────────────────────────────────────────
IS_PIPED=0
if [[ ! -t 0 ]]; then
    IS_PIPED=1
fi

# ─── Configuration ────────────────────────────────────────────────────────────
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    readonly SCRIPT_NAME="install-terminal.sh"
    readonly SCRIPT_DIR="$(pwd)"
fi
DRY_RUN=0
AUTO_YES=0
BACKUP=0
USER_ONLY=0

# ─── Logging ──────────────────────────────────────────────────────────────────
log_info()  { printf '%s\n' "[INFO] $*" >&2; }
log_warn()  { printf '%s\n' "[WARN] $*" >&2; }
log_error() { printf '%s\n' "[ERROR] $*" >&2; }

# ─── Error Handler ──────────────────────────────────────────────────────────────
err_handler() {
    local rc=$?
    local line=$1
    log_error "Unexpected error at line ${line} (exit code ${rc})"
    exit "${rc:-1}"
}
trap 'err_handler ${LINENO}' ERR

# ─── Cleanup ──────────────────────────────────────────────────────────────────
readonly SCRIPT_TMPDIR="$(mktemp -d -t "install-term.XXXXXX")"
cleanup() { rm -rf "${SCRIPT_TMPDIR}"; }
trap cleanup EXIT

# ─── User Detection ───────────────────────────────────────────────────────────
if [[ -n "${SUDO_USER:-}" ]]; then
    CURRENT_USER="${SUDO_USER}"
else
    CURRENT_USER="$(logname 2>/dev/null || whoami)"
fi
readonly CURRENT_USER

HOME_DIR=""
if command -v getent >/dev/null 2>&1; then
    HOME_DIR="$(getent passwd "${CURRENT_USER}" | cut -d: -f6)" || HOME_DIR=""
fi
if [[ -z "${HOME_DIR}" ]]; then
    if [[ "${CURRENT_USER}" == "root" ]]; then
        HOME_DIR="/root"
    else
        HOME_DIR="/home/${CURRENT_USER}"
    fi
fi
readonly HOME_DIR

# ─── CLI Parsing ──────────────────────────────────────────────────────────────
usage() {
    cat >&2 <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
  -y, --yes       Auto-confirm prompts (non-interactive)
  -n, --dry-run   Show what would be done without executing
  -b, --backup    Backup dotfiles before modification
  -u, --user-only Skip system packages (apt), install only user-space tools
  -h, --help      Show this help and exit

Examples:
  ${SCRIPT_NAME} --yes --backup
  ${SCRIPT_NAME} --dry-run
  ${SCRIPT_NAME} --user-only --yes
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)      AUTO_YES=1; shift ;;
        -n|--dry-run)  DRY_RUN=1;  shift ;;
        -b|--backup)   BACKUP=1;   shift ;;
        -u|--user-only)USER_ONLY=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# ─── Pipe safety: when piped via curl|bash, force --yes so read does not consume stdin ──
if [[ "${IS_PIPED}" -eq 1 && "${AUTO_YES}" -eq 0 ]]; then
    AUTO_YES=1
    log_info "Detected piped execution (curl | bash); forcing --yes to avoid interactive stdin reads"
fi

# ─── Display ────────────────────────────────────────────────────────────────────
section() {
    printf '\n📦 ═══════════════════════════════════════════════════════════════════════════════\n'
    printf '📦                           %s\n' "$1"
    printf '📦 ═══════════════════════════════════════════════════════════════════════════════\n'
}

# ─── Safe Backup ──────────────────────────────────────────────────────────────
backup_file() {
    local target="$1"
    if [[ "${BACKUP}" -eq 0 ]] || [[ ! -f "${target}" ]]; then
        return 0
    fi
    local backup_path
    backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would backup ${target} -> ${backup_path}"
        return 0
    fi
    cp -p "${target}" "${backup_path}"
    log_info "Backup created: ${backup_path}"
}

# ─── Dotfiles Snapshot (Git-based rollback) ───────────────────────────────────
snapshot_dotfiles() {
    local snapshot_dir="${HOME_DIR}/.dotfiles-backup"
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would snapshot dotfiles to ${snapshot_dir}"
        return 0
    fi
    if [[ ! -d "${snapshot_dir}/.git" ]]; then
        sudo -u "${CURRENT_USER}" git init "${snapshot_dir}" >/dev/null 2>&1 || true
    fi
    # Copy current dotfiles into snapshot repo before any changes
    local files=(.zshrc .bashrc .profile)
    for f in "${files[@]}"; do
        local src="${HOME_DIR}/${f}"
        if [[ -f "${src}" ]]; then
            cp -p "${src}" "${snapshot_dir}/${f}" 2>/dev/null || true
        fi
    done
    (
        cd "${snapshot_dir}" >/dev/null 2>&1 || return 0
        sudo -u "${CURRENT_USER}" git add -A >/dev/null 2>&1 || true
        sudo -u "${CURRENT_USER}" git commit -m "snapshot before install-terminal ($(date -Iseconds))" >/dev/null 2>&1 || true
    )
    log_info "Dotfiles snapshot saved to ${snapshot_dir}"
}

# ─── Download + Optional SHA-256 Verification ──────────────────────────────────
download_verify() {
    local url="$1"
    local dest="$2"
    local expected_sha256="${3:-}"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would download ${url} -> ${dest}"
        return 0
    fi

    if ! curl --proto '=https' --tlsv1.2 -fsSL "${url}" -o "${dest}"; then
        log_error "Download failed: ${url}"
        return 1
    fi

    local computed
    computed="$(sha256sum "${dest}" | awk '{print $1}')"
    log_info "Downloaded ${url} -> ${dest} (sha256: ${computed})"

    if [[ -n "${expected_sha256}" ]]; then
        if [[ "${computed}" != "${expected_sha256}" ]]; then
            log_error "SHA-256 mismatch for ${url}"
            log_error "  Expected: ${expected_sha256}"
            log_error "  Got:      ${computed}"
            return 1
        fi
        log_info "SHA-256 verified for ${url}"
    else
        log_warn "No expected SHA-256 provided for ${url}; verify ${computed} manually"
    fi
}

# ─── Idempotent RC Append ─────────────────────────────────────────────────────
# Appends a block only if its unique marker is not already present.
append_unique_to_rc() {
    local file="$1"
    local marker="$2"
    local payload="$3"
    local base
    base="$(basename "${file}")"
    if [[ "${base}" != .* ]]; then
        base=".${base}"
    fi
    local target
    target="${HOME_DIR}/${base}"

    if [[ ! -f "${target}" ]]; then
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_info "[dry-run] Would create ${target}"
            return 0
        fi
        touch "${target}"
    fi

    # Idempotency: skip if marker already present
    if [[ -f "${target}" ]] && grep -qF "# marker:${marker}" "${target}" 2>/dev/null; then
        log_info "Already present in ${target} (marker=${marker}), skipping"
        return 0
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would append to ${target}: ${marker}"
        return 0
    fi

    backup_file "${target}"
    {
        printf '# marker:%s (%s)\n' "${marker}" "$(date -Iseconds)"
        printf '%s\n' "${payload}"
    } >> "${target}"
    chown "${CURRENT_USER}:${CURRENT_USER}" "${target}" 2>/dev/null || true
    log_info "${target} updated (${marker})"
}

# ─── Package Helpers ──────────────────────────────────────────────────────────
apt_install() {
    local pkg="$1" count="$2" total="$3"
    if [[ "${USER_ONLY}" -eq 1 ]]; then
        log_info "[user-only] Skipping apt package ${pkg}"
        return 0
    fi
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would apt-get install ${pkg} (${count}/${total})"
        return 0
    fi
    if dpkg -s "${pkg}" >/dev/null 2>&1; then
        printf '   (%s/%s) ✅ %s (already installed)\n' "${count}" "${total}" "${pkg}"
        return 0
    fi
    if sudo apt-get install -y "${pkg}" >/dev/null 2>&1; then
        printf '   (%s/%s) ✅ %s\n' "${count}" "${total}" "${pkg}"
    else
        printf '   (%s/%s) ❌ %s\n' "${count}" "${total}" "${pkg}"
    fi
}

# ─── Version Extraction ───────────────────────────────────────────────────────
extract_version() {
    local s="$1"
    local cmd="${2:-}"

    case "${cmd}" in
        eza)
            if command -v eza >/dev/null 2>&1; then
                local eza_out
                eza_out="$(eza -v 2>&1 || eza --help 2>&1 | grep -i version | head -n1 || true)"
                if [[ "${eza_out}" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                    printf '%s\n' "${BASH_REMATCH[1]}"
                    return 0
                fi
            fi
            printf '%s\n' "dev"
            return 0
            ;;
    esac

    if [[ "${s}" =~ ([0-9]+\.[0-9]+\.[0-9]+)([-._][A-Za-z0-9]+)? ]]; then
        local ver="${BASH_REMATCH[1]}"
        if [[ -n "${BASH_REMATCH[2]:-}" ]]; then
            ver="${ver}${BASH_REMATCH[2]}"
        fi
        printf '%s\n' "${ver}"
        return 0
    fi

    if [[ "${s}" =~ ([0-9]+\.[0-9]+) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi

    if [[ "${s}" =~ ([0-9]+) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi

    printf '%s\n' "${s}"
}

# ─── Version Check ────────────────────────────────────────────────────────────
try_version() {
    local cmd="$1"
    local RESET="\033[0m"
    local BOLD="\033[1m"
    local GREEN="\033[32m"
    local RED="\033[31m"
    local CYAN="\033[36m"

    local path_found=""

    if command -v "${cmd}" >/dev/null 2>&1; then
        path_found="$(command -v "${cmd}")"
    elif [[ "${cmd}" == "bat" ]] && command -v batcat >/dev/null 2>&1; then
        path_found="$(command -v batcat)"
    fi

    if [[ -z "${path_found}" ]]; then
        local candidates=(
            "${HOME_DIR}/.local/bin/${cmd}"
            "${HOME_DIR}/.cargo/bin/${cmd}"
            "${HOME_DIR}/.atuin/bin/${cmd}"
            "${HOME_DIR}/.linuxbrew/bin/${cmd}"
            "/home/linuxbrew/.linuxbrew/bin/${cmd}"
            "/usr/local/bin/${cmd}"
            "/snap/bin/${cmd}"
        )
        for p in "${candidates[@]}"; do
            if [[ -x "${p}" ]]; then
                path_found="${p}"
                break
            fi
        done
    fi

    if [[ -z "${path_found}" ]] && command -v sudo >/dev/null 2>&1 && [[ -n "${CURRENT_USER:-}" ]] && [[ "${CURRENT_USER}" != "$(whoami)" ]]; then
        local user_path=""
        user_path="$(sudo -u "${CURRENT_USER}" command -v "${cmd}" 2>/dev/null || true)"
        if [[ -n "${user_path}" ]]; then
            path_found="${user_path}"
        fi
    fi

    if [[ -z "${path_found}" ]]; then
        printf '   ❌ %b%s%b : %bnon installé%b\n' "${BOLD}" "${cmd}" "${RESET}" "${RED}" "${RESET}"
        return 0
    fi

    local out=""
    if [[ "${path_found}" != "$(command -v "${cmd}" 2>/dev/null || true)" ]] && command -v sudo >/dev/null 2>&1 && [[ -n "${CURRENT_USER:-}" ]] && [[ "${CURRENT_USER}" != "$(whoami)" ]]; then
        out="$(sudo -u "${CURRENT_USER}" "${path_found}" --version 2>&1 || sudo -u "${CURRENT_USER}" "${path_found}" -v 2>&1 || sudo -u "${CURRENT_USER}" "${path_found}" version 2>&1 || sudo -u "${CURRENT_USER}" "${path_found}" -V 2>&1 || printf '%s\n' "version inconnue")"
    else
        out="$("${path_found}" --version 2>&1 || "${path_found}" -v 2>&1 || "${path_found}" version 2>&1 || "${path_found}" -V 2>&1 || printf '%s\n' "version inconnue")"
    fi
    out="$(printf '%s\n' "${out}" | head -n1)"

    local ver
    ver="$(extract_version "${out}" "${cmd}" || true)"

    local icon="🔹"
    local col_cmd="${CYAN}"
    case "${cmd}" in
        curl) icon="🌊"; col_cmd="\033[36m" ;;
        wget) icon="⬇️"; col_cmd="\033[35m" ;;
        git)  icon="🐙"; col_cmd="\033[34m" ;;
        zsh)  icon="💠"; col_cmd="\033[35m" ;;
        bat)  icon="📚"; col_cmd="\033[33m" ;;
        less) icon="📘"; col_cmd="\033[36m" ;;
        btop) icon="📈"; col_cmd="\033[33m" ;;
        eza)  icon="📁"; col_cmd="\033[36m" ;;
        rg|ripgrep) icon="🔎"; col_cmd="\033[36m" ;;
        zoxide) icon="🧭"; col_cmd="\033[36m" ;;
        duf)    icon="📊"; col_cmd="\033[36m" ;;
        direnv) icon="🛡️"; col_cmd="\033[36m" ;;
        atuin)  icon="🛰️"; col_cmd="\033[36m" ;;
        micro)  icon="✍️"; col_cmd="\033[32m" ;;
        brew)   icon="🍺"; col_cmd="\033[33m" ;;
        gcc)    icon="🔧"; col_cmd="\033[33m" ;;
        apt-get)icon="📦"; col_cmd="\033[33m" ;;
    esac

    if [[ -n "${ver:-}" ]] && [[ "${ver}" != "version inconnue" ]]; then
        printf '   %s %b%s%b : %b%s%b\n' "${icon}" "${BOLD}" "${col_cmd}" "${cmd}" "${RESET}" "${GREEN}" "${ver}" "${RESET}"
    else
        printf '   %s %b%s%b : %b%s%b\n' "${icon}" "${BOLD}" "${col_cmd}" "${cmd}" "${RESET}" "${GREEN}" "${out}" "${RESET}"
    fi
}

show_versions() {
    local RESET="\033[0m"
    local BLUE="\033[34m"
    printf '%b📦 ═══════════════════════════════════════════════════════════════════════════════%b\n' "${BLUE}" "${RESET}"
    printf '%b📦                           VERSIONS INSTALLÉES%b\n' "${BLUE}" "${RESET}"
    printf '%b📦 ═══════════════════════════════════════════════════════════════════════════════%b\n' "${BLUE}" "${RESET}"

    local cmds=(curl wget git zsh bat less btop eza rg zoxide duf direnv atuin micro cat brew python node docker gcc apt-get)
    for c in "${cmds[@]}"; do
        try_version "${c}"
    done

    if [[ -d "${HOME_DIR}/.oh-my-zsh" ]]; then
        local omz_ver="installé"
        if [[ -d "${HOME_DIR}/.oh-my-zsh/.git" ]]; then
            omz_ver="$(cd "${HOME_DIR}/.oh-my-zsh" 2>/dev/null && (git describe --tags --always 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || printf '%s' "installé")"
        fi
        printf '   📂 \033[1moh-my-zsh\033[0m : \033[32m%s\033[0m\n' "${omz_ver}"
    else
        printf '   📂 \033[1moh-my-zsh\033[0m : \033[31mnon installé\033[0m\n'
    fi
    printf '\n'
}

# ─── Pre-flight Checks ────────────────────────────────────────────────────────
if [[ "${USER_ONLY}" -eq 0 ]] && [[ "${DRY_RUN}" -eq 0 ]]; then
    if ! command -v apt-get >/dev/null 2>&1; then
        log_error "Compatible Debian/Ubuntu uniquement (or use --user-only)"
        exit 1
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        log_error "Installez sudo d'abord (or use --user-only)"
        exit 1
    fi
fi

# ─── Interactive or Auto Mode ─────────────────────────────────────────────────
CHOICE=""
if [[ "${AUTO_YES}" -eq 1 ]]; then
    CHOICE="4"
    log_info "Auto-yes enabled: selecting option 4 (complete install)"
else
    printf '👤 Utilisateur détecté : %s\n' "${CURRENT_USER}"
    printf '🏠 Home : %s\n\n' "${HOME_DIR}"

    printf '📋 Choisissez une option :\n'
    printf '   1) 🛠️  Installation de base (Zsh + outils essentiels)\n'
    printf '   2) 🐚 Installation Oh My Zsh\n'
    printf '   3) 🍺 Installation Homebrew (Linux non-root)\n'
    printf '   4) 🔥 Installation complète (1+2+3)\n'
    printf '   5) 🔍 Afficher les versions des éléments installés (contrôle)\n'
    printf '   6) ❌ Quitter sans exécuter le script\n\n'
    read -rp "Votre choix (1-6) [1] : " CHOICE
    CHOICE="${CHOICE:-1}"
fi

BASE=0
OMZ=0
BREW=0

case "${CHOICE}" in
    1) BASE=1 ;;
    2) OMZ=1 ;;
    3) BREW=1 ;;
    4) BASE=1; OMZ=1; BREW=1 ;;
    5)
        show_versions
        exit 0
        ;;
    6)
        log_info "Sortie demandée : le script ne sera pas exécuté."
        exit 0
        ;;
    *)
        log_error "Option invalide."
        exit 1
        ;;
esac

log_info "Début installation... (${CHOICE} sélectionné)"

# Snapshot dotfiles before any mutation
snapshot_dotfiles

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PRÉREQUIS
# ═══════════════════════════════════════════════════════════════════════════════
section "PRÉREQUIS"

PACKAGES=(curl wget git zsh build-essential procps file locales-all)
readonly TOTAL_PREREQS="${#PACKAGES[@]}"

if [[ "${DRY_RUN}" -eq 0 ]] && [[ "${USER_ONLY}" -eq 0 ]]; then
    sudo apt-get update -y >/dev/null 2>&1
fi

i=0
for pkg in "${PACKAGES[@]}"; do
    i=$((i + 1))
    apt_install "${pkg}" "${i}" "${TOTAL_PREREQS}"
done
log_info "Prérequis traités."

# ═══════════════════════════════════════════════════════════════════════════════
# 1. Installation de base
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "${BASE}" -eq 1 ]]; then
    section "INSTALLATION DE BASE"
    apt_install "less"  "1" "7"
    apt_install "btop"  "2" "7"
    apt_install "eza"   "3" "7"
    apt_install "ripgrep" "4" "7"
    apt_install "zoxide" "5" "7"
    apt_install "duf"   "6" "7"
    apt_install "direnv" "7" "7"

    # Atuin — téléchargement vers tmp, pas de curl|sh direct
    log_info "Atuin..."
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would download and install atuin"
    else
        atuin_script="${SCRIPT_TMPDIR}/atuin-install.sh"
        if download_verify "https://setup.atuin.sh" "${atuin_script}"; then
            bash "${atuin_script}"
        else
            log_warn "Failed to download atuin installer"
        fi
    fi
    append_unique_to_rc ".zshrc" "atuin" 'eval "$(atuin init zsh)"'

    # Micro
    log_info "Micro..."
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would install micro to /usr/local/bin"
    else
        if [[ "${USER_ONLY}" -eq 0 ]]; then
            sudo mkdir -p /usr/local/bin
            micro_script="${SCRIPT_TMPDIR}/micro-install.sh"
            if download_verify "https://getmic.ro" "${micro_script}"; then
                (cd /usr/local/bin && sudo bash "${micro_script}")
            else
                log_warn "Failed to download micro installer"
            fi
        else
            log_warn "[user-only] Micro requires system install; skipped. Install manually to ~/.local/bin if needed."
        fi
    fi
    log_info "Micro installé"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 2. Oh My Zsh
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "${OMZ}" -eq 1 ]]; then
    section "OH MY ZSH"
    log_info "Oh My Zsh (officiel)..."

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would install Oh My Zsh for ${CURRENT_USER}"
    else
        omz_script="${SCRIPT_TMPDIR}/omz-install.sh"
        # OMZ official installer URL (pinned to master, no static SHA-256 available)
        if download_verify "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "${omz_script}"; then
            sudo -u "${CURRENT_USER}" bash "${omz_script}" "" --unattended
        else
            log_error "Failed to download Oh My Zsh installer"
            exit 1
        fi
    fi

    if [[ "${DRY_RUN}" -eq 0 ]]; then
        sudo -u "${CURRENT_USER}" bash -c "mkdir -p '${HOME_DIR}/.oh-my-zsh/custom/plugins'"
        if [[ -f "${HOME_DIR}/.zshrc" ]]; then
            backup_file "${HOME_DIR}/.zshrc"
            sed -i 's/robbyrussell/jonathan/g' "${HOME_DIR}/.zshrc" 2>/dev/null || true
        fi
    fi

    # Plugins
    omz_custom="${HOME_DIR}/.oh-my-zsh/custom/plugins"
    if [[ "${DRY_RUN}" -eq 0 ]]; then
        if [[ ! -d "${omz_custom}/zsh-autosuggestions" ]]; then
            sudo -u "${CURRENT_USER}" git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${omz_custom}/zsh-autosuggestions"
        fi
        if [[ ! -d "${omz_custom}/zsh-syntax-highlighting" ]]; then
            sudo -u "${CURRENT_USER}" git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${omz_custom}/zsh-syntax-highlighting"
        fi
    fi

    payload=$'plugins=(git zsh-autosuggestions zsh-syntax-highlighting sudo)\nsource "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"\nexport ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"\nsource "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"\nif command -v bat >/dev/null 2>&1; then\n  alias cat="bat --style=header --paging=never"\nelif command -v batcat >/dev/null 2>&1; then\n  alias cat="batcat --style=header --paging=never"\nelif command -v less >/dev/null 2>&1; then\n  alias cat="less -R"\nfi\nalias grep=rg\neval "$(zoxide init zsh)"\neval "$(direnv hook zsh)"\nalias relbash="source ~/.zshrc"\nalias zshconfig="nano ~/.zshrc"\nalias cls="clear"'

    append_unique_to_rc ".zshrc" "oh-my-zsh aliases and plugins" "${payload}"

    maj_payload='maj() { echo "🍓  Mise à jour complète"; echo "──────────────────────────────────────────"; echo -e "\n📦  Mise à jour des dépôts APT..."; if command -v sudo >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then sudo apt-get update -y; echo -e "\n⚙️  Installation des mises à jour disponibles..."; sudo apt-get upgrade -y; echo -e "\n🚀  Mise à niveau de la distribution..."; sudo apt-get dist-upgrade -y; fi; if command -v brew >/dev/null 2>&1; then echo -e "\n☕️  Mise à jour Homebrew..."; brew update; echo -e "\n📦  Mise à niveau des paquets Homebrew..."; brew upgrade; echo -e "\n🧹  Nettoyage Homebrew..."; brew autoremove; fi; if command -v sudo >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then echo -e "\n🧹  Nettoyage des paquets obsolètes..."; sudo apt-get autoremove -y; sudo apt-get autoclean -y; sudo apt-get clean; fi; echo -e "\n🏁  Mise à jour terminée avec succès ! 🎉"; echo "──────────────────────────────────────────"; }'
    append_unique_to_rc ".zshrc" "maj update function" "${maj_payload}"

    chown "${CURRENT_USER}:${CURRENT_USER}" "${HOME_DIR}/.zshrc" 2>/dev/null || true
    log_info "Oh My Zsh + thème JONATHAN + plugins + aliases pour ${CURRENT_USER}"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 3. Homebrew
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "${BREW}" -eq 1 ]]; then
    section "HOMEBREW (Linux)"
    if command -v brew >/dev/null 2>&1; then
        log_info "Homebrew déjà installé"
    else
        log_info "Homebrew pour ${CURRENT_USER}..."
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_info "[dry-run] Would install Homebrew"
        else
            brew_script="${SCRIPT_TMPDIR}/brew-install.sh"
            if download_verify "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "${brew_script}"; then
                NONINTERACTIVE=1 sudo -u "${CURRENT_USER}" /bin/bash "${brew_script}"
            else
                log_error "Failed to download Homebrew installer"
                exit 1
            fi
        fi

        append_unique_to_rc ".zshrc" "homebrew shellenv" 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
        chown "${CURRENT_USER}:${CURRENT_USER}" "${HOME_DIR}/.zshrc" 2>/dev/null || true

        if [[ "${DRY_RUN}" -eq 0 ]]; then
            if [[ "${USER_ONLY}" -eq 0 ]]; then
                sudo apt-get install -y build-essential
            fi
            if command -v brew >/dev/null 2>&1; then
                brew install gcc
            fi
        fi
        log_info "Homebrew -> /home/linuxbrew/.linuxbrew/bin/brew"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 4. Default Shell
# ═══════════════════════════════════════════════════════════════════════════════
ZSH_BIN=""
ZSH_BIN="$(command -v zsh || true)"
if [[ -n "${ZSH_BIN}" ]]; then
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[dry-run] Would set ${ZSH_BIN} as default shell for ${CURRENT_USER}"
    else
        sudo chsh -s "${ZSH_BIN}" "${CURRENT_USER}" 2>/dev/null || true
    fi
else
    log_warn "zsh introuvable, chsh ignoré"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 5. Launch OMZ if installed
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "${OMZ}" -eq 1 ]] && [[ "${DRY_RUN}" -eq 0 ]]; then
    log_info "Lancement Oh My Zsh..."
    sudo -u "${CURRENT_USER}" zsh -l || true
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 🎉 TERMINÉ !
# ═══════════════════════════════════════════════════════════════════════════════
section "INSTALLATION TERMINÉE !"
log_info "Configuration appliquée pour : ${CURRENT_USER}"
printf '\n📋 Vérifications :\n'
printf '   • Zsh : zsh --version\n'
printf '   • OMZ : ls ~/.oh-my-zsh\n'
printf '   • Brew: brew --version\n'
printf '   • Atuin: atuin register\n'
printf '   • Alias: relbash, zshconfig, maj\n\n'
if [[ "${OMZ}" -eq 1 ]]; then
    printf '🚀 Déjà lancé dans Oh My Zsh avec thème JONATHAN ! (Ctrl+D pour quitter)\n'
fi
printf '🔥 ═══════════════════════════════════════════════════════════════════════════════\n'
