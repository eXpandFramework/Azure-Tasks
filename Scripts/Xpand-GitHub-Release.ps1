param(
    [string]$AzureToken=(Get-AzureToken),
    [string]$Root,
    [string]$GitHubUserName,
    [string]$GitHubPass
)
$VerbosePreference = "continue"
$yaml = @"
- Name: XpandPosh
  Version: 1.8.0
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
$targetRepo = "eXpand.lab"
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
if ($targetRepo -eq "eXpand.lab") {
    $releaseDate = (Get-GitHubRelease -Repository $targetRepo @cred|Select-Object -First 1 ).PublishedAt.DateTime
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
if ($targetRepo -eq "eXpand.lab"){
    $latest="-Latest"
}
$installerNotes=@"
The msi installer is replaced with the powershell [XpandPosh](https://github.com/eXpandFramework/XpandPosh) module. 
iTo install artifacts you can use either the ``Install-Xpand`` function or execute the copy paste the next lines in an ``Admin`` powershell prompt.
``````ps1
Set-ExecutionPolicy Bypass -Scope Process -Force 
`$installer="Install-Xpand -Assets @('Assemblies','Nuget','VSIX','Source') $latest #-Version '$version'"
iex "`$((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/eXpandFramework/XpandPosh/master/XpandPosh/Public/Xpand/Install-Xpand.ps1'));`$installer"
``````
"@
if (!$notes){
    $notes="There are no enhacements or bugs."
}
$notes = "![GitHub Releases (by Release)](https://img.shields.io/github/downloads/expandframework/$targetRepo/$version/total.svg)`r`n`r`nThis release is compiled against DevExpress.XAF v$dxversion.`r`n$usernotes`r`n`r`n$notes`r`n`r`n$installerNotes"
$publishArgs = (@{
    Repository   = $targetRepo
    ReleaseName  = $version
    ReleaseNotes = $notes
    Files        = $files
    Draft        = ($build.definitionName -eq "Xpand-Release")
}+$cred)
$publishArgs
Publish-GitHubRelease @publishArgs


 



