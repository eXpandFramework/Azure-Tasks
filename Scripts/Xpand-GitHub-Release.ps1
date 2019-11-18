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
- Name: XpandPwsh
  Version: 0.30.6
- Name: VSTeam
  Version: 6.3.6
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

function UpdateHistory {
    param(
        $CommitIssues,
        $Release
    )
    
    $directory = [System.Guid]::NewGuid()
    New-Item -Path "$env:TEMP\$directory" -ItemType Directory
    Set-Location "$env:TEMP\$directory"
    $url = "https://$GithubUserName`:$GithubPass@github.com/eXpandFramework/eXpand.git"
    git clone $url
    Set-Location "$env:TEMP\$directory\eXpand\ReleaseNotesHistory"

    try {
        git config --global user.email $GitUserEmail
        git config --global user.name "Apostolis Bekiaris"
    }
    catch {
        
    }
    $releaseHistory = @($commitIssues | ForEach-Object {
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
    })
    "releaseHistory:"
    $releaseHistory|Write-Host
    $import = Import-Csv .\History.csv | ForEach-Object {
        [PSCustomObject]@{
            Release = $_.Release
            Issues  = $_.issues
            Labels  = $_.labels
            Message = $_.message
            Sha     = $_.GitHubCommit.Sha
        } 
    }
    
    @($releaseHistory + $import) | Export-Csv "$env:TEMP\$directory\eXpand\ReleaseNotesHistory\History.csv" -NoTypeInformation 
    "Exported"
    $ErrorActionPreference="continue"
    git add -A 
    git commit -m "Update $Release History"
    git push -f origin
    $ErrorActionPreference="Stop"
    "Update $Release History"
}
Set-VSTeamAPIVersion AzD
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken
$labdefintion=Get-VSTeamBuildDefinition -ProjectName eXpandFramework -Filter "Xpand-Lab"
$labBuild=Get-VSTeamBuild -ProjectName eXpandFramework -Definitions $labdefintion.Id -StatusFilter completed -ResultFilter succeeded|Select-Object -First 1

$releaseDefinition=Get-VSTeamBuildDefinition -ProjectName eXpandFramework -Filter "Xpand-Release"
$releaseBuild=Get-VSTeamBuild -ProjectName eXpandFramework -Definitions $releaseDefinition.Id -StatusFilter completed -ResultFilter succeeded|Select-Object -First 1
$labBuild.buildNumber
$releaseBuild.BuildNumber
$version = $labBuild.BuildNumber
$build=$labBuild
$targetRepo = "eXpand.lab"

if ((new-object System.Version($releaseBuild.buildNumber)) -gt (new-object System.Version($labBuild.buildNumber))) {
    $version = $releaseBuild.BuildNumber
    $build = $releaseBuild
    $targetRepo = "eXpand"
}
"version=$version"
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$a = Get-VSTeamBuildArtifact -Id $build.id -ProjectName eXpandFramework -ErrorAction Continue
$uri = "$($a.resource.downloadUrl)"
"uri=$uri" 
# $uri="https://dev.azure.com/expandDevOps/dc0010e5-9ecf-45ac-b89d-2d51897f3855/_apis/build/builds/5255/artifacts?artifactName=Xpand.v19.2.301.4&api-version=5.0&%24format=zip"
$wc=New-Object System.Net.WebClient
$wc.DownloadFile($uri,"$Root\artifact.zip")
# Invoke-WebRequest -Uri $uri -OutFile "$Root\artifact.zip"
# throw "pass"
Expand-Archive "$Root\artifact.zip" -destinationpath $Root\artifacts 

$files = Get-ChildItem $Root\artifacts\Xpand.v$version | Select-Object -ExpandProperty FullName
$files
if (!$files) {
    throw "No artifacts found"
}
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GitHubPass 
    Organization = "eXpandFramework"
}
$date = (Get-GitHubRelease -Repository $targetRepo @cred | Select-Object -First 1).PublishedAt
$commitIssues = Get-GitHubCommitIssue -Repository1 eXpand -Repository2 $targetRepo @cred -Since $date.DateTime
"commitIssues:"
$commitIssues.GitHubCommit.Commit.Message
# if ($targetRepo -eq "eXpand.lab") {
#     $lastLabRelease = Get-GitHubRelease -Repository $targetRepo @cred | Select-Object -First 2 -Skip 1
#     "lastLabRelease=$($lastLabRelease.TagName)"
#     $releaseDate = $lastLabRelease.PublishedAt.DateTime
#     "releaseDate=$releaseDate"
#     $commitIssues = $commitIssues | Where-Object { $releaseDate -lt $_.Githubcommit.Commit.Author.Date.DateTime }
#     "commitIssues:"
# }
$commitIssues.GitHubCommit.Commit.Message

if ($commitIssues) {
    if ($targetRepo -eq "eXpand") {
        UpdateHistory $commitIssues $version
    }
    
    $notes = New-GithubReleaseNotes -CommitIssues $commitIssues 
    "notes=$notes"
    
    $authors = $commitIssues.githubcommit.commit.author | Where-Object { $_.Name -ne "Apostolis Bekiaris" } | ForEach-Object { "[$($_.Name)](https://github.com/$($_.Name.Replace(' ',''))), " } | Select-Object -Unique
    "authors=$authors"
    if ($commitIssues.Issues) {
        $commentsUsers = $commitIssues.Issues | Get-GitHubIssueComment -Repository eXpand @cred | ForEach-Object { $_.User } | Where-Object { $_.Login -ne "eXpand" }
        "commentsUsers=$commentsUsers"
    }
    
    $users = (@($commitIssues.Issues.User) + @($commentsUsers)) | Where-Object { $_.Login -ne "eXpand" } | Sort-Object Login -Unique | Where-Object { $_ } | ForEach-Object { "[$($_.Login)]($($_.HtmlUrl)), " }
    "users=$users"
    $contributors = (($users + $authors) | Select-Object -Unique)
    "contributors=$contributors"

    $userNotes = "Big thanks for their contribution to:`r`n$contributors"
    "userNotes=$userNotes"
}
$dxVersion = Get-DevExpressVersion $version -Build
$extraParams="#-Version '$version' -SkipGac -InstallationPath 'YOURPATH'"
if ($targetRepo -eq "eXpand.lab") {
    $latest = "-Latest"
    $extraParams="-Version '$version' #-SkipGac -InstallationPath 'YOURPATH'"
}
$installerNotes = @"
The msi installer is replaced with the powershell [XpandPwsh](https://github.com/eXpandFramework/XpandPwsh) module. 
To install artifacts you can use either the [Install-Xpand](https://github.com/eXpandFramework/XpandPwsh/wiki/Install-Xpand) function or copy paste the next line in an ``Admin`` powershell prompt.
``````ps1
Set-ExecutionPolicy Bypass -Scope Process -Force;iex `"`$(([System.Net.WebClient]::new()).DownloadString('http://install.expandframework.com'));Install-Xpand -Assets @('Assemblies','Nuget','VSIX','Source')  $extraParams`"
``````


"@
if (!$notes) {
    $notes = "There are no enhancements or bugs."
}
[version]$v=$version
$badgeVersion = "$($v.Major).$($v.Minor).$($v.Build)"
$notes = @"
![Open Collective backers and sponsors](https://img.shields.io/opencollective/all/expand?label=PLEASE%20SPONSOR%20our%20activities%20if%20we%20helped%20your%20business&style=for-the-badge)

![GitHub Releases (by Release)](https://img.shields.io/github/downloads/expandframework/$targetRepo/$version/total?style=social) ![Custom badge](https://img.shields.io/endpoint.svg?style=social&label=Nuget&url=https%3A%2F%2Fxpandnugetstats.azurewebsites.net%2Fapi%2Ftotals%2Fversion%3Fid%3DeXpand%26version%3D$badgeVersion)

This release is compiled against DevExpress.XAF v$dxversion.
$usernotes

[Release History](https://github.com/eXpandFramework/eXpand/tree/master/ReleaseNotesHistory)
$notes`r`n`r`n$installerNotes
"@
$publishArgs = (@{
        Repository   = $targetRepo
        ReleaseName  = $version
        ReleaseNotes = $notes
        Files        = $files
        Draft        = ($build.definitionName -eq "Xpand-Release")
    } + $cred)
$publishArgs
Publish-GitHubRelease @publishArgs


 



