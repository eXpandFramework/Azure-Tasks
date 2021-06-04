$notTwitt = "Patcher|Xpand.Extensions|Xpand.Collections|Fasterflect|Xpand.XAF.Modules.Reactive.Win|Wizard|Test|Rest|ModelEditor"
$publishedPackages = (Get-XpandPackages -PackageType XAFAll -Source Release | Where-Object { $_.Id -notmatch $notTwitt }).Id #|Where-Object{$_ -eq "Xpand.XAF.Modules.HideToolBar"}
# $packages=$publishedPackages|Invoke-Parallel -script {
$packages = $publishedPackages| ForEach-Object {
    $package = $_
    $homePage = (Get-XpandPackageHome $package).Replace("https://github.com/eXpandFramework/Reactive.XAF/tree/master/", "https://raw.githubusercontent.com/eXpandFramework/Reactive.XAF/master/")
    $c = [System.Net.WebClient]::new()
    $readMe = $c.DownloadString("$homePage/Readme.md")
    $regex = [regex] '(?is)# About([^#]*)'
    $summary = $regex.Match($readMe).Groups[1].Value.Trim();
    $regex = [regex] '(?is)<twitter\b[^>]*>(.*?)</twitter>'
    ($regex.Matches($readMe)) | ForEach-Object {
        if ($_.Value) {
            $_.Value
        }
    }|ForEach-Object{    
        ([PSCustomObject]@{
            Name  = $package
            Tag = $_
            Tweeted=0
            Summary=$summary
        })
    }
}

# Set-Content ".\Nugetpackages.txt" (ConvertTo-Json $packages)
$storedPackages=ConvertFrom-Json (Get-Content ".\Nugetpackages.txt" -Raw)
$packageTwit=$packages|ForEach-Object{
    $package=$_
    $storedPackages|Where-Object{$_.Name -eq $package.Name}|ForEach-Object{
        $package.Tweeted=$_.Tweeted
    }
    $package
}| Format-Shuffle|Where-Object{!$_.Tweeted}|Select-Object -First 1
$packageTwit.Tweeted=1
Write-HostFormatted "Tweeting $($packageTwit.Name)" -Section

$homePage = (Get-XpandPackageHome $packageTwit.Name).Replace("https://github.com/eXpandFramework/Reactive.XAF/tree/master/", "https://raw.githubusercontent.com/eXpandFramework/Reactive.XAF/master/")
if (!$packageTwit.Tag) {
    throw "Twitter tag not found"
}

$regex = [regex] '(?is)tags="([^"]*)'

$extraTags=$regex.Match($packageTwit.Tag).Groups[1].Value
$message = @"
#DevExpress_XAF: $($packageTwit.Summary)

Compatibility: >= 3 years

$(Get-XpandPackageHome -Id $packageTwit.Name)#details

#XAF_Modules #rx #developer #business $extraTags
"@
$message = Format-Text -Text $message.Trim() -length 280 -UrlLength 24
Write-HostFormatted "Message" -Section
$message

if ($packageTwit.Tag -like "*https://*.gif*") {
    $regex = [regex] '(?i)\b(https?|ftp|file)://[-A-Z0-9+&@#/%?=~_|$!:,.;]*[A-Z0-9+&@#/%=~_|$]'
    $result = $regex.Match($packageTwit.Tag).Value;
    Remove-Item "$env:TEMP\$packageTwit" -Force -Recurse -ErrorAction SilentlyContinue
    New-Item "$env:TEMP\$($packageTwit.Name)" -ItemType Directory 
    $c.DownloadFile($result, "$env:TEMP\$($packageTwit.Name)\$($packageTwit.Name).gif")
    $outputFile = Get-Item "$env:TEMP\$($packageTwit.Name)\$($packageTwit.Name).gif"
    Split-Video -Video $outputFile -Parts 2
    Remove-Item "$env:TEMP\$($packageTwit.Name)\$($packageTwit.Name).gif"
    Set-Location "$env:TEMP\$($packageTwit.Name)"
    $startGif = Get-ChildItem "$env:TEMP\$($packageTwit.Name)\*.gif"
    Write-HostFormatted "startGif" -Section
    $startGif
    "count=$($startGif.Count)"
    if ($startGif.Count -ne 2) {
        throw "failed"
    }
    $videoInfo = Get-VideoInfo ($startGif | Select-Object -First 1)
    $frameRate = Invoke-Expression ($videoInfo.r_frame_rate)
    New-Image $videoInfo.width $videoInfo.height
    $image = Get-Item image.png
    Write-HostFormatted "new-image" -Section
    $image
    $c = [System.Net.WebClient]::new()
    $c.DownloadFile("https://user-images.githubusercontent.com/159464/109433099-44ada800-7a17-11eb-9d3e-d0b3f7e4843e.png", "$env:TEMP\overlay.png")
    Add-ImageAnnotation -Image $image -ImageOverlay "$env:TEMP\overlay.png" 
    
    $msgVideo = New-Video $image "$env:TEMP\$($packageTwit.Name)\$($packageTwit.Name)_Msg.mp4" 10 $frameRate | ConvertTo-GifFromMp4
    
    $videos = @($msgVideo, ($startGif | Select-Object -First 1), $msgVideo, ($startGif | Select-Object -Last 1)) 
    Write-HostFormatted "videos list" -Section
    $videos
    $videoWidth = $videoInfo.width
    if ($videoWidth -gt 1024) {
        $videoWidth = 1024
    }
    
    $videos | Join-Video -OutputFile $outputFile.fullname
    $outputFile = Optimize-Gif -Gif $outputFile -Scale 1024
    
    
}
else {
    $regex = [regex] '(?is)<twitter\b[^>]*>(.*?)</twitter>'
    $twitterTag = "$($regex.Match($packageTwit.Tag).Groups[1].Value)".Trim();
    ConvertTo-Image $twitterTag -OutputFile "$env:TEMP\$($packageTwit.Name).png" -MaximumSizeBytes 5000000 -MaximumWidth 1024
    $outputFile = get-item "$env:TEMP\$($packageTwit.Name).png"
}

Write-HostFormatted "TwitterStatuses_Update" -Section
$media = Push-TwitterMedia $twitterContext $outputFile 
$media

$tweet = XpandPwsh\Send-Tweet -TwitterContext $twitterContext -status $message -Media $media

Write-HostFormatted "Storing twit" -Section

Set-Content $env:TEMP\storage\twitter\NugetPackages.txt (ConvertTo-Json $packages)
Set-Location $env:TEMP\storage\
Push-Git -AddAll -Message $packageTwit.Name -UserMail $GitUserEmail -Username "apobekiaris"

Write-HostFormatted "Retweet tolisss" -Section
Send-Retweet $myTwitterContext $tweet
New-TwitterFavorite $myTwitterContext $tweet

Write-HostFormatted "DM tolisss" -Section
Send-TweetDirectMessage $twitterContext $tolisss $message

