![Preview](images/result.png)

## Ein mächtiges, einheitliches Bash-Setup für Debian 12 und Debian 13 VMs (und Bare-Metal Systeme), das deine Shell extrem angenehm und produktiv macht.

![Starship Prompt](https://img.shields.io/badge/Prompt-Starship-blue)
![Debian](https://img.shields.io/badge/Debian-12%20%7C%2013-red)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Was macht dieses Skript?

Dieses `bashrc.sh` ist weit mehr als nur eine normale `.bashrc`. Es ist ein **komplettes Bootstrap- & Konfigurationssystem**, das:

### Einmaliges Setup (beim ersten Start)

- Aktualisiert das komplette System
- Installiert eine umfangreiche Sammlung moderner Tools:
  - **eza** (modernes `ls` mit Icons)
  - **Starship** (wunderschöner, schneller Prompt)
  - **Fastfetch** (neofetch-Nachfolger)
  - **Nerd Font** (JetBrainsMono)
  - **fzf, ripgrep, bat, zoxide, btop, neovim, fd-find** uvm.
- Erstellt optimierte Konfigurationen für Starship und Fastfetch
- Richtet deutsche Locale ein

### Permanente Verbesserungen

- Sehr schöner, informativer **zweizeiliger Starship-Prompt**
- Über 80 praktische **Aliase** (Git, System, Navigation, Netzwerk…)
- Nützliche **Funktionen** (`mkcd`, `extract`, `f`, `show_system_info` etc.)
- Smarte History-Einstellungen
- `fzf` Integration mit Catppuccin-Design
- `zoxide` (intelligentes `cd`)
- Automatische Anzeige von System-Info beim Öffnen eines neuen Terminals


## Installation

### 1. Skript herunterladen und installieren
```bash
curl -fsSL https://raw.githubusercontent.com/sudoAndro/linux-starter-kit/refs/heads/main/bashrc.sh -o "$HOME/bashrc.sh" && chmod +x "$HOME/bashrc.sh" && (grep -qxF 'source "$HOME/bashrc.sh"' "$HOME/.bashrc" || echo 'source "$HOME/bashrc.sh"' >> "$HOME/.bashrc") && source "$HOME/bashrc.sh"
```

## Installation standart weg

# Empfohlener Speicherort
```bash
git clone https://github.com/sudoAndro/linux-starter-kit.git
chmod +x ~/bashrc.sh
```
2. In deine .bashrc einbinden
Füge am Ende deiner ~/.bashrc folgende Zeile hinzu:
Bash# === Meine erweiterte Bash-Konfiguration ===
[ -f "$HOME/bashrc.sh" ] && source "$HOME/bashrc.sh"

3. Einloggen / Terminal neu starten
Beim nächsten Öffnen eines Terminals wird das Setup automatisch einmalig ausgeführt (kann einige Minuten dauern).


## Setup zurücksetzen

Falls du das komplette Setup neu ausführen möchtest:
```bash
Bashvm-setup-reset
```
Danach Terminal schließen und neu öffnen.


## Verfügbare Aliase & Befehle (Auszug)

Navigation
.., ..., ...., home, -
Dateien & Anzeige
ls, l, ll, la, lt, lta, lg (mit Git-Status), cat → bat
System
update, install, remove, search, fixbroken, top (btop/htop), disk (ncdu)
Netzwerk
myip, myip6, ports, wetter, wetterv
Git
gs, ga, gaa, gc, gcm, gp, gpl, gl, gd usw.
Funktionen

mkcd <ordner> → Ordner erstellen + wechseln
extract datei.tar.gz → automatisches Entpacken
f [suchbegriff] → fuzzy Suche mit Vorschau
show_system_info → schöne Systemübersicht
aliases → Übersicht aller Aliase


## Voraussetzungen

Debian 12 oder 13 (getestet)
sudo-Rechte
Internetverbindung (beim ersten Start)


📝 Lizenz
MIT License – frei verwendbar und anpassbar.

Made with ❤️ für alle, die sich in der Shell wohlfühlen wollen.

### Created by: sudoAndro