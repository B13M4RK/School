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

# --- PDFs außerhalb des PDFs-Ordners löschen, damit dort nur Rohdateien bleiben ---
find . -mindepth 2 -type f -name "*.pdf" ! -path "./PDFs/*" -delete

# 3b. Leere Ordner finden und mit einer .gitkeep versehen, damit Git sie erkennt
find . -type d -empty -exec touch {}/.gitkeep \;

# 4. Datum und Uhrzeit holen
DATUM=$(date +"%d.%m.%Y - %H:%M Uhr")

# --- Statistik & Noten-Markdown aktualisieren ---
if [ -f "stats.sh" ]; then
    bash stats.sh
fi

# --- README.md direkt per integriertem Python-Skript aus den PDFs generieren ---
python3 - << 'EOF'
import os
import glob

PDF_DIR = "PDFs"
README_PATH = "README.md"

# Bekannte Fächer mit festem Display-Namen und Tier
SUBJECTS = {
    "PHY": ("⚡ Physik", "LK"),
    "MAA": ("📏 Mathematik", "LK"),
    "MAC": ("📏 Mathematik", "LK"),
    "ENG": ("🇬🇧 Englisch", "LK"),
    "GER": ("✍️ Deutsch", "GK"),
    "HIS": ("🏛️ Geschichte", "GK"),
    "SOP": ("⚖️ Gemeinschaftskunde", "GK"),
    "REL": ("⛪ Religion", "GK"),
    "ART": ("🎨 Kunst", "GK"),
    "SPO": ("⚽ Sport", "GK"),
    "MAT": ("📐 Mathe Vertiefung", "GK"),
    "CHE": ("🧪 Chemie", "GK"),
}

def scan_pdfs():
    files = glob.glob(os.path.join(PDF_DIR, "*.pdf"))
    categorized = {"LK": {}, "GK": {}}

    for filepath in files:
        filename = os.path.basename(filepath)
        name_no_ext = os.path.splitext(filename)[0]
        
        if filename in ["grades.pdf", "lehrplan.pdf"]:
            continue
            
        parts = name_no_ext.split("_")
        prefix = parts[0] if len(parts) > 0 else ""
        
        if prefix in SUBJECTS:
            subj_name, tier = SUBJECTS[prefix]
        else:
            # Fallback für komplett neue/unbekannte Fächer (Standardmäßig als Grundkurs GK)
            subj_name = f"📖 Fach ({prefix})" if prefix else "📖 Sonstige"
            tier = "GK"

        if subj_name not in categorized[tier]:
            categorized[tier][subj_name] = []
        categorized[tier][subj_name].append(filename)
            
    return categorized

def generate_markdown(categorized):
    md = []
    md.append('<div align="center">\n\n')
    md.append('  <img src="./Assets/img/Turmkreuz.png" alt="Logo" height="80">\n\n')
    md.append('  # Evangelische Schule Schloss Gaienhofen\n')
    md.append('  ### Oberstufe • Digitales Kursheft\n  \n')
    md.append('  ![Last Commit](https://img.shields.io/github/last-commit/B13M4RK/SCHOOL?style=flat-square&color=blue)\n')
    md.append('  ![License](https://img.shields.io/badge/Abitur-2028-orange?style=flat-square)\n  \n')
    md.append('  **Autor:** Paul Dreißig\n\n</div>\n\n---\n\n')
    md.append('## 📚 Kurse & Fächer\n\n')
    md.append('Das ist mein zentrales Repository für die Oberstufe. Hier findest du alle Notizen, Materialien und Kapitel zu den einzelnen Kursen:\n\n')

    for tier_key, tier_title in [("LK", "🔥 Leistungskurse (LK)"), ("GK", "📖 Grundkurse (GK)")]:
        subjects = categorized.get(tier_key, {})
        if not subjects:
            continue
        md.append(f'<details>\n<summary><b>{tier_title}</b></summary>\n<br>\n\n')
        
        for subj_name, pdf_list in sorted(subjects.items()):
            md.append(f'<details>\n<summary><b>{subj_name}</b></summary>\n<br>\n\n')
            
            pdf_list.sort()
            for pdf in pdf_list:
                clean_name = os.path.splitext(pdf)[0]
                parts = clean_name.split("_")
                label = " - ".join(parts[1:]) if len(parts) > 1 else clean_name
                md.append(f'* [{label}](./PDFs/{pdf})\n')
                
            md.append('\n</details>\n\n')
            
        md.append('</details>\n\n')

    md.append('---\n\n## Übersicht\n\n')
    md.append('* [📊 Notentabelle öffnen](./PDFs/grades.pdf)\n')
    md.append('* [📊 Lehrplan öffnen](./PDFs/lehrplan.pdf)\n\n')
    md.append('---\n\n## 📥 Projekt Herunterladen\n\n')
    md.append('Git Clone (zum Updaten bis AUG 2028)\n\n1. Falls noch nicht geschehen\n\n```bash\ncd Documents/\ngit clone [https://github.com/B13M4RK/School.git](https://github.com/B13M4RK/School.git)\n```\n\n2. Updating\n\n```bash\ncd Documents/School\ngit pull\n```\n\nDownload Zip (einmalig)\n```bash\ncd Downloads\ncurl -L -O [https://github.com/B13M4RK/SCHOOL/archive/refs/heads/main.zip](https://github.com/B13M4RK/SCHOOL/archive/refs/heads/main.zip)\nunzip main.zip\nrm main.zip\n```\n\n---\n\n## ⚖️ Lizenz & Nutzung\n\nAlle Zusammenfassungen, Mitschriften und Lösungen kannst du **frei herunterladen und zum Lernen nutzen**! \n\n* **Eigene Inhalte** (mit `Autor: Paul Dreißig`) stehen unter der [MIT-Lizenz](LICENSE) und sind Open Source.\n* **Aufgabenstellungen** dienen als Zitat zur Orientierung; die Rechte daran liegen bei den jeweiligen Lehrkräften/Verlagen.\n')
    
    return "".join(md)

if __name__ == "__main__":
    cat = scan_pdfs()
    content = generate_markdown(cat)
    with open(README_PATH, "w", encoding="utf-8") as f:
        f.write(content)
EOF

# 5. Alle Dateien (inkl. erzeugter PDFs, aktualisierter README und .gitkeep-Dateien) vormerken
git add . 

# 6. Nur committen und pushen, wenn es Änderungen gab
if ! git diff-index --quiet HEAD -- || [ -n "$(git status --porcelain)" ]; then 
    git commit -m "Automatisches Backup vom $DATUM" 
    git push origin main 
    notify-send "Git Backup" "Schulordner, PDFs & README erfolgreich aktualisiert!" -i document-save 
fi
