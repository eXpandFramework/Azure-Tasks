$packageTwits = @(Get-Content ".\Nugetpackages.txt")
function GetPackageToTweet{
    $notTwitt="Patcher|Xpand.Extensions|Xpand.Collections|Fasterflect|Xpand.XAF.Modules.Reactive.Win|Wizard|Test"
    $publishedPackages=(Get-XpandPackages -PackageType XAFAll -Source Release|Where-Object{$_.Id -notmatch $notTwitt}).Id|Format-Shuffle
    $packageTwit=$publishedPackages|Where-Object{$_ -notin $packageTwits}|Select-Object -First 1
    if (!$packageTwit){
        Set-Content ".\Nugetpackages.txt" ""
        $packageTwits=""
        GetPackageToTweet
    }
    $packageTwit
}
$packageTwit=GetPackageToTweet
# $packageTwit="Xpand.XAF.Modules.Office.Cloud.Microsoft"
Write-HostFormatted "Tweeting $($packageTwit)" -Section
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

$packageTwits+=$packageTwit

$message=@"
#DevExpress_XAF: $summary

Compatibility: >= 3 years

$(Get-XpandPackageHome -Id $packageTwit)#details

#XAF_Modules #rx #developer #business
"@
$message=Format-Text -Text $message.Trim() -length 280 -UrlLength 24
Write-HostFormatted "Message" -Section
$message

if ($twitterTag -like "*https://*.gif*"){
    $regex = [regex] '(?i)\b(https?|ftp|file)://[-A-Z0-9+&@#/%?=~_|$!:,.;]*[A-Z0-9+&@#/%=~_|$]'
    $result = $regex.Match($twitterTag).Value;
    Remove-Item "$env:TEMP\$packageTwit" -Force -Recurse -ErrorAction SilentlyContinue
    New-Item "$env:TEMP\$packageTwit" -ItemType Directory
    $c.DownloadFile($result,"$env:TEMP\$packageTwit\$($packageTwit).gif")
    $outputFile=Get-Item "$env:TEMP\$packageTwit\$($packageTwit).gif"
    Split-Video -Video $outputFile -Parts 2
    Remove-Item "$env:TEMP\$packageTwit\$packageTwit.gif"
    Set-Location "$env:TEMP\$packageTwit"
    $startGif=Get-ChildItem $env:TEMP\$packageTwit *.gif
    Write-HostFormatted "startGif" -Section
    $startGif
    "count=$($startGif.Count)"
    if ($startGif.Count -ne 2){
        throw "failed"
    }
    $videoInfo=Get-VideoInfo ($startGif|Select-Object -First 1)
    $frameRate=Invoke-Expression ($videoInfo.r_frame_rate)
    New-Image $videoInfo.width $videoInfo.height
    $image=Get-Item image.png
    Write-HostFormatted "new-image" -Section
    $image
    $c=[System.Net.WebClient]::new()
    $c.DownloadFile("https://user-images.githubusercontent.com/159464/89112500-317c2f00-d46c-11ea-824c-172cb95ee6df.png","$env:TEMP\overlay.png")
    Add-ImageAnnotation -Image $image -ImageOverlay "$env:TEMP\overlay.png" 
    
    $msgVideo=New-Video $image "$env:TEMP\$packageTwit\$($packageTwit)_Msg.mp4" 10 $frameRate|ConvertTo-GifFromMp4
    
    $videos=@($msgVideo,($startGif|Select-Object -First 1),$msgVideo,($startGif|Select-Object -Last 1)) 
    Write-HostFormatted "videos list" -Section
    $videos
    $videoWidth=$videoInfo.width
    if ($videoWidth -gt 1024){
        $videoWidth=1024
    }
    
    $videos|Join-Video -OutputFile $outputFile.fullname
    $outputFile=Optimize-Gif -Gif $outputFile -Scale 1024
    
    
}
else{
    
    ConvertTo-Image $twitterTag -OutputFile "$env:TEMP\$($packageTwit).png" -MaximumSizeBytes 5000000 -MaximumWidth 1024
    $outputFile=get-item "$env:TEMP\$($packageTwit).png"
}

Write-HostFormatted "TwitterStatuses_Update" -Section
$media=Push-TwitterMedia $twitterContext $outputFile 
$media

$tweet=XpandPwsh\Send-Tweet -TwitterContext $twitterContext -status $message -Media $media

Write-HostFormatted "Storing twit" -Section
Set-Content $env:TEMP\storage\twitter\NugetPackages.txt $packageTwits 
Set-Location $env:TEMP\storage\
Push-Git -AddAll -Message $packageTwit -UserMail $GitUserEmail -Username "apobekiaris"

Write-HostFormatted "Retweet tolisss" -Section
Send-Retweet $myTwitterContext $tweet
New-TwitterFavorite $myTwitterContext $tweet

Write-HostFormatted "DM tolisss" -Section
Send-TweetDirectMessage $twitterContext $tolisss $message

