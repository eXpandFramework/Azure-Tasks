param(
    $DXApiFeed = $env:DxFeed,
    $TwitterAPIKey = $env:TwitterAPIKey,
    $TwitterAPISecret = $env:TwitterAPISecret,
    $TwitterAccessToken = $env:TwitterAccessToken,
    $TwitterAccessTokenSecret = $env:TwitterAccessTokenSecret,
    $MyTwitterAPIKey = $env:MyTwitterAPIKey,
    $MyTwitterAPISecret = $env:MyTwitterAPISecret,
    $MyTwitterAccessToken = $env:MyTwitterAccessToken,
    $MyTwitterAccessTokenSecret = $env:MyTwitterAccessTokenSecret
)
$VerbosePreference = "continue"

$yaml = @"
- Name: XpandPwsh
  Version: 1.201.11.7
- Name: PSTwitterAPI
  Version: 0.0.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

$dxVersion = Get-DevExpressVersion -LatestVersionFeed $DXApiFeed
$message = "New @DevExpresss_XAF version $dxVersion is in the private #DevExpreess nuget feed."
$OAuthSettings = @{
    ApiKey            = $TwitterAPIKey
    ApiSecret         = $TwitterAPISecret
    AccessToken       = $TwitterAccessToken
    AccessTokenSecret = $TwitterAccessTokenSecret
}
Set-TwitterOAuthSettings @OAuthSettings

$timeline = Get-TwitterStatuses_UserTimeline -screen_name 'eXpandFramework' -count 1000
$expandId = (Get-TwitterUsers_Lookup -screen_name 'eXpandFramework').Id
if (!($timeline | Where-Object { $_.user.id -eq $expandId -and $_.text -like "*$message*" })) {
    Write-Host $message -f Green
    $twitUpdate=Send-TwitterStatuses_Update -status $message 
    $tolisssId = (Get-TwitterUsers_Lookup -screen_name 'tolisss').Id
    Send-TwitterDirectMessages_EventsNew -recipient_id $tolisssId -text $message 

    Write-HostFormatted "Retweet tolisss" -Section
    $OAuthSettings = @{
        ApiKey            = $MyTwitterAPIKey
        ApiSecret         = $MyTwitterAPISecret
        AccessToken       = $MyTwitterAccessToken
        AccessTokenSecret = $MyTwitterAccessTokenSecret
    }
    Set-TwitterOAuthSettings @OAuthSettings
    Send-TwitterStatuses_Retweet_Id -id $twitUpdate.Id
}
