#!/usr/bin/env bash 

save_menu() {
    local id="$1" name="$2" day="$3"
    local encoded outdir
    encoded=$(jq -rn --arg n "$name" '$n|@uri')
    outdir="data/${day}"
    mkdir -p "$outdir"
    curl -s -H "Accept: application/json" \
      "https://api.hfs.purdue.edu/menus/v2/locations/${encoded}/${day}" \
      | jq -r '.Meals[]? | select(.Status != "Closed") | .Name as $meal | .Stations[]? | .Name as $station | .Items[]? | select(.IsVegetarian) | "\($meal)\t\($station)\t\(.Name)"' \
      > "${outdir}/${id}.txt"
    [ -s "${outdir}/${id}.txt" ] || rm -f "${outdir}/${id}.txt"
    rmdir "$outdir" 2>/dev/null || true
}

save_all_menus() {
    local days="${1:-10}" i day
    for ((i = 0; i < days; i++)); do
        day=$(date -v+${i}d +%F)
        while IFS=$'\t' read -r id name; do
            save_menu "$id" "$name" "$day"
        done < locations.txt
    done
}
