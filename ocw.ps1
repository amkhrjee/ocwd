<# 
    Fetches courses from MIT OCW
#>

# we only need the first occuence for our use case
function Show-Error($msg){
    Write-Host $msg -ForegroundColor DarkRed
}
function Get-Details{
    #shows the details of the course
    $titlePattern = '<title>(?<title>.*)</title>'
   
    if($webResponse.Content -match $titlePattern){ 
        $titleName = $Matches.title -split "\|" #split expects a RE
        Write-Host "▶️Course Name:" $titleName[0]
        
    } else {
        Show-Error("Title Not Found")
    }
    # Don't touch this!
    $instructorPattern = '<a class="course-info-instructor strip-link-offline"  href=".*">(?<instructor>.*)</a>'
   
    if($webResponse.Content -match $instructorPattern){
        Write-Host "▶️Instructor:" $Matches.instructor
    }else{
        Show-Error("Instructor Not Found")
    }

    $otherPattern = '<span class="course-number-term-detail">(?<other>.*)</span>'
    if($webResponse.Content -match $otherPattern){ 
        $otherDetails = $Matches.other -split "\|"
        Write-Host "▶️Course ID:" $otherDetails[0]
        Write-Host "▶️Course Semester:" $otherDetails[1]
        Write-Host "▶️Course Level:" $otherDetails[2]
    }
}

$link =  Read-Host "Enter the OCW url"
if ($link -match 'https://ocw\.mit\.edu/courses') {
    try{   
        $webResponse = Invoke-WebRequest -Uri $link
        Write-Host "⚡Course Found" -ForegroundColor DarkGreen #make this more useful
        Write-Host ":::::::::::::::::::::::::::::::::::"
        Get-Details
    }catch{
        $StatusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Error: Exited with error code" $StatusCode -ForegroundColor Red
    }
 
} else {
    Write-Host "Error: Invalid link" -ForegroundColor Red
    Write-Host "Please enter a link that starts with `"https://ocw.mit.edu/courses/"`" -ForegroundColor DarkRed
}
