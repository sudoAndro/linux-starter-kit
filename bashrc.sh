#!/usr/bin/env bash
# =============================================================================
#  bashrc.sh — Debian 12/13 VM Bootstrap & Shell-Konfiguration
#  Repo: https://github.com/<dein-user>/bashrc
#
#  Installation (einmalig, ganz unten in ~/.bashrc einfügen):
#    [ -f "$HOME/bashrc.sh" ] && source "$HOME/bashrc.sh"
#
#  Oder mit absolutem Pfad (empfohlen):
#    [ -f "/pfad/zu/bashrc.sh" ] && source "/pfad/zu/bashrc.sh"
#
#  Setup zurücksetzen:
#    vm-setup-reset
# =============================================================================

# Nur für interaktive Shells
case $- in
    *i*) ;;
    *) return ;;
esac

# =============================================================================
#  EINSTELLUNGEN — hier kannst du alles anpassen
# =============================================================================
SETUP_FLAG="$HOME/.config/vm-bootstrap/setup_done"
SETUP_LOG="$HOME/.config/vm-bootstrap/setup.log"
NERD_FONT="JetBrainsMono"
FONT_DIR="$HOME/.local/share/fonts"

# =============================================================================
#  FARBEN
# =============================================================================
C_RESET="\e[0m"
C_BOLD="\e[1m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_CYAN="\e[1;36m"
C_WHITE="\e[1;37m"
C_DIM="\e[0;37m"

# =============================================================================
#  HILFSFUNKTIONEN FÜR DEN SETUP
# =============================================================================
_log()  { echo -e "${C_GREEN}[✔]${C_RESET} $*" | tee -a "$SETUP_LOG"; }
_info() { echo -e "${C_BLUE}[→]${C_RESET} $*" | tee -a "$SETUP_LOG"; }
_warn() { echo -e "${C_YELLOW}[!]${C_RESET} $*" | tee -a "$SETUP_LOG"; }
_err()  { echo -e "${C_RED}[✘]${C_RESET} $*" | tee -a "$SETUP_LOG"; }

_has() { command -v "$1" >/dev/null 2>&1; }

# Sudo nur wenn nötig
if [[ $EUID -eq 0 ]]; then
    _sudo() { "$@"; }
else
    _sudo() { sudo "$@"; }
fi

# =============================================================================
#  ERSTEINRICHTUNG — läuft nur einmal
# =============================================================================
_run_setup() {
    mkdir -p "$(dirname "$SETUP_FLAG")" "$(dirname "$SETUP_LOG")"
    echo "=== Setup gestartet: $(date) ===" >> "$SETUP_LOG"

    echo -e "\n${C_CYAN}${C_BOLD}╔══════════════════════════════════════════╗"
    echo -e "║       VM Bootstrap wird gestartet...     ║"
    echo -e "╚══════════════════════════════════════════╝${C_RESET}\n"

    # --- Debian-Version erkennen ---
    DEBIAN_VER=$(grep -oP '(?<=VERSION_ID=")[0-9]+' /etc/os-release 2>/dev/null || echo "12")
    _info "Debian-Version erkannt: $DEBIAN_VER"

    # --- System updaten ---
    _info "System wird aktualisiert..."
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    _sudo apt-get update -qq
    _sudo apt-get full-upgrade -y -qq
    _log "System aktualisiert."

    # --- Basis-Pakete ---
    _info "Installiere Basis-Pakete..."
    _sudo apt-get install -y -qq \
        curl wget git build-essential \
        bash-completion \
        unzip zip p7zip-full \
        htop btop \
        tmux \
        neovim \
        jq \
        fzf \
        ripgrep \
        fd-find \
        bat \
        zoxide \
        fontconfig \
        ca-certificates \
        lsb-release \
        apt-transport-https \
        gnupg \
        net-tools \
        dnsutils \
        tree \
        ncdu \
        iotop \
        rsync \
        screen
    _log "Basis-Pakete installiert."

    # --- eza installieren ---
    if ! _has eza; then
        _info "Installiere eza (modernes ls)..."
        if [[ "$DEBIAN_VER" -ge 13 ]]; then
            _sudo apt-get install -y -qq eza 2>/dev/null || _install_eza_manual
        else
            _install_eza_manual
        fi
    fi

    # --- Fastfetch installieren ---
    if ! _has fastfetch; then
        _info "Installiere Fastfetch..."
        _install_fastfetch
    fi

    # --- Starship installieren ---
    if ! _has starship; then
        _info "Installiere Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes >> "$SETUP_LOG" 2>&1 \
            && _log "Starship installiert." \
            || _err "Starship Installation fehlgeschlagen."
    fi

    # --- Nerd Font installieren ---
    if ! fc-list 2>/dev/null | grep -qi "$NERD_FONT"; then
        _info "Installiere ${NERD_FONT} Nerd Font..."
        _install_nerd_font
    fi

    # --- Konfigurationen erstellen ---
    _setup_starship_config
    _setup_fastfetch_config

    # --- Setup abgeschlossen ---
    touch "$SETUP_FLAG"
    echo "=== Setup abgeschlossen: $(date) ===" >> "$SETUP_LOG"

    echo -e "\n${C_GREEN}${C_BOLD}╔══════════════════════════════════════════╗"
    echo -e "║      Setup erfolgreich abgeschlossen!    ║"
    echo -e "║   Starte ein neues Terminal zum Testen   ║"
    echo -e "╚══════════════════════════════════════════╝${C_RESET}\n"
}

# eza manuell über GitHub installieren (für Debian 12)
_install_eza_manual() {
    local ARCH EZA_VER
    ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
    EZA_VER=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$EZA_VER" ]]; then
        _warn "eza Version konnte nicht ermittelt werden, überspringe."
        return
    fi
    wget -q "https://github.com/eza-community/eza/releases/download/${EZA_VER}/eza_${ARCH}-unknown-linux-gnu.tar.gz" \
        -O /tmp/eza.tar.gz
    tar -xzf /tmp/eza.tar.gz -C /tmp/
    _sudo install -m 755 /tmp/eza /usr/local/bin/eza
    rm -f /tmp/eza.tar.gz /tmp/eza
    _log "eza installiert."
}

# Fastfetch über GitHub installieren
_install_fastfetch() {
    local ARCH FF_VER
    ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
    FF_VER=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$FF_VER" ]]; then
        _warn "Fastfetch Version konnte nicht ermittelt werden, überspringe."
        return
    fi
    wget -q "https://github.com/fastfetch-cli/fastfetch/releases/download/${FF_VER}/fastfetch-linux-${ARCH}.deb" \
        -O /tmp/fastfetch.deb
    _sudo dpkg -i /tmp/fastfetch.deb >> "$SETUP_LOG" 2>&1
    rm -f /tmp/fastfetch.deb
    _log "Fastfetch installiert."
}

# Nerd Font installieren
_install_nerd_font() {
    local FONT_VER
    FONT_VER=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$FONT_VER" ]]; then
        _warn "Nerd Font Version konnte nicht ermittelt werden, überspringe."
        return
    fi
    mkdir -p "$FONT_DIR/${NERD_FONT}"
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VER}/${NERD_FONT}.zip" \
        -O /tmp/nerdfont.zip
    unzip -q -o /tmp/nerdfont.zip -d "$FONT_DIR/${NERD_FONT}"
    rm -f /tmp/nerdfont.zip
    fc-cache -f "$FONT_DIR" >> "$SETUP_LOG" 2>&1
    _log "${NERD_FONT} Nerd Font installiert."
}

# Starship-Konfiguration erstellen
_setup_starship_config() {
    mkdir -p "$HOME/.config"
    local CFG="$HOME/.config/starship.toml"
    [[ -f "$CFG" ]] && { _info "Starship Config existiert bereits, überspringe."; return; }
    _info "Erstelle Starship Config..."
    cat > "$CFG" << 'STARSHIP_EOF'
"$schema" = 'https://starship.rs/config-schema.json'

# Zweizeiliger Prompt mit Modulen oben, Eingabe unten
format = """
[╭─](bold green)\
$os\
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$rust\
$golang\
$java\
$docker_context\
$cmd_duration\
$line_break\
[╰─](bold green)\
$character"""

add_newline = true

[os]
disabled = false
style = "bold cyan"

[os.symbols]
Debian = " "
Ubuntu = " "
Raspbian = " "
Linux = " "
Windows = " "
Macos = " "

[username]
show_always = true
style_user = "bold yellow"
style_root = "bold red"
format = "[$user]($style)"

[hostname]
ssh_only = false
style = "bold blue"
format = "[@$hostname]($style) "

[directory]
style = "bold purple"
read_only = " 󰌾"
truncation_length = 4
truncate_to_repo = false
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
style = "bold green"
format = "on [$symbol$branch]($style) "

[git_status]
style = "bold red"
format = '([$all_status$ahead_behind]($style) )'
conflicted = "⚡"
ahead = "⇡${count}"
behind = "⇣${count}"
untracked = "?"
modified = "!"
staged = "+"
deleted = "✘"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold yellow)"

[cmd_duration]
min_time = 2_000
format = "took [$duration](bold yellow) "

[python]
symbol = " "
format = '[$symbol$pyenv_prefix($version)(\($virtualenv\))]($style) '

[nodejs]
symbol = " "

[rust]
symbol = " "

[golang]
symbol = " "

[java]
symbol = " "

[docker_context]
symbol = " "
format = "[$symbol$context]($style) "
style = "blue bold"
only_with_files = true

[memory_usage]
disabled = true
threshold = 75
symbol = "󰍛 "
format = "[$symbol$ram]($style) "
style = "bold dimmed green"

[time]
disabled = true
format = '🕙 [$time]($style) '
time_format = "%H:%M"
STARSHIP_EOF
    _log "Starship Config erstellt."
}

# Fastfetch-Konfiguration erstellen
_setup_fastfetch_config() {
    mkdir -p "$HOME/.config/fastfetch"
    local CFG="$HOME/.config/fastfetch/config.jsonc"
    [[ -f "$CFG" ]] && { _info "Fastfetch Config existiert bereits, überspringe."; return; }
    _has fastfetch || return
    _info "Erstelle Fastfetch Config..."
    cat > "$CFG" << 'FASTFETCH_EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "auto",
        "color": {
            "1": "red",
            "2": "white"
        }
    },
    "display": {
        "separator": " → ",
        "color": "cyan"
    },
    "modules": [
        "title",
        "separator",
        {
            "type": "os",
            "key": " OS",
            "keyColor": "blue"
        },
        {
            "type": "kernel",
            "key": " Kernel",
            "keyColor": "blue"
        },
        {
            "type": "uptime",
            "key": "󰔚 Uptime",
            "keyColor": "green"
        },
        {
            "type": "packages",
            "key": "󰏗 Pakete",
            "keyColor": "yellow"
        },
        {
            "type": "shell",
            "key": " Shell",
            "keyColor": "cyan"
        },
        {
            "type": "terminal",
            "key": " Terminal",
            "keyColor": "cyan"
        },
        {
            "type": "cpu",
            "key": " CPU",
            "keyColor": "red"
        },
        {
            "type": "memory",
            "key": "󰍛 RAM",
            "keyColor": "magenta"
        },
        {
            "type": "disk",
            "key": "󰋊 Disk",
            "keyColor": "yellow",
            "folders": "/"
        },
        {
            "type": "localip",
            "key": "󰲁 Lokale IP",
            "keyColor": "green",
            "showIpv6": false
        },
        "separator",
        "colors"
    ]
}
FASTFETCH_EOF
    _log "Fastfetch Config erstellt."
}

# =============================================================================
#  SETUP AUSLÖSEN — nur wenn noch nicht gelaufen
# =============================================================================
if [[ ! -f "$SETUP_FLAG" ]]; then
    _run_setup
fi

# =============================================================================
#  SHELL OPTIONEN & HISTORY
# =============================================================================
shopt -s histappend
shopt -s checkwinsize
shopt -s cdspell
shopt -s dirspell 2>/dev/null || true
shopt -s autocd 2>/dev/null || true
shopt -s globstar 2>/dev/null || true
shopt -s nocaseglob 2>/dev/null || true

HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT="%d.%m.%Y %H:%M:%S  "
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# =============================================================================
#  UMGEBUNGSVARIABLEN
# =============================================================================
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R --use-color"
export LESSHISTFILE="-"
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
export LANG="de_DE.UTF-8"
export LC_ALL="de_DE.UTF-8"

# =============================================================================
#  ALIASE — Navigation
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias home='cd ~'
alias ~='cd ~'
alias -- -='cd -'

# =============================================================================
#  ALIASE — ls / eza
# =============================================================================
if _has eza; then
    alias ls='eza --icons=auto --group-directories-first --color=auto'
    alias l='eza --icons=auto --group-directories-first'
    alias ll='eza -la --icons=auto --group-directories-first --git --header'
    alias la='eza -a --icons=auto --group-directories-first'
    alias lt='eza --tree --icons=auto --level=2 --group-directories-first'
    alias lta='eza --tree --icons=auto --level=3 -a --group-directories-first'
    alias lg='eza -la --icons=auto --git --git-ignore'
else
    alias ls='ls --color=auto'
    alias l='ls -CF'
    alias ll='ls -lah'
    alias la='ls -A'
    alias lt='tree -C'
fi

# =============================================================================
#  ALIASE — cat / bat
# =============================================================================
if _has bat; then
    alias cat='bat --style=auto --paging=never'
    alias bcat='bat'
    alias less='bat --paging=always'
elif _has batcat; then
    alias cat='batcat --style=auto --paging=never'
    alias bat='batcat'
    alias bcat='batcat'
    alias less='batcat --paging=always'
fi

# =============================================================================
#  ALIASE — fd (auf Debian "fdfind")
# =============================================================================
if _has fdfind && ! _has fd; then
    alias fd='fdfind'
fi

# =============================================================================
#  ALIASE — System
# =============================================================================
alias c='clear'
alias cls='clear'
alias q='exit'
alias :q='exit'
alias reload='exec bash'
alias edit-bash='${EDITOR:-nano} ~/.bashrc'
alias edit-setup='${EDITOR:-nano} ~/bashrc.sh'

alias update='sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get autoclean'
alias install='sudo apt-get install'
alias remove='sudo apt-get remove'
alias purge='sudo apt-get purge'
alias search='apt-cache search'
alias show='apt-cache show'
alias fixbroken='sudo apt-get --fix-broken install'
alias autoremove='sudo apt-get autoremove'

alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias ps='ps aux'
alias psg='ps aux | grep'

if _has btop; then
    alias top='btop'
elif _has htop; then
    alias top='htop'
fi

# =============================================================================
#  ALIASE — Netzwerk
# =============================================================================
alias ports='ss -tulnp'
alias openports='sudo lsof -i -P -n | grep LISTEN'
alias mounts='mount | column -t'
alias myip='curl -4 -s --max-time 3 ifconfig.me && echo'
alias myip6='curl -6 -s --max-time 3 ifconfig.me && echo'
alias localip='hostname -I | awk "{print \$1}"'
alias gateway='ip route | grep default | awk "{print \$3}"'
alias wetter='curl -s wttr.in/?lang=de'
alias wetterv='curl -s "wttr.in/?lang=de&format=v2"'

# =============================================================================
#  ALIASE — Git
# =============================================================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate --color'
alias gll='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias gst='git stash'
alias gstp='git stash pop'

# =============================================================================
#  ALIASE — Sicherheit
# =============================================================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias chmod='chmod -v'
alias chown='chown -v'

# =============================================================================
#  ALIASE — Nützliches
# =============================================================================
alias h='history'
alias hs='history | grep'
alias j='jobs -l'
alias ping='ping -c 5'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%H:%M:%S"'
alias nowdate='date +"%d.%m.%Y"'
alias week='date +%V'
alias publicip=myip
alias utf8='export LANG=de_DE.UTF-8 LC_ALL=de_DE.UTF-8'

# ncdu statt du für interaktive Disk-Analyse
_has ncdu && alias disk='ncdu --color dark'

# =============================================================================
#  FUNKTIONEN
# =============================================================================

# Ordner erstellen und direkt hineinwechseln
mkcd() { mkdir -p "$1" && cd "$1" || return 1; }

# Archiv entpacken (automatisch erkennen)
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)  tar xjf "$1"  ;;
            *.tar.gz)   tar xzf "$1"  ;;
            *.tar.xz)   tar xJf "$1"  ;;
            *.tar.zst)  tar --zstd -xf "$1" ;;
            *.tar)      tar xf  "$1"  ;;
            *.bz2)      bunzip2 "$1"  ;;
            *.gz)       gunzip "$1"   ;;
            *.zip)      unzip "$1"    ;;
            *.7z)       7z x "$1"     ;;
            *.rar)      unrar x "$1" 2>/dev/null || 7z x "$1" ;;
            *.xz)       xz -d "$1"   ;;
            *.zst)      zstd -d "$1" ;;
            *)          _err "Unbekanntes Format: $1" ;;
        esac
    else
        _err "Datei nicht gefunden: $1"
    fi
}

# Datei/Ordner suchen (fzf-gestützt falls vorhanden)
f() {
    if _has fzf && _has fdfind; then
        fdfind --hidden --follow --exclude .git "${1:-.}" | fzf --preview 'bat --style=auto --color=always {} 2>/dev/null || ls -la {}'
    elif _has fdfind; then
        fdfind "${1:-.}"
    else
        find . -name "*${1}*" 2>/dev/null
    fi
}

# Schneller grep mit Farbe
g() {
    if _has rg; then
        rg --color=always "$@"
    else
        grep --color=auto -r "$@"
    fi
}

# Speedtest
speedtest-now() {
    if _has speedtest; then
        speedtest
    elif _has speedtest-cli; then
        speedtest-cli
    else
        _warn "Speedtest nicht installiert. Installieren mit: sudo apt install speedtest-cli"
    fi
}
alias speedtest='speedtest-now'

# System-Info anzeigen
show_system_info() {
    local HOST IP WAN UPTIME LOAD RAM DISK GATEWAY TEMP_RAW TEMP_INFO TEMP_NUM
    local DOCKER_INFO FAIL2BAN_INFO

    HOST="$(hostname 2>/dev/null || echo 'n/a')"
    IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
    [[ -z "$IP" ]] && IP="n/a"
    WAN="$(curl -4 -s --max-time 3 ifconfig.me 2>/dev/null)"
    [[ -z "$WAN" ]] && WAN="n/a"
    UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //')"
    [[ -z "$UPTIME" ]] && UPTIME="n/a"
    LOAD="$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}')"
    [[ -z "$LOAD" ]] && LOAD="n/a"
    RAM="$(free -h 2>/dev/null | awk 'NR==2 {print $3 " / " $2}')"
    [[ -z "$RAM" ]] && RAM="n/a"
    DISK="$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " genutzt)"}')"
    [[ -z "$DISK" ]] && DISK="n/a"
    GATEWAY="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"
    [[ -z "$GATEWAY" ]] && GATEWAY="n/a"

    # CPU-Temperatur
    if _has vcgencmd; then
        TEMP_RAW="$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 | tr -d "'")"
    elif [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
        TEMP_RAW="$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)"
    else
        TEMP_RAW="n/a"
    fi
    if [[ "$TEMP_RAW" =~ ^([0-9]+(\.[0-9]+)?) ]]; then
        TEMP_NUM="${BASH_REMATCH[1]}"
        if awk "BEGIN {exit !($TEMP_NUM < 50)}"; then
            TEMP_INFO="${C_GREEN}${TEMP_RAW}${C_RESET}"
        elif awk "BEGIN {exit !($TEMP_NUM < 70)}"; then
            TEMP_INFO="${C_YELLOW}${TEMP_RAW}${C_RESET}"
        else
            TEMP_INFO="${C_RED}${TEMP_RAW}${C_RESET}"
        fi
    else
        TEMP_INFO="$TEMP_RAW"
    fi

    # Docker
    if _has docker; then
        if systemctl is-active --quiet docker 2>/dev/null; then
            local CNT; CNT="$(docker ps -q 2>/dev/null | wc -l)"
            DOCKER_INFO="${C_GREEN}aktiv${C_RESET} (${CNT} Container)"
        else
            DOCKER_INFO="${C_YELLOW}installiert, Dienst inaktiv${C_RESET}"
        fi
    else
        DOCKER_INFO="${C_DIM}nicht installiert${C_RESET}"
    fi

    # Fail2Ban
    if _has fail2ban-client; then
        if systemctl is-active --quiet fail2ban 2>/dev/null; then
            FAIL2BAN_INFO="${C_GREEN}aktiv${C_RESET}"
        else
            FAIL2BAN_INFO="${C_YELLOW}installiert, Dienst inaktiv${C_RESET}"
        fi
    else
        FAIL2BAN_INFO="${C_DIM}nicht installiert${C_RESET}"
    fi

    echo
    echo -e "${C_CYAN}${C_BOLD}┌─── System-Info ───────────────────────────────┐${C_RESET}"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "Hostname:"   "$HOST"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "Lokale IP:"  "$IP"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "WAN-IP:"     "$WAN"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "Gateway:"    "$GATEWAY"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "Uptime:"     "$UPTIME"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "Load:"       "$LOAD"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "RAM:"        "$RAM"
    printf "${C_CYAN}│${C_RESET} %-12s ${C_WHITE}%s${C_RESET}\n" "Disk /:"     "$DISK"
    printf "${C_CYAN}│${C_RESET} %-12s %b\n"                     "CPU Temp:"   "$TEMP_INFO"
    printf "${C_CYAN}│${C_RESET} %-12s %b\n"                     "Docker:"     "$DOCKER_INFO"
    printf "${C_CYAN}│${C_RESET} %-12s %b\n"                     "Fail2Ban:"   "$FAIL2BAN_INFO"
    echo -e "${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}│${C_BOLD} Letzte Logins:${C_RESET}"
    last -n 4 2>/dev/null | head -4 | while IFS= read -r line; do
        printf "${C_CYAN}│${C_RESET}  %s\n" "$line"
    done
    echo -e "${C_CYAN}└───────────────────────────────────────────────┘${C_RESET}\n"
}

# Setup zurücksetzen (erzwingt Neuinstallation beim nächsten Shell-Start)
vm-setup-reset() {
    rm -f "$SETUP_FLAG"
    echo -e "${C_YELLOW}[!]${C_RESET} Setup-Flag gelöscht. Starte ein neues Terminal, um das Setup erneut auszuführen."
}

# Alias-Übersicht
aliases() {
    echo -e "\n${C_CYAN}${C_BOLD}═══ Eigene Aliase & Funktionen ═══${C_RESET}"
    echo -e "${C_BOLD}Navigation:${C_RESET}  .., ..., ...., home, -"
    echo -e "${C_BOLD}Dateien:${C_RESET}     ls/l/ll/la/lt/lta/lg, cat (bat), fd"
    echo -e "${C_BOLD}System:${C_RESET}      update, install, remove, purge, search, fixbroken"
    echo -e "${C_BOLD}Netzwerk:${C_RESET}    myip, localip, ports, wetter, wetterv"
    echo -e "${C_BOLD}Git:${C_RESET}         gs, ga, gc, gp, gl, gd, gco, gb"
    echo -e "${C_BOLD}Tools:${C_RESET}       top (btop), disk (ncdu), speedtest"
    echo -e "${C_BOLD}Funktionen:${C_RESET}  mkcd, extract, f (suchen), show_system_info"
    echo -e "${C_BOLD}Setup:${C_RESET}       vm-setup-reset (Neuinstallation erzwingen)"
    echo
}

# =============================================================================
#  BASH-COMPLETION
# =============================================================================
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
    source /etc/bash_completion
fi

# =============================================================================
#  FZF — Tastenkürzel & Farben
# =============================================================================
if _has fzf; then
    # Key-Bindings laden
    for _fzf_kb in \
        /usr/share/doc/fzf/examples/key-bindings.bash \
        /usr/share/fzf/key-bindings.bash \
        ~/.fzf/shell/key-bindings.bash; do
        [[ -f "$_fzf_kb" ]] && source "$_fzf_kb" && break
    done
    unset _fzf_kb

    # Bash Completion laden
    for _fzf_comp in \
        /usr/share/doc/fzf/examples/completion.bash \
        /usr/share/fzf/completion.bash \
        ~/.fzf/shell/completion.bash; do
        [[ -f "$_fzf_comp" ]] && source "$_fzf_comp" && break
    done
    unset _fzf_comp

    # Catppuccin Mocha Farbschema
    export FZF_DEFAULT_OPTS="
        --height=50%
        --layout=reverse
        --border=rounded
        --info=inline
        --prompt='❯ '
        --pointer='▶'
        --marker='✓'
        --color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8
        --color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8
        --color=info:#89dceb,prompt:#cba6f7,pointer:#f5c2e7
        --color=marker:#a6e3a1,spinner:#f5c2e7,header:#fab387
        --color=border:#6c7086
        --bind='ctrl-d:half-page-down,ctrl-u:half-page-up'
        --bind='ctrl-y:execute-silent(echo {} | xclip -sel c 2>/dev/null || echo {} | xsel -ib 2>/dev/null)'
        --bind='?:toggle-preview'
    "

    if _has rg; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    elif _has fdfind; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    export FZF_CTRL_R_OPTS="--sort --exact --preview 'echo {}' --preview-window=down:3:hidden:wrap"
fi

# =============================================================================
#  ZOXIDE — intelligenter cd-Ersatz
# =============================================================================
if _has zoxide; then
    eval "$(zoxide init bash)"
    # Behalte 'cd' für normale Nutzung, 'z' für zoxide
    alias j='z'     # 'jump' shortcut
    alias ji='zi'   # interaktives Auswählen
fi

# =============================================================================
#  STARSHIP — Prompt
# =============================================================================
if _has starship; then
    eval "$(starship init bash)"
fi

# =============================================================================
#  ANZEIGE BEIM LOGIN
# =============================================================================
clear

if _has fastfetch; then
    fastfetch
fi

show_system_info
