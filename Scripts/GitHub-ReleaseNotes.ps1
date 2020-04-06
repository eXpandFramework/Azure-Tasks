param(
    [parameter(Mandatory)]
    [System.DateTimeOffset]$date,
    [parameter(Mandatory)]
    [string]$Repository1,
    [parameter(Mandatory)]
    [string]$Repository2,
    [parameter(Mandatory)]
    [string]$GitHubToken,
    [parameter(Mandatory)]
    [string]$version,
    [string]$ExtraHeader,
    [string]$Branch="master",
    [string]$extrabadge
)
$dxVersion = Get-VersionPart (Get-DevExpressVersion) Build
$cred = @{
    Token        = $GitHubToken
    Organization = "eXpandFramework"
}
$commitIssues = Get-GitHubCommitIssue -Repository1 $Repository1 -Repository2 $Repository2 @cred -Since $date -Branch $Branch
Write-HostFormatted "commitIssues:" -Section
$commitIssues.GitHubCommit.Commit.Message
if ($commitIssues) {
    
    $notes = New-GithubReleaseNotes -CommitIssues $commitIssues 
    if (!$notes){
        throw "No Enhacement or Bug label found"
    }
    "notes=$notes"
    
    $authors = $commitIssues.githubcommit.commit.author | Where-Object { $_.Name -ne "Apostolis Bekiaris" } | ForEach-Object { "[$($_.Name)](https://github.com/$($_.Name.Replace(' ',''))), " } | Select-Object -Unique
    "authors=$authors"
    if ($commitIssues.Issues) {
        $commentsUsers = $commitIssues.Issues | Get-GitHubIssueComment -Repository eXpand @cred | ForEach-Object { $_.User } | Where-Object { $_.Login -ne "eXpand" }
        "commentsUsers=$commentsUsers"
    }
    
    $users = (@($commitIssues.Issues.User) + @($commentsUsers)) | Where-Object { $_.Login -ne "eXpand" } | Sort-Object Login -Unique | Where-Object { $_ } | ForEach-Object { "[$($_.Login)]($($_.HtmlUrl)), " }
    "users=$users"
    $contributors = (($users + $authors) | Select-Object -Unique)
    "contributors=$contributors"

    $userNotes = "Big thanks for their contribution to:`r`n$contributors"
    "userNotes=$userNotes"
}
if (!$notes) {
    $notes = "There are no enhancements or bugs."
}

$notes = @"
[![image](https://xpandshields.azurewebsites.net/badge/Exclusive%20services%3F-Head%20to%20the%20dashboard-Blue)](https://github.com/sponsors/apobekiaris)

![GitHub Releases (by Release)](https://xpandshields.azurewebsites.net/github/downloads/expandframework/$Repository2/$version/total?style=social) $extrabadge

This release is compiled against DevExpress.XAF v$dxversion.
$usernotes

$ExtraHeader
$notes
"@