<# 
    Fetches courses from MIT OCW
#>
function Show-Error($msg) {
    Write-Host $msg -ForegroundColor DarkRed
}
#shows the details of the course
function Get-Details {
    $titlePattern = '<title>(?<title>.*)</title>'
   
    if ($webResponse.Content -match $titlePattern) { 
        $titleName = $Matches.title -split "\|" #split expects a RE
        Write-Host "▶️Title:" $titleName[0]
        
    }
    else {
        Show-Error("Title Not Found")
    }
    # Don't touch this!
    $instructorPattern = '<a class="course-info-instructor strip-link-offline"  href=".*">(?<instructor>.*)</a>'
   
    if ($webResponse.Content -match $instructorPattern) {
        Write-Host "▶️Instructor:" $Matches.instructor
    }
    else {
        Show-Error("Instructor Not Found")
    }

    $otherPattern = '<span class="course-number-term-detail">(?<other>.*)</span>'
    if ($webResponse.Content -match $otherPattern) { 
        $otherDetails = $Matches.other -split "\|"
        Write-Host "▶️ID:" $otherDetails[0].Trim()
        Write-Host "▶️Semester:" $otherDetails[1].Trim()
        Write-Host "▶️Level:" $otherDetails[2].Trim()
    }
}
function Get-Resources {
    # shows what resources are available for download
    $link = $link + 'download/'
    try {
        $downloadPage = Invoke-WebRequest -Uri $link
        Write-Host "::::::::::::::::::::::::::::::::"
        Write-Host "⚡Resources Available" -ForegroundColor Green
        Write-Host "::::::::::::::::::::::::::::::::"
        # $lectureVideoAvailable = $downloadPage.Content -match 'Lecture Videos'
        # $assignmentsAvailable = $downloadPage.Content -match 'Assignments'
        # $examsAvailable = $downloadPage.Content -match 'Exams'
        # $lectureNotesAvailable = $downloadPage.Content -match 'Lecture Notes'
        
        $keys = 'Lecture Videos', 'Assignments', 'Exams', 'Lecture Notes'
        $index = 0
        foreach ($key in $keys) {
            if ($downloadPage.Content -match $key) {
                Write-Host $index $key
                $index += 1
            }
        }
        Get-Response($index)
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Error: Exited with error code in download" $StatusCode -ForegroundColor Red        
    }
}

# Gets the input from the user
function Get-Response($index) {
    Write-Host "Enter the index/indices of desired resource for download (Enter A for all):" -ForegroundColor Cyan
    Write-Host "Example: 2,3,1" -ForegroundColor DarkBlue
    $userInputs = Read-Host "➡️"
    $userInputs = $userInputs -split ','
    Write-Host $userInputs
    # input sanity check
    foreach ($userInput in $userInputs) { 
        if (($userInput -gt $index) -or ($input -le 0)) {
            Show-Error("Index " + $userInput + " does not exist.")
            Get-Response($index)
        }
    }
}
# driver
$link = Read-Host "Enter the OCW url"
$link = $link.Trim()
if ($link -match 'https://ocw\.mit\.edu/courses') {
    try {   
        $webResponse = Invoke-WebRequest -Uri $link
        Write-Host "⚡Course Found" -ForegroundColor DarkGreen #make this more useful
        Write-Host ":::::::::::::::::::::::::::::::::::"
        Get-Details
        Get-Resources
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Error: Exited with error code" $StatusCode -ForegroundColor Red
    }
 
}
else {
    Write-Host "Error: Invalid link" -ForegroundColor Red
    Write-Host "Please enter a link that starts with `"https://ocw.mit.edu/courses/"`" -ForegroundColor DarkRed
}
