# Close Github Issue For Age

```ps1
Install-Module XpandPosh -Scope CurrentUser -Force
Close-GithubIssue -Repository1 eXpand -GitHubApp eXpandFramework -Owner $(GithubUserName) -Pass $(GithubPass) -Organization eXpandFramework
```