param(
    $DXApiFeed = $env:DxFeed,
    $TwitterAPIKey = $env:TwitterAPIKey,
    $TwitterAPISecret = $env:TwitterAPISecret,
    $TwitterAccessToken = $env:TwitterAccessToken,
    $TwitterAccessTokenSecret = $env:TwitterAccessTokenSecret,
    $MyTwitterAPIKey = $env:MyTwitterAPIKey,
    $MyTwitterAPISecret = $env:MyTwitterAPISecret,
    $MyTwitterAccessToken = $env:MyTwitterAccessToken,
    $MyTwitterAccessTokenSecret = $env:MyTwitterAccessTokenSecret,
    $AzDevOpsToken=$env:AzDevOpsToken
)
$yaml = @"
- Name: XpandPwsh
  Version: 1.201.22.1
- Name: PSTwitterAPI
  Version: 0.0.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
if (Test-AzDevops){
    $env:AzDevopsToken = $AzDevOpsToken
    $env:AzOrganization = "eXpandDevOps"
    $env:AzProject = "eXpandFramework"
}
$VerbosePreference="continue"
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
        $OAuthSettings,
        $MyOAuthSettings,
        $timeline,
        $expandId,
        $tolisssId
    )
    Set-TwitterOAuthSettings @OAuthSettings
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
        $mainReleaseMsg="Outdated XAF releases are not supported from the main framework. However you can custom build`r`n`r`nreleases.expandframework.com"
    }
    else{
        $mainReleaseMsg="XAF preleases are not supported from the main framework. However you can custom build`r`n`r`nreleases.expandframework.com"
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
    
    $message = "New @DevExpresss_XAF version $dxVersion is in the private #DevExpress nuget feed."
    $needsTwitt=!($timeline | Where-Object { $_.user.id -eq $expandId -and $_.text -like "*$message*" -and $_.text -notlike "*twitt again*" })
    if ($needsTwitt) {
        $message+="`r`n`r`n$mainReleaseMsg"
        Write-HostFormatted message -Section
        $message
        $twitUpdate=Send-TwitterStatuses_Update -status $message 
        Set-TwitterOAuthSettings @MyOAuthSettings
        Write-HostFormatted "Retweet tolisss" -Section
        Send-TwitterStatuses_Retweet_Id -id $twitUpdate.Id
        Send-TwitterDirectMessages_EventsNew -recipient_id $tolisssId -text "$message`r`n`r`nRUN BACKUP-DX" 
        $xafPackages
        $twitUpdate=Send-TwitterStatuses_Update -status $xafPackages 
        Set-TwitterOAuthSettings @MyOAuthSettings
        Write-HostFormatted "Retweet tolisss" -Section
        Send-TwitterStatuses_Retweet_Id -id $twitUpdate.Id
        Send-TwitterDirectMessages_EventsNew -recipient_id $tolisssId -text "$xafPackages`r`n`r`nRUN BACKUP-DX" 
    }
    else{
        Set-TwitterOAuthSettings @MyOAuthSettings
    }
}


Get-Variable OAuthSettings|Out-Variable
Set-TwitterOAuthSettings @OAuthSettings
$timeline = Get-TwitterStatuses_UserTimeline -screen_name 'eXpandFramework' -count 1000
$expandId = (Get-TwitterUsers_Lookup -screen_name 'eXpandFramework').Id
Get-Variable expandId|Out-Variable
$tolisssId = (Get-TwitterUsers_Lookup -screen_name 'tolisss').Id
Get-Variable tolisssId|Out-Variable
$latestVersion=Get-XAFLatestMinors -Source $DXApiFeed |ConvertTo-Indexed
Get-Variable latestVersion|Out-Variable
$latestVersion|ForEach-Object{
    $dxVersion=Get-VersionPart $_.Value Build
    Write-HostFormatted "Twitt $dxVersion" -Section
    Twitt $dxVersion $_.Index $OAuthSettings $MyOAuthSettings $timeline $expandId $tolisssId
}
$metadata=Get-NugetPackageSearchMetadata -Name DevExpress.ExpressApp -Source $DXApiFeed -IncludePrerelease
if ($metadata.Identity.Version.IsPrerelease){
    $dxVersion = $metadata.identity.Version.OriginalVersion
    Write-HostFormatted "Prelease $dxVersion" -Section
    Twitt $dxVersion -1 $OAuthSettings $MyOAuthSettings $timeline $expandId $tolisssId
}

