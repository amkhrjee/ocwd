#!/usr/bin/bash

show_details() {
    echo "╰(*°▽°*)╯ Course Found"
    echo ":::::::::::::::::::::::::::::::::::"
    # Title
    titleLine=$(echo "$1" | grep '<title>')
    titleLine=$(awk '{$1=$1};1' <<<"$titleLine")
    titleLine=$(echo "$titleLine" | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p')
    title=$(awk -F "|" '{print $1}' <<<"$titleLine")
    echo "- Title: $title"

    # Instructor
    instructorLine=$(echo "$1" | grep -m 1 '<a class="course-info-instructor strip-link-offline"  href=".*">')
    instructorLine=$(awk '{$1=$1};1' <<<"$instructorLine")
    instructorLine=$(echo "$instructorLine" | sed -n 's/.*<a[^>]*>\(.*\)<\/a>.*/\1/p')
    echo "- Instructor: $instructorLine"
}

if [ $# -eq 0 ]; then
    echo "ocwd Copyright (C) 2023 Aniruddha Mukherjee"
    echo "This program comes with ABSOLUTELY NO WARRANTY"
    echo "This is free software, and you are welcome to redistribute it under certain conditions"
    echo ""
    read -rep "Please enter the link to course homepage: " link
fi
if [ $# -eq 1 ]; then
    link="$1"
fi
if [ $# -gt 1 ]; then
    echo "E: More than one argument passed"
    echo "Usage: ocwd <link>"
    exit
fi

# trims the link
link=$(awk '{$1=$1};1' <<<"$link")

if [[ $link == "https://ocw.mit.edu/courses/"* ]]; then
    http_status=$(wget --spider --server-response "$link" 2>&1 | awk '/HTTP\/1.1/{print $2}' | tail -1)
    if [ "$http_status" -eq 200 ]; then
        pageHtml=$(wget "$link" -q -O -)
        show_details "$pageHtml"
    fi
fi
