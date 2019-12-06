param(
    $AzureToken=$env:AzDevOpsToken,
    $Root="$env:TEMP\PublishNugetPackages\",
    $NugetApiKey=$env:NugetApiKey
)
$env:AzDevOpsToken=$AzureToken
$env:AzOrganization="eXpandDevOps"
$env:AzProject="eXpandFramework"
New-Item $Root -ItemType Directory -Force
$ErrorActionPreference="stop"
$yaml = @"
- Name: XpandPwsh
  Version: 1.192.11
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

$publishNugetFeed = Get-PackageFeed -Xpand


$labBuild=Get-AzBuilds -Definition Xpand-Lab -Result succeeded -Status completed |Select-Object -First 1
$releaseBuild=Get-AzBuilds -Definition Xpand-Release -Result succeeded -Status completed |Select-Object -First 1
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
Set-VsoVariable build.updatebuildnumber $version
$nugetPath="$Root\nugets"
Remove-Item $nugetPath -Force -Recurse -ErrorAction SilentlyContinue
New-Item $nugetPath -ItemType Directory -ErrorAction SilentlyContinue
$artifact=Get-AzArtifact -BuildId $build.id -Outpath $nugetPath

# $files = Get-ChildItem $artifact.FullName  -Recurse -File | Select-Object -ExpandProperty FullName
# $a = Get-VSTeamBuildArtifact -Id $build.id -ProjectName eXpandFramework -ErrorAction Continue
# $uri="$($a.resource.downloadUrl)"
# "uri=$uri"
# $c=New-Object System.net.WebClient
# $c.DownloadFile($uri,"$Root\artifact.zip")
# Expand-7Zip "$Root\artifact.zip"  "$Root\artifacts" 
# Expand-7Zip "$Root\artifacts\Xpand.v$version\Nupkg-$version.zip"  $nugetPath 

$artifact=Get-ChildItem $artifact *nupkg* -Recurse
Expand-Archive $artifact $nugetPath
$nuget=Get-NugetPath
& $nuget List -Source "$nugetPath"
Write-HostFormatted "Publishing" -Section
Publish-NugetPackage -NupkgPath "$nugetPath" -Source $publishNugetFeed -ApiKey $NugetApiKey
