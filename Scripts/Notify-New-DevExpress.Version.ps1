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
# $VerbosePreference = "continue"

$yaml = @"
- Name: XpandPwsh
  Version: 1.201.12.3
- Name: PSTwitterAPI
  Version: 0.0.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

$OAuthSettings = @{
    ApiKey            = $TwitterAPIKey
    ApiSecret         = $TwitterAPISecret
    AccessToken       = $TwitterAccessToken
    AccessTokenSecret = $TwitterAccessTokenSecret
}
$MyOAuthSettings = @{
    ApiKey            = $MyTwitterAPIKey
    ApiSecret         = $MyTwitterAPISecret
    AccessToken       = $MyTwitterAccessToken
    AccessTokenSecret = $MyTwitterAccessTokenSecret
}

function Twitt {
    param (
        $dxVersion,
        $OAuthSettings,
        $MyOAuthSettings,
        $timeline,
        $expandId,
        $tolisssId
    )
    Set-TwitterOAuthSettings @OAuthSettings
    $message = "New @DevExpresss_XAF version ($dxVersion) is in the private #DevExpreess nuget feed."
    if (!($timeline | Where-Object { $_.user.id -eq $expandId -and $_.text -like "*$message*" })) {
        Write-Host $message -f Green
        $twitUpdate=Send-TwitterStatuses_Update -status $message 
        
        Send-TwitterDirectMessages_EventsNew -recipient_id $tolisssId -text $message 
    
        Write-HostFormatted "Retweet tolisss" -Section
        Set-TwitterOAuthSettings @MyOAuthSettings
        Send-TwitterStatuses_Retweet_Id -id $twitUpdate.Id
    }
}
Set-TwitterOAuthSettings @OAuthSettings
$timeline = Get-TwitterStatuses_UserTimeline -screen_name 'eXpandFramework' -count 1000
$expandId = (Get-TwitterUsers_Lookup -screen_name 'eXpandFramework').Id
$tolisssId = (Get-TwitterUsers_Lookup -screen_name 'tolisss').Id
$latestVersion=Get-XAFLatestMinors -Source $DXApiFeed 
$latestVersion|ForEach-Object{
    $dxVersion=Get-VersionPart $_ Build
    Twitt $dxVersion $OAuthSettings $MyOAuthSettings $timeline $expandId $tolisssId
}
$dxVersion = (Get-NugetPackageSearchMetadata -Name DevExpress.ExpressApp -Source $DXApiFeed -IncludePrerelease).identity.Version.OriginalVersion
Twitt $dxVersion $OAuthSettings $MyOAuthSettings $timeline $expandId $tolisssId

