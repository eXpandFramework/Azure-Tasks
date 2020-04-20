
$twits = @(Get-Content ".\XpandPwsh.txt")

function GetAttributes($command) {
    if ($command.CommandType -eq "cmdlet") {
        $command.ImplementingType.GetCustomAttributes([System.Attribute])
    }
    else {
        $command.ScriptBlock.Attributes
    }
    
}
$availableCommands = Get-Command  -Module XpandPwsh | Where-Object {
    GetAttributes $_ | Where-Object { $_.TypeId.Name -eq "CmdLetTag" }
} | Where-Object { $_.Name -notin $twits }
$c = [System.Net.WebClient]::new()
$readme = $c.DownloadString("https://raw.githubusercontent.com/eXpandFramework/XpandPwsh/master/ReadMe.md")
$command = $availableCommands | ForEach-Object {
    $commandName = $_.Name
    $regex = [regex] "(?isn)\[$commandName\]\(https://github\.com/expandframework/xpandpwsh/wiki/$commandName\)\|(?<text>[^|]*)"
    $result = $regex.Match($readme).Groups["text"].Value;
    if ($result -and $result -notlike "*Fill in the Synopsis*") {
        [PSCustomObject]@{
            Command  = $_
            Synopsis = $result
        }
    }
} | Select-Object -First 1
$commandName = $command.Command.Name
if (!$commandName){
    throw "No CmdLet found"
}
Write-HostFormatted  "Twit $commandName" -Section
$twits += $commandName

$result = "The $commandName #XpandPwsh PowerShell CmdLet: $($command.Synopsis)"
$url = "https://github.com/eXpandFramework/XpandPwsh/wiki/$commandName"
$tags = @((GetAttributes $command.Command).Tags)
$tags += "#DevExpress", "#XAF", "#powershell", "#pscore", "@expandframework", "@Devexpress_XAF"
$tagsText = $tags -join ", "
$text = "`r`n`r`n$url`r`n`r`n$tagsText"
$usedLenght = 24 + $tagsText.Length + (4 * "`r`n".Length)
if (280 - $usedLenght - 2 -lt ($result.Length)) {
    $result = $result.Substring(0, 280 - $usedLenght - 1)
}
$result += $text
        
Write-HostFormatted "Message" -Section
$message=$result
$message
Write-HostFormatted "TwitterStatuses_Update" -Section
$OAuthSettings = @{
    ApiKey = $TwitterAPIKey
    ApiSecret = $TwitterAPISecret
    AccessToken = $TwitterAccessToken
    AccessTokenSecret =$TwitterAccessTokenSecret
}
Set-TwitterOAuthSettings @OAuthSettings
$twitUpdate=Send-TwitterStatuses_Update -status $message 
$twitUpdate

Write-HostFormatted "Storing twit" -Section
Set-Content $env:TEMP\storage\twitter\XpwshTwits.txt $twits
Push-Git -AddAll -Message $commandName -UserMail $GitUserEmail -Username "apobekiaris"

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




