#!/bin/bash
set -euo pipefail


# Logging-Verzeichnis
LOGDIR="./logs"
mkdir -p "$LOGDIR"

# --- Konfiguration ---
SCANNER="fujitsu:fi-6130dj:119376" # place ur device name, which u can get with "scanimage -L"
TMP_SCAN_DIR="/tmp/scans" 
PAPERLESS_CONSUME="/path/to/consume" # change it how u like where u want to place ur pdf´s 
RESOLUTION=300 
MODE="Gray" 
SOURCE="ADF Duplex"
CONTRAST=20
BRIGHTNESS=20
LANGUAGES="deu+eng"
MIN_BLACK=1  # Schwarzanteil in %, alles darunter gilt als leer  / % of black min of 1% 

# ----------------------
# Letzte Lognummer bestimmen
LASTNUM=$(ls "$LOGDIR"/scan_*.log 2>/dev/null | \
   sed 's/.*scan_\([0-9]\+\)\.log/\1/' | \
   sort -n | \
   tail -1 || echo 0)

# Wenn leer, setze auf 0
LASTNUM=${LASTNUM:-0}

# Nächste Lognummer berechnen
NEXTNUM=$(printf "%03d" $((10#$LASTNUM + 1)))

# Logfile festlegen
LOGFILE="$LOGDIR/scan_${NEXTNUM}.log"

# Logging aktivieren
exec > >(tee -a "$LOGFILE") 2>&1

echo "Starte Scanlauf, Logfile: $LOGFILE"

mkdir -p "$TMP_SCAN_DIR"
mkdir -p "$PAPERLESS_CONSUME"

TS=$(date +%Y%m%d_%H%M%S)

echo "Starte Scan vom Fi-6130DJ..."

# 1. Duplex-Scan in TIFFs
scanimage \
  --device-name "$SCANNER" \
  --format=tiff \
  --mode "$MODE" \
  --resolution "$RESOLUTION" \
  --source "$SOURCE" \
  --contrast "$CONTRAST" \
  --brightness "$BRIGHTNESS" \
  --page-width 210 --page-height 297 \
  --batch="$TMP_SCAN_DIR/scan_%03d.tiff" \
  --batch-start=1

echo "Scan abgeschlossen. TIFFs gespeichert in $TMP_SCAN_DIR"# 1. Duplex-Scan in TIFFs

# 2. TIFFs -> PDFs mit OCR, Rotation, Deskew und Schwarzanteil-Prüfung
for tiff in "$TMP_SCAN_DIR"/scan_*.tiff; do
  base=$(basename "${tiff%.tiff}")
  tmp_pdf="/tmp/${TS}_${base}.pdf"
  final_pdf="$PAPERLESS_CONSUME/${TS}_${base}.pdf"

  echo "Verarbeite $tiff ..."

  # Schwarzanteil prüfen
  black_percent=$(convert "$tiff" -colorspace Gray -format "%[fx:100*(1-mean)]" info:)
  black_percent_int=$(awk "BEGIN{printf \"%d\", $black_percent}")
  echo "Schwarzanteil: $black_percent %"

  if [ "$black_percent_int" -lt "$MIN_BLACK" ]; then
    echo "Seite gilt als leer (unter $MIN_BLACK % schwarz), wird verworfen: $tiff"
    continue
  fi

  # OCR -> PDF mit Auto-Rotation und Deskew
  if ocrmypdf \
       --language "$LANGUAGES" \
       --rotate-pages \
       --rotate-pages-threshold 0 \
       "$tiff" "$tmp_pdf"; then

    # Seitenweise prüfen
    NUM_PAGES=$(pdfinfo "$tmp_pdf" | awk '/^Pages:/ {print $2}')
    non_empty_pages=()

    for ((i=1;i<=NUM_PAGES;i++)); do
      text=$(pdftotext -f $i -l $i "$tmp_pdf" -)
      num_chars=$(echo "$text" | tr -cd '[:alnum:]' | wc -c)
      if [ "$num_chars" -ge 5 ]; then
        non_empty_pages+=($i)
      fi
    done

    if [ ${#non_empty_pages[@]} -gt 0 ]; then
      qpdf "$tmp_pdf" --pages "$tmp_pdf" "${non_empty_pages[@]}" -- "$final_pdf"
      echo "PDF gespeichert: $final_pdf"
    else
      echo "Alle Seiten leer, PDF wird verworfen: $tmp_pdf"
      rm -f "$tmp_pdf"
    fi

  else
    echo "Fehler bei OCR: $tiff"
    rm -f "$tmp_pdf" || true
  fi
done

# 3. Aufräumen
rm -f "$TMP_SCAN_DIR"/scan_*.tiff

echo "Alle Scans fertig. PDFs im Paperless-Consume-Ordner abgelegt."