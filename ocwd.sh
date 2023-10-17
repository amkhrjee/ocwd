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
    http_status=$(wget --spider --server-response "$downloadPageLink" 2>&1 | awk '/HTTP\/1.1/{print $2}' | tail -1)
    if [ "$http_status" -eq 200 ]; then
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
    else
        echo "E: Error $http_status, could not fetch reosources"
        exit 1
    fi
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
                index=0
                for item in "${resourceList[@]}"; do
                    targetKeys["$index"]="$item"
                    ((index++))
                done
                correctInputFlag=1
            else
                if ((option > 0 && option <= ${#resourceList[@]})); then
                    resourceIndex=$((option - 1))
                    targetKeys["0"]="${resourceList["$resourceIndex"]}"
                    correctInputFlag=1
                else
                    echo "E: Invalid Index"
                fi
            fi
            ;;
        2) echo "E: Invalid Index" ;;
        *)
            if [[ $option == 'All' || $option == 'all' ]]; then
                index=0
                for item in "${resourceList[@]}"; do
                    targetKeys["$index"]="$item"
                    ((index++))
                done
                correctInputFlag=1
            else
                IFS=',' read -ra temptargetKeys <<<"$option"
                index=0
                for element in "${temptargetKeys[@]}"; do
                    if ((element > 0 && element <= ${#resourceList[@]})); then
                        resourceIndex=$((element - 1))
                        targetKeys["$index"]="${resourceList["$resourceIndex"]}"
                        ((index++))
                        correctInputFlag=1
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

get_files() {
    http_status=$(wget --spider --server-response "$1" 2>&1 | awk '/HTTP\/1.1/{print $2}' | tail -1)
    if [ "$http_status" -eq 200 ]; then
        basePageHtml=$(wget "$1" -q -O -)
        downloadUrls=$(echo "$basePageHtml" | grep -Eo 'href="[^"]+"')
        downloadUrls=$(echo "$downloadUrls" | grep -o '"[^"]\+"')
        downloadUrls=$(echo "$downloadUrls" | grep -oE '/[^"]+')

        if [[ $2 =~ 'LVideos' ]]; then
            downloadUrls=$(echo "$downloadUrls" | grep '.mp4$')
            extension=".mp4"
        else
            downloadUrls=$(echo "$downloadUrls" | grep '.pdf$')
            extension=".pdf"
        fi
        # echo "$downloadUrls"

        # Converting the multi-line variable into a list
        downloadUrlList=()
        while IFS= read -r url; do
            downloadUrlList+=("$url")
        done <<<"$downloadUrls"

        baseLink="https://ocw.mit.edu"

        # the following part deals with downloads
        index=1
        mkdir -p "$2/"
        if [ $? -eq 0 ]; then
            echo "Directory '$2' created successfully."
        else
            echo "E: Failed to create directory '$2'."
        fi
        echo "How would you like the files to be downloded?"
        echo "1. Serially (one after another)"
        echo "2. Parallely (multiple files simultaneusly)"

        correctFlag=0
        while [ "$correctFlag" -eq 0 ]; do
            read -rep "Input (1 or 2): " downloadOption
            case "$downloadOption" in
            "1")
                correctFlag=1
                # serial download
                for url in "${downloadUrlList[@]}"; do
                    filename=$(basename "$2")
                    wget -q -O "./$2/$filename$index$extension" "$baseLink$url"
                    ((index++))
                done
                ;;
            "2")
                correctFlag=1
                # parallel download
                for url in "${downloadUrlList[@]}"; do
                    filename=$(basename "$2")
                    wget -q -O "./$2/$filename$index$extension" "$baseLink$url" &
                    ((index++))
                done
                wait
                ;;
            *) echo "E: The only valid inputs are 1 & 2" ;;
            esac
        done
    else
        echo "E: Error $http_status, could not load $1"
    fi
}

get_resources() {
    if [[ ! $link =~ /$ ]]; then
        link="$link/"
    fi
    # Take directory path for the download
    echo "Enter directory name or path (will be created if doesn't exist)"
    echo "=>Example: IntroToAlgorithms"
    echo "=>Example: courses/IntroToAlgorithms"
    read -rep "Input: " inputPath
    if [[ ! $inputPath =~ /$ ]]; then
        inputPath="$inputPath/"
    fi
    for element in "${targetKeys[@]}"; do
        case "$element" in
        'Lecture Videos')
            echo "✨ Fetching Lecture Videos"
            augmentLink="resources/lecture-videos/"
            directoryTitle="LVideos"
            get_files "$link$augmentLink" "$inputPath$directoryTitle"
            ;;
        'Assignments')
            echo "✨ Fetching Assignments"
            augmentLink="resources/assignments/"
            directoryTitle="Assignments"
            get_files "$link$augmentLink" "$inputPath$directoryTitle"
            ;;
        'Exams')
            echo "✨ Fetching Exams"
            augmentLink="resources/exams/"
            directoryTitle="Exams"
            get_files "$link$augmentLink" "$inputPath$directoryTitle"
            ;;
        'Lecture Notes')
            echo "✨ Fetching Lecture Notes"
            augmentLink="resources/lecture-notes/"
            directoryTitle="LNotes"
            get_files "$link$augmentLink" "$inputPath$directoryTitle"
            ;;
        *) echo "E: Invalid type of resource" ;;
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
    exit 1
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
        targetKeys=()
        get_options
        get_resources
    else
        echo "E: Error $http_status, could not parse website"
        exit 1
    fi
fi
