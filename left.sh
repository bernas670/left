#!/bin/bash

get_progress_bar() {
    local elapsed=$1
    local left=$2

    local e_str="$(printf "\e[2m·%.0s\e[0m" $(seq 1 $elapsed))"
    local l_str="$(printf "•%.0s" $(seq 1 $left))"

    progress_bar="$e_str$l_str"
}

life_progress() {
    elapsed=$((\
        12 - $(date -d "$birthdate" +%m) + \
        12 * ($(date +%Y) - $(date -d "$birthdate" +%Y) - 1) + \
        $(date +%m)))
    total=$((83 * 12))
    left=$((total - elapsed))

    label_left="Life"
    label_right="$left months left"
}

year_progress() {
    local year=$(date +%Y)
    local current=$(date +%s)
    local start=$(date -d "$year-01-01" +%s)
    local end=$(date -d "$year-12-31" +%s)

    elapsed=$(((current - start) / 86400))
    total=$(((end - start) / 86400))
    left=$((total - elapsed))

    label_left="$year"
    label_right="$left days left"
}

month_progress() {
    elapsed=$(date +%d)
    total=$(date -d "-$(date +%d) days month" +%d)
    left=$((total - elapsed))

    label_left=$(date +%B)
    label_right="$left days left"
}

day_progress() {
    elapsed=$(($(date +%H) + 1))
    total=24
    left=$((total - elapsed))

    label_left=$(date +%A)
    label_right="$left hours left"
}

mode="year"

usage() {
    echo "Usage: $0 -m (life|year|month|day) [-b birthdate] [-h]"
    echo "  -m  Mode: life, year, month, or day (default: year)"
    echo "  -b  Birthdate in yyyy-mm-dd format (required for life mode)"
    echo "  -q  Quiet mode (only show progress bar)"
    echo "  -h  Show this help message"
}

while getopts "m:b:hq" opt; do
    case $opt in
    m) mode=$OPTARG ;;
    b) birthdate=$OPTARG ;;
    q) quiet=true ;;
    h)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

if [[ "$mode" == "life" && -z "$birthdate" ]]; then
    echo "Error: Birthdate (-b) is required for life mode."
    echo "Usage: $0 -m life -b \"yyyy-mm-dd\" [-p]"
    exit 1
fi

progress_function="${mode}_progress"
if declare -f "$progress_function" >/dev/null; then
    $progress_function
else
    echo "Invalid mode: $mode. Use one of (life|year|month|day)."
    exit 1
fi

get_progress_bar $elapsed $left

if [[ -z $quiet ]]; then
    width=$(tput cols)
    total_width=$((${#label_left} + total + ${#label_right} + 2))

    if [[ $total_width -ge $width ]]; then
        n_spaces=$(($(tput cols) - ${#label_left} - ${#label_right}))
        spaces=$(printf "%${n_spaces}s")

        printf "%b\n" "$progress_bar"
        printf "\e[1m%s\e[0m%s%s\n" "$label_left" "$spaces" "$label_right"
    else
        n_spaces=$((width - ${#label_left} - ${#label_right} - total))
        left_spaces=$((n_spaces / 2))
        right_spaces=$((n_spaces - left_spaces))
        spaces_left=$(printf "%${left_spaces}s")
        spaces_right=$(printf "%${right_spaces}s")

        printf "\e[1m%s\e[0m%s%s%s%s\n" "$label_left" "$spaces_left" "$progress_bar" "$spaces_right" "$label_right"
    fi
else
    printf "%b\n" "$progress_bar"
fi
