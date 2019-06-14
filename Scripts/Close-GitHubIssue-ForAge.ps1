param(
    $GitHubUserName,
    $GitHubPass
)
Install-Module XpandPwsh -RequiredVersion 0.7.1 -Scope CurrentUser -Force -Repository PSGallery
Close-GithubIssue -Repository1 eXpand  -Owner $GithubUserName -Pass $GithubPass -Organization eXpandFramework