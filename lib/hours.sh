#!/usr/bin/env bash

# Prints when each dining location serves each meal on a given day.
# Needs fetch_menu_json (lib/api.sh) to be loaded first.

show_hours() {
    local name="$1" day="$2" json
    echo "== $name ($day) =="
    # One failed request (offline, or no menu for that date) shouldn't stop
    # the loop over the other locations, so report it and move on.
    if ! json=$(fetch_menu_json "$name" "$day"); then
        echo "  (could not fetch hours)"
        return 0
    fi
    # Closed meals have null Hours, so print "Closed" instead of reading them.
    echo "$json" | jq -r '.Meals[]? | if .Status == "Closed" then "  \(.Name): Closed" else "  \(.Name): \(.Hours.StartTime) - \(.Hours.EndTime)" end'
}

show_all_hours() {
    local day="$1"
    while IFS=$'\t' read -r id name; do 
        show_hours "$name" "$day"
    done < locations.txt
}
