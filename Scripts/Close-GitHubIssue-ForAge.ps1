param(
    $GitHubUserName,
    $GitHubToken=$env:eXpandGitHubToken
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.221.0.14
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Close-GithubIssue -Repository1 eXpand  -Token $GithubToken -Organization eXpandFramework -KeepWhenAssignees -top 1