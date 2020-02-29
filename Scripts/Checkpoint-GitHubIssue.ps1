param(
    $GithubUserName = "eXpand",
    $GithubPass = $env:eXpandGithubPass,
    $ProjectName = "xaf"
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.201.11.5
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
$VerbosePreference = "continue"
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GitHubPass 
    Organization = "eXpandFramework"
}
function UpdateIssues ($Repository, $Branch) {

    $commitArgs = @{
        Repository1 = "eXpand"
        Repository2 = $Repository
        Branch      = $Branch
    } + $cred
    $commitArgs
    $commitIssues = Get-GitHubCommitIssue @commitArgs 
    $commitIssues.GitHubCommit.Commit.Message | Sort-Object -Unique
    $commitIssues.issues.Number | Sort-Object -Unique
    if ($commitIssues) {
        $milestone = Get-GitHubMilestone -Repository eXpand -Latest @cred
        $milestone.Title
        Checkpoint-GithubIssue -CommitIssues $commitIssues -Message $msg @cred | ForEach-Object {
            if ($_) {
                $_
                if ($_.IssueNumber) {
                    $updateArgs = @{
                        IssueNumber    = $_.IssueNumber 
                        Repository     = "eXpand" 
                        MileStoneTitle = $milestone.Title
                    } + $cred
                    $updateArgs
                    Update-GitHubIssue  @updateArgs
                }
            }
        }
    }
}

if ($ProjectName -eq "XAF") {
    $latestRelease=Get-GitHubRelease -Repository DevExpress.XAF @cred
    $w=[System.Net.WebClient]::new()
    $w.DownloadFile($latestRelease.Assets.BrowserDownloadUrl,"$env:TEMP\packages.zip")
    Expand-Archive "$env:TEMP\packages.zip" -DestinationPath $env:TEMP\releasedpackages -Force
    $packages=& (Get-NugetPath) list -source $env:TEMP\releasedpackages|ConvertTo-PackageObject
    $packagesString = $packages | Sort-Object Id | ForEach-Object {
        "1. $(Get-XpandPackageHome $_.Id $_.Version)`r`n"
    }
    $msg = "The pre-release [$($latestRelease.Name)](https://github.com/eXpandFramework/DevExpress.XAF/releases/tag/$($latestRelease.Name)) in the [DevExpress.XAF](https://github.com/eXpandFramework/DevExpress.XAF/tree/lab) ``lab`` branch  includes commits that relate to this task:`r`n`r`n{Commits}`r`n`r`nReleased packages:`r`n$packagesString`r`n`r`nPlease update the related Nuget packages and test if issues is addressed. These are nightly nuget packages available only from our [NugetServer](https://xpandnugetserver.azurewebsites.net/nuget/).`r`n`r`nIf you do not use these packages directly but through a module of the main eXpandFramework project, please wait for the bot to notify you again when integration is finished or update the related packages manually.`r`n`r`nThanks a lot for your contribution."
    UpdateIssues "DevExpress.XAF" "lab"    
}

if ($ProjectName -eq "lab") {
    
    $version = Get-XpandVersion -Lab 
    $msg = "eXpand.lab release [$version](https://github.com/eXpandFramework/eXpand.lab/releases/$version) includes commit that relate to this task:`r`n`r`n{Commits}`r`n`r`nPlease test if it addresses the problem. If you use nuget add our `LAB` [NugetServer](https://xpandnugetserver.azurewebsites.net/nuget) as a nuget package source in VS.`r`n`r`nThanks a lot for your contribution."
    $msg
    UpdateIssues "eXpand.lab" "master"
    
}
