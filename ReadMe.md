# Requirement
```ps1
Install-Module XpandPosh -Scope CurrentUser -Force
```
## Checkpoint Github Issue
[![Build Status](https://dev.azure.com/eXpandDevOps/eXpandFramework/_apis/build/status/Checkpoint-GithubIssue?branchName=master)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build/latest?definitionId=34&branchName=master)
```ps1
Checkpoint-GithubIssue -GitHubApp eXpandFramework -Owner $(GithubUserName) -Organization eXpandFramework -Repository1 eXpand -Repository2 "lab" -Message $msg -Pass $(GithubPass) 
```
## Close Github Issue For Age
[![Build Status](https://dev.azure.com/eXpandDevOps/eXpandFramework/_apis/build/status/Close-Issue-ForAge?branchName=master)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build/latest?definitionId=33&branchName=master)
```ps1
Close-GithubIssue -Repository1 eXpand -GitHubApp eXpandFramework -Owner $(GithubUserName) -Pass $(GithubPass) -Organization eXpandFramework
```
## Notify New DevExpress XAF version
[![Build Status](https://dev.azure.com/eXpandDevOps/eXpandFramework/_apis/build/status/Notify-New-XAF-Version?branchName=master)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build/latest?definitionId=35&branchName=master)
```ps1
$dxVersion=Get-DevExpressVersion -Latest -Sources $(DXApiFeed)
$message="New DevExpresss XAF version $dxVersion is out."
Send-Tweet -Message $message
Send-TwitterDm -Message $message -Username "tolisss"
```

Feel free to send a PR with your twitter name, so you can get notified as well.
## Populate DevExpress Packages Contents
[![Build Status](https://dev.azure.com/eXpandDevOps/eXpandFramework/_apis/build/status/Populate-DevExpress-Packages-Contents?branchName=master)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build/latest?definitionId=36&branchName=master)
```ps1
Get-NugetPackageSearchMetadata -AllVersions -Sources $dxFeed|Select-Object -ExpandProperty metadata|Select-Object -ExpandProperty Version |Select-Object -ExpandProperty Version -Unique|ForEach-Object{
    Add-Content -Value $_ "VersionList.txt"
}
```
## New-Xpand-GitHub-Release
[![Build Status](https://dev.azure.com/eXpandDevOps/eXpandFramework/_apis/build/status/Xpand-Github-Release?branchName=master)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build/latest?definitionId=37&branchName=master)
```ps1
Publish-GitHubRelease -Owner $(GitHubUserName) -Organization eXpandFramework -Repository lab -ReleaseName $milestone -ReleaseNotes $notes -Pass $(GitHubPass) -Verbose -Files $files
```
## Label-StandaloneModule-Issue
[![Build Status](https://dev.azure.com/eXpandDevOps/eXpandFramework/_apis/build/status/Label-StandAloneModule-Issues?branchName=master)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build/latest?definitionId=42&branchName=master)
```ps1
Get-GitHubIssue|Update-GitHubIssue -Repository eXpand -Labels "Standalone_XAF_Modules" 
```
## Test-Installer-Script
[![Build Status](https://dev.azure.com/eXpandDevOps/eXpandFramework/_apis/build/status/BuildTools/Test-Installer-Script?branchName=master)](https://dev.azure.com/eXpandDevOps/eXpandFramework/_build/latest?definitionId=43&branchName=master)
```ps1
& .\Scripts\Test-Installer-Script.ps1
```
