#!/usr/bin/env bash

# The only place that talks to Purdue's dining API, so hours.sh and menu.sh
# share one request instead of copying it.

fetch_menu_json(){
    local name="$1" day="$2" encoded
    # Location names have spaces and "!" (e.g. "Earhart On-the-GO!"),
    # so they must be URL-encoded before going into the path.
    encoded=$(jq -rn --arg n "$name" '$n|@uri')
    # -f makes curl fail on HTTP errors, so callers can detect a bad request.
    curl -sf -H "Accept: application/json" \
      "https://api.hfs.purdue.edu/menus/v2/locations/${encoded}/${day}"
}
