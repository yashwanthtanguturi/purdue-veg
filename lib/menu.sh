#!/usr/bin/env bash

# Saves vegetarian items for each location. Needs fetch_menu_json (lib/api.sh).

# Closed meals are skipped because Status "Closed" means that meal is not
# served, so it has nothing to list.
vegetarian_filter='
.Meals[]?
| select(.Status != "Closed")
| .Name as $meal
| .Stations[]?
| .Name as $station
| .Items[]?
| select(.IsVegetarian)
| "\($meal)\t\($station)\t\(.Name)"
'

# GNU date (Linux) uses -d. macOS date uses -v. Try GNU first.
day_offset() {
    local offset="$1"
    date -d "+${offset} days" +%F 2>/dev/null || date -v+"${offset}"d +%F
}

save_menu() {
    local id="$1" name="$2" day="$3"
    local outdir json
    outdir="data/${day}"
    mkdir -p "$outdir"

    # One failed request should not stop the rest of the update.
    if ! json=$(fetch_menu_json "$name" "$day"); then
        echo "Could not fetch the menu for $name on $day; skipping." >&2
        rmdir "$outdir" 2>/dev/null || true
        return 0
    fi

    # Files are named by location ID. Display names contain spaces and
    # punctuation ("Earhart On-the-GO!"), which are awkward in filenames.
    if ! printf '%s\n' "$json" | jq -r "$vegetarian_filter" > "${outdir}/${id}.txt"; then
        echo "Could not read the menu for $name on $day; skipping." >&2
        rm -f "${outdir}/${id}.txt"
        rmdir "$outdir" 2>/dev/null || true
        return 0
    fi

    # Remove an empty file so "no vegetarian items" is not stored as a blank
    # file that view.sh would treat as a saved menu.
    [ -s "${outdir}/${id}.txt" ] || rm -f "${outdir}/${id}.txt"
    # Remove the day folder when every location was empty or failed, so
    # data/ does not fill up with empty directories.
    rmdir "$outdir" 2>/dev/null || true
}

save_all_menus() {
    local days="${1:-10}" i day
    for ((i = 0; i < days; i++)); do
        day=$(day_offset "$i")
        while IFS=$'\t' read -r id name; do
            save_menu "$id" "$name" "$day"
        done < locations.txt
    done
}
