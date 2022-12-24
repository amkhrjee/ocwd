<# 
    Fetches courses from MIT OCW
#>
function Show-Error($msg){
    Write-Host $msg -ForegroundColor DarkRed
}
function Get-Details{
    #shows the details of the course
    $titlePattern = "<title>(?<title>.*)</title>"
    # $instructorPattern = "<a class=`"course-info-instructor strip-link-offline`">(?<instructor>.*)</a>"
    if($webResponse.Content -match $titlePattern){
        $AllMatches = ($webResponse.Content | Select-String $titlePattern -AllMatches).Matches
        foreach($match in $AllMatches){
            $title = ($match.Groups.Where{$_.Name -like 'title'}).Value
        }
        Write-Host "::Course Title::::::::::" -ForegroundColor Gray 
        Write-Host $title -ForegroundColor Green -BackgroundColor Black
        # if($webResponse.Content -match $instructorPattern){
        #     $AllMatches = ($webResponse.Content | Select-String $instructorPattern -AllMatches).Matches
        #     foreach($match in $AllMatches){
        #         $instructor = ($match.Groups.Where{$_.Name -like 'instructor'}).Value
        #     }
        #     Write-Host "::Instructor::::::::::" -ForegroundColor Gray 
        #     Write-Host $instructor -ForegroundColor Green -BackgroundColor Black
        # }else{
        #     Show-Error("Instructor Not Found")
        # }
    }
       
    else {
       Show-Error("Title Not Found")
    }
}

$link =  Read-Host "Enter the OCW url"
if ($link -match 'https://ocw\.mit\.edu/courses') {
    try{   
        $webResponse = Invoke-WebRequest -Uri $link
        Write-Host "Course Found..." -ForegroundColor DarkGreen #make this more useful
        Get-Details
    }catch{
        $StatusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Error: Exited with error code" $StatusCode -ForegroundColor Red
    }
 
} else {
    Write-Host "Error: Invalid link" -ForegroundColor Red
    Write-Host "Please enter a link that starts with `"https://ocw.mit.edu/courses/"`" -ForegroundColor DarkRed
}
