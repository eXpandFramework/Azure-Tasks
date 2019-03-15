param(
    $GithubUserName ="apobekiaris",
    $GithubPass =$env:GithubPass
)
$VerbosePreference = "continue"
$yaml = @"
- Name: XpandPosh
  Version: 1.1.5
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
$version = Get-XpandVersion -Lab 
$version
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GitHubPass 
    Organization = "eXpandFramework"
}
$commitArgs=@{
    Repository1="eXpand"
    Repository2="lab"
}+$cred
$commitArgs
$commitIssues = Get-GitHubCommitIssue @commitArgs
$commitIssues
if ($commitIssues) {
    $milestone = Get-GitHubMilestone -Repository eXpand -Latest @cred
    $milestone
    Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"

    $msg = "Installer lab build [$version](https://github.com/eXpandFramework/lab/releases/$version) includes commit {Commits} that relate to this task. Please test if it addresses the problem. If you use nuget add our [NugetServer](https://xpandnugetserver.azurewebsites.net/) as a nuget package source in VS.`r`n`r`n. Thanks a lot for your contribution."
    $msg
    Checkpoint-GithubIssue -CommitIssues $commitIssues -Message $msg @cred -WhatIf |ForEach-Object {
        if ($_){
            Update-GitHubIssue -IssueNumber $_.Number -Repository eXpand -MileStoneTitle $milestone
        }
    }
}