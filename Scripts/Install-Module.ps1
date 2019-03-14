param(
    [string]$AzureToken,
    [string]$Root,
    [string]$GitHubUserName,
    [string]$GitHubPass
)
$VerbosePreference="continue"
if (!(Get-Module powershell-yaml -ListAvailable)){
    Install-Module powershell-yaml -RequiredVersion 0.4.0 -Scope CurrentUser -Force -Repository PSGallery 
    Import-Module powershell-yaml
}

(@"
- Name: XpandPosh
  Version: 1.0.48
- Name: VSTeam
  Version: 6.1.2
"@|ConvertFrom-Yaml)|ForEach-Object{
    Install-Module $_.Name -RequiredVersion $_.Version -Scope CurrentUser -Force -Repository PSGallery 
}
$releaseVersion=Get-XpandVersion -Release
$labVersion=Get-XpandVersion -Lab
$targetRepo="eXpand"
if ($labVersion -gt $releaseVersion){
    $targetRepo="lab"
}
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken
$labBuild = Get-VSTeamBuild -ProjectName eXpandFramework|Where-Object {$_.DefinitionName -eq "Xpand-Lab" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$releaseBuild = Get-VSTeamBuild -ProjectName eXpandFramework|Where-Object {$_.DefinitionName -eq "Xpand-Release" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$labBuild.buildNumber
$releaseBuild.BuildNumber
$version = $labBuild.BuildNumber
$build=$labBuild
if ((new-object System.Version($releaseBuild.buildNumber)) -gt (new-object System.Version($labBuild.buildNumber))){
    $version = $releaseBuild.BuildNumber
    $build=$releaseBuild
}
$version
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$a = Get-VSTeamBuildArtifact -Id $build.id -ProjectName eXpandFramework -ErrorAction Continue
$uri="$($a.resource.downloadUrl)"
Invoke-WebRequest -Uri $uri -OutFile "$Root\artifact.zip"
Expand-Archive "$Root\artifact.zip" -destinationpath $Root\artifacts 

$files=Get-ChildItem $Root\artifacts\Xpand.v$version|Select-Object -ExpandProperty FullName
$files
if (!$files){
  throw "No artifacts found"
}

$commitIssues=Get-GitHubCommitIssue -Repository1 eXpand -Repository2 lab -Owner $GitHubUserName -Pass $GitHubPass -Organization eXpandFramework
if ($targetRepo -eq "lab"){
    $commitIssues
    $releaseDate=(Get-GitHubRelease -Repository lab -Owner $GitHubUserName -Organization eXpandFramework -Pass $GithubPass|Select-Object -First 1 ).PublishedAt.DateTime
    $releaseDate
    $commitIssues=$commitIssues|Where-Object{$releaseDate -lt $_.Githubcommit.Commit.Author.Date.DateTime}
}
$commitIssues
if ($commitIssues){
    $notes=New-GithubReleaseNotes -Repository1 eXpand -Repository2 lab -Owner $GitHubUserName -ReleaseNotesTemplate (New-GithubReleaseNotesTemplate) -Organization eXpandFramework -Pass $GitHubPass -CommitIssues $commitIssues 
    $notes
    $authors=$commitIssues.githubcommit.commit.author|ForEach-Object{"[$($_.Name)](https://github.com/$($_.Name.Replace(' ',''))), "}|Select-Object -Unique
    $authors
    $users=$commitIssues.Issues.User|ForEach-Object{"[$($_.Login)]($($_.HtmlUrl)), "}|Select-Object -Unique
    $users
    $contributors=(($users+$authors)|Select-Object -Unique)
    $contributors
    $userNotes="Big thanks for their contribution to:`r`n$contributors"
    $userNotes
}
$dxVersion=Get-DevExpressVersion $version -Build
$notes="This release is compiled against DevExpress.XAF v$dxversion.`r`n$usernotes`r`n$notes"
$publishArgs=@{
    Owner=$GitHubUserName
    Organization="eXpandFramework"
    Repository=$targetRepo
    ReleaseName=$version
    ReleaseNotes=$notes
    Pass=$GitHubPass
    Files=$files
    Draft=($build.definitionName -eq "Xpand-Release")
}

Publish-GitHubRelease @publishArgs


 



