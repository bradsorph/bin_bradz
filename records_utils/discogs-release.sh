
#!/usr/bin/env bash

set -euo pipefail

API_BASE="https://api.discogs.com"
USER_AGENT="bradz667-discogs/2.0"

OUTPUT_DIR="./discogs-releases"

mkdir -p "$OUTPUT_DIR"

if ! command -v curl >/dev/null 2>&1; then
    echo "Errore: curl non trovato."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Errore: jq non trovato."
    echo "Installa jq con: brew install jq"
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "Uso:"
    echo "  $0 RELEASE_ID [RELEASE_ID ...]"
    echo
    echo "Esempio:"
    echo "  $0 577332"
    echo "  $0 577332 9579823 5789680"
    exit 1
fi

TOKEN_FILE="$HOME/.config/discogs/token"
TOKEN=""

if [[ -f "$TOKEN_FILE" ]]; then
    TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"
fi

for ID in "$@"; do

    if ! [[ "$ID" =~ ^[0-9]+$ ]]; then
        echo "ID non valido: $ID"
        continue
    fi

    echo
    echo "=================================================="
    echo "DISCOGS RELEASE: $ID"
    echo "=================================================="

    JSON_FILE="${OUTPUT_DIR}/${ID}.json"
    TXT_FILE="${OUTPUT_DIR}/${ID}.txt"

    CURL_ARGS=(
        -fsS
        --retry 3
        --retry-delay 1
        -H "User-Agent: ${USER_AGENT}"
    )

    if [[ -n "$TOKEN" ]]; then
        CURL_ARGS+=(
            -H "Authorization: Discogs token=${TOKEN}"
        )
    fi

    if ! curl "${CURL_ARGS[@]}" \
        "${API_BASE}/releases/${ID}" \
        -o "$JSON_FILE"; then
        echo "Errore nel recupero della release $ID."
        rm -f "$JSON_FILE"
        continue
    fi

    # Generazione rapporto testuale

    jq -r '
    def join_values:
        map(select(. != null and . != "")) | join("; ");

    "TITLE:       \(.title // "N/A")",
    "ARTIST:      \([.artists[]?.name] | join(", "))",
    "YEAR:        \(.year // "N/A")",
    "RELEASED:    \(.released // "N/A")",
    "COUNTRY:     \(.country // "N/A")",
    "LABELS:      \([.labels[]? | .name] | join("; "))",
    "CATALOG NO:  \([.labels[]? | .catno] | join("; "))",
    "FORMAT:      \([.formats[]? | "\(.qty // "") \(.name // "") \((.descriptions // []) | join(", "))"] | join("; "))",
    "GENRE:       \([.genres[]?] | join(", "))",
    "STYLE:       \([.styles[]?] | join(", "))",
    "MASTER ID:   \(.master_id // "N/A")",
    "",
    "IDENTIFIERS:",
    (.identifiers[]? | "  \(.type // "N/A"): \(.value // "N/A") \(.description // "")"),
    "",
    "COMPANIES:",
    (.companies[]? | "  \(.name // "N/A") - \(.entity_type_name // "") - \(.catno // "")"),
    "",
    "TRACKLIST:",
    (.tracklist[]? | "  \(.position // "")  \(.title // "")  [\(.duration // "")]"),
    "",
    "EXTRA ARTISTS:",
    (.extraartists[]? | "  \(.name // "") - \(.role // "")"),
    "",
    "NOTES:",
    (.notes // "N/A"),
    "",
    "COMMUNITY:",
    "  Have: \(.community.have // 0)",
    "  Want: \(.community.want // 0)",
    "  Rating: \(.community.rating.average // "N/A")",
    "",
    "DATA QUALITY: \(.data_quality // "N/A")",
    "DISCOGS URL: \(.uri // "N/A")",
    "",
    "IMAGES:",
    (.images[]? | "  \(.uri // "")")
    ' "$JSON_FILE" > "$TXT_FILE"

    cat "$TXT_FILE"

    echo
    echo "JSON: $JSON_FILE"
    echo "TXT:  $TXT_FILE"

    sleep 1

done

echo
echo "Elaborazione terminata."
