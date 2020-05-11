$packageTwits = @(Get-Content ".\Nugetpackages.txt")
$publishedPackages=(Get-XpandPackages -PackageType XAFAll -Source Release|Where-Object{$_.Id -notmatch "Patcher|Xpand.Extensions|Xpand.Collections|Fasterflect"}).Id|Format-Shuffle
$packageTwit=$publishedPackages|Where-Object{$_ -notin $packageTwits}|Select-Object -First 1
$homePage=(Get-XpandPackageHome $packageTwit).Replace("https://github.com/eXpandFramework/DevExpress.XAF/tree/master/","https://raw.githubusercontent.com/eXpandFramework/DevExpress.XAF/master/")
$c=[System.Net.WebClient]::new()
$readMe=$c.DownloadString("$homePage/Readme.md")
$regex = [regex] '(?is)<twitter\b[^>]*>(.*?)</twitter>'
$twitterTag = "$($regex.Match($readMe).Groups[1].Value)".Trim();
if (!$twitterTag){
    throw "Twitter tag not found"
}
$regex = [regex] '(?is)# About([^#]*)'
$summary = $regex.Match($readMe).Groups[1].Value.Trim();

Write-HostFormatted "publishedPackages" -Section
$publishedPackages

if (!$packageTwit){
    $packageTwit=$publishedPackages|Select-Object -First 1
    if (!$packageTwits){
        Remove-Item .\NugetPackages.txt
    }
}
Write-HostFormatted "Tweeting $($packageTwit)" -Section
$packageTwits+=$packageTwit

$message=@"
@DevExpress_XAF: $summary

Compatibility: >= 3 years

$(Get-XpandPackageHome -Id $packageTwit)#details

#XAF_Modules #rx #developer #business
"@
$message=Format-Text $message.Trim() -length 280 -UrlLength 24
Write-HostFormatted "Message" -Section
$message

if ($twitterTag -like "*https://*.gif*"){
    $regex = [regex] '(?i)\b(https?|ftp|file)://[-A-Z0-9+&@#/%?=~_|$!:,.;]*[A-Z0-9+&@#/%=~_|$]'
    $result = $regex.Match($twitterTag).Value;
    $outputFile="$env:TEMP\$($packageTwit).gif"
    $c.DownloadFile($result,$outputFile)
}
else{
    $outputFile="$env:TEMP\$($packageTwit).png"
    ConvertTo-Image $twitterTag -OutputFile $outputFile -MaximumSizeBytes 5000000 -MaximumWidth 1024
    $outputFile
}

Write-HostFormatted "TwitterStatuses_Update" -Section
$media=Push-TwitterMedia $twitterContext $outputFile 
$media
$tweet=Send-Tweet $twitterContext $message $media

Write-HostFormatted "Storing twit" -Section
Set-Content $env:TEMP\storage\twitter\NugetPackages.txt $packageTwits
Push-Git -AddAll -Message $packageTwit -UserMail $GitUserEmail -Username "apobekiaris"

Write-HostFormatted "Retweet tolisss" -Section
Send-Retweet $myTwitterContext $tweet
New-TwitterFavorite $myTwitterContext $tweet

Write-HostFormatted "DM tolisss" -Section
Send-TweetDirectMessage $twitterContext $tolisss $message

