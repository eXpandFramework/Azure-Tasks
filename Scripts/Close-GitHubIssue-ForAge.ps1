param(
    $GitHubUserName,
    $GitHubPass=$env:eXpandGitHubToken
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.201.25.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Close-GithubIssue -Repository1 eXpand  -Token $GithubPass -Organization eXpandFramework -KeepWhenAssignees