param(
    $GithubUserName ,
    $GithubPass 
)
$VerbosePreference = "continue"
Install-Module XpandPosh -RequiredVersion 1.1.0 -Scope CurrentUser -Force -Repository PSGallery 
$version = Get-XpandVersion -Lab 
$version
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GitHubPass 
    Organization = "eXpandFramework"
}

$commitIssues = Get-GitHubCommitIssue -Repository1 eXpand -Repository2 lab @cred
$commitIssues
$milestone=Get-GitHubMilestone -Repository eXpand -Latest @cred
$milestone
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"

$msg = "Installer lab build [$version](https://github.com/eXpandFramework/lab/releases/$version) includes commit {Commits} that relate to this task. Please test if it addresses the problem. If you use nuget add our [NugetServer](https://xpandnugetserver.azurewebsites.net/) as a nuget package source in VS.`r`n`r`n. Thanks a lot for your contribution."
$msg
Checkpoint-GithubIssue -CommitIssues $commitIssues -Message $msg @cred |ForEach-Object{
    Update-GitHubIssue -IssueNumber $_.Number -Repository eXpand -MileStoneTitle $milestone
}