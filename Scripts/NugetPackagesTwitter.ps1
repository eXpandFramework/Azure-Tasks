. "$PSScriptRoot\Twitter.ps1"
$packageTwits=@()
if (Test-Path .\NugetPackages.txt) {
    $packageTwits = @(Get-Content ".\NugetPackages.txt")
}
$publishedPackages=Get-XpandPackages -PackageType XAFAll -Source Release|Where-Object{$_.Id -notmatch "Patcher|Xpand.Extensions|Xpand.Collections|Fasterflect"}|ForEach-Object{
    [PSCustomObject]@{
        Name = $_.Id
        Summary=(Get-NugetPackageSearchMetadata $_.Id -Source (Get-PackageFeed -Nuget)).Summary
    }
}
Write-HostFormatted "publishedPackages" -Section
$publishedPackages
$packageTwit=$publishedPackages|Where-Object{$_.Name -notin $packageTwits}|Select-Object -First 1
if (!$packageTwit){
    $packageTwit=$publishedPackages|Select-Object -First 1
    if (!$packageTwits){
        Remove-Item .\NugetPackages.txt
    }
}
$packageTwits+=$packageTwit.Name
$message=@"
The $($packageTwit.Name) @DevExpress_XAF:

$($packageTwit.Summary)

Wiki: $(Get-XpandPackageHome -Id $packageTwit.Name)
"@
Write-HostFormatted "Message" -Section
$message
Write-HostFormatted "TwitterStatuses_Update" -Section
$OAuthSettings = @{
    ApiKey = $TwitterAPIKey
    ApiSecret = $TwitterAPISecret
    AccessToken = $TwitterAccessToken
    AccessTokenSecret =$TwitterAccessTokenSecret
}
Set-TwitterOAuthSettings @OAuthSettings
# $twitUpdate=Send-TwitterStatuses_Update -status $message 

Write-HostFormatted "Storing twit" -Section
Set-Content .\NugetPackages.txt $packageTwits
Set-AzStorageBlobContent -File ".\NugetPackages.txt" -Container "twitter" -Blob "NugetPackages.txt" -Context $storageAccount.Context -Force

Write-HostFormatted "DM tolisss" -Section
$tolisssId=(Get-TwitterUsers_Lookup -screen_name 'tolisss').Id
Send-TwitterDirectMessages_EventsNew -recipient_id $tolisssId -text $message 

Write-HostFormatted "Retweet tolisss" -Section
$OAuthSettings = @{
    ApiKey = $MyTwitterAPIKey
    ApiSecret = $MyTwitterAPISecret
    AccessToken = $MyTwitterAccessToken
    AccessTokenSecret =$MyTwitterAccessTokenSecret
  }
Set-TwitterOAuthSettings @OAuthSettings
Send-TwitterStatuses_Retweet_Id -id $twitUpdate.Id 
Send-TwitterFavorites_Create -id $twitUpdate.Id
