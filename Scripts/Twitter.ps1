param(
    $TwitterAPIKey=$env:TestTwitterAPIKey,
    $TwitterAPISecret=$env:TestTwitterAPISecret,
    $TwitterAccessToken=$env:TestTwitterAccessToken,
    $TwitterAccessTokenSecret=$env:TestTwitterAccessTokenSecret,
    $MyTwitterAPIKey=$env:MyTwitterAPIKey,
    $MyTwitterAPISecret=$env:MyTwitterAPISecret,
    $MyTwitterAccessToken=$env:MyTwitterAccessToken,
    $MyTwitterAccessTokenSecret=$env:MyTwitterAccessTokenSecret,
    $ScriptName="NugetPackagesTwitter",
    # $ScriptName="XpandPwshTwitter",
    $GitHubToken=$env:GitHubToken,
    $GitUserEmail=$env:GitUserEmail
)

$VerbosePreference = "continue"
$ErrorActionPreference="stop"
Set-Location $PSScriptRoot

$yaml = @"
- Name: XpandPwsh
  Version: 1.202.40.25
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

if (Test-Path $env:TEMP\storage){
    Remove-Item $env:TEMP\storage -Force -Recurse 
}

Set-Location $env:TEMP
git clone "https://apobekiaris:$GithubToken@github.com/eXpandFramework/storage.git"
Set-Location $env:TEMP\storage\Twitter

$twitterContext=New-TwitterContext $TwitterAPIKey $TwitterAPISecret $TwitterAccessToken $TwitterAccessTokenSecret
$myTwitterContext=New-TwitterContext $MyTwitterAPIKey $MyTwitterAPISecret $MyTwitterAccessToken $MyTwitterAccessTokenSecret
$tolisss=Find-TwitterUser $myTwitterContext "tolisss"
. "$PSScriptRoot\$ScriptName.ps1" $twitterContext $myTwitterContext $tolisss
