<#PSScriptInfo

.VERSION 2.4.2

.GUID a31639e2-a8ab-4a29-9fed-66d5b5f9e1e9

.AUTHOR Aniruddha Mukherjee

.COMPANYNAME

.SYNOPSIS Downloads resources from the MIT OpenCourseWare repository

.EXAMPLE ocwd <link to a course homepage>

.COPYRIGHT (C) Aniruddha Mukherjee 2023

.TAGS PSEdition_Core Windows PSEdition_Desktop Linux MacOS

.LICENSEURI https://www.gnu.org/licenses/gpl-3.0.en.html

.PROJECTURI https://github.com/amkhrjee/ocwd

.ICONURI https://i.imgur.com/1eklM2i.png

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES Last edited: 5 Jan 2023

.PRIVATEDATA

.DESCRIPTION Downloads MIT OCW course resources 

#>

Param(
    [Parameter(HelpMessage = "The URL to a course homepage")]
    $link
)
$platform = $PSVersionTable.Platform
if ($platform -eq 'Unix') { $slash = '/' } else { $slash = '\' } 

$patterns = @{
    titlePattern             = '<title>(?<title>.*)</title>'
    instructorPattern        = '<a class="course-info-instructor strip-link-offline"  href=".*">(?<instructor>.*)</a>'
    additionalDetailsPattern = '<span class="course-number-term-detail">(?<other>.*)</span>'
}
function Show-Error($msg) {
    Write-Host "Error:" $msg -ForegroundColor Red
}

function Show-Instruction($msg) {
    Write-Host $msg -ForegroundColor Blue
}

function Show-Exception($msg) {
    Write-Host $msg -ForegroundColor DarkRed  
}

function Get-Details {
    if ($webResponse.Content -match $patterns['titlePattern']) { 
        $titleName = ($Matches.title -split "\|")[0] #split expects a RE
    }
    else {
        $titleName = "Title not found"
    }
    if ($webResponse.Content -match $patterns['instructorPattern']) {
        $instructorName = $Matches.instructor
    }
    else {
        $instructorName = "Instructor not found"
    }
    return @($titleName, $instructorName)
}


function Show-Details ($detailsList) {
    Write-Host "- Title:" $detailsList[0]
    Write-Host "- Instructor:" $detailsList[1] 
}

function Get-AdditionalDetails {
    if ($webResponse.Content -match $patterns['additionalDetailsPattern']) {
        return $Matches.other -split "\|" 
    }
    else {
        return @("Course ID not found", 
            "Course Semester not found.", 
            "Course Level not found.")
    }
}

function Show-AdditonalDetails($additionalDetails) {
    Write-Host "- ID:" $additionalDetails[0]
    Write-Host "- Semester:" $additionalDetails[1]
    Write-Host "- Level:" $additionalDetails[2]
}
function Set-ResourceList($downloadsPagelink) {
    try {
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
    catch {
        Show-Error("Unable to load resource list")
    }
}
function Show-Resources {
    if ($resList.Length -ne 0) {
        Write-Host "::::::::::::::::::::::::::::::::"
        if ($PSVersionTable.PSEdition -eq 'Desktop') {

            Write-Host "--------Resources Available--------" -ForegroundColor Green
        }
        else {
            Write-Host "╰(*°▽°*)╯ Resources Available" -ForegroundColor Green
        }
        Write-Host "::::::::::::::::::::::::::::::::"   
        $index = 0
        foreach ($res in $resList) {
            Write-Host ($index += 1) $res 
        }
    }
    else {
        Write-Host ":(" -ForegroundColor Red
        Write-Host "No resources found!" -ForegroundColor Red
        Show-Instruction("Please try downloading manually.")
        Exit
    }
}

function Get-Options {
    Write-Host "Enter the index of the desired resource for download"  -ForegroundColor Cyan
    Write-Host "=>Use commas for multiple indices"  -ForegroundColor Gray
    Write-Host "=>Enter A for downloading all resources" -ForegroundColor Gray
    Write-Host "=>Example: 1,2"
    $userInputs = Read-Host "Input"
    switch ($userInputs.Length) {
        0 {
            throw "Input cannot be empty"
        }
        1 {
            if (($userInputs -ne 'a') -or ($userInputs -ne 'A')) {
                if (([System.Convert]::ToDecimal($userInputs) -lt 1) -or ([System.Convert]::ToDecimal($userInputs) -gt $resList.Length)) {
                    throw "Invalid index"
                }
            }
            elseif (($userInputs -eq 'a') -or ($userInputs -eq 'A')) {
                return 'all'
            }
        }
        2 {
            throw "Invalid index"
        }
        Default {
            $targetIndices = @()
            $userInputs = $userInputs -split ','
            foreach ($userInput in $userInputs) {
                if (([System.Convert]::ToDecimal($userInput) -lt 0) -or ([System.Convert]::ToDecimal($userInput) -gt $resList.Length)) {
                    throw "One or more of the indices invalid"
                }
                $targetIndices += ($userInput - 1)
        
            }
            return $targetIndices
        }
    }
    return $userInputs - 1
}

function Get-Path {
    Write-Host "Enter the download path: " -ForegroundColor Cyan
    Write-Host "=>Example: C:\Users\john\OneDrive\Desktop"
    $inputPath = Read-Host "Input" 
    if ($inputPath.Length -eq 0) {
        throw "Path cannot be empty string"
    }
    return $inputPath
}

function Get-Response {
    try {
        $userInputs = Get-Options
    }
    catch {
        Show-Error($_.Exception.InnerException.Message)
        Exit
    }
    try {
        $inputPath = Get-Path
    }
    catch {
        Show-Error($_.Exception.Message)
        Exit
    }
    return @{
        inputPath  = $inputPath
        userInputs = $userInputs
    }
}

function Get-Files($baseUri, $dirName, $downloadPath) {
    try {
        $basePage = Invoke-WebRequest -Uri $baseUri
    }
    catch {
        Show-Exception($_.Exception.Message)
    }
    if ($dirName -match 'LVideos') {
        $downloadLinksList = $basePage.Links | Where-Object { $_.href -match '.mp4$' } | Select-Object -ExpandProperty href
    }
    else {
        $downloadLinksList = $basePage.Links | Where-Object { $_.href -match '.pdf$' } | Select-Object -ExpandProperty href
    }
    
    $files = @()
    New-Item -Path ($downloadPath + $dirName) -ItemType Directory 
    $downloadPath = $downloadPath + $dirName
    $index = 1
    if ($platform -eq 'Unix') { $regexForSlash = '/' } else { $regexForSlash = '//' }
    foreach ($downloadLink in $downloadLinksList) {
        if ($downloadLink -match '/courses/') {
            $downloadLink = 'https://ocw.mit.edu' + $downloadLink
            $extension = '.pdf'
        }
        else {
            $extension = '.mp4'
        }
        $files += @{
            Uri     = $downloadLink
            outFile = $downloadPath + $slash + ($dirName -split $regexForSlash)[1] + ' ' + ($index++) + $extension
        }
    }
    $jobs = @()
    
    if ($PSVersionTable.PSEdition -eq 'Core') {
        foreach ($file in $files) {

            $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
                $params = $using:file
                try {
                    Invoke-WebRequest @params
                }
                catch {
                    Show-Exception($_.Exception.Message)
                }
            }
        }
        Write-Host ($dirName -split $regexForSlash)[1] "downloads in progress..." -ForegroundColor DarkYellow
    
        # prevents from logging job objects on screen
        $waitJobLog = Wait-Job -Job $jobs
    
        $results = @()
        foreach ($job in $jobs) {
            $results += Receive-Job -Job $job
        }
        Write-Host  ($dirName -split $regexForSlash)[1] "downloads finished" -ForegroundColor Green
    }
    # Windows PowerShell does not support Thread Jobs
    else {
        Write-Host ($dirName -split $regexForSlash)[1] "downloads in progress..." -ForegroundColor DarkYellow
        $task = ($dirName -split $regexForSlash)[1]
        try {
            $index = 1
            foreach ($file in $files) {
                $progress = [System.Convert]::ToInt16((($index++) / $files.Length) * 100)
                Write-Progress -Activity "$task Downloading" -Status "$progress% complete" -PercentComplete $progress
                Invoke-WebRequest $file['Uri'] -OutFile $file['outFile']    
            }
            Write-Host  ($dirName -split $regexForSlash)[1] "downloads finished" -ForegroundColor Green
        }
        catch {
            Show-Exception($_.Exception.Message)
        }
    }
}

function Get-LVideos($downloadPath) {
    try {
        Get-Files ($link + 'resources/lecture-videos/') ($slash + 'LVideos') $downloadPath
    }
    catch {
        Show-Error("Error in dowloading Lecture Videos")
        Show-Exception($_.Exception.Message)
    }
}

function Get-Assignments($downloadPath) {
    try {
        Get-Files ($link + 'resources/assignments/') ($slash + 'Assignments') $downloadPath
    }
    catch {
        Show-Error("Error in downloading Assignments")
        Show-Exception($_.Exception.Message)
    }
}

function Get-Exams($downloadPath) {
    try {
        Get-Files ($link + 'resources/exams/') ($slash + 'Exams') $downloadPath
    }
    catch {
        Show-Error("Error in downloading Exams")
        Show-Exception($_.Exception.Message)
    }
}

function Get-LNotes($downloadPath) {
    try {
        Get-Files ($link + 'resources/lecture-notes/') ($slash + 'LNotes') $downloadPath
    }
    catch {
        Show-Error('Error in downloading LNotes')
        Show-Exception($_.Exception.Message)
    }
} 

function Import-Resoruces($userResponse) {
    $downloadPath = $userResponse['inputPath']
    if ($userResponse['userInputs'] -eq 'all') {
        # download everything that is in the resList
        foreach ($res in $resList) {
            switch ($res) {
                'Lecture Videos' {
                    Write-Host "Downloading Lecture Videos..." -ForegroundColor Yellow
                    Get-LVideos($downloadPath)
                }
                'Assignments' {
                    Write-Host "Downloading Assignments..." -ForegroundColor Yellow
                    Get-Assignments($downloadPath)
                }
                'Exams' {
                    Write-Host "Downloading Exams..." -ForegroundColor Yellow
                    Get-Exams($downloadPath)
                }
                'Lecture Notes' {
                    Write-Host "Download Lecture Notes..." -ForegroundColor Yellow
                    Get-LNotes($downloadPath)
                }
            }
        }
    }
    else {
        foreach ($index in $userResponse['userInputs']) {
            switch ($resList[$index]) {
                'Lecture Videos' {
                    Write-Host "Downloading Lecture Videos..." -ForegroundColor Yellow
                    Get-LVideos($downloadPath)
                }
                'Assignments' {
                    Write-Host "Downloading Assignments..." -ForegroundColor Yellow
                    Get-Assignments($downloadPath)
                }
                'Exams' {
                    Write-Host "Downloading Exams..." -ForegroundColor Yellow
                    Get-Exams($downloadPath)
                }
                'Lecture Notes' {
                    Write-Host "Downloadng Lecture Notes..." -ForegroundColor Yellow
                    Get-LNotes($downloadPath)
                }
            }
        }
    }
}

# driver
if ($link.Length -eq 0 ) {
    Write-Host "ocwd Copyright (C) 2023 Aniruddha Mukherjee"
    Write-Host "This program comes with ABSOLUTELY NO WARRANTY"
    Write-Host "This is free software, and you are welcome to redistribute it under certain conditions"
    Write-Host " "
    $link = Read-Host "Enter the URL to course homepage"
}
$link = $link.Trim()

if ($link -match 'https://ocw\.mit\.edu/courses') {
    try {   
        $webResponse = Invoke-WebRequest -Uri $link
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        if ($StatusCode.Length -eq 0) { $StatusCode = 502 }
        $StatusCode = [System.Convert]::ToDecimal($StatusCode)
        Show-Error("Exited with error code $StatusCode")
        if (($StatusCode -ge 300) -and ($StatusCode -lt 400)) {
            Show-Error("The URL provided does not exist")
        }
        elseif (($StatusCode -ge 400) -and ($StatusCode -lt 600)) {
            Show-Error("Invalid URL or No internet")
        }
        Exit
    }
    if ($PSVersionTable.PSEdition -eq 'Desktop') {

        Write-Host "--------Course Found--------" -ForegroundColor DarkGreen #make this more useful
    }
    else {
        Write-Host "╰(*°▽°*)╯ Course Found" -ForegroundColor DarkGreen #make this more useful
    }
    Write-Host ":::::::::::::::::::::::::::::::::::"
    $details = Get-Details
    Show-Details($details)
    $additionalDetails = Get-AdditionalDetails
    Show-AdditonalDetails($additionalDetails)

    if ($link -match '/$') { $downloadsPagelink = $link + 'download/' } 
    else { $downloadsPagelink = $link + '/download/' }
    try {

        $resList = Set-ResourceList($downloadsPagelink)
        Show-Resources
    }
    catch {
        Show-Error($_.Exception.InnerException.Message)
        Exit
    }
    $userResponse = Get-Response
    try {

        Import-Resoruces($userResponse)
        Invoke-Item $userResponse['inputPath']
    }
    catch {
        Show-Exception($_.Exception.Message)
    }
    
 
}
else {
    Show-Error("Invalid URL")
    Show-Instruction("Please enter a link that starts with `"https://ocw.mit.edu/courses/`"")
}