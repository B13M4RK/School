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

# 1. Fächerliste (Menü-Anzeige : Englischer Ordnername)
FAECHER_DISPLAY=(
  "Kunst"
  "Mathe Vertiefungskurs"
  "Gesellschaftskunde"
  "Englisch"
  "Deutsch"
  "Geschichte"
  "Mathe"
  "Sport"
  "Physik"
  "Religion"
  "Chemie"
)

FAECHER_FOLDER=(
  "Art"
  "Math_Adv"
  "SocialStudies"
  "English"
  "German"
  "History"
  "Math_Core"
  "PE"
  "Physics"
  "Religion"
  "Chemistry"
)

# 2. Fach auswählen
echo "=== FACH WÄHLEN ==="
for i in "${!FAECHER_DISPLAY[@]}"; do
  echo "$((i+1))) ${FAECHER_DISPLAY[$i]}"
done
read -p "Nummer eingeben: " WAHL_FACH

FACH="${FAECHER_FOLDER[$((WAHL_FACH-1))]}"

# Spezifische Kürzel für Mathe Core und Mathe Advanced, sonst Standard (erste 3 Buchstaben)
case "$FACH" in
  "Math_Core") FACH_SHORT="MAC" ;;
  "Math_Adv")  FACH_SHORT="MAA" ;;
  *)           FACH_SHORT=$(echo "$FACH" | cut -c1-3 | tr '[:lower:]' '[:upper:]') ;;
esac

# Basis-Pfad & Template-Pfad (Angepasst auf Developer/School)
BASE_DIR="$HOME/Developer/School/Subjects/$FACH"
TEMPLATE_DIR="$HOME/Developer/School/Templates"
mkdir -p "$BASE_DIR"

# 3. Dokument-Art auswählen
echo -e "\n=== DOKUMENT-ART WÄHLEN ==="
ARTEN=("EXP (Experiment)" "ESS (Essay)" "SUM (Summary)" "EXE (Exercises)" "FOR (Formula/Formelsammlung)")
for i in "${!ARTEN[@]}"; do
  echo "$((i+1))) ${ARTEN[$i]}"
done
read -p "Nummer eingeben: " WAHL_ART

case $WAHL_ART in
  1) ART="EXP" ;;
  2) ART="ESS" ;;
  3) ART="SUM" ;;
  4) ART="EXE" ;;
  5) ART="FOR" ;;
  *) echo "Ungültige Auswahl!"; exit 1 ;;
esac

# --- LEHRKRAFT ZUWEISEN ---
case "$FACH" in
  "German")        TEACHER="Ute Bonath" ;;
  "Physics")       TEACHER="Lukas Herrwanger" ;;
  "Religion")      TEACHER="Arnold Glitsch-Hünnefeld" ;;
  "Art")           TEACHER="Lucas König" ;;
  "English")       TEACHER="Mark Kaiser" ;;
  "Chemistry")     TEACHER="Sina Postius" ;;
  "Math_Core")     TEACHER="Cornelia Kessler" ;;
  "Math_Adv")      TEACHER="Johanna Bohlken" ;;
  "SocialStudies") TEACHER="Nikolaus Göller" ;;
  "History")       TEACHER="Tobias Urban" ;;
  *)               TEACHER="LEHRER" ;;
esac

# 4. Zielordner ist direkt das Fach, Nummerierung fortlaufend ermitteln
ZIELORDNER="$BASE_DIR"

if [ "$ART" == "FOR" ]; then
  read -p "Name für die Formelsammlung: " DOC_NAME
  DOC_NAME_UPPER=$(echo "$DOC_NAME" | tr '[:lower:]' '[:upper:]')
  
  FULL_HEADER="${FACH_SHORT}_FOR_${DOC_NAME_UPPER}"
  DATEINAME="${FACH_SHORT}_FOR_${DOC_NAME}.odt"

else
  # Fortlaufende Nummer für diesen Dokumenttyp im Fach ermitteln
  MAX_NUM=0
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    filename=$(basename "$file")
    num=$(echo "$filename" | sed -n "s/^${FACH_SHORT}_${ART}_\([0-9]\+\)_.*$/\1/p")
    if [[ -n "$num" ]] && (( 10#$num > MAX_NUM )); then
      MAX_NUM=$((10#$num))
    fi
  done < <(find "$ZIELORDNER" -maxdepth 1 -type f -name "${FACH_SHORT}_${ART}_*.odt" 2>/dev/null)

  NEXT_NUM=$((MAX_NUM + 1))
  NUMMER=$(printf "%02d" "$NEXT_NUM")
  echo "Fortlaufende Nummer für $ART in $FACH: $NUMMER"

  read -p "Name des Dokuments (z. B. Freier_Fall): " DOC_NAME
  DOC_NAME_UPPER=$(echo "$DOC_NAME" | tr '[:lower:]' '[:upper:]')
  
  FULL_HEADER="${FACH_SHORT}_${ART}_${NUMMER}_${DOC_NAME_UPPER}"
  DATEINAME="${FACH_SHORT}_${ART}_${NUMMER}_${DOC_NAME}.odt"
fi

# 5. Dateipfad definieren
CURRENT_DATE=$(date +"%d.%m.%Y")
DATEIPFAD="$ZIELORDNER/$DATEINAME"

# 6. Template per LibreOffice nativ in .odt konvertieren & Variablen ersetzen
if [ -f "$DATEIPFAD" ]; then
  echo -e "\nDas Dokument existiert bereits! Öffne bestehende Datei..."
else
  TEMPLATE_FILE="$TEMPLATE_DIR/TEM_${ART}.ott"

  if [ -f "$TEMPLATE_FILE" ]; then
    echo -e "\nErstelle Dokument aus Vorlage: TEM_${ART}.ott"

    TMP_DIR=$(mktemp -d)

    soffice --headless --convert-to odt "$TEMPLATE_FILE" --outdir "$TMP_DIR" >/dev/null 2>&1
    CONVERTED_ODT="$TMP_DIR/TEM_${ART}.odt"

    if [ -f "$CONVERTED_ODT" ]; then
      UNZIP_DIR="$TMP_DIR/unpacked"
      mkdir -p "$UNZIP_DIR"
      unzip -q "$CONVERTED_ODT" -d "$UNZIP_DIR"

      replace_in_xml() {
        local file="$1"
        if [ -f "$file" ]; then
          sed -i "s/FACH_${ART}_NUMBER_NAME/${FULL_HEADER}/g" "$file"
          sed -i "s/FACH_${ART}_NUMMER_NAME/${FULL_HEADER}/g" "$file"
          sed -i "s/FACH_${ART}_NAME/${FULL_HEADER}/g" "$file"

          sed -i "s/FACH/$FACH_SHORT/g" "$file"
          if [ "$ART" != "FOR" ]; then
            sed -i "s/NUMBER/$NUMMER/g" "$file"
            sed -i "s/NUMMER/$NUMMER/g" "$file"
          fi
          sed -i "s/NAME/$DOC_NAME_UPPER/g" "$file"

          sed -i "s/DATUM/$CURRENT_DATE/g" "$file"
          sed -i "s/Datum/$CURRENT_DATE/g" "$file"
          sed -i "s/DATE/$CURRENT_DATE/g" "$file"
          sed -i "s/Date/$CURRENT_DATE/g" "$file"

          sed -i "s/LEHRER/$TEACHER/g" "$file"
          sed -i "s/Lehrer/$TEACHER/g" "$file"
          sed -i "s/TEACHER/$TEACHER/g" "$file"
          sed -i "s/Teacher/$TEACHER/g" "$file"

          sed -i 's/fo:color="[^"]*"/fo:color="#000000"/g' "$file"
        fi
      }

      replace_in_xml "$UNZIP_DIR/content.xml"
      replace_in_xml "$UNZIP_DIR/styles.xml"

      cd "$UNZIP_DIR" || exit
      zip -0 -X -q "$DATEIPFAD" mimetype
      zip -r -q "$DATEIPFAD" . -x mimetype
      cd - >/dev/null || exit
    fi

    rm -rf "$TMP_DIR"

  else
    echo -e "\nKeine Vorlage '$TEMPLATE_FILE' gefunden! Erstelle leere Datei..."
    touch "$DATEIPFAD"
  fi
fi

chmod 644 "$DATEIPFAD"
sync

libreoffice "$DATEIPFAD" >/dev/null 2>&1 &

read -p "Drücke Enter zum Beenden..."
