#!/usr/bin/bash

trim() {
    trimmed=$(awk '{$1=$1};1' <<<"$1")
    echo "$trimmed"
}

show_details() {
    echo "::::::::::::::::::::::::::::::::"
    echo "╰(*°▽°*)╯ Course Found"
    echo ":::::::::::::::::::::::::::::::::::"
    # Title
    titleLine=$(echo "$1" | grep '<title>')
    titleLine=$(trim "$titleLine")
    titleLine=$(echo "$titleLine" | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p')
    title=$(awk -F "|" '{print $1}' <<<"$titleLine")
    echo "- Title: $title"

    # Instructor
    instructorLine=$(echo "$1" | grep -m 1 '<a class="course-info-instructor strip-link-offline"  href=".*">')
    instructorLine=$(trim "$instructorLine")
    instructorLine=$(echo "$instructorLine" | sed -n 's/.*<a[^>]*>\(.*\)<\/a>.*/\1/p')
    echo "- Instructor: $instructorLine"
}

show_additional_details() {
    additionalDetailsLine=$(echo "$1" | grep '<span class="course-number-term-detail">')
    additionalDetailsLine=$(trim "$additionalDetailsLine")
    additionalDetails=$(echo "$additionalDetailsLine" | sed -n 's/.*<span[^>]*>\(.*\)<\/span>.*/\1/p')
    courseId=$(echo "$additionalDetails" | awk -F "|" '{print $1}')
    courseId=$(trim "$courseId")
    courseSem=$(echo "$additionalDetails" | awk -F "|" '{print $2}')
    courseSem=$(trim "$courseSem")
    courseLevel=$(echo "$additionalDetails" | awk -F "|" '{print $3}')
    courseLevel=$(trim "$courseLevel")
    echo "- ID: $courseId"
    echo "- Semester: $courseSem"
    echo "- Level: $courseLevel"
}

show_resources() {
    echo "::::::::::::::::::::::::::::::::"
    echo "╰(*°▽°*)╯ Resources Available"
    echo "::::::::::::::::::::::::::::::::"
    download="download"
    if [[ $1 =~ /$ ]]; then
        downloadPageLink="$1$download/"
    else
        downloadPageLink="$1/download/"
    fi
    downloadPageHtml=$(wget "$downloadPageLink" -q -O -)
    keys=("Lecture Videos" "Assignments" "Exams" "Lecture Notes")
    index=0
    for key in "${keys[@]}"; do
        if [[ "$downloadPageHtml" =~ $key ]]; then
            resourceList["$index"]="$key"
            ((index++))
            echo "$index. $key"
        fi
    done
}

get_options() {
    echo "Enter the index of the desired resource for download"
    echo "=>Use commas for multiple indices"
    echo "=>Enter A for downloading all resources"
    echo "=>Example: 1,2"

    correctInputFlag=0
    while [ "$correctInputFlag" -ne 1 ]; do
        read -rep "Input: " option

        case ${#option} in
        "0") echo "Input cannot be empty!" ;;
        "1")
            if [[ $option == 'a' || $option == 'A' ]]; then
                echo "You want to download everything"
                correctInputFlag=1
            else
                if ((option > 0 && option <= ${#resourceList[@]})); then
                    echo "You want to download $option"
                    correctInputFlag=1
                else
                    echo "Invalid Index"
                fi
            fi
            ;;
        2) echo "Invalid Index" ;;
        *)
            if [[ $option == 'All' || $option == 'all' ]]; then
                echo "You want to download everything"
                correctInputFlag=1
            else
                IFS=',' read -ra tempTargetIndices <<<"$option"
                index=0
                for element in "${tempTargetIndices[@]}"; do
                    if ((element > 0 && element <= ${#resourceList[@]})); then
                        targetIndices["$index"]="$element"
                        echo "You want to download $element"
                        correctInputFlag=1
                        ((index++))
                    else
                        correctInputFlag=0
                        echo "E: Invalid index: $element"
                        break
                    fi
                done
            fi

            ;;
        esac
    done

}

# Starting point

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
        show_additional_details "$pageHtml"
        resourceList=()
        show_resources "$link"
        targetIndices=()
        get_options
    fi
fi
