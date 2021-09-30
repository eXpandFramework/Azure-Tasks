param(
    $GithubUserName = "eXpand",
    $GithubToken = $env:eXpandGitHubToken,
    $ProjectName = "XAF"
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.202.48.11
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
# $VerbosePreference = "continue"
$cred = @{
    Token         = $GitHubToken 
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
    $latestRelease=Get-GitHubRelease -Repository Reactive.XAF @cred|Select-Object -First 1
    $w=[System.Net.WebClient]::new()
    $downloadUrl=$latestRelease.Assets.BrowserDownloadUrl.split(' ')[0]
    "download=$downloadUrl"
    $w.DownloadFile($downloadUrl,"$env:TEMP\packages.zip")
    Expand-Archive "$env:TEMP\packages.zip" -DestinationPath $env:TEMP\releasedpackages -Force
    $packages=& (Get-NugetPath) list -source $env:TEMP\releasedpackages|ConvertTo-PackageObject
    $packagesString = $packages | Sort-Object Id | ForEach-Object {
        "$(Get-XpandPackageHome $_.Id $_.Version -Html)</br>"
    }
    if (!$packagesString){
        $packagesString="No packages released."
    }
    $msg = @"
The pre-release [$($latestRelease.Name)](https://github.com/eXpandFramework/Reactive.XAF/releases/tag/$($latestRelease.Name)) in the [Reactive.XAF](https://github.com/eXpandFramework/Reactive.XAF/tree/lab) ``lab`` branch  includes commits that relate to this task:

{Commits}

To minimize version conflicts we recommend that you use the [Xpand.XAF.Core.All](https://www.nuget.org/packages/Xpand.XAF.Core.All), [Xpand.XAF.Win.All](https://www.nuget.org/packages/Xpand.XAF.Win.All), [Xpand.XAF.Web.All](https://www.nuget.org/packages/Xpand.XAF.Web.All) packages. Doing so, all packages will be at your disposal and .NET will add a dependecy only to those packages that you actually use and not to all (see the [Modules installation-registrations](https://youtu.be/LvxQ-U_0Sbg) youtube video).
<details>
    <summary>Released packages:</summary>
$packagesString
</details>

Please update the related Nuget packages and test if issues is addressed. These are nightly nuget packages available only from our [NugetServer](https://xpandnugetserver.azurewebsites.net/nuget/).

If you do not use these packages directly but through a module of the main eXpandFramework project, please wait for the bot to notify you again when integration is finished or update the related packages manually.

Thanks a lot for your contribution.
"@
    UpdateIssues "Reactive.XAF" "lab"    
}

if ($ProjectName -eq "lab") {
    
    $version = Get-XpandVersion -Lab 
    $msg = @"
eXpand.lab release [$version](https://github.com/eXpandFramework/eXpand.lab/releases/$version) includes commit that relate to this task:

{Commits}

Please test if it addresses the problem. If you use nuget add our `LAB` [NugetServer](https://xpandnugetserver.azurewebsites.net/nuget) as a nuget package source in VS.

To minimize version conflicts we recommend that you switch to PackageReference format and use only the [eXpandAgnostic](https://www.nuget.org/packages/eXpandAgnostic), [eXpandWin](https://www.nuget.org/packages/eXpandWin), [eXpandWeb](https://www.nuget.org/packages/eXpandWeb) packages. Doing so, all packages will be at your disposal and .NET will add a dependecy only to those packages that you actually use and not to all (see the [Modules installation-registrations](https://youtu.be/LvxQ-U_0Sbg) youtube video). 

Thanks a lot for your contribution.
"@
    $msg
    UpdateIssues "eXpand.lab" "master"
    
}
