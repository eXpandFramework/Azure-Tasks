param(
    $DXApiFeed=$env:DxFeed,
    $TwitterAPIKey=$env:TwitterAPIKey,
    $TwitterAPISecret=$env:TwitterAPISecret,
    $TwitterAccessToken=$env:TwitterAccessToken,
    $TwitterAccessTokenSecret=$env:TwitterAccessTokenSecret
)
$VerbosePreference="continue"

$yaml = @"
- Name: XpandPwsh
  Version: 0.22.0
- Name: PSTwitterAPI
  Version: 0.0.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

$dxVersion=Get-DevExpressVersion -LatestVersionFeed $DXApiFeed
$message="New @DevExpresss_XAF version $dxVersion is out."
$OAuthSettings = @{
    ApiKey = $TwitterAPIKey
    ApiSecret = $TwitterAPISecret
    AccessToken = $TwitterAccessToken
    AccessTokenSecret =$TwitterAccessTokenSecret
  }
Set-TwitterOAuthSettings @OAuthSettings

$timeline=Get-TwitterStatuses_UserTimeline -screen_name 'eXpandFramework' -count 1000
$expandId=(Get-TwitterUsers_Lookup -screen_name 'eXpandFramework').Id
if(!($timeline|Where-Object{$_.user.id -eq $expandId -and $_.text -like "*$message*"})){
    Write-Host $message -f Green
    Send-TwitterStatuses_Update -status $message 
    $tolisssId=(Get-TwitterUsers_Lookup -screen_name 'tolisss').Id
    Send-TwitterDirectMessages_EventsNew -recipient_id $tolisssId -text $message 
}
