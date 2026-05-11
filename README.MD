![Preview](images/result.png)



## Debian VM Bootstrap & Bash-Konfiguration

Dieses Skript automatisiert die Ersteinrichtung einer Debian-VM und verwandelt eine Standard-Shell in eine moderne Entwicklungsumgebung.
Was macht dieses Skript?

Das Skript führt bei der ersten Ausführung folgende Schritte aus:

    System-Update: Aktualisiert das gesamte System mit apt full-upgrade.

    Basis-Pakete: Installiert Tools wie git, curl, htop, tmux, neovim und net-tools.

    Modern Unix Tools: Installiert eza (ls-Ersatz), bat (cat-Klon), fzf (Fuzzy-Finder) und zoxide.

    Optik: Konfiguriert den Starship Prompt und installiert die JetBrainsMono Nerd Font.

    System-Info: Fügt die Funktion show_system_info hinzu, die beim Login Statuswerte anzeigt.

## Installation

Folge diesen Schritten, um das Skript in deiner VM zu aktivieren:

    Skript herunterladen Lade die Datei bashrc.sh in dein Home-Verzeichnis (/home/dein-nutzer/).

    Skript ausführbar machen Gib diesen Befehl im Terminal ein:

Bash

chmod +x ~/bashrc.sh

    In die .bashrc einbinden Öffne deine originale Konfigurationsdatei:

Bash

nano ~/.bashrc

    Zeile hinzufügen Scroll ganz nach unten und füge diese Zeile ein:

Bash

[ -f "$HOME/bashrc.sh" ] && source "$HOME/bashrc.sh"

    Neu starten Lade die Konfiguration neu oder starte das Terminal neu:

Bash

source ~/.bashrc

## Reset

Falls du das Setup erneut erzwingen möchtest, nutze diesen Befehl:
Bash

vm-setup-reset