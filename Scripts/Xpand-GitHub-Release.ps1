param(
    [string]$AzureToken = $env:AzDevOpsToken,
    [string]$Root = "$env:TEMP\1",
    [string]$GitHubToken = "$env:GitHubToken",
    [string]$GitHubPass = $env:GithubPass,
    [string]$GitHubUserEmail=$env:GithubUserEmail
)

$ErrorActionPreference = "stop"
if (!(Get-Module eXpandFramework -ListAvailable)) {
    $env:AzDevopsToken = $AzureToken
    $env:AzOrganization = "eXpandDevOps"
    $env:AzProject = "eXpandFramework"
    $env:DxFeed = $DxApiFeed
    git config --global user.email $GitHubUserEmail
    git config --global user.name "Apostolis Bekiaris"
    git config --global core.safecrlf false
}
# if (Test-Path $Root) {
#     remove-item $Root -Force -Recurse
# }
New-Item $Root -ItemType Directory -Force -ErrorAction SilentlyContinue
$yaml = @"
- Name: XpandPwsh
  Version: 1.201.10.3
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

function UpdateHistory {
    param(
        $CommitIssues,
        $Release,
        $GitHubToken,
        $GitHubPass
    )
    
    $directory = [System.Guid]::NewGuid()
    New-Item -Path "$env:TEMP\$directory" -ItemType Directory
    Set-Location "$env:TEMP\$directory"
    $url = "https://$GitHubPass`:$GitHubToken@github.com/eXpandFramework/eXpand.git"
    $url
    git clone $url -q
    Write-HostFormatted eXpandRepoFiles -Section
    Get-ChildItem "$env:TEMP\$directory\eXpand"
    Set-Location "$env:TEMP\$directory\eXpand\ReleaseNotesHistory"

    
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
    Write-HostFormatted "releaseHistory:" -Section
    $releaseHistory | Write-Host
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
    
    git add -A 
    git commit -m "Update $Release History"
    git push -f origin -q
    
    "Update $Release History"
}

Invoke-Script {
    $labBuild = Get-AzBuilds -Definition Xpand-Lab -Status completed -Result succeeded -Top 1
    $releaseBuild = Get-AzBuilds -Definition Xpand-Release -Status completed -Result succeeded -Top 1
    $labBuild.buildNumber
    $releaseBuild.BuildNumber
    $version = $labBuild.BuildNumber
    $build = $labBuild
    $targetRepo = "eXpand.lab"

    if ((New-Object System.Version($releaseBuild.buildNumber)) -gt (New-Object System.Version($labBuild.buildNumber))) {
        $version = $releaseBuild.BuildNumber
        $build = $releaseBuild
        $targetRepo = "eXpand"
    }
    "version=$version"
    Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
    $artifact = Get-AzArtifact -BuildId $build.id -Outpath $Root
 

    $files = Get-ChildItem $artifact -Recurse -File | Select-Object -ExpandProperty FullName
    Write-HostFormatted "Files" -section
    $files
    if (!$files) {
        throw "No artifacts found"
    }
    $cred = @{
        Token        = $GitHubToken
        Organization = "eXpandFramework"
    }
    $date = (Get-GitHubRelease -Repository $targetRepo @cred | Select-Object -First 1).PublishedAt
    $commitIssues = Get-GitHubCommitIssue -Repository1 eXpand -Repository2 $targetRepo @cred -Since $date.DateTime
    Write-HostFormatted "commitIssues:" -Section
    $commitIssues.GitHubCommit.Commit.Message
    # if ($targetRepo -eq "eXpand.lab") {
    #     $lastLabRelease = Get-GitHubRelease -Repository $targetRepo @cred | Select-Object -First 2 -Skip 1
    #     "lastLabRelease=$($lastLabRelease.TagName)"
    #     $releaseDate = $lastLabRelease.PublishedAt.DateTime
    #     "releaseDate=$releaseDate"
    #     $commitIssues = $commitIssues | Where-Object { $releaseDate -lt $_.Githubcommit.Commit.Author.Date.DateTime }
    #     "commitIssues:"
    # }


    if ($commitIssues) {
        if ($targetRepo -eq "eXpand") {
            UpdateHistory $commitIssues $version $GitHubToken $GitHubPass
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
    $extraParams = "#-Version '$version' -SkipGac -InstallationPath 'YOURPATH'"
    if ($targetRepo -eq "eXpand.lab") {
        $latest = "-Latest"
        $extraParams = "-Version '$version' #-SkipGac -InstallationPath 'YOURPATH'"
    }
    $installerNotes = @"
The msi installer is replaced with the powershell [XpandPwsh](https://github.com/eXpandFramework/XpandPwsh) module. 
To install artifacts you can use either the [Install-Xpand](https://github.com/eXpandFramework/XpandPwsh/wiki/Install-Xpand) function or copy paste the next line in an ``Admin`` powershell prompt.
``````ps1
Set-ExecutionPolicy Bypass -Scope Process -Force;iex `"`$(([System.Net.WebClient]::new()).DownloadString('http://install.expandframework.com'));Install-Xpand -Assets @('Assemblies','Nuget','VSIX','Source')  $extraParams`"
``````
[![Azure DevOps builds](https://img.shields.io/azure-devops/build/eXpandDevops/dc0010e5-9ecf-45ac-b89d-2d51897f3855/43?label=Installer-Tests&style=social)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build?definitionId=43&_a=summary)


"@
    if (!$notes) {
        $notes = "There are no enhancements or bugs."
    }
    [version]$v = $version
    $badgeVersion = "$($v.Major).$($v.Minor).$($v.Build)"
    $notes = @"
[![image](https://img.shields.io/badge/Exclusive%20services%3F-Head%20to%20the%20dashboard-Blue)](https://github.com/sponsors/apobekiaris)

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

}