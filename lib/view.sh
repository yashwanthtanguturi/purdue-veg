#!/usr/bin/env bash


show_menu() {
    local id="$1" day="$2"
    local file="data/${day}/${id}.txt"
    local name
    name=$(awk -F'\t' -v id="$id" '$1 == id { print $2 }' locations.txt)


    if [ ! -f "$file" ]; then 
        echo "No Vegetarian menu saved for ${name:-$id} on $day"
        return
    fi 

    echo "== ${name:-$id} ($day) =="
    awk -F'\t' '
        $1 != meal    { meal = $1; station = ""; print "  " meal }
        $2 != station { station = $2; print "    " station ":" }
                      { print "      - " $3 }
    ' "$file"
}



show_day() {
    local day="$1" found=0
    while IFS=$'\t' read -r id name; do
        if [ -f "data/${day}/${id}.txt" ]; then
            show_menu "$id" "$day"
            found=1
        fi
    done < locations.txt
    [ "$found" -eq 1 ] || echo "No menus saved for $day"
}
