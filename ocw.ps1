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

function Set-ResourceList($downloadsPagelink) {
    $downloadPage = Invoke-WebRequest -Uri $downloadsPagelink
    $keys = 'Lecture Videos', 'Assignments', 'Exams', 'Lecture Notes'
    $resourceList = @()
    foreach ($key in $keys) {
        if ($downloadPage.Content -match $key) {
            $resourceList += $key
        }
    }
    return $resourceList
}
function Show-Resources {
    # shows what resources are available for download
    Write-Host "::::::::::::::::::::::::::::::::"
    Write-Host "⚡Resources Available" -ForegroundColor Green
    Write-Host "::::::::::::::::::::::::::::::::"
    try {
        $index = 0
        foreach ($res in $resList) {
            Write-Host ($index += 1) $res 
        }
    }
    catch {
        Write-Error "Error in fetching resources"      
    }
}

# Gets the input from the user
function Get-Path {
    Write-Host "Enter the download path: " -ForegroundColor Cyan
    Write-Host "Example: C:\Users\john\OneDrive\Desktop" -ForegroundColor DarkCyan
    $downloadPath = Read-Host "➡️"
    return $downloadPath
}

function Get-Response() {
    Write-Host "Enter the index of the desired resource for download"  -ForegroundColor Cyan
    Write-Host "💡Use commas for multiple indices"  -ForegroundColor Gray
    Write-Host "💡Enter A for downloading all resources" -ForegroundColor Gray
    Write-Host "🪶 Example: 1,2"
    $userInputs = Read-Host "➡️"
    $target = Confirm-Response($userInputs)
    $downloadPath = Get-Path
    Import-Resoruces($target, $downloadPath)
}

function Confirm-Response($userInputs) {
    switch ($userInputs.Length) {
        0 {
            Show-Error("Input cannot be empty")
            Get-Response
        }
        1 {
            if (($userInputs -eq 'A') -or ($userInputs -eq 'a')) {
                return 999
            }
            else {
                if (($userInputs -lt 0) -or ($userInputs -gt $resList.Length)) {
                    Write-Error "Invalid Index"
                    Get-Response
                    break
                }
                return ($userInputs - 1)
            }
        }
        Default {
            $targetIndices = @()
            $userInputs = $userInputs -split ','
            foreach ($userInput in $userInputs) {
                if (($userInput -lt 0) -or ($userInput -gt $resList.Length)) {
                    Write-Error "Invalid Index"
                    Get-Response
                    break
                }
                $targetIndices += ($userInput - 1)
            }
            return $targetIndices
        }
    }
}

function Import-Resoruces($target, $downloadPath) {
    if ($target -eq 999) {
        # download everything that is in the resList
        foreach ($res in $resList) {
            switch ($res) {
                'Lecture Videos' {
                    Write-Host "Download Lecture Videos"
                }
                'Assignments' {
                    Write-Host "Download Assignments"
                }
                'Exams' {
                    Write-Host "Download Exams"
                }
                'Lecture Notes' {
                    Write-Host "Download Lecture Notes"
                }
            }
        }
    }
    else {
        foreach ($index in $target) {
            switch ($resList[$index]) {
                'Lecture Videos' {
                    Write-Host "Download Lecture Videos"
                }
                'Assignments' {
                    Write-Host "Download Assignments"
                }
                'Exams' {
                    Write-Host "Exams"
                }
                'Lecture Notes' {
                    Write-Host "Download Lecture Notes"
                }
            
            }
        }
    }
}


function Get-Files($baseUri, $dirName, $downloadPath) {
    $basePage = Invoke-WebRequest -Uri $baseUri
    # Thanks to Emanuel Palm -> "https://pipe.how/invoke-webscrape/#parsing-data"
    $AllMatches = ($basePage.Content | Select-String '<a href="(?<downloadLink>.*)" target="_blank" download>' -AllMatches).Matches
    $downloadLinksList = ($AllMatches.Groups.Where{ $_.Name -like 'downloadLink' }).Value
    $files = @()
    New-Item -Path ($downloadPath + $dirName) -ItemType Directory 
    $downloadPath = $downloadPath + $dirName
    foreach ($downloadLink in $downloadLinksList) {
        $files += @{
            Uri     = $downloadLink
            outFile = $downloadPath + '\' + ($downloadLink -split '/')[5]
        }
    }
        
    $jobs = @()

    foreach ($file in $files) {
        $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
            $params = $using:file
            Invoke-WebRequest @params
        }
    }

    Write-Host ($dirName -split '\')[1] "Downloads started..."
    Wait-Job -Job $jobs

    foreach ($job in $jobs) {
        Receive-Job -Job $job
        
    }
}
function Get-LVideos($downloadPath) {
    try {
        Get-Files($link + 'resources/lecture-videos/', '\LVideos', $downloadPath)
    }
    catch {
        Show-Error("Error in dowloading Lecture Videos")
    }
}
function Get-Assignments($downloadPath) {
    try {
        Get-Files($link + 'resources/assignments/', '\Assignments', $downloadPath)
    }
    catch {
        Show-Error("Error in downloading Assignments")
    }
}
function Get-Exams($downloadPath) {
    try {
        Get-Files($link + 'resources/exams/', '\Exams', $downloadPath)
    }
    catch {
        Show-Error("Error in downloading Exams")
    }
}
function Get-LNotes($downloadPath) {
    try {
        Get-Files($link + 'resources/lecture-notes/', '\LNotes', $downloadPath)
    }
    catch {
        Show-Error('Error in downloading LNotes')
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
        $downloadsPagelink = $link + 'download/'
        $resList = Set-ResourceList($downloadsPagelink)
        Show-Resources
        Get-Response
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
