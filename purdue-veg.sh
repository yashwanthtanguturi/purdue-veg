#!/usr/bin/env bash

# Entry point: check the tools and data file, then run one subcommand.

set -euo pipefail

cd "$(dirname "$0")"

# jq reads the API's JSON. curl downloads it. Both have to be on PATH.
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "purdue-veg: '$1' is required but not installed." >&2
        exit 1
    }
}

require_cmd jq
require_cmd curl

# locations.txt is only the offline copy. Commands prefer the live API list,
# which is every dining location Purdue currently publishes.

source lib/api.sh
source lib/hours.sh
source lib/menu.sh
source lib/view.sh

usage() {
    cat << 'EOF'
Usage:
  ./purdue-veg.sh update            Fetch the next 10 days of menus
  ./purdue-veg.sh list              List locations and their IDs
  ./purdue-veg.sh hours [DATE]      Show hours for every location
  ./purdue-veg.sh day [DATE]        Show vegetarian items at every location
  ./purdue-veg.sh show ID [DATE]    Show vegetarian items at one location

DATE is YYYY-MM-DD and defaults to today.
EOF
}

# Reject a bad DATE before it is used as a folder name or sent to the API.
# macOS date accepts an impossible day and rolls it forward (Feb 31 becomes
# March 3), so the formatted result has to match the original text.
valid_date() {
    local d="$1" formatted
    [[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 1
    formatted=$(date -j -f "%Y-%m-%d" "$d" "+%Y-%m-%d" 2>/dev/null \
        || date -d "$d" "+%Y-%m-%d" 2>/dev/null) || return 1
    [ "$formatted" = "$d" ]
}

require_date() {
    local d="${1:-$(date +%F)}"
    if ! valid_date "$d"; then
        echo "purdue-veg: DATE must be a real day in YYYY-MM-DD form (got: $d)" >&2
        return 1
    fi
    printf '%s\n' "$d"
}

command="${1:-}"

case "$command" in
    update) save_all_menus 10 ;;
    list)
        ensure_locations || exit 1
        printf '%s\n' "$LOCATIONS_TSV" | column -t -s$'\t'
        ;;
    hours)
        # Check the date in this shell. exit inside $(...) only leaves the
        # substitution, and the command would keep going with an empty date.
        date_arg=$(require_date "${2:-}") || exit 1
        show_all_hours "$date_arg"
        ;;
    day)
        date_arg=$(require_date "${2:-}") || exit 1
        show_day "$date_arg"
        ;;
    show)
        [ -n "${2:-}" ] || { usage; exit 1; }
        date_arg=$(require_date "${3:-}") || exit 1
        show_menu "$2" "$date_arg"
        ;;
    *)      usage ;;
esac
