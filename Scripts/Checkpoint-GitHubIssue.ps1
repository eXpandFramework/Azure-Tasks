param(
    $GithubUserName,
    $GithubPass
)
$VerbosePreference="continue"
Install-Module XpandPosh -RequiredVersion 1.0.46 -Scope CurrentUser -Force -Repository PSGallery 
$version=Get-XpandVersion -Lab 
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$nugetServerUri="https://xpandnugetserver.azurewebsites.net/"
$installerBuildUri="https://github.com/eXpandFramework/lab/releases/$version"
$msg="Installer lab build [$version]($installerBuildUri) includes commit {Commits} that relate to this task. Please test if it addresses the problem. If you use nuget add our [NugetServer]({$nugetServerUri}) as a nuget package source in VS"
$msg
Checkpoint-GithubIssue -GitHubApp eXpandFramework -Owner $GithubUserName -Organization eXpandFramework -Repository1 eXpand -Repository2 "lab" -Message $msg -Pass $GithubPass