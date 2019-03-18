param(
    [string]$AzureToken=(Get-AzureToken),
    [string]$Root,
    [string]$GitHubUserName,
    [string]$GitHubPass
)
$VerbosePreference = "continue"
$yaml = @"
- Name: XpandPosh
  Version: 1.2.9
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
"commitIssues=$commitIssues"
if ($targetRepo -eq "lab") {
    $releaseDate = (Get-GitHubRelease -Repository lab @cred|Select-Object -First 1 ).PublishedAt.DateTime
    "releaseDate=$releaseDate"
    $commitIssues = $commitIssues|Where-Object {$releaseDate -lt $_.Githubcommit.Commit.Author.Date.DateTime}
}
$commitIssues
if ($commitIssues) {
    $commitIssues|Select-Object -ExpandProperty Githubcommit|Select-Object -ExpandProperty Commit|Select-Object -ExpandProperty Message
    $notes = New-GithubReleaseNotes -CommitIssues $commitIssues 
    "notes=$notes"
    
    $authors = $commitIssues.githubcommit.commit.author|ForEach-Object {"[$($_.Name)](https://github.com/$($_.Name.Replace(' ',''))), "}|Select-Object -Unique
    "authors=$authors"
    $users = $commitIssues.Issues.User|Where-Object{$_}|ForEach-Object {"[$($_.Login)]($($_.HtmlUrl)), "}|Select-Object -Unique
    "users=$users"
    $contributors = (($users + $authors)|Select-Object -Unique)
    "contributors=$contributors"
    $userNotes = "Big thanks for their contribution to:`r`n$contributors"
    "userNotes=$userNotes"
}
$dxVersion = Get-DevExpressVersion $version -Build
if ($targetRepo -eq "lab"){
    $latestFlag="- Latest"
}
$installerNotes="The msi installaer is replaced with the powershell [XpandPosh](https://github.com/eXpandFramework/XpandPosh) module. To install artifacts you can use either the ``Install-Xpand`` function or execute the next one-liner from a ps prompt.`r`n``````ps1`r`nSet-ExecutionPolicy Bypass -Scope Process -Force; iex `"`$((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/eXpandFramework/XpandPosh/master/XpandPosh/Public/Install-Xpand.ps1'));Install-Xpand -Assets @('Assemblies','Nuget','VSIX','Source') $latestFlag`"`r`n``````"
if (!$notes){
    $notes="There are no enhacements or bugs."
}
$notes = "This release is compiled against DevExpress.XAF v$dxversion.`r`n$usernotes`r`n$notes`r`n`r`n$installerNotes"
$publishArgs = (@{
    Repository   = $targetRepo
    ReleaseName  = $version
    ReleaseNotes = $notes
    Files        = $files
    Draft        = ($build.definitionName -eq "Xpand-Release")
}+$cred)
$publishArgs
Publish-GitHubRelease @publishArgs


 



