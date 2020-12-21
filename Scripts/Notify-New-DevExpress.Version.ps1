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
    $AzureToken=$env:AzureToken
)
$yaml = @"
- Name: XpandPwsh
  Version: 1.202.48.4
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
if (Test-AzDevops){
    $env:AzureToken = $AzureToken
    $env:AzOrganization = "eXpandDevOps"
    $env:AzProject = "eXpandFramework"
}
$twitterContext=New-TwitterContext $TwitterAPIKey $TwitterAPISecret $TwitterAccessToken $TwitterAccessTokenSecret
$myTwitterContext=New-TwitterContext $MyTwitterAPIKey $MyTwitterAPISecret $MyTwitterAccessToken $MyTwitterAccessTokenSecret
$VerbosePreference="continue"

function Twitt {
    param (
        $dxVersion,
        [int]$Index,
        $timeline,
        $expandId,
        $tolisssId
    )
    
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
    $needsTwitt=!($timeline | Where-Object { $_.text -like "*$message*" -and $_.text -notlike "*twitt again*" })
    if ($needsTwitt) {
        $message+="`r`n`r`n$mainReleaseMsg"
        Write-HostFormatted message -Section
        $message
        $twitUpdate=Send-Tweet $twitterContext $message
        
        Write-HostFormatted "Retweet tolisss" -Section
        Send-Retweet $myTwitterContext $twitUpdate
        Send-TweetDirectMessage $twitterContext $tolisssId "$message`r`n`r`nRUN BACKUP-DX"  

        $xafPackages
        $twitUpdate=Send-Tweet $twitterContext $xafPackages 
        Write-HostFormatted "Retweet tolisss" -Section
        Send-Retweet $myTwitterContext $twitUpdate
        Send-TweetDirectMessage $twitterContext $tolisssId "$xafPackages`r`n`r`nRUN BACKUP-DX"  
    }
}

$timeline = Find-Tweet $twitterContext -ScreenName "eXpandFramework" 
$expandId = Find-TwitterUser $twitterContext 'eXpandFramework'
Get-Variable expandId|Out-Variable
$tolisssId = Find-TwitterUser $twitterContext "tolisss"
Get-Variable tolisssId|Out-Variable
$latestVersion=Get-XAFLatestMinors -Source $DXApiFeed |ConvertTo-Indexed
Get-Variable latestVersion|Out-Variable
$latestVersion|ForEach-Object{
    $dxVersion=Get-VersionPart $_.Value Build
    Write-HostFormatted "Twitt $dxVersion" -Section
    Twitt $dxVersion $_.Index $timeline $expandId $tolisssId
}
$metadata=Get-NugetPackageSearchMetadata -Name DevExpress.ExpressApp -Source $DXApiFeed -IncludePrerelease
if ($metadata.Identity.Version.IsPrerelease){
    $dxVersion = $metadata.identity.Version.OriginalVersion
    Write-HostFormatted "Prelease $dxVersion" -Section
    Twitt $dxVersion -1 $timeline $expandId $tolisssId
}

