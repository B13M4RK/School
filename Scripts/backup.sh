#!/bin/bash

# 1. In den Schulordner wechseln
cd ~/Developer/School || exit

# 2. Alte PDFs zentral im PDFs-Ordner löschen
find PDFs/ -type f -name "*.pdf" -delete

# 3. Alle LibreOffice-Dateien suchen und als PDF in den zentralen PDFs-Ordner konvertieren
find . -type f \( -name "*.odt" -o -name "*.ods" -o -name "*.odp" -o -name "*.odg" -o -name "*.odb" -o -name "*.odf" -o -name "*.ott" \) | while read -r FILE; do
    # Konvertierung direkt in den zentralen PDFs-Ordner (Flat-Structure)
    libreoffice --headless --convert-to pdf "$FILE" --outdir "PDFs" 2>/dev/null
done

# --- NEU: PDFs außerhalb des PDFs-Ordners löschen, damit dort nur Rohdateien bleiben ---
find . -mindepth 2 -type f -name "*.pdf" ! -path "./PDFs/*" -delete

# 3b. Leere Ordner finden und mit einer .gitkeep versehen, damit Git sie erkennt
find . -type d -empty -exec touch {}/.gitkeep \;

# 4. Datum und Uhrzeit holen
DATUM=$(date +"%d.%m.%Y - %H:%M Uhr")

# --- Statistik & Noten-Markdown aktualisieren ---
if [ -f "stats.sh" ]; then
    bash stats.sh
fi

# 5. Alle Dateien (inkl. der erzeugten PDFs und .gitkeep-Dateien) vormerken
git add . 

# 6. Nur committen und pushen, wenn es Änderungen gab
if ! git diff-index --quiet HEAD -- || [ -n "$(git status --porcelain)" ]; then 
    git commit -m "Automatisches Backup vom $DATUM" 
    git push origin main 
    notify-send "Git Backup" "Schulordner & PDFs erfolgreich gesichert!" -i document-save 
fi


