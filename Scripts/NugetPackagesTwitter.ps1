function GetPackageToTweet{
    $packageTwits = @(Get-Content ".\Nugetpackages.txt")
    $notTwitt="Patcher|Xpand.Extensions|Xpand.Collections|Fasterflect|Xpand.XAF.Modules.Reactive.Win|Wizard"
    $publishedPackages=(Get-XpandPackages -PackageType XAFAll -Source Release|Where-Object{$_.Id -notmatch $notTwitt}).Id|Format-Shuffle
    $packageTwit=$publishedPackages|Where-Object{$_ -notin $packageTwits}|Select-Object -First 1
    if (!$packageTwit){
        Set-Content ".\Nugetpackages.txt" ""
        GetPackageToTweet
    }
    $packageTwit
}
# $packageTwit=GetPackageToTweet
$packageTwit="Xpand.XAF.Modules.Office.Cloud.Microsoft.Todo"
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
@DevExpress_XAF: $summary

Compatibility: >= 3 years

$(Get-XpandPackageHome -Id $packageTwit)#details

#XAF_Modules #rx #developer #business
"@
$message=Format-Text -Text $message.Trim() -length 280 -UrlLength 24
Write-HostFormatted "Message" -Section
$message
function ConvertTo-GifFromMp41 {
    [CmdletBinding()]
    
    param (
        [parameter(Mandatory,ValueFromPipeline)]
        [System.IO.FileInfo]$Mp4Path,
        [parameter()]
        [string]$OutputFile,
        [int]$FrameRate=15,
        [int]$Width=-1
    )
    
    begin {
        if (!(Get-Chocopackage ffmpeg)){
            Install-ChocoPackage ffmpeg
        }
        
    }
    
    process {
        if (!$OutputFile){
            $OutputFile="$($Mp4Path.DirectoryName)\$($Mp4Path.BaseName).gif"
        }
        Remove-Item $OutputFile -ErrorAction SilentlyContinue
        $palette="$env:TEMP/palette.png"

        # $filters="fps=$FrameRate,scale=$Width`:-1:flags=lanczos"
        # ffmpeg -v warning -i $Mp4Path -vf "$filters,palettegen=stats_mode=diff" -y $palette
        # ffmpeg -i $Mp4Path -i $palette -lavfi "$filters,paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y $OutputFile
        ffmpeg -i $Mp4Path  $OutputFile
        Get-Item $OutputFile
    }
    
    end {
        
    }
}
if ($twitterTag -like "*https://*.gif*"){
    $regex = [regex] '(?i)\b(https?|ftp|file)://[-A-Z0-9+&@#/%?=~_|$!:,.;]*[A-Z0-9+&@#/%=~_|$]'
    $result = $regex.Match($twitterTag).Value;
    Remove-Item "$env:TEMP\$packageTwit" -Force -Recurse -ErrorAction SilentlyContinue
    New-Item "$env:TEMP\$packageTwit" -ItemType Directory
    $c.DownloadFile($result,"$env:TEMP\$packageTwit\$($packageTwit).gif")
    $outputFile=Get-Item "$env:TEMP\$packageTwit\$($packageTwit).gif"
    if (!(Get-Chocopackage ffmpeg)){
        Install-ChocoPackage ffmpeg
    }
    # Write-HostFormatted "ToMp4" -Section
    # ffmpeg -i $outputFile  $env:TEMP\$packageTwit.mp4
    # Write-HostFormatted "ToGif" -Section
    # Remove-Item $outputFile
    # ffmpeg -i $env:TEMP\$packageTwit.mp4 $outputFile  
    # return
    $mp4=ConvertTo-Mp4FromGif $outputFile
    
    Split-Video -Parts 2 -Video "$env:TEMP\$packageTwit\$packageTwit.mp4"
    Remove-Item "$env:TEMP\$packageTwit\$packageTwit.mp4"
    Remove-Item "$env:TEMP\$packageTwit\$packageTwit.gif"
    Set-Location "$env:TEMP\$packageTwit"
    $startGif=Get-ChildItem $env:TEMP\$packageTwit *.mp4
    Write-HostFormatted "startGif" -Section
    $startGif
    "count=$($startGif.Count)"
    if ($startGif.Count -ne 2){
        throw "mp4ToGif failed"
    }
    $videoInfo=Get-VideoInfo ($startGif|Select-Object -First 1)
    $frameRate=Invoke-Expression ($videoInfo.r_frame_rate)
    New-Image $videoInfo.width $videoInfo.height
    $image=Get-Item image.png
    Write-HostFormatted "new-image" -Section
    $image
    $c=[System.Net.WebClient]::new()
    $c.DownloadFile("https://user-images.githubusercontent.com/159464/88835926-a20e1c00-d1de-11ea-9e2e-c843443b7b85.png","$env:TEMP\overlay.png")
    Add-ImageAnnotation -Image $image -ImageOverlay "$env:TEMP\overlay.png" 
    
    $msgVideo=New-Video $image "$env:TEMP\$packageTwit\$($packageTwit)_Msg.mp4" 10 $frameRate
    
    $videos=@($msgVideo,($startGif|Select-Object -First 1),$msgVideo,($startGif|Select-Object -Last 1)) 
    Write-HostFormatted "videos list" -Section
    $videos
    $videoWidth=$videoInfo.width
    if ($videoWidth -gt 1024){
        $videoWidth=1024
    }
    
    $videos|Join-Video -OutputFile $outputFile
    
    return
    # $mp4=Join-Video $videos "$env:TEMP\$($packageTwit).mp4"

    # Write-HostFormatted "mp4 join" -Section
    # "mp4=$mp4"
    # $ErrorActionPreference="continue"
    # ConvertTo-GifFromMp41 -Mp4Path $mp4 -Width $videoWidth -OutputFile $outputFile
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

