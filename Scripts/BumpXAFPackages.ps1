param(
    $GithubUserName = "apobekiaris",
    $GitHubToken=(Get-GithubToken),
    $XpandPath,
    $XAFPAth
)

$yaml = @"
- Name: XpandPwsh
  Version: 0.25.12
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
$VerbosePreference = "continue"



if (!$XpandPath){
    "Cloning eXpand.lab..."
    # Set-Location "C:\Users\Tolis\AppData\Local\Temp\eXpand.lab\eXpand.lab\"
    Get-XpandRepository eXpand.lab $GithubUserName $GitHubToken 
}
else{
    Set-location $XpandPath
}
$repoDir=Get-Location
$projects = Get-ChildItem  *.csproj -Recurse -Exclude *VSIX*

[DateTime]$lastBump = (git log --pretty="format:%ai$%s" | Select-String "Bump standalone packages*" | Select-Object -First 1).ToString().Split("$")[0]
$integratedModules = Get-ChildItem *.csproj -Recurse | ForEach-Object {
    [xml]$csproj = Get-Content $_.FullName
    $csproj.Project.ItemGroup.PackageReference.include | Where-Object { $_ -like "Xpand.XAF.Modules*" } | ForEach-Object {
        $_.Replace("Xpand.XAF.Modules.", "")
    }
} | Sort-Object -Unique

if (!$XAFPAth){
    "Cloning DevExpress.XAF..."
    Get-XpandRepository DevExpress.XAF $GithubUserName $GithubToken 
    try {
        git checkout lab 
    }
    catch {
        
    }
}
else{
    Set-Location $XAFPath
}
Write-host "AllLog:"
$allLog=git log --pretty="format:%ai$%s"
$allLog|Out-String

Write-host "GitLog:"
$gitLog = $allLog | Where-Object {
    [datetime]$dt = $_.ToString().Split("$")[0]
    $dt -gt $lastBump
} 
$gitLog|Out-String
If (!$gitLog -and !$XAFPAth){
    return
}
Write-host "Issues:"
$issues = ($gitLog | ForEach-Object {
        $resultlist = New-Object System.Collections.Specialized.StringCollection
        $regex = [regex] '#([\d]*)'
        $match = $regex.Match($_)
        while ($match.Success) {
            $value = $match.Groups[1].Value
            if ($value -and !($resultlist.Contains($value))) {
                $resultlist.Add($value) | Out-Null
            }
            $match = $match.NextMatch()
        } 
        $resultlist
    } | Where-Object { $_ } | Sort-Object -Unique)
$issues|Out-String
$xafissues = ($issues | ForEach-Object {
        $cred = @{
            Token =$GitHubToken
            Organization = "eXpandFramework"
        }
        $issueArgs = @{
            IssueNumber = $_ 
            Repository  = "eXpand" 
        } + $cred
        $issue = Get-GitHubIssue @issueArgs 
        $needUpdate = $issue.labels | Where-Object { $integratedModules -contains $_.Name }
        if ($needUpdate) {
            "#$_"
        }
    } | ForEach-Object {
        $gitLog | ForEach-Object {
            $regex = [regex] '#([\d]*)'
            if ($regex.IsMatch($_)) {
                "1. $($_.Split('$')[1])"
            }
        }
    } | Sort-Object -Unique) -join [System.Environment]::NewLine
$issueString = "Bump standalone packages`r`n $xafIssues"
Write-Host $issueString -ForegroundColor DarkMagenta
# $filter = "Xpand.*"
# $excludeFilter = "Collections|Patcher|Fasterflect"
# Update-NugetPackage -Filter $filter -sources (Get-PackageFeed -Xpand) -Verbose -projects $projects -excludeFilter $excludeFilter
$packages=Find-XpandPackage Xpand* Lab
"packages"
$packages|Out-String

Set-Location $repoDir
$projects|ForEach-Object{
    [xml]$csproj=Get-Content $_
    Write-Host "parsing $($_.BaseName)" -ForegroundColor Blue
    $csproj.Project.ItemGroup.Packagereference|ForEach-Object{
        $include=$_.Include
        $package=$packages|Where-Object{$include -eq $_.Id}
        if ($package){
            Write-Host "Update $package v$($_.Version) to $($package.Version)" -ForegroundColor DarkGray
            $_.Version=$package.Version
        }
    }
    $csproj.Save($_)
}
if (!$XAFPAth){
    git config --global user.email apostolis.bekiaris@gmail.com
    git config --global user.name apobekiaris
    "Stage.."
    git add -A 
    "Commit.."
    git commit -q -m $issueString
    "Push.."
    git push -f "https://apobekiaris:$GithubToken@github.com/eXpandFramework/eXpand.lab.git"
}
