#!/bin/bash

# --- AUTOMATISCHER TERMINAL-LAUNCHER ---
if [ ! -t 0 ]; then
  if command -v gnome-terminal >/dev/null 2>&1; then
    exec gnome-terminal -- "$0" "$@"
  elif command -v ptyxis >/dev/null 2>&1; then
    exec ptyxis -- "$0" "$@"
  elif command -v x-terminal-emulator >/dev/null 2>&1; then
    exec x-terminal-emulator -e "$0" "$@"
  elif command -v xterm >/dev/null 2>&1; then
    exec xterm -e "$0" "$@"
  else
    echo "Kein unterstütztes Terminal gefunden!"
    exit 1
  fi
fi

# In den Schulordner wechseln (Basis)
cd ~/Developer/School || exit

# 1. Fächer-Arrays (Astronomie entfernt, Mathe Vertiefung hinzugefügt)
FAECHER_DISPLAY=(
  "Kunst"
  "Mathe Vertiefung"
  "Gesellschaftskunde"
  "Englisch"
  "Deutsch"
  "Geschichte"
  "Mathe"
  "Sport"
  "Physik"
  "Religion"
)

FAECHER_FOLDER=(
  "Art"
  "AdvancedMath"
  "SocialStudies"
  "English"
  "German"
  "History"
  "Math"
  "PE"
  "Physics"
  "Religion"
)

# 2. Fach auswählen
echo "=== 📚 KLASSENARBEITS-VORBEREITER ==="
echo "Welches Fach wird gelernt?"
for i in "${!FAECHER_DISPLAY[@]}"; do
  echo "$((i+1))) ${FAECHER_DISPLAY[$i]}"
done
read -p "Nummer eingeben: " WAHL_FACH

FACH_FOLDER_NAME="${FAECHER_FOLDER[$((WAHL_FACH-1))]}"
FACH_TITLE="${FAECHER_DISPLAY[$((WAHL_FACH-1))]}"
FACH_PATH="Subjects/$FACH_FOLDER_NAME"

if [ ! -d "$FACH_PATH" ]; then
    echo "Fehler: Der Ordner für $FACH_TITLE existiert noch nicht!"
    read -p "Drücke Enter zum Beenden..."
    exit 1
fi

# Zielordner auf dem Desktop erstellen
DESKTOP_DIR="$HOME/Desktop/Lernmappe_${FACH_TITLE}"
rm -rf "$DESKTOP_DIR"
mkdir -p "$DESKTOP_DIR"

echo ""
echo "Erstelle Lernmappe für: $FACH_TITLE"
echo "Ziel: Desktop/Lernmappe_${FACH_TITLE}"
echo "--------------------------------------------------"

# 3. Schleife für Kapitel und Material-Auswahl
while true; do
    echo ""
    echo "Verfügbare Kapitel in $FACH_TITLE:"
    
    # Zeige alle verfügbaren Ordner (CHA_* und FOR) an
    CHAPTERS=()
    while IFS= read -r dir; do
        if [ -d "$dir" ]; then
            CHAPTERS+=("$(basename "$dir")")
        fi
    done < <(find "$FACH_PATH" -mindepth 1 -maxdepth 1 -type d | sort)

    if [ ${#CHAPTERS[@]} -eq 0 ]; then
        echo "Keine Kapitel oder Ordner in diesem Fach gefunden!"
        break
    fi

    for i in "${!CHAPTERS[@]}"; do
        echo "$((i+1))) ${CHAPTERS[$i]}"
    done
    
    echo "--------------------------------------------------"
    read -p "Welches Kapitel/Ordner hinzufügen? (Nummer eingeben): " WAHL_CHA

    INDEX=$((WAHL_CHA-1))
    if [[ $INDEX -ge 0 && $INDEX -lt ${#CHAPTERS[@]} ]]; then
        SELECTED_CHA="${CHAPTERS[$INDEX]}"
        SOURCE_DIR="$FACH_PATH/$SELECTED_CHA"

        echo "-> Kopiere PDFs aus '$SELECTED_CHA'..."
        
        # Kopiert alle PDFs direkt in den Haupt-Desktop-Ordner (ohne Unterordner anzulegen)
        find "$SOURCE_DIR" -type f -name "*.pdf" -exec cp {} "$DESKTOP_DIR/" \;
        
        # Prüfen, wie viele PDFs insgesamt im Zielordner liegen
        PDF_COUNT_TOTAL=$(find "$DESKTOP_DIR" -type f -name "*.pdf" | wc -l)
        echo "   Erfolgreich PDFs hinzugefügt (Gesamt in Mappe: $PDF_COUNT_TOTAL)"
    else
        echo "Ungültige Auswahl!"
    fi

    echo ""
    read -p "Möchtest du noch ein weiteres Kapitel/FOR hinzufügen? (j/n): " WEITER
    if [[ "$WEITER" != "j" && "$WEITER" != "J" && "$WEITER" != "ye" && "$WEITER" != "yes" ]]; then
        break
    fi
done

echo ""
echo "=================================================="
echo " Fertig! Deine Lernmappe liegt auf dem Desktop:"
echo " Desktop/Lernmappe_${FACH_TITLE}"
echo "=================================================="
read -p "Drücke Enter zum Beenden..."
