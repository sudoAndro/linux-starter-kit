#!/usr/bin/env bash



# ======================================================
#  ↓↓ Wichtig! In .bashrc Datei ganz unten einfügen ↓↓
# ======================================================
# [ -f "$HOME/bashrc.sh" ] && source "$HOME/bashrc.sh"


# Nur für interaktive Shells
case $- in
    *i*) ;;
    *) return ;;
esac

# =========================================
# EINSTELLUNGEN
# =========================================
SETUP_FLAG="$HOME/.bashrc_setup_done"
FASTFETCH_CONFIG="$HOME/.config/fastfetch/config.jsonc"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
FASTFETCH_LOGO="auto"
STARSHIP_PRESET="pastel-powerline"

# =========================================
# ERSTEINRICHTUNG - NUR EINMAL
# =========================================
if [ ! -f "$SETUP_FLAG" ]; then
    echo "Ersteinrichtung wird ausgeführt..."

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/fastfetch"

    # Fastfetch installieren
    if ! command -v fastfetch >/dev/null 2>&1; then
        sudo apt update
        sudo NEEDRESTART_MODE=a apt install -y fastfetch
    fi

    # Starship installieren
    if ! command -v starship >/dev/null 2>&1; then
        sudo NEEDRESTART_MODE=a apt install -y starship
    fi

    # Fastfetch Config erstellen
    if [ ! -f "$FASTFETCH_CONFIG" ]; then
        fastfetch --gen-config
    fi

    # Raspberry Pi Logo setzen
    if [ -f "$FASTFETCH_CONFIG" ]; then
        if grep -q '"logo"' "$FASTFETCH_CONFIG"; then
            sed -i '/"logo": {/,/},/c\
  "logo": {\
    "source": "'"$FASTFETCH_LOGO"'"\
  },' "$FASTFETCH_CONFIG"
        elif ! grep -q "\"source\": \"$FASTFETCH_LOGO\"" "$FASTFETCH_CONFIG"; then
            sed -i '3i\
  "logo": {\
    "source": "'"$FASTFETCH_LOGO"'"\
  },\
' "$FASTFETCH_CONFIG"
        fi
    fi

    # Starship Config erstellen
    if [ ! -f "$STARSHIP_CONFIG" ]; then
        starship preset "$STARSHIP_PRESET" -o "$STARSHIP_CONFIG"
    fi

    touch "$SETUP_FLAG"
    echo "Ersteinrichtung abgeschlossen."
fi

# =========================================
# ALIASE
# =========================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias home='cd ~'
alias c='clear'
alias cls='clear'
alias q='exit'

alias l='ls -CF'
alias la='ls -A'
alias ll='ls -lah'
alias lt='ls -lahtr'
alias tree='tree -C'

alias ports='ss -tulpen'
alias openports='sudo lsof -i -P -n'
alias mounts='mount | column -t'
alias memoryinfo='grep -E "MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree" /proc/meminfo'
alias usage='du -sh ./* 2>/dev/null | sort -h'
alias öffentlicheip='curl -s ifconfig.me && echo'
alias localeip='hostnam -I'

alias wetter='curl wttr.in'
alias sprache='sudo apt install language-pack-de'
alias update='sudo apt update && sudo apt full-upgrade -y'
alias speedtest="speedtest-now"

alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias fixbroken='sudo apt --fix-broken install'
alias autoremove='sudo apt autoremove'

# =========================================
# SPEEDTEST ALS FUNKTION
# =========================================
speedtest-now() {
    if command -v speedtest >/dev/null 2>&1; then
        speedtest
    elif command -v speedtest-cli >/dev/null 2>&1; then
        speedtest-cli
    else
        echo "Speedtest ist nicht installiert."
        echo "Installiere z.B. mit:"
        echo "  sudo apt install speedtest-cli"
    fi
}

# =========================================
# FARBEN
# =========================================
C_RESET="\e[0m"
C_TITLE="\e[1;36m"
C_LABEL="\e[1;37m"
C_OK="\e[1;32m"
C_WARN="\e[1;33m"
C_ERR="\e[1;31m"
C_INFO="\e[1;34m"
C_DIM="\e[0;37m"

# =========================================
# SYSTEMINFOS
# =========================================
HOSTNAME_INFO="$(hostname)"

IP_INFO="$(hostname -I 2>/dev/null | awk '{print $1}')"
[ -z "$IP_INFO" ] && IP_INFO="nicht verfügbar"

UPTIME_INFO="$(uptime -p 2>/dev/null | sed 's/^up //')"
[ -z "$UPTIME_INFO" ] && UPTIME_INFO="nicht verfügbar"

LOAD_INFO="$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}')"
[ -z "$LOAD_INFO" ] && LOAD_INFO="nicht verfügbar"

RAM_INFO="$(free -h 2>/dev/null | awk 'NR==2 {print $3 " / " $2}')"
[ -z "$RAM_INFO" ] && RAM_INFO="nicht verfügbar"

DISK_INFO="$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " benutzt)"}')"
[ -z "$DISK_INFO" ] && DISK_INFO="nicht verfügbar"

# =========================================
# TEMPERATUR
# =========================================
if command -v vcgencmd >/dev/null 2>&1; then
    TEMP_RAW="$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 | tr -d "'")"
else
    TEMP_RAW="$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)"
fi

[ -z "$TEMP_RAW" ] && TEMP_RAW="nicht verfügbar"

if [[ "$TEMP_RAW" =~ ^([0-9]+(\.[0-9]+)?) ]]; then
    TEMP_NUM="${BASH_REMATCH[1]}"
    if awk "BEGIN {exit !($TEMP_NUM < 50)}"; then
        TEMP_INFO="${C_OK}${TEMP_RAW}${C_RESET}"
    elif awk "BEGIN {exit !($TEMP_NUM < 65)}"; then
        TEMP_INFO="${C_WARN}${TEMP_RAW}${C_RESET}"
    else
        TEMP_INFO="${C_ERR}${TEMP_RAW}${C_RESET}"
    fi
else
    TEMP_INFO="$TEMP_RAW"
fi

# =========================================
# SYSTEM INFO ANZEIGE
# =========================================
show_system_info() {
    local HOSTNAME_INFO IP_INFO WAN_IP UPTIME_INFO LOAD_INFO RAM_INFO DISK_INFO
    local GATEWAY_INFO DOCKER_INFO FAIL2BAN_INFO LAST_LOGINS
    local TEMP_RAW TEMP_INFO TEMP_NUM

    echo
    echo -e "${C_TITLE}System-Infos${C_RESET}"
    echo "------------------------------"

    HOSTNAME_INFO="$(hostname 2>/dev/null)"
    [ -z "$HOSTNAME_INFO" ] && HOSTNAME_INFO="nicht verfügbar"

    IP_INFO="$(hostname -I 2>/dev/null | awk '{print $1}')"
    [ -z "$IP_INFO" ] && IP_INFO="nicht verfügbar"

    WAN_IP="$(curl -4 -s --max-time 2 ifconfig.me 2>/dev/null)"
    [ -z "$WAN_IP" ] && WAN_IP="nicht verfügbar"

    UPTIME_INFO="$(uptime -p 2>/dev/null | sed 's/^up //')"
    [ -z "$UPTIME_INFO" ] && UPTIME_INFO="nicht verfügbar"

    LOAD_INFO="$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}')"
    [ -z "$LOAD_INFO" ] && LOAD_INFO="nicht verfügbar"

    RAM_INFO="$(free -h 2>/dev/null | awk 'NR==2 {print $3 " / " $2}')"
    [ -z "$RAM_INFO" ] && RAM_INFO="nicht verfügbar"

    DISK_INFO="$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " benutzt)"}')"
    [ -z "$DISK_INFO" ] && DISK_INFO="nicht verfügbar"

    GATEWAY_INFO="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"
    [ -z "$GATEWAY_INFO" ] && GATEWAY_INFO="nicht verfügbar"

    # Temperatur
    if command -v vcgencmd >/dev/null 2>&1; then
        TEMP_RAW="$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 | tr -d "'")"
    elif [ -r /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP_RAW="$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)"
    else
        TEMP_RAW="nicht verfügbar"
    fi

    if [[ "$TEMP_RAW" =~ ^([0-9]+(\.[0-9]+)?) ]]; then
        TEMP_NUM="${BASH_REMATCH[1]}"
        if awk "BEGIN {exit !($TEMP_NUM < 50)}"; then
            TEMP_INFO="${C_OK}${TEMP_RAW}${C_RESET}"
        elif awk "BEGIN {exit !($TEMP_NUM < 65)}"; then
            TEMP_INFO="${C_WARN}${TEMP_RAW}${C_RESET}"
        else
            TEMP_INFO="${C_ERR}${TEMP_RAW}${C_RESET}"
        fi
    else
        TEMP_INFO="$TEMP_RAW"
    fi

    # Docker
    if command -v docker >/dev/null 2>&1; then
        if systemctl is-active --quiet docker 2>/dev/null; then
            local DOCKER_COUNT
            DOCKER_COUNT="$(docker ps -q 2>/dev/null | wc -l)"
            DOCKER_INFO="aktiv (${DOCKER_COUNT} Container laufen)"
        else
            DOCKER_INFO="installiert, aber Dienst nicht aktiv"
        fi
    else
        DOCKER_INFO="Docker nicht installiert"
    fi

    # Fail2Ban
    if command -v fail2ban-client >/dev/null 2>&1; then
        if systemctl is-active --quiet fail2ban 2>/dev/null; then
            FAIL2BAN_INFO="aktiv"
        else
            FAIL2BAN_INFO="installiert, aber Dienst nicht aktiv"
        fi
    else
        FAIL2BAN_INFO="Fail2Ban nicht installiert"
    fi

    printf "%-14s %s\n" "Hostname:" "$HOSTNAME_INFO"
    printf "%-14s %s\n" "Lokale IP:" "$IP_INFO"
    printf "%-14s %s\n" "WAN-IP:" "$WAN_IP"
    printf "%-14s %s\n" "Gateway:" "$GATEWAY_INFO"
    printf "%-14s %s\n" "Uptime:" "$UPTIME_INFO"
    printf "%-14s %s\n" "Load:" "$LOAD_INFO"
    printf "%-14s %s\n" "RAM:" "$RAM_INFO"
    printf "%-14s %s\n" "Root FS:" "$DISK_INFO"
    printf "%-14s %b\n" "CPU Temp:" "$TEMP_INFO"
    printf "%-14s %s\n" "Docker:" "$DOCKER_INFO"
    printf "%-14s %s\n" "Fail2Ban:" "$FAIL2BAN_INFO"

    echo
    echo -e "${C_TITLE}Letzte 5 Logins${C_RESET}"
    echo "------------------------------"
    last -n 5 2>/dev/null
    echo
}
# =========================================
# STARSHIP LADEN
# =========================================
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# =========================================
# ANZEIGE BEIM LOGIN
# =========================================
clear

if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

show_system_info
