#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

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

command="${1:-}"

case "$command" in
    update) save_all_menus 10 ;;
    list)   column -t -s$'\t' locations.txt ;;
    hours)  show_all_hours "${2:-$(date +%F)}" ;;
    day)    show_day "${2:-$(date +%F)}" ;;
    show)
        [ -n "${2:-}" ] || { usage; exit 1; }
        show_menu "$2" "${3:-$(date +%F)}"
        ;;
    *)      usage ;;
esac
