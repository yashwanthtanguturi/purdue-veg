#!/usr/bin/env bash

# Prints vegetarian menus that update already saved under data/.
# Run ./purdue-veg.sh update before day or show.

show_menu() {
    local id="$1" day="$2"
    local file="data/${day}/${id}.txt"
    local name
    name=$(awk -F'\t' -v id="$id" '$1 == id { print $2 }' locations.txt)

    if [ ! -d "data/${day}" ]; then
        echo "No menu data has been fetched yet. Run ./purdue-veg.sh update first."
        return
    fi

    if [ ! -f "$file" ]; then
        echo "No vegetarian menu saved for ${name:-$id} on $day"
        return
    fi

    echo "== ${name:-$id} ($day) =="
    # menu.sh writes items in API order: meal, then station within that meal.
    # This awk prints a heading only when the meal or station changes, so the
    # file has to stay sorted that way. An unsorted file would attach items
    # to the wrong heading.
    awk -F'\t' '
        $1 != meal    { meal = $1; station = ""; print "  " meal }
        $2 != station { station = $2; print "    " station ":" }
                      { print "      - " $3 }
    ' "$file"
}

show_day() {
    local day="$1" found=0
    if [ ! -d "data/${day}" ]; then
        echo "No menu data has been fetched yet. Run ./purdue-veg.sh update first."
        return
    fi
    while IFS=$'\t' read -r id name; do
        if [ -f "data/${day}/${id}.txt" ]; then
            show_menu "$id" "$day"
            found=1
        fi
    done < locations.txt
    [ "$found" -eq 1 ] || echo "No menus saved for $day"
}
