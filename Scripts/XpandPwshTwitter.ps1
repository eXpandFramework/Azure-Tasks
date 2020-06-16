function GetAttributes($command) {
    if ($command.CommandType -eq "cmdlet") {
        $command.ImplementingType.GetCustomAttributes([System.Attribute])
    }
    else {
        $command.ScriptBlock.Attributes
    }
    
}
Push-Location $env:TEMP
git clone "https://github.com/eXpandFramework/XpandPwsh.wiki.git"
Pop-Location

$twits = @(Get-Content ".\XpandPwsh.txt")
$availableCommands = Get-Command  -Module XpandPwsh | Where-Object {
    GetAttributes $_ | Where-Object { $_.TypeId.Name -eq "CmdLetTag" }
} | Where-Object { $_.Name -notin $twits }|Format-Shuffle
$c = [System.Net.WebClient]::new()
$readme = $c.DownloadString("https://raw.githubusercontent.com/eXpandFramework/XpandPwsh/master/ReadMe.md")
# $availableCommands=@(Get-Command "Unprotect-SecretVariable")
$command = $availableCommands | ForEach-Object {
    $commandName = $_.Name
    $regex = [regex] "(?isn)\[$commandName\]\(https://github\.com/expandframework/xpandpwsh/wiki/$commandName\)\|(?<text>[^|]*)"
    $synopsis = $regex.Match($readme).Groups["text"].Value;
    if ($synopsis -and $synopsis -notlike "*Fill in the Synopsis*") {
        [PSCustomObject]@{
            Command  = $_
            Synopsis = $synopsis
        }
    }
} | Select-Object -First 1
$commandName =$command.Command.Name 
if (!$commandName){
    throw "No CmdLet found"
}
Write-HostFormatted  "Twit $($command.Command.Name)" -Section
$twits += $command.Command.Name
$url = "https://github.com/eXpandFramework/XpandPwsh/wiki/$($command.Command.Name)"
$result = @"
The $commandName #XpandPwsh PowerShell CmdLet: 

$($command.Synopsis)

Wiki: $url

"@
    
$tags = @((GetAttributes $command.Command).Tags)
$tags += "@Devexpress_XAF","#DevExpress", "#powershell", "#automation","#developer","#business"
$result += "`r`n`r`n$($tags -join ', ')"
$result=Format-Text $result -length 280 -UrlLength 23
Write-HostFormatted "Message" -Section
$message=$result
$message
Write-HostFormatted "TwitterStatuses_Update" -Section

$mdReadMe=Get-Content (Get-ChildItem "$env:TEMP\XpandPwsh.wiki" "$($command.Command.Name).md" -Recurse) -raw
$regex = [regex] '(?is)### Example 1(?<text>.*)((### EXAMPLE 2)|(## PARAMETERS))'
$examble=@"
![hire-logo](https://user-images.githubusercontent.com/159464/84767068-7e9a6380-afda-11ea-967b-78404a94bfc2.png)
"@
$examble += $regex.Match($mdReadMe).Groups['text'].Value;
$examble+="`r`n`r`n---"
$image="$env:TEMP\$($command.Command.Name).png"
ConvertTo-Image $examble $image -MaximumSizeBytes 500000 -Width 1100 -MinimumCanvasHeight 628
$image

$media=Push-TwitterMedia $twitterContext $image -MediaCategory tweet_image
$tweet=Send-Tweet $twitterContext $message $media
$tweet

Write-HostFormatted "Storing twit" -Section
Set-Content $env:TEMP\storage\twitter\XpandPwsh.txt $twits
Push-Git -AddAll -Message $commandName -UserMail $GitUserEmail -Username "apobekiaris"

Write-HostFormatted "DM tolisss" -Section
Send-TweetDirectMessage $twitterContext $tolisss $message


Test-TwitterCredentials $myTwitterContext
Write-HostFormatted "Favorite tolisss" -Section
New-TwitterFavorite $myTwitterContext $tweet
Write-HostFormatted "Retweet tolisss" -Section
Send-Retweet $myTwitterContext $tweet  


