param(
    [string]$AzureToken = (Get-AzureToken),
    [string]$Root = "$env:TEMP\1",
    [string]$GitHubUserName = "apobekiaris",
    [string]$GitHubPass = $env:GithubPass
)
$ErrorActionPreference = "stop"

if (Test-Path $Root) {
    remove-item $Root -Force -Recurse
}
New-Item $Root -ItemType Directory
$yaml = @"
- Name: XpandPosh
  Version: 2.3.0
- Name: VSTeam
  Version: 6.2.1
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
function UpdateHistory {
    param(
        $CommitIssues,
        $Release
    )
    Set-Location $env:TEMP
    $directory = [System.Guid]::NewGuid()
    New-Item $directory -ItemType Directory
    "$env:TEMP\$directory"
    $url = "https://$GithubUserName`:$GithubPass@github.com/eXpandFramework/eXpand.git"
    git clone $url
    Set-Location ".\eXpand\ReleaseNotesHistory"

    git config --global user.email $GitUserEmail
    git config --global user.name "Apostolis Bekiaris"
    $releaseHistory=$commitIssues | ForEach-Object {
        $issues = $_.Issues.Number -join ", "
        $message = $_.GitHubCommit.Commit.Message
        $_.Issues.Number | ForEach-Object {
            $message = $message.replace("#$_", "").Trim(",").Trim()
        }
        $excludeLabels = @("Question", "Bug", "Enhancement")
        $labels = ($_.Issues.Labels | Where-Object { !$excludeLabels.Contains($_.Name) } | Select-Object -ExpandProperty Name | Sort-Object -Unique) -join ", "
        if ($labels) {
            [PSCustomObject]@{
                Release = $Release
                Issues  = $issues
                Labels  = $labels
                Message = $message
                Sha     = $_.GitHubCommit.Sha
            } 
        }
    }
    $import=Import-Csv .\History.csv|ForEach-Object{
        [PSCustomObject]@{
            Release = $_.Release
            Issues  = $_.issues
            Labels  = $_.labels
            Message = $_.message
            Sha     = $_.GitHubCommit.Sha
        } 
    }
    Remove-Item .\History.csv
    ($releaseHistory+$import)|Export-Csv .\History.csv -NoTypeInformation
    
    git add -A 
    git commit -m "Update $Release History"
    git push -f origin
}
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken
$allBuilds=Get-VSTeamBuild -ProjectName eXpandFramework
$labBuild = $allBuilds|Where-Object {$_.DefinitionName -eq "Xpand-Lab" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$betaBuild = $allBuilds|Where-Object {$_.DefinitionName -eq "Beta" -and $_.Result -eq "succeeded"}|Select-Object -first 1
if ([version]$betaBuild.buildNumber -gt [version]$labBuild.buildNumber){
    $labBuild=$betaBuild
}
$releaseBuild = $allBuilds|Where-Object {$_.DefinitionName -eq "Xpand-Release" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$labBuild.buildNumber
$releaseBuild.BuildNumber
$version = $labBuild.BuildNumber
$build = $labBuild
$targetRepo = "eXpand.lab"
$VerbosePreference = "continue"
if ((new-object System.Version($releaseBuild.buildNumber)) -gt (new-object System.Version($labBuild.buildNumber))) {
    $version = $releaseBuild.BuildNumber
    $build = $releaseBuild
    $targetRepo = "eXpand"
}
"version=$version"
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$a = Get-VSTeamBuildArtifact -Id $build.id -ProjectName eXpandFramework -ErrorAction Continue
$uri = "$($a.resource.downloadUrl)"
$uri 
Invoke-WebRequest -Uri $uri -OutFile "$Root\artifact.zip"
Expand-Archive "$Root\artifact.zip" -destinationpath $Root\artifacts 

$files = Get-ChildItem $Root\artifacts\Xpand.v$version|Select-Object -ExpandProperty FullName
$files
if (!$files) {
    throw "No artifacts found"
}
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GitHubPass 
    Organization = "eXpandFramework"
}
$commitIssues = Get-GitHubCommitIssue -Repository1 eXpand -Repository2 $targetRepo @cred -Since (Get-Date).AddDays(-6)
"commitIssues:"
$commitIssues.GitHubCommit.Commit.Message
if ($targetRepo -eq "eXpand.lab") {
    $lastLabRelease = Get-GitHubRelease -Repository $targetRepo @cred | Select-Object -First 2 -Skip 1
    "lastLabRelease=$($lastLabRelease.TagName)"
    $releaseDate = $lastLabRelease.PublishedAt.DateTime
    "releaseDate=$releaseDate"
    $commitIssues = $commitIssues | Where-Object { $releaseDate -lt $_.Githubcommit.Commit.Author.Date.DateTime }
    "commitIssues:"
}
    $commitIssues.GitHubCommit.Commit.Message

if ($commitIssues) {
    if ($targetRepo -eq "eXpand"){
        UpdateHistory $commitIssues $version
    }
    
    $notes = New-GithubReleaseNotes -CommitIssues $commitIssues 
    "notes=$notes"
    
    $authors = $commitIssues.githubcommit.commit.author|Where-Object{$_.Name -ne "Apostolis Bekiaris"} | ForEach-Object { "[$($_.Name)](https://github.com/$($_.Name.Replace(' ',''))), " } | Select-Object -Unique
    "authors=$authors"
    $commentsUsers = $commitIssues.Issues | Get-GitHubIssueComment -Repository eXpand @cred | ForEach-Object {$_.User}|Where-Object{$_.Login -ne "eXpand"}
    "commentsUsers=$commentsUsers"
    $users = (@($commitIssues.Issues.User) + @($commentsUsers)) | Where-Object { $_.Login -ne "eXpand" } | Sort-Object Login -Unique | Where-Object { $_ } | ForEach-Object { "[$($_.Login)]($($_.HtmlUrl)), " }
    "users=$users"
    $contributors = (($users + $authors) | Select-Object -Unique)
    "contributors=$contributors"

    $userNotes = "Big thanks for their contribution to:`r`n$contributors"
    "userNotes=$userNotes"
}
$dxVersion = Get-DevExpressVersion $version -Build
if ($targetRepo -eq "eXpand.lab") {
    $latest = "-Latest"
}
$installerNotes = @"
The msi installer is replaced with the powershell [XpandPosh](https://github.com/eXpandFramework/XpandPosh) module. 
To install artifacts you can use either the [Install-Xpand](https://github.com/eXpandFramework/XpandPosh/wiki/Install-Xpand) function or copy paste the next line in an ``Admin`` powershell prompt.
``````ps1
Set-ExecutionPolicy Bypass -Scope Process -Force;iex `"`$(([System.Net.WebClient]::new()).DownloadString('http://install.expandframework.com'));Install-Xpand -Assets @('Assemblies','Nuget','VSIX','Source')  #-Version '$version' -SkipGac -InstallationPath 'YOURPATH'`"
``````

![open collective backers and sponsors](https://img.shields.io/opencollective/all/expand.svg?label=If%20this%20organization%20helped%20your%20business%2C%20we%20kindly%20request%20to%20consider%20sponsoring%20our%20activities)
"@
if (!$notes) {
    $notes = "There are no enhancements or bugs."
}
$badgeVersion="$($version.Major).$($version.Minor).$($version.Build)"
$notes = "![GitHub Releases (by Release)](https://img.shields.io/github/downloads/expandframework/$targetRepo/$version/total.svg) ![Custom badge](https://img.shields.io/endpoint.svg?label=Nuget&url=https%3A%2F%2Fxpandnugetstats.azurewebsites.net%2Fapi%2Ftotals%2Fversion%3Fid%3DeXpand%26version%3D$badgeVersion)`r`n`r`nThis release is compiled against DevExpress.XAF v$dxversion.`r`n$usernotes`r`n`r`n[<img src='https://img.shields.io/badge/Search-ReleaseHistory-green.svg'/>](https://github.com/eXpandFramework/eXpand/tree/master/ReleaseNotesHistory)`r`n$notes`r`n`r`n$installerNotes"
$publishArgs = (@{
        Repository   = $targetRepo
        ReleaseName  = $version
        ReleaseNotes = $notes
        Files        = $files
        Draft        = ($build.definitionName -eq "Xpand-Release")
    } + $cred)
$publishArgs
Publish-GitHubRelease @publishArgs


 



