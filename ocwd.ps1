<#PSScriptInfo

.VERSION 1.1.1

.GUID a31639e2-a8ab-4a29-9fed-66d5b5f9e1e9

.AUTHOR Aniruddha Mukherjee

.COMPANYNAME

.COPYRIGHT Aniruddha Mukherjee

.TAGS PSEdition_Core Windows

.LICENSEURI https://www.gnu.org/licenses/gpl-3.0.en.html

.PROJECTURI https://github.com/amkhrjee/ocwd

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES Improved RegEx logic


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Downloads MIT OCW course resources 

#> 
Param(
    [Parameter(HelpMessage = "The URL to a course homepage")]
    $link
)
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
        Write-Host "Error in loading resouce list" -ForegroundColor Red
    }
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

function Get-Response() {
    Write-Host "Enter the index of the desired resource for download"  -ForegroundColor Cyan
    Write-Host "💡Use commas for multiple indices"  -ForegroundColor Gray
    Write-Host "💡Enter A for downloading all resources" -ForegroundColor Gray
    Write-Host "🪶 Example: 1,2"
    $userInputs = Read-Host "➡️"
    $target = Confirm-Response($userInputs)
    try {
        Write-Host "Enter the download path: " -ForegroundColor Cyan
        Write-Host "🪶Example: C:\Users\john\OneDrive\Desktop"
        $downloadPath = Read-Host "➡️"
    }
    catch {
        Show-Error("Invalid path")
    }
  
    Import-Resoruces $target $downloadPath
    Invoke-Item $downloadPath
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
                    Write-Host "Invalid Index" -ForegroundColor Red
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
                    Write-Host "Invalid Index" -ForegroundColor Red
                    Get-Response
                    break
                }
                $targetIndices += ($userInput - 1)
            }
            return $targetIndices
        }
    }
}

function Get-Files($baseUri, $dirName, $downloadPath) {
    $basePage = Invoke-WebRequest -Uri $baseUri
    switch ($dirName) {
        '\LVideos' {
            $downloadLinksList = $basePage.Links | Where-Object { $_.href -match '.mp4$' } | Select-Object -ExpandProperty href
        }
        Default {
            $downloadLinksList = $basePage.Links | Where-Object { $_.href -match '.pdf$' } | Select-Object -ExpandProperty href
        }
    }
    Write-Host $downloadLinksList    
    $files = @()
    New-Item -Path ($downloadPath + $dirName) -ItemType Directory 
    $downloadPath = $downloadPath + $dirName
    $index = 1
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
            outFile = $downloadPath + '\' + ($dirName -split '\\')[1] + ' ' + ($index++) + $extension
        }
    }
    $jobs = @()
    foreach ($file in $files) {
        $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
            $params = $using:file
            Invoke-WebRequest @params
        }
    }

    Write-Host ($dirName -split '\\')[1] "downloads in progress..." -ForegroundColor DarkYellow
    
    $waitJobLog = Wait-Job -Job $jobs

    $results = @()
    foreach ($job in $jobs) {
        $results += Receive-Job -Job $job
    }
    Write-Host  ($dirName -split '\\')[1] "downloads finished" -ForegroundColor Green
}
function Get-LVideos($downloadPath) {
    try {
        Get-Files ($link + 'resources/lecture-videos/') '\LVideos' $downloadPath
    }
    catch {
        Show-Error("Error in dowloading Lecture Videos")
    }
}
function Get-Assignments($downloadPath) {
    try {
        Get-Files ($link + 'resources/assignments/') '\Assignments' $downloadPath
    }
    catch {
        Show-Error("Error in downloading Assignments")
    }
}
function Get-Exams($downloadPath) {
    try {
        Get-Files ($link + 'resources/exams/') '\Exams' $downloadPath
    }
    catch {
        Show-Error("Error in downloading Exams")
    }
}
function Get-LNotes($downloadPath) {
    try {
        Get-Files ($link + 'resources/lecture-notes/') '\LNotes' $downloadPath
    }
    catch {
        Show-Error('Error in downloading LNotes')
    }
} 


function Import-Resoruces($target, $downloadPath) {
    if ($target -eq 999) {
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
        foreach ($index in $target) {
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
    Write-Host "ocwd Copyright (C) 2022 Aniruddha Mukherjee"
    Write-Host "This program comes with ABSOLUTELY NO WARRANTY"
    Write-Host "This is free software, and you are welcome to redistribute it under certain conditions"
    Write-Host " "
    $link = Read-Host "Enter the URL to course homepage"
}
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
        if ($StatusCode.Length -eq 0) { $StatusCode = 502 }
        $StatusCode = [System.Convert]::ToDecimal($StatusCode)
        Write-Host "Error: Exited with error code $StatusCode" -ForegroundColor Red
        if (($StatusCode -ge 300) -and ($StatusCode -lt 400)) {
            Write-Host "The URL provided does not exist" -ForegroundColor Red
        }
        elseif (($StatusCode -ge 400) -and ($StatusCode -lt 600)) {
            Write-Host "Please check your internet connection and try again" -ForegroundColor Red
        }
    }
 
}
else {
    Write-Host "Error: Invalid link" -ForegroundColor Red
    Write-Host "Please enter a link that starts with `"https://ocw.mit.edu/courses/"`" -ForegroundColor DarkRed
}