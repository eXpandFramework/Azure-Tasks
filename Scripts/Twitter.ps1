param(
    $TwitterAPIKey=$env:TwitterAPIKey,
    $TwitterAPISecret=$env:TwitterAPISecret,
    $TwitterAccessToken=$env:TwitterAccessToken,
    $TwitterAccessTokenSecret=$env:TwitterAccessTokenSecret,
    $MyTwitterAPIKey=$env:MyTwitterAPIKey,
    $MyTwitterAPISecret=$env:MyTwitterAPISecret,
    $MyTwitterAccessToken=$env:MyTwitterAccessToken,
    $MyTwitterAccessTokenSecret=$env:MyTwitterAccessTokenSecret,
    $ScriptName="NugetPackagesTwitter",
    $GitHubToken=$env:GitHubToken,
    $GitUserEmail=$env:GitUserEmail
)
$VerbosePreference = "continue"
$ErrorActionPreference="stop"
Set-Location $PSScriptRoot
$yaml = @"
- Name: XpandPwsh
  Version: 1.201.27.3
- Name: PSTwitterAPI
  Version: 0.0.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

Remove-Item $env:TEMP\storage -Force -Recurse -ErrorAction SilentlyContinue
Set-Location $env:TEMP
git clone "https://apobekiaris:$GithubToken@github.com/eXpandFramework/storage.git"
Set-Location $env:TEMP\storage\Twitter

$twitterContext=New-TwitterContext $TwitterAPIKey $TwitterAPISecret $TwitterAccessToken $TwitterAccessTokenSecret
$myTwitterContext=New-TwitterContext $MyTwitterAPIKey $MyTwitterAPISecret $MyTwitterAccessToken $MyTwitterAccessTokenSecret
$tolisss=Get-TwitterUser $myTwitterContext "tolisss"
. "$PSScriptRoot\$ScriptName.ps1" $twitterContext $myTwitterContext $tolisss
