#!/usr/bin/env bash

# The only place that talks to Purdue's dining API, so hours.sh and menu.sh
# share one request instead of copying it.

fetch_menu_json(){
    local name="$1" day="$2" encoded
    # Location names have spaces and "!" (e.g. "Earhart On-the-GO!"),
    # so they must be URL-encoded before going into the path.
    encoded=$(jq -rn --arg n "$name" '$n|@uri')
    # -f makes curl fail on HTTP errors, so callers can detect a bad request.
    # A 10-day update makes more than a hundred requests, and Purdue sometimes
    # drops one of them. Retry that request before the caller skips the location.
    curl -sf --retry 3 --retry-delay 1 --retry-all-errors \
      -H "Accept: application/json" \
      "https://api.hfs.purdue.edu/menus/v2/locations/${encoded}/${day}"
}

# Every dining court, On-the-GO!, and quick bite the menu API currently
# publishes, stored as "ID<TAB>Name" in LOCATIONS_TSV. locations.txt is only
# the offline copy. Call this in the current shell: a command substitution
# would throw the cache away and refetch for every location.
ensure_locations() {
    if [ -n "${LOCATIONS_TSV:-}" ]; then
        return 0
    fi

    local json
    if json=$(curl -sf -H "Accept: application/json" \
        "https://api.hfs.purdue.edu/menus/v2/locations"); then
        LOCATIONS_TSV=$(printf '%s\n' "$json" | jq -r '
            .Location[]
            | select(.LocationId != null and .Name != null)
            | [.LocationId, .Name]
            | @tsv
        ')
    elif [ -s locations.txt ]; then
        echo "Could not refresh locations from the API; using locations.txt." >&2
        LOCATIONS_TSV=$(cat locations.txt)
    else
        echo "purdue-veg: could not load dining locations." >&2
        return 1
    fi

    if [ -z "$LOCATIONS_TSV" ]; then
        echo "purdue-veg: the location list was empty." >&2
        return 1
    fi
}
