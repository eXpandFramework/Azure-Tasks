param(
    $GitHubUserName,
    $GitHubPass=$env:eXpandGitHubToken
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.202.44.2
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Close-GithubIssue -Repository1 eXpand  -Token $GithubPass -Organization eXpandFramework -KeepWhenAssignees -top 1