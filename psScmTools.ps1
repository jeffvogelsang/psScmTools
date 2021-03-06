﻿# psScmTools.ps1

function getSCMString {

    $scmString = ""
    if((isGitValid) -and (getGitStats)) { $scmString+= "[git;$(getGitBranch);$(getGitStats)] " }
    if((isMercurialValid) -and (getMercurialStats)) { $scmString+= "[hg;$(getMercurialBranch);$(getMercurialStats)] " }
    if((isSubversionValid) -and (getSubversionStats)) { $scmString+= "[svn;$(getSubversionBranch);$(getSubversionStats)] " }
    $scmString
}

# Git Functions

function isGitAvailable {
    try { Get-Command "git" -EA Stop } catch { $false }
}

function isGitValid {

   if ( isGitAvailable )
   {
       $gitVersion = Invoke-Expression "git --version 2>&1"
       if($gitVersion -match "git version")
       { return $gitVersion }
       else
       { return $false }
   }
   else { $false }
}       

function isGitValidString {

    if( isGitValid ) { "git+" } else { "git-" }
}

function getGitBranch {

    $gitBranches = Invoke-Expression "git branch 2>&1"
    if($gitBranches -match "fatal:") { return $false }
    
    if($gitBranches) {
        foreach ($branch in $gitBranches)
        {
            if($branch.Substring(0,2).Equals("* "))
            {
                return "$($branch.Substring(2,$branch.Length-2))"
            }
        }    
    }
    else { return "n/a" }
}

function getGitStats {

    $gitStatus = Invoke-Expression "git status --porcelain 2>&1"
    if($gitStatus -match "fatal:") { return $false }

    $modified=$added=$deleted=$renamed=$copied=$upnomerge=$notTracked=0
    if($gitStatus) {
        foreach( $item in $gitStatus )
        {
            if( $item -match "( M )" ) { $modified++ }
            if( $item -match "( A )" ) { $added++ }
            if( $item -match "( D )" ) { $deleted++ }
            if( $item -match "( R )" ) { $renamed++ }
            if( $item -match "( C )" ) { $copied++ }
            if( $item -match "( U )" ) { $upnomerge++ }
            if( $item -match "(\?\? )" ) { $notTracked++ }
        }
    }
    return "$($modified)m,$($added)a,$($deleted)d,$($renamed)r,$($copied)c,$($upnomerge)u,$($notTracked)?"
}

# Mercurial Functions

function isMercurialAvailable {

    try { Get-Command "hg" -EA Stop } catch { $false }
}

function isMercurialValid {

   if ( isMercurialAvailable )
   {
       $mercurialVersion = Invoke-Expression "hg --version 2>&1"
       if($mercurialVersion -match "Mercurial Distributed SCM \(version")
       { return $mercurialVersion }
       else
       { return $false}
   }
   else { return $false }
}

function isMercurialValidString {
    if(isMercurialValid) { "hg+" } else { "hg-" }
}

function getMercurialBranch {

    if(isMercurialValid) {
        $mercurialBranch = Invoke-Expression "hg branch 2>&1"
        if($mercurialBranch -match "abort:") { return $false }
    }
    else { return $false }
    
    if($mercurialBranch) { return $mercurialBranch }
    else { return "n/a" }    
}

function getMercurialStats {

    $mercurialStatus = Invoke-Expression "hg status 2>&1"
    if($mercurialStatus -match "abort:") { return $false }

    $modified=$added=$removed=$notTracked=$missing=0

    if($mercurialStatus) {
        foreach( $item in $mercurialStatus )
        {
            if( $item -match "(M )" ) { $modified++ }
            if( $item -match "(A )" ) { $added++ }
            if( $item -match "(D )" ) { $removed++ }
            if( $item -match "(\? )" ) { $notTracked++ }
            if( $item -match "(! )" ) { $missing++ }
        }
    }
    return "$($modified)m,$($added)a,$($removed)r,$($notTracked)?,$($missing)!"
}

# Subversion Functions

function isSubversionAvailable {

    try { Get-Command "svn" -EA Stop } catch { $false }
}

function isSubversionValid {

   if ( isSubversionAvailable ) {
       $subversionVersion = Invoke-Expression "svn --version 2>&1"
       if($subversionVersion -match "svn, version" -and $subversionVersion -match "Subversion")
       { return $subversionVersion }
       else
       { return $false }
   }
   else { $false }
}

function isSubversionValidString {

    if(isSubversionValid) { "svn+" } else { "svn-" }
}

function getSubversionBranch {

    $test = Invoke-Expression "svn info 2>&1"
    if($test -match "svn: '.' is not a working copy") { return $false }

    [xml] $svnInfoXml = Invoke-Expression "svn info --xml 2>&1"

    $rootUrl = $svnInfoXml.info.entry.repository.root
    $url =$svnInfoXml.info.entry.url

    if(!$rootUrl.Equals($url))
    {
        # Walk from the end of the path back to the base, looking for conventional directories.
        $relativePaths = $url.Substring($rootUrl.Length+1,$url.Length-$rootUrl.Length-1).Split("/")
        for ($pathNum=$relativePaths.Length-1; $pathNum -ge $false ; $pathNum--)
        {
            if($relativePaths[$pathNum].Equals("trunk"))
            {
                return "trunk"
            }
            elseif($relativePaths[$pathNum].Equals("branches") -and $pathNum -lt $relativePaths.Length-1)
            {
                return "branch:" + $relativePaths[$pathNum+1]
            }
            elseif($relativePaths[$pathNum].Equals("tags") -and $pathNum -lt $relativePaths.Length-1)
            {
                return "tag:" + $relativePaths[$pathNum+1]
            }
        }
    }

    return "n/a"
}

function getSubversionStats {

    $test = Invoke-Expression "svn status 2>&1"
    if($test -match "svn: warning: '.' is not a working copy") { return $false }

    [xml] $svnStatusXml = Invoke-Expression "svn status --xml 2>&1"
    
    $added=$deleted=$modified=$unversioned=$missing=0
    if($svnStatusXml.status.target.entry) {
        foreach( $entry in $svnStatusXml.status.target.entry )
        { 

            if( $entry.'wc-status'.item.Equals("added") ) { $added++ }
            if( $entry.'wc-status'.item.Equals("deleted") ) { $deleted++ }
            if( $entry.'wc-status'.item.Equals("modified") ) { $modified++ }
            if( $entry.'wc-status'.item.Equals("unversioned") ) { $unversioned++ }
            if( $entry.'wc-status'.item.Equals("missing") ) { $missing++ }
            
        }
    }
    return "$($modified)m,$($added)a,$($deleted)d,$($unversioned)?,$($missing)!"
}