param(
    $AzureToken,
    $Root,
    $NugetApiKey
)
$VerbosePreference="continue"
Write-Host "Installing VSTeam"
Install-Module VSTeam -Scope CurrentUser -Force -Repository PSGallery 
Set-VSTeamAccount -Account eXpandDevOps -PersonalAccessToken $AzureToken
$filter = "Xpand-Lab"
$publishNugetFeed = "https://xpandnugetserver.azurewebsites.net/nuget"
if ($repository -like "*/eXpand") {
    $filter = "Xpand-Release"
    $publishNugetFeed = "https://api.nuget.org/v3/index.json"
}
$build = Get-VSTeamBuild -ProjectName eXpandFramework|Where-Object {$_.DefinitionName -like $filter -and $_.Result -eq "succeeded"}|Select-Object -First 1
$build.Id
$version = $build.BuildNumber
$version
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$a = Get-VSTeamBuildArtifact -Id $build.id -ProjectName eXpandFramework -ErrorAction Continue
$uri="$($a.resource.downloadUrl)"
Invoke-WebRequest -Uri $uri -OutFile "$Root\artifact.zip"
Expand-Archive "$Root\artifact.zip" -destinationpath $Root\artifacts 
Expand-Archive "$Root\artifacts\Xpand.v$version\Nupkg-$version.zip" -destinationpath $Root\Nugets 

Get-ChildItem $Root\nugets
Write-Host "Installing XpandPosh"
Install-Module XpandPosh -RequiredVersion 1.0.45 -Scope CurrentUser -Force -Repository PSGallery 
Import-Module XpandPosh -Verbose
Nuget List -Source "$Root\Nugets"
Write-Host "Publishing"
Publish-NugetPackage -NupkgPath "$Root\Nugets" -Source $publishNugetFeed -ApiKey $NugetApiKey 
return
$NupkgPath = "$Root\Nugets"
$Source = $publishNugetFeed 
$ApiKey = $NugetApiKey
$packages = (& Nuget List -source $NupkgPath)|convertto-packageobject
Write-Verbose "Packages found:"
$packages|Write-Verbose
        
$published = $packages|Select-Object -ExpandProperty Name| Invoke-Parallel -activityName "Getting latest versions from sources" -VariablesToImport @("Source") -Script { 
    Get-NugetPackageSearchMetadata -Name $_ -Sources $Source
} 
Write-Verbose "Published packages:"
$published = $published|Select-object -ExpandProperty Metadata|Get-MetadataVersion
$published|Write-Verbose 
        
$needPush = $packages|Where-Object {
    $p = $_
    $published |Where-Object {
        $_.Name -eq $p.Name -and $_.Version -eq $_.Version
    }
}
Write-Verbose "NeedPush"
$needPush|Write-Verbose 
$NupkgPath = $NupkgPath.TrimEnd("\")
$publishScript = {        
    $package = "$NupkgPath\$($_.Name).$($_.Version).nupkg"
    "Pushing $package in $Source "
    nuget Push "$package" -ApiKey $ApiKey -source $Source
}
        
$needPush|Invoke-Parallel -ActivityName "Publishing Nugets" -VariablesToImport @("ApiKey", "NupkgPath", "Source") -Script $publishScript