param(
    $AzureToken=$env:AzureToken,
    $Root,
    $NugetApiKey
)

$ErrorActionPreference="stop"
$yaml = @"
- Name: XpandPwsh
  Version: 0.25.12
- Name: VSTeam
  Version: 6.3.6
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Set-VSTeamAPIVersion AzD
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken

$publishNugetFeed = Get-PackageFeed -Xpand
$labdefintion=Get-VSTeamBuildDefinition -ProjectName eXpandFramework -Filter "Xpand-Lab"
$labBuild=Get-VSTeamBuild -ProjectName eXpandFramework -Definitions $labdefintion.Id -StatusFilter completed -ResultFilter succeeded|Select-Object -First 1

$releaseDefinition=Get-VSTeamBuildDefinition -ProjectName eXpandFramework -Filter "Xpand-Release"
$releaseBuild=Get-VSTeamBuild -ProjectName eXpandFramework -Definitions $releaseDefinition.Id -StatusFilter completed -ResultFilter succeeded|Select-Object -First 1
$labBuild.buildNumber
$releaseBuild.BuildNumber
$version = $labBuild.BuildNumber
$build=$labBuild
if (([version]$releaseBuild.buildNumber -gt [version]$labBuild.buildNumber)){
    $version = $releaseBuild.BuildNumber
    $build=$releaseBuild
    $publishNugetFeed = Get-PackageFeed -Nuget
}
"version=$version"
"publishNugetFeed=$publishNugetFeed"
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$a = Get-VSTeamBuildArtifact -Id $build.id -ProjectName eXpandFramework -ErrorAction Continue
$uri="$($a.resource.downloadUrl)"
"uri=$uri"
$c=New-Object System.net.WebClient
$c.DownloadFile($uri,"$Root\artifact.zip")
Expand-7Zip "$Root\artifact.zip"  "$Root\artifacts" 
Expand-7Zip "$Root\artifacts\Xpand.v$version\Nupkg-$version.zip"  $Root\Nugets 

Get-ChildItem $Root\nugets
Write-Host "Installing XpandPwsh"

Import-Module XpandPwsh 
$nuget=Get-NugetPath
& $nuget List -Source "$Root\Nugets"
Write-Host "Publishing"
Publish-NugetPackage -NupkgPath "$Root\Nugets" -Source $publishNugetFeed -ApiKey $NugetApiKey
