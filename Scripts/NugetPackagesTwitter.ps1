$packageTwits = @(Get-Content ".\Nugetpackages.txt")
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
Write-HostFormatted "Tweeting $($packageTwit.Name)" -Section
$packageTwits+=$packageTwit.Name
$boldText=$packageTwit.Name
$message=@"
@DevExpress_XAF, the $boldText :

$($packageTwit.Summary)

Details: $(Get-XpandPackageHome -Id Xpand.XAF.Modules.LookupCascade)#details

#XAF_Modules #RX #Reactive
"@
$message=Format-Text $message -length 280 -UrlLength 24
Write-HostFormatted "Message" -Section
$message
$homePage=(Get-XpandPackageHome $packageTwit.Name).Replace("https://github.com/eXpandFramework/DevExpress.XAF/tree/master/","https://raw.githubusercontent.com/eXpandFramework/DevExpress.XAF/master/")
$c=[System.Net.WebClient]::new()
$readMe=$c.DownloadString("$homePage/Readme.md")
$regex = [regex] '(?is)<twitter\b[^>]*>(.*?)</twitter>'
$result = "$($regex.Match($readMe).Groups[1].Value)".Trim();
if (!$result){
    throw "Twitter tag not found"
}
if ($result -like "https://*.gif"){
    $regex = [regex] '(?i)\b(https?|ftp|file)://[-A-Z0-9+&@#/%?=~_|$!:,.;]*[A-Z0-9+&@#/%=~_|$]'
    $result = $regex.Match($result).Value;
    $outputFile="$env:TEMP\$($packageTwit.Name).gif"
    $c.DownloadFile($outputFile)
}
else{
    $outputFile="$env:TEMP\$($packageTwit.Name).png"
    ConvertTo-Image $result -OutputFile $outputFile -MaximumSizeBytes 5000000 -MaximumWidth 1024
    $outputFile
}

Write-HostFormatted "TwitterStatuses_Update" -Section
$media=Push-TwitterMedia $twitterContext $outputFile -MediaCategory tweet_image
$media
$tweet=Send-Tweet $twitterContext $message $media

Write-HostFormatted "Storing twit" -Section
Set-Content $env:TEMP\storage\twitter\NugetPackages.txt $packageTwits
Push-Git -AddAll -Message $packageTwit.Name -UserMail $GitUserEmail -Username "apobekiaris"

Write-HostFormatted "Retweet tolisss" -Section
Send-Retweet $myTwitterContext $tweet
New-TwitterFavorite $myTwitterContext $tweet

Write-HostFormatted "DM tolisss" -Section
Send-TweetDirectMessage $twitterContext $tolisss $message

