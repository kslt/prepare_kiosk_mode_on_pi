#!/bin/bash

# === Meny ===
echo "Välj åtgärd:"
echo "1) Installera unclutter och uppdatera LightDM"
echo "2) Ta bort index.lighttpd.html"
echo "3) Hantera Wi-Fi (av/på permanent)"
echo "4) Gör alla"
read -p "Ange val (1-4): " choice

# === Y/N questions function ===
confirm() {
    read -p "$1 (j/n): " answer
    case "$answer" in
        [JjYy]* ) return 0 ;;
        * ) return 1 ;;
    esac
}

# === Part 1: Install unclutter and LightDM-ändring ===
install_unclutter_lightdm() {
    if confirm "Vill du installera unclutter och uppdatera LightDM?"; then
        # Check unclutter
        if dpkg -s unclutter &> /dev/null; then
            echo "✔ unclutter är redan installerat."
        else
            echo "Installerar unclutter..."
            sudo apt-get update
            sudo apt-get install -y unclutter
        fi

        # Check LightDM-filer
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

# === Part 2: Delete index.lighttpd.html ===
remove_index_file() {
    if [[ -f /var/www/html/index.lighttpd.html ]]; then
        if confirm "Vill du ta bort /var/www/html/index.lighttpd.html?"; then
            sudo rm -f /var/www/html/index.lighttpd.html
            echo "Filen borttagen."
        else
            echo "Åtgärden avbruten."
        fi
    else
        echo "✔ Filen /var/www/html/index.lighttpd.html finns inte redan."
    fi
}

# === Part 3: Wi-Fi on/off permanent ===
wifi_toggle() {
    CONFIG="/boot/firmware/config.txt"
    DISABLE_LINE="dtoverlay=disable-wifi"

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

# === Run depending on choice of action ===
case "$choice" in
    1) install_unclutter_lightdm ;;
    2) remove_index_file ;;
    3) wifi_toggle ;;
    4) install_unclutter_lightdm; remove_index_file; wifi_toggle ;;
    *) echo "Ogiltigt val." ;;
esac

echo "Klart!"
