param(
    $AzureToken,
    $Root,
    $NugetApiKey
)
$VerbosePreference="continue"
Write-Host "Installing VSTeam"
if (!(Get-Module powershell-yaml -ListAvailable)){
    Install-Module powershell-yaml -RequiredVersion 0.4.0 -Scope CurrentUser -Force -Repository PSGallery 
    Import-Module powershell-yaml
}

(@"
- Name: XpandPosh
  Version: 1.1.1
- Name: VSTeam
  Version: 6.1.2
"@|ConvertFrom-Yaml)|ForEach-Object{
    if (!(Get-Module $_.Name -ListAvailable)){
        Install-Module $_.Name -RequiredVersion $_.Version -Scope CurrentUser -Force -Repository PSGallery 
    }
}
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken
$publishNugetFeed = "https://xpandnugetserver.azurewebsites.net/nuget"
if ($repository -like "*/eXpand") {
    $publishNugetFeed = "https://api.nuget.org/v3/index.json"
}
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
$uri
Invoke-WebRequest -Uri $uri -OutFile "$Root\artifact.zip"
Expand-Archive "$Root\artifact.zip" -destinationpath $Root\artifacts 
Expand-Archive "$Root\artifacts\Xpand.v$version\Nupkg-$version.zip" -destinationpath $Root\Nugets 

Get-ChildItem $Root\nugets
Write-Host "Installing XpandPosh"

Import-Module XpandPosh -Verbose
Nuget List -Source "$Root\Nugets"
Write-Host "Publishing"
Publish-NugetPackage -NupkgPath "$Root\Nugets" -Source $publishNugetFeed -ApiKey $NugetApiKey 
