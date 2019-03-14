param(
    [string]$AzureToken,
    [string]$Root,
    [string]$GitHubUserName,
    [string]$GitHubPass
)
$VerbosePreference = "continue"
$yaml = @"
- Name: XpandPosh
  Version: 1.1.3
- Name: VSTeam
  Version: 6.1.2
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken
$labBuild = Get-VSTeamBuild -ProjectName eXpandFramework|Where-Object {$_.DefinitionName -eq "Xpand-Lab" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$releaseBuild = Get-VSTeamBuild -ProjectName eXpandFramework|Where-Object {$_.DefinitionName -eq "Xpand-Release" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$labBuild.buildNumber
$releaseBuild.BuildNumber
$version = $labBuild.BuildNumber
$build = $labBuild
$targetRepo = "lab"
if ((new-object System.Version($releaseBuild.buildNumber)) -gt (new-object System.Version($labBuild.buildNumber))) {
    $version = $releaseBuild.BuildNumber
    $build = $releaseBuild
    $targetRepo = "eXpand"
}
$version
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$a = Get-VSTeamBuildArtifact -Id $build.id -ProjectName eXpandFramework -ErrorAction Continue
$uri = "$($a.resource.downloadUrl)"
$uri 
Invoke-WebRequest -Uri $uri -OutFile "$Root\artifact.zip"
Expand-Archive "$Root\artifact.zip" -destinationpath $Root\artifacts 

$files = Get-ChildItem $Root\artifacts\Xpand.v$version|Select-Object -ExpandProperty FullName
$files
if (!$files) {
    throw "No artifacts found"
}
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GitHubPass 
    Organization = "eXpandFramework"
}
$commitIssues = Get-GitHubCommitIssue -Repository1 eXpand -Repository2 $targetRepo @cred
if ($targetRepo -eq "lab") {
    $commitIssues
    $releaseDate = (Get-GitHubRelease -Repository lab @cred|Select-Object -First 1 ).PublishedAt.DateTime
    $releaseDate
    $commitIssues = $commitIssues|Where-Object {$releaseDate -lt $_.Githubcommit.Commit.Author.Date.DateTime}
}
$commitIssues
if ($commitIssues) {
    $commitIssues|Select-Object -ExpandProperty Githubcommit|Select-Object -ExpandProperty Commit|Select-Object -ExpandProperty Message
    $notes = New-GithubReleaseNotes -ReleaseNotesTemplate (New-GithubReleaseNotesTemplate) -CommitIssues $commitIssues 
    $notes
    $authors = $commitIssues.githubcommit.commit.author|ForEach-Object {"[$($_.Name)](https://github.com/$($_.Name.Replace(' ',''))), "}|Select-Object -Unique
    $authors
    $users = $commitIssues.Issues.User|ForEach-Object {"[$($_.Login)]($($_.HtmlUrl)), "}|Select-Object -Unique
    $users
    $contributors = (($users + $authors)|Select-Object -Unique)
    $contributors
    $userNotes = "Big thanks for their contribution to:`r`n$contributors"
    $userNotes
}
$dxVersion = Get-DevExpressVersion $version -Build
$notes = "This release is compiled against DevExpress.XAF v$dxversion.`r`n$usernotes`r`n$notes"
$publishArgs = (@{
    Repository   = $targetRepo
    ReleaseName  = $version
    ReleaseNotes = $notes
    Files        = $files
    Draft        = ($build.definitionName -eq "Xpand-Release")
}+$cred)
$publishArgs
Publish-GitHubRelease @publishArgs


 



