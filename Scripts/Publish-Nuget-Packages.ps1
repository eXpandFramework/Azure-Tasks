param(
    $AzureToken,
    $Root,
    $NugetApiKey
)
$VerbosePreference="continue"
$ErrorActionPreference="stop"
$yaml = @"
- Name: XpandPosh
  Version: 1.9.8
- Name: VSTeam
  Version: 6.2.1
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken

$publishNugetFeed = Get-PackageFeed -Xpand
$allBuilds=Get-VSTeamBuild -ProjectName eXpandFramework
$labBuild = $allBuilds|Where-Object {$_.DefinitionName -eq "Xpand-Lab" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$betaBuild = $allBuilds|Where-Object {$_.DefinitionName -eq "Beta" -and $_.Result -eq "succeeded"}|Select-Object -first 1
if ([version]$betaBuild.buildNumber -gt [version]$labBuild.buildNumber){
    $labBuild=$betaBuild
}
$releaseBuild = $allBuilds|Where-Object {$_.DefinitionName -eq "Xpand-Release" -and $_.Result -eq "succeeded"}|Select-Object -first 1
$labBuild.buildNumber
$releaseBuild.BuildNumber
$version = $labBuild.BuildNumber
$build=$labBuild
if ((new-object System.Version($releaseBuild.buildNumber)) -gt (new-object System.Version($labBuild.buildNumber))){
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
Write-Host "Installing XpandPosh"

Import-Module XpandPosh 
$nuget=Get-NugetPath
& $nuget List -Source "$Root\Nugets"
Write-Host "Publishing"
Publish-NugetPackage -NupkgPath "$Root\Nugets" -Source $publishNugetFeed -ApiKey $NugetApiKey
