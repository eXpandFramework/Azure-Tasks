param(
    $GithubUserName ,
    $GithubPass ,
    $BuildRepository
)
$VerbosePreference = "continue"
$yaml = @"
- Name: XpandPosh
  Version: 1.5.3
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
function UpdateIssues ($Repository,$Branch) {
    
    $cred = @{
        Owner        = $GitHubUserName 
        Pass         = $GitHubPass 
        Organization = "eXpandFramework"
    }

    $commitArgs = @{
        Repository1 = "eXpand"
        Repository2 = $Repository
        Branch=$Branch
    } + $cred
    $commitArgs
    $commitIssues = Get-GitHubCommitIssue @commitArgs 
    $commitIssues
    if ($commitIssues) {
        $milestone = Get-GitHubMilestone -Repository eXpand -Latest @cred
        $milestone
        Checkpoint-GithubIssue -CommitIssues $commitIssues -Message $msg @cred |ForEach-Object {
            if ($_) {
                $_
                if ($_.Number) {
                    Update-GitHubIssue -IssueNumber $_.Number -Repository eXpand -MileStoneTitle $milestone
                }
            }
        }
    }
}


$msg="The DevExpress.XAF includes commit {Commits} that relate to this task. Please update the related Nuget packages and test if issues is addressed. These are nightly nuget packages available only from our [NugetServer](https://xpandnugetserver.azurewebsites.net/)."
UpdateIssues "DevExpress.XAF" "lab"

$version = Get-XpandVersion -Lab 
$msg = "eXpand.lab Installer [$version](https://github.com/eXpandFramework/lab/releases/$version) includes commit {Commits} that relate to this task. Please test if it addresses the problem. If you use nuget add our `LAB` [NugetServer](https://xpandnugetserver.azurewebsites.net/) as a nuget package source in VS.`r`n`r`n. Thanks a lot for your contribution."
$msg
UpdateIssues "eXpand.lab" "18.2"
