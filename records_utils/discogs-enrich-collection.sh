#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Discogs Collection Enricher
#
# Uso:
#   ./discogs-enrich-collection.sh collection.csv
#
# Output:
#   collection-enriched.csv
#
# Requisiti:
#   curl
#   jq
# ============================================================

TOKEN_FILE="$HOME/.config/discogs/token"
API_BASE="https://api.discogs.com"
USER_AGENT="bradz667-discogs-collection/1.0"

if ! command -v curl >/dev/null 2>&1; then
    echo "Errore: curl non trovato."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Errore: jq non trovato."
    echo "Installalo con: brew install jq"
    exit 1
fi

if [[ ! -f "$TOKEN_FILE" ]]; then
    echo "Errore: token non trovato:"
    echo "$TOKEN_FILE"
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Uso:"
    echo "  $0 collection.csv"
    exit 1
fi

INPUT="$1"
OUTPUT="${INPUT%.csv}-enriched.csv"

TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"

if [[ ! -s "$INPUT" ]]; then
    echo "Errore: file CSV vuoto o inesistente: $INPUT"
    exit 1
fi

echo
echo "Discogs Collection Enricher"
echo "==========================="
echo "Input:  $INPUT"
echo "Output: $OUTPUT"
echo

# ------------------------------------------------------------
# Individua la colonna Release ID.
# Discogs normalmente usa "release_id".
# ------------------------------------------------------------

HEADER="$(head -n 1 "$INPUT")"

if ! echo "$HEADER" | grep -qi 'release_id'; then
    echo "Errore: non trovo una colonna 'release_id' nel CSV."
    echo
    echo "Intestazione trovata:"
    echo "$HEADER"
    exit 1
fi

# ------------------------------------------------------------
# Funzione per ottenere un campo semplice dal JSON.
# ------------------------------------------------------------

get_release() {
    local id="$1"

    curl -fsS \
        --retry 3 \
        --retry-delay 1 \
        -H "User-Agent: ${USER_AGENT}" \
        -H "Authorization: Discogs token=${TOKEN}" \
        "${API_BASE}/releases/${id}"
}

# ------------------------------------------------------------
# Crea il nuovo CSV.
#
# Manteniamo tutte le colonne originali e aggiungiamo:
#
# discogs_year
# discogs_country
# discogs_labels
# discogs_catalog_numbers
# discogs_format
# discogs_genre
# discogs_style
# discogs_master_id
# discogs_identifiers
# discogs_matrix
# discogs_notes
# discogs_url
# ------------------------------------------------------------

python3 - "$INPUT" "$OUTPUT" <<'PY'
import csv
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

with open(input_file, "r", encoding="utf-8-sig", newline="") as f:
    reader = csv.DictReader(f)
    rows = list(reader)
    fieldnames = reader.fieldnames or []

new_fields = [
    "discogs_year",
    "discogs_country",
    "discogs_labels",
    "discogs_catalog_numbers",
    "discogs_format",
    "discogs_genre",
    "discogs_style",
    "discogs_master_id",
    "discogs_identifiers",
    "discogs_matrix",
    "discogs_notes",
    "discogs_url",
]

for field in new_fields:
    if field not in fieldnames:
        fieldnames.append(field)

with open(output_file, "w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    for row in rows:
        writer.writerow(row)

print(f"Preparato CSV con {len(rows)} record.")
PY

# ------------------------------------------------------------
# Estrai gli ID dal CSV.
# Usiamo Python per gestire correttamente CSV quotati.
# ------------------------------------------------------------

RELEASE_IDS=()

while IFS= read -r ID; do
    [[ -n "$ID" ]] && RELEASE_IDS+=("$ID")
done < <(
python3 - "$INPUT" <<'PY'
import csv
import sys

with open(sys.argv[1], "r", encoding="utf-8-sig", newline="") as f:
    reader = csv.DictReader(f)

    for row in reader:
        value = row.get("release_id", "").strip()
        if value:
            print(value)
PY
)

TOTAL="${#RELEASE_IDS[@]}"

if [[ "$TOTAL" -eq 0 ]]; then
    echo "Nessun Release ID trovato."
    exit 1
fi

echo "Release da interrogare: $TOTAL"
echo

# ------------------------------------------------------------
# File temporaneo JSON.
# ------------------------------------------------------------

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

COUNT=0

for ID in "${RELEASE_IDS[@]}"; do

    COUNT=$((COUNT + 1))

    JSON_FILE="${TMP_DIR}/${ID}.json"

    printf "[%4d/%4d] Release %s ... " "$COUNT" "$TOTAL" "$ID"

    if get_release "$ID" > "$JSON_FILE"; then
        echo "OK"
    else
        echo "ERRORE"
        echo '{"error":true}' > "$JSON_FILE"
    fi

    # Discogs API rate limiting:
    # manteniamo un ritmo prudente.
    sleep 1

done

echo
echo "API download completato."
echo "Costruzione CSV finale..."

# ------------------------------------------------------------
# Arricchimento del CSV con Python.
# ------------------------------------------------------------

python3 - "$OUTPUT" "$TMP_DIR" <<'PY'
import csv
import json
import os
import sys

csv_file = sys.argv[1]
json_dir = sys.argv[2]

with open(csv_file, "r", encoding="utf-8", newline="") as f:
    rows = list(csv.DictReader(f))
    fieldnames = list(rows[0].keys()) if rows else []

def clean(value):
    if value is None:
        return ""
    return str(value).replace("\n", " ").replace("\r", " ").strip()

for row in rows:

    release_id = clean(row.get("release_id"))

    if not release_id:
        continue

    json_path = os.path.join(json_dir, f"{release_id}.json")

    if not os.path.exists(json_path):
        continue

    try:
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        continue

    if data.get("error"):
        continue

    row["discogs_year"] = clean(data.get("year"))
    row["discogs_country"] = clean(data.get("country"))

    labels = data.get("labels", [])
    row["discogs_labels"] = "; ".join(
        clean(x.get("name"))
        for x in labels
        if x.get("name")
    )

    row["discogs_catalog_numbers"] = "; ".join(
        clean(x.get("catno"))
        for x in labels
        if x.get("catno")
    )

    formats = data.get("formats", [])
    format_strings = []

    for fmt in formats:
        parts = []

        if fmt.get("qty"):
            parts.append(clean(fmt.get("qty")))

        if fmt.get("name"):
            parts.append(clean(fmt.get("name")))

        descriptions = fmt.get("descriptions", [])

        if descriptions:
            parts.append(", ".join(clean(x) for x in descriptions))

        format_strings.append(" ".join(parts))

    row["discogs_format"] = "; ".join(format_strings)

    row["discogs_genre"] = "; ".join(
        clean(x) for x in data.get("genres", [])
    )

    row["discogs_style"] = "; ".join(
        clean(x) for x in data.get("styles", [])
    )

    row["discogs_master_id"] = clean(data.get("master_id"))

    identifiers = data.get("identifiers", [])

    identifier_strings = []

    for x in identifiers:
        typ = clean(x.get("type"))
        value = clean(x.get("value"))

        if typ and value:
            identifier_strings.append(f"{typ}: {value}")

    row["discogs_identifiers"] = "; ".join(identifier_strings)

    # Cerca esplicitamente eventuali matrici/runout.
    matrix_strings = []

    for x in identifiers:
        typ = clean(x.get("type")).lower()
        desc = clean(x.get("description")).lower()
        value = clean(x.get("value"))

        if (
            "matrix" in typ
            or "runout" in typ
            or "matrix" in desc
            or "runout" in desc
        ):
            matrix_strings.append(value)

    row["discogs_matrix"] = "; ".join(matrix_strings)

    notes = data.get("notes", "")
    row["discogs_notes"] = clean(notes)

    row["discogs_url"] = clean(data.get("uri"))

with open(csv_file, "w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print(f"CSV completato: {csv_file}")
PY

echo
echo "============================================================"
echo "COMPLETATO"
echo "============================================================"
echo
echo "File:"
echo "  $OUTPUT"
echo
