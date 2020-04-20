param(
    $TwitterAPIKey=$env:TwitterAPIKey,
    $TwitterAPISecret=$env:TwitterAPISecret,
    $TwitterAccessToken=$env:TwitterAccessToken,
    $TwitterAccessTokenSecret=$env:TwitterAccessTokenSecret,
    $MyTwitterAPIKey=$env:MyTwitterAPIKey,
    $MyTwitterAPISecret=$env:MyTwitterAPISecret,
    $MyTwitterAccessToken=$env:MyTwitterAccessToken,
    $MyTwitterAccessTokenSecret=$env:MyTwitterAccessTokenSecret,
    $ScriptName="XpandPwshTwitter",
    $GitHubToken=$env:GitHubToken,
    $GitUserEmail=$env:GitUserEmail
)
$VerbosePreference = "continue"
$ErrorActionPreference="stop"
Set-Location $PSScriptRoot
$yaml = @"
- Name: XpandPwsh
  Version: 1.201.26.1  
- Name: PSTwitterAPI
  Version: 0.0.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

Remove-Item $env:TEMP\storage -Force -Recurse -ErrorAction SilentlyContinue
Set-Location $env:TEMP
$url = "https://apobekiaris:$GithubToken@github.com/eXpandFramework/storage.git"
git clone $url
Set-Location $env:TEMP\storage\Twitter

. "$PSScriptRoot\$ScriptName.ps1"
