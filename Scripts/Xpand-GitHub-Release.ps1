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
$buildDefinition="Xpand-Release"
$targetRepo="eXpand"
if ($labVersion -gt $releaseVersion){
    $buildDefinition="Xpand-Lab"
    $targetRepo="lab"
}
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken
$build = Get-VSTeamBuild -ProjectName eXpandFramework|Where-Object {$_.DefinitionName -like $buildDefinition -and $_.Result -eq "succeeded"}|Select-Object -First 1
$build.Id
$version = $build.BuildNumber
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
    $releaseDate=(Get-GitHubRelease -Repository lab -Owner $GitHubUserName -Organization eXpandFramework -Pass $GithubPass|Select-Object -First 1 ).CreatedAt
    $releaseDate
    $commitIssues=$commitIssues|Where-Object{$releaseDate -lt $_.Githubcommit.Commit.Author.Date}
}
$commitIssues
if ($commitIssues){
    $notes=New-GithubReleaseNotes -Repository1 eXpand -Repository2 lab -Owner $GitHubUserName -ReleaseNotesTemplate (New-GithubReleaseNotesTemplate) -Organization eXpandFramework -Pass $GitHubPass -CommitIssues $commitIssues 
    $notes
    $users= ($commitIssues.githubcommit.Commit.Committer|select-object -unique -ExpandProperty Name|ForEach-Object{"[$_](https://github.com/$($_.Replace(' ','')))"})
    $userNotes="Big thanks for their contribution to:`r`n$users"
    $userNotes
}
$dxVersion=Get-DevExpressVersion $version
$notes="This release is compiled against DevExpress.XAF v$dxversion.`r`n$usernotes"
Publish-GitHubRelease -Owner $GitHubUserName -Organization eXpandFramework -Repository $targetRepo -ReleaseName $version -ReleaseNotes $notes -Pass $GitHubPass -Verbose -Files $files 


 



