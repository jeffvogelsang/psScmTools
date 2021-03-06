﻿# psScmPrompt.ps1

function prompt
{
    # Load SCM Tools, get SCM string
    . "$(Get-Content ENV:USERPROFILE)\Documents\WindowsPowershell\psScmTools.ps1"
    $scmString = getSCMString

    # Grab Host    
    $theHost = (Get-Host).UI.RawUI
    $theHost.WindowTitle = "$(Get-Location)"

    Write-Host ""
    Write-Host "$(Get-Content ENV:USERNAME)@$(Get-Content ENV:COMPUTERNAME)" -f Green -nonewline
    Write-Host " | " -f DarkGray -nonewline
    Write-Host "$(Get-Date)" -f Green -nonewline

    if($scmString)
    {
        $theHost.WindowTitle = $theHost.WindowTitle + " $scmString"
        Write-Host " | " -f DarkGray -nonewline
        Write-Host "$($scmString)" -f yellow
    }
    else { Write-Host "" }

    # $scmPromptString += "[n/a;installed:$(isGitValidString);$(isMercurialValidString);$(isSubversionValidString)]"        
        
    $separator = ""
    for($i=0; $i -lt "$(Get-Location)".Length; $i++) { $separator+="-" }
    Write-Host "$separator" -f DarkGray       
    Write-Host "$(Get-Location)"

    return "`n> "
}