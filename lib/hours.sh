#!/usr/bin/env bash

show_hours() {
    local name="$1" day="$2"
    local encoded
    encoded=$(jq -rn --arg n "$name" '$n|@uri')
    echo "== $name ($day) =="
    curl -s -H "Accept: application/json" \
      "https://api.hfs.purdue.edu/menus/v2/locations/${encoded}/${day}" \
      | jq -r '.Meals[]? | if .Status == "Closed" then "  \(.Name): Closed" else "  \(.Name): \(.Hours.StartTime) - \(.Hours.EndTime)" end' 
}

show_all_hours() {
    local day="$1"
    while IFS=$'\t' read -r id name; do 
        show_hours "$name" "$day"
    done < locations.txt
}
