![Preview](images/result.png)



## Debian VM Bootstrap & Bash-Konfiguration

Dieses Skript automatisiert die Ersteinrichtung einer Debian-VM (getestet auf Debian 12 & 13) und verwandelt eine Standard-Shell in eine moderne, produktive Entwicklungsumgebung.

Was macht dieses Skript?

## Das Skript führt bei der ersten Ausführung eine vollständige Systemoptimierung durch:

1. System-Update & Basis-Pakete

    Aktualisiert das gesamte System (apt full-upgrade).

    Installiert essenzielle Werkzeuge: git, curl, wget, htop, tmux, neovim, jq, unzip, net-tools u.v.m.


2. Moderne CLI-Tools (Modern Unix)

Es installiert und konfiguriert moderne Alternativen zu Standard-Befehlen

    eza: Ein verbesserter Ersatz für ls mit Icons und Git-Status.

    bat: Ein cat-Klon mit Syntax-Highlighting.

    fzf: Ein interaktiver Fuzzy-Finder für die Kommandozeile.

    zoxide: Ein intelligenter cd-Ersatz, der lernt, in welche Verzeichnisse du oft springst.

    fastfetch: Zeigt Systeminformationen beim Login schick an.


3. Optik & Komfort

    Starship Prompt: Ein extrem schneller, anpassbarer Shell-Prompt (zweizeilig).

    Nerd Fonts: Installiert automatisch die "JetBrainsMono" Nerd Font für korrekte Icon-Darstellung.

    FZF-Integration: Inklusive Farbschema (Catppuccin Mocha) und Tastenkürzeln.


4. Nützliche Aliase & Funktionen

    Viele Shortcuts für Git (gs, gp, gc), Navigation (.., ...) und Systemverwaltung (update).

    extract: Eine Funktion, die fast jedes Archivformat automatisch erkennt und entpackt.

    mkcd: Verzeichnis erstellen und sofort hineinwechseln.

    show_system_info: Eine grafische Übersicht über IP, Auslastung und Temperatur.


## Installation

Folge diesen Schritten, um das Skript in deiner VM zu aktivieren

    Skript herunterladen
    Lade die Datei bashrc.sh in dein Home-Verzeichnis (/home/dein-nutzer/).

    Skript ausführbar machen
    Bash

    chmod +x ~/bashrc.sh

    In die .bashrc einbinden
    Öffne deine originale .bashrc Datei
    Bash

    nano ~/.bashrc

    Füge ganz am Ende der Datei folgende Zeile hinzu
    Bash

    [ -f "$HOME/bashrc.sh" ] && source "$HOME/bashrc.sh"

    Shell neu starten
    Schließe das Terminal und öffne es neu, oder tippe
    Bash

    source ~/.bashrc

Beim ersten Start wird das Skript automatisch das komplette Setup (Installation der Pakete) durchführen. Danach steht dir die neue Konfiguration sofort zur Verfügung.
Reset

## Falls du das Setup erneut erzwingen möchtest (z.B. nach einem Fehler), nutze den Befehl:
Bash

vm-setup-reset