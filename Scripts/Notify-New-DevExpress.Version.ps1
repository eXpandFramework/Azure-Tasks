param(
    $DXApiFeed=(get-feed -dx),
    $TwitterAPIKey,
    $TwitterAPISecret,
    $TwitterAccessToken,
    $TwitterAccessTokenSecret
)
# $s=Get-TwitterSecrets
# $TwitterAccessToken=$s.AccessToken
# $TwitterAccessTokenSecret=$s.AccessTokenSecret
# $TwitterAPISecret=$s.APISecret
# $TwitterAPIKey=$s.APIKey
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

$timeline=Get-TwitterStatuses_UserTimeline -screen_name 'eXpandFramework'
if(!($timeline|Where-Object{$_.user.id -eq "245344230" -and $_.text -like "*$message*"})){
    # $xpandVersion=Get-XpandVersion -Release
    # if ($xpandVersion -notlike "$dxVersion*"){
        Write-Host $message -f Green
        Send-TwitterStatuses_Update -status $message 
        Send-TwitterDirectMessages_EventsNew -recipient_id toliss -text $message 
        Write-Host "DM toliss"            
        # Send-TwitterDm -Message $message -Username "tolisss"
        
    # }
}
# Remove-MyTwitterConfiguration 