$rtPrefix = "RT @DevExpress_XAF: "
$lastRetweet = Find-Tweet $twitterContext -ScreenName "expandframework" -IncludeRetweets -TweetMode Extended -MatchPattern $rtPrefix | Select-Object -First 1

$lastRetweetText = ($lastRetweet).RetweetedStatus.fulltext.replace($rtPrefix, "")
"lastRetweet:$($lastRetweetText)"
if (!$lastRetweetText) {
    throw "Last retweet not found"
}
$found = $false
$nextRetweet = Find-Tweet $twitterContext -ScreenName "DevExpress_XAF" -TweetMode Extended | ForEach-Object {
    if (!$found) {
        $found = $_.fulltext -eq $lastRetweetText
        $_
    }
} |Select-Object -SkipLast 1

$nextRetweet|ForEach-Object{
    Write-HostFormatted "Retweet eXpandFramework" -Section
    Send-Retweet $TwitterContext $_

    Write-HostFormatted "Retweet tolisss" -Section
    Send-Retweet $myTwitterContext $_

    Write-HostFormatted "DM tolisss" -Section
    Send-TweetDirectMessage $twitterContext $tolisss "RT XAF: $($nextRetweet.FullText)"
}
