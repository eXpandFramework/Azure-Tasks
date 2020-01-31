param(
    $Branch = "lab",
    $sourcesRoot = "$PSScriptRoot\..\..",
    $apiKey=$env:NugetApiKey,
    $localPackageSource = "$PSScriptRoot\..\..\bin\Nupkg",
    $PastBuild,
    $criteria = "Xpand.*"

)

"localPackageSource=$localPackageSource"
if (!(Get-Module XpandPwsh -ListAvailable)){
    Install-Module XpandPwsh -Force
}
"Build_DefinitionName=$env:Build_DefinitionName"
New-Item $sourcesRoot\build\Nuget -ItemType Directory
$nupkg=Get-ChildItem "$localPackageSource" 
$localPackages=((& (Get-NugetPath) list -source $localPackageSource)|ConvertTo-PackageObject)
$localPackages=$localPackages|ForEach-Object{
    $id=$_.Id
    $version=$_.version
    [PSCustomObject]@{
        Id = $id
        Version=$version
        FullName=($nupkg|Where-Object{$_.BaseName -eq "$id.$version"}).FullName
    }
}
Write-HostFormatted "local-packages:" -Section
$localPackages

$pArgs = @{
    PackageSource = "Release"
    Filter=$criteria
}
$remotePackageSource=Get-PackageFeed -Nuget
if ($Branch -eq "lab") {
    $pArgs.PackageSource="Lab"
    $remotePackageSource=Get-PackageFeed -Xpand
}
$args
$packages =Find-XpandPackage  @pArgs

Write-HostFormatted "remote-packages:" -Section
$packages|Format-Table -AutoSize


$localPackages| ForEach-Object {
    $localPackageName = $_.id
    $localPackageVersion = $_.Version
    "localPackage=$localPackageName, $localPackageVersion"
    $package = $packages | Where-Object { $_.Id -eq $localPackageName }
    "publishedPackage=$package"
    if (!$package -or (([version]$package.Version) -lt ([version]$localPackageVersion))) {
        "Pushing $($_.FullName)"
        & (Get-Nugetpath) push $_.FullName -source $remotePackageSource -ApiKey $apikey
        $clearCache=$true
    }
    else{
        Remove-Item $_.FullName -Verbose
    }
}
if ($clearCache){
    Invoke-RestMethod "https://xpandnugetstats.azurewebsites.net/api/totals/clearcache"
}
