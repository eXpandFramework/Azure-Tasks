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
        [int]$Index,
        [hashtable]$OAuthSettings,
        $MyOAuthSettings,
        $timeline,
        $expandId,
        $tolisssId
    )
    $ErrorActionPreference="Continue"
    Set-TwitterOAuthSettings @OAuthSettings -Force
    $ErrorActionPreference="Stop"
    if ($Index -eq 0){
        $mainVersion=(Get-NugetPackage -Name "eXpandSystem" -Source (Get-PackageFeed -Nuget) -ResultType NupkgFile|ConvertTo-PackageObject).Version
        if ($mainVersion -ge ([version]$dxVersion)){
            $mainReleaseMsg="Our main release $mainVersion is already compatible.`r`n`r`nhttps://github.com/eXpandFramework/eXpand/releases/tag/$mainVersion"
        }
        else{
            $mainReleaseMsg="We will soon provide a compatible release for the main framework. Watch the releases to get notified.`r`n`r`nhttps://github.com/eXpandFramework/eXpand/releases"
        }
    }
    elseif ($Index -gt -1){
        $mainReleaseMsg="XAF releases published while a more recent version is already out, are not supported from our main framework. Feel free to download the latest compatible source and build it on your own.`r`n`r`nhttps://github.com/eXpandFramework/eXpand/releases"
    }
    else{
        $mainReleaseMsg="XAF preleases are not supported from the main framework. Feel free to download the latest compatible source and build it on your own.`r`n`r`nhttps://github.com/eXpandFramework/eXpand/releases"
    }
    if ($Index -gt -1){
        $build=Get-AzBuilds -Definition DevExpress.XAF-Lab-Tests -Tag "$dxVersion.0" -BranchName "master" -Result succeeded|Select-Object -Last 1
    }
    $xafPackages="The packages from the DevExpress.XAF repository are version agnostic so they work with $dxVersion"
    if ($build -and ([System.DateTimeOffset]::Now.Subtract([System.DateTimeOffset]::Parse($build.finishTime)).TotalHours -gt 8)){
        $xafPackages+=" and the tests run already to verify it.`r`n`r`nhttps://github.com/eXpandFramework/DevExpress.XAF#compatibility-matrix"
    }
    elseif ($Index -gt -1){
        $xafPackages+=" however the tests did not run yet to verify it. We will twitt again once the test builld is green.`r`n`r`nhttps://github.com/eXpandFramework/DevExpress.XAF#compatibility-matrix"
    }
    
    $message = "New @DevExpresss_XAF version ($dxVersion) is in the private #DevExpress nuget feed."
    if (!($timeline | Where-Object { $_.user.id -eq $expandId -and $_.text -like "*$message*" -and $_.text -notlike "*twitt again*" })) {
        $message+="`r`n`r`n$mainReleaseMsg`r`n`r`n$xafPackages"
        Write-HostFormatted message -Section
        $message
        $twitUpdate=Send-TwitterStatuses_Update -status $message 
        
        Send-TwitterDirectMessages_EventsNew -recipient_id $tolisssId -text "$message`r`n`r`nRUN BACKUP-DX" 
    
        Write-HostFormatted "Retweet tolisss" -Section
        $ErrorActionPreference="Continue"
        Set-TwitterOAuthSettings @MyOAuthSettings -Force
        $ErrorActionPreference="Stop"
        Send-TwitterStatuses_Retweet_Id -id $twitUpdate.Id
    }
}
$timeline = Get-TwitterStatuses_UserTimeline -screen_name 'eXpandFramework' -count 1000
$expandId = (Get-TwitterUsers_Lookup -screen_name 'eXpandFramework').Id
$tolisssId = (Get-TwitterUsers_Lookup -screen_name 'tolisss').Id
$latestVersion=Get-XAFLatestMinors -Source $DXApiFeed |ConvertTo-Indexed

$latestVersion|ForEach-Object{
    $dxVersion=Get-VersionPart $_.Value Build
    Twitt $dxVersion $_.Index $OAuthSettings $MyOAuthSettings $timeline $expandId $tolisssId
}
$metadata=Get-NugetPackageSearchMetadata -Name DevExpress.ExpressApp -Source $DXApiFeed -IncludePrerelease
if ($metadata.Identity.Version.IsPrerelease){
    $dxVersion = $metadata.identity.Version.OriginalVersion
    Twitt $dxVersion -1 $OAuthSettings $MyOAuthSettings $timeline $expandId $tolisssId
}

