#!/bin/bash

# === STATUSKONTROLL ===
echo "=== Kontroll av systemstatus ==="

# Kolla unclutter
if dpkg-query -W -f='${Status}' unclutter 2>/dev/null | grep -q "install ok installed"; then
    echo "✔ unclutter är installerat"
else
    echo "✘ unclutter är INTE installerat"
fi

# Kolla LightDM
LIGHTDM_OK=false
for file in /usr/share/lightdm/lightdm.conf.d/*.conf; do
    if grep -q "xserver-command=X -nocursor" "$file"; then
        LIGHTDM_OK=true
    fi
done
if $LIGHTDM_OK; then
    echo "✔ LightDM är konfigurerat med 'xserver-command=X -nocursor'"
else
    echo "✘ LightDM har INTE raden 'xserver-command=X -nocursor'"
fi

# Kolla indexfil
if [[ -f /var/www/html/index.lighttpd.html ]]; then
    echo "✘ index.lighttpd.html finns kvar"
else
    echo "✔ index.lighttpd.html är redan borttagen"
fi

# Kolla Wi-Fi
CONFIG="/boot/firmware/config.txt"
DISABLE_LINE="dtoverlay=disable-wifi"
if grep -q "^$DISABLE_LINE" "$CONFIG"; then
    echo "✔ Wi-Fi är AVSTÄNGT permanent"
else
    echo "✔ Wi-Fi är PÅSLAGET"
fi

echo ""
echo "=== Vad vill du göra? ==="
echo "1) Installera unclutter och uppdatera LightDM"
echo "2) Ta bort index.lighttpd.html"
echo "3) Hantera Wi-Fi (av/på permanent)"
echo "4) Gör alla"
echo "0) Avbryt"
read -p "Ange val (0-4): " choice

# === Hjälpfunktion för ja/nej ===
confirm() {
    read -p "$1 (j/n): " answer
    case "$answer" in
        [JjYy]* ) return 0 ;;
        * ) return 1 ;;
    esac
}

# === Del 1: unclutter + LightDM ===
install_unclutter_lightdm() {
    if confirm "Vill du installera unclutter och uppdatera LightDM?"; then
        if dpkg -s unclutter &> /dev/null; then
            echo "✔ unclutter är redan installerat."
        else
            echo "Installerar unclutter..."
            sudo apt-get update
            sudo apt-get install -y unclutter
        fi

        for file in /usr/share/lightdm/lightdm.conf.d/*.conf; do
            if grep -q "xserver-command=X -nocursor" "$file"; then
                echo "✔ Raden finns redan i $file"
            else
                echo "Lägger till raden i $file..."
                echo "xserver-command=X -nocursor" | sudo tee -a "$file" > /dev/null
            fi
        done
    else
        echo "Åtgärden avbruten."
    fi
}

# === Del 2: index.lighttpd.html ===
remove_index_file() {
    if [[ -f /var/www/html/index.lighttpd.html ]]; then
        if confirm "Vill du ta bort /var/www/html/index.lighttpd.html?"; then
            sudo rm -f /var/www/html/index.lighttpd.html
            echo "Filen borttagen."
        else
            echo "Åtgärden avbruten."
        fi
    else
        echo "✔ Filen finns redan inte."
    fi
}

# === Del 3: Wi-Fi toggle ===
wifi_toggle() {
    ask_reboot() {
        read -p "🔄 Vill du starta om nu? (J/N): " reboot
        if [[ "$reboot" =~ ^[Jj]$ ]]; then
            echo "Startar om..."
            sudo reboot
        else
            echo "🔔 Kom ihåg att starta om manuellt för att ändringen ska gälla."
        fi
    }

    if grep -q "^$DISABLE_LINE" "$CONFIG"; then
        echo "📡 Wi-Fi är just nu: AVSTÄNGT"
        read -p "Vill du slå PÅ Wi-Fi igen? (J/N): " svar
        if [[ "$svar" =~ ^[Jj]$ ]]; then
            sudo sed -i "/^$DISABLE_LINE/d" "$CONFIG"
            echo "✅ Wi-Fi har aktiverats."
            ask_reboot
        else
            echo "❌ Ingen ändring gjordes."
        fi
    else
        echo "📡 Wi-Fi är just nu: PÅSLAGET"
        read -p "Vill du stänga AV Wi-Fi permanent? (J/N): " svar
        if [[ "$svar" =~ ^[Jj]$ ]]; then
            echo "$DISABLE_LINE" | sudo tee -a "$CONFIG" > /dev/null
            echo "✅ Wi-Fi har stängts av."
            ask_reboot
        else
            echo "❌ Ingen ändring gjordes."
        fi
    fi
}

# === Kör beroende på val ===
case "$choice" in
    1) install_unclutter_lightdm ;;
    2) remove_index_file ;;
    3) wifi_toggle ;;
    4) install_unclutter_lightdm; remove_index_file; wifi_toggle ;;
    0) echo "Avbryter. Ingen åtgärd utförd." ;;
    *) echo "Ogiltigt val." ;;
esac

echo "Klart!"
