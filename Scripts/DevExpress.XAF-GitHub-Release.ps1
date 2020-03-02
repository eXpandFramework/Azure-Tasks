param(
    [string]$AzureToken = $env:AzDevOpsToken,
    [string]$Root = "$env:TEMP\DevExpress.XAF.GitHub.Release",
    [string]$GitHubToken = "$env:GitHubToken",
    [string]$GitHubPass = $env:GithubPass,
    [string]$GitHubUserEmail = $env:GithubUserEmail
)

$ErrorActionPreference = "stop"
if (!(Get-Module eXpandFramework -ListAvailable)) {
    $env:AzDevopsToken = $AzureToken
    $env:AzOrganization = "eXpandDevOps"
    $env:AzProject = "eXpandFramework"
    $env:DxFeed = $DxApiFeed
    git config --global user.email $GitHubUserEmail
    git config --global user.name "Apostolis Bekiaris"
    git config --global core.safecrlf false
}
Remove-Item $Root -Force -Recurse -ErrorAction SilentlyContinue
New-Item $Root -ItemType Directory -Force -ErrorAction SilentlyContinue
$yaml = @"
- Name: XpandPwsh
  Version: 1.201.11.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Get-Module XpandPwsh -ListAvailable
$publishBuild = Get-AzBuilds -Definition PublishNugets-DevExpress.XAF -Result succeeded -Status completed -Top 1 

$artifact = Get-AzArtifact -BuildId $publishBuild.id -Outpath $Root 
$files = Get-ChildItem $artifact *.nupkg -Recurse 
$filesDirectory = ($files | Select-Object -First 1).DirectoryName
$zip = "$filesDirectory\..\packages.zip"
Compress-Files $filesDirectory $zip
$packages = & (Get-NugetPath) list -source $filesDirectory | ConvertTo-PackageObject
$version = ($packages | Select-Object -First 1).Version
$branch = "master"
if ($publishBuild.sourceBranch -like "*/lab") {
    $branch = "lab"
    Write-HostFormatted "Getting previous build" -Section
    $previousBuild = Get-AzBuilds -Definition PublishNugets-DevExpress.XAF -Result succeeded -Status completed  -Top 2 -BranchName $publishBuild.sourceBranch | Select-Object -Last 1
    $cred = @{
        Token        = $GitHubToken
        Organization = "eXpandFramework"
    }
    $lastRelease = Get-GitHubRelease -Repository DevExpress.XAF @cred 
    if (!$lastRelease) {
        $version = "$(Get-VersionPart $version Minor).0.0"
    }
    else{
        $version=Update-Version $lastRelease.Name -Revision
    }
    $a = @{
        Date        = (([System.DateTimeOffset]::Parse($previousBuild.queueTime)))
        Repository1 = "eXpand"
        Repository2 = "DevExpress.XAF"
        GitHubToken = $GitHubToken
        Version     = $version
        Branch      = "lab"
    }
    . $PSScriptRoot\GitHub-ReleaseNotes.ps1  @a
}
else {
    throw [System.NotImplementedException]::new("")
}


# if ($lastRelease.Prerelease) {
#     Remove-GitHubRelease -Repository "DevExpress.XAF" -ReleaseId $lastRelease.Id
# }
$packagesString = $packages | Sort-Object Id | ForEach-Object {
    "1. $(Get-XpandPackageHome $_.Id $_.Version)`r`n"
}
$notes += "`r`n`r`nAll packages that depend on DevExpress assemblies use the [VersionConverter](https://github.com/eXpandFramework/DevExpress.XAF/tree/master/tools/Xpand.VersionConverter) and can run fine against different DX version than $dxVersion."
$notes += "`r`n`r`nThis release contains the following packages:`r`n$packagesString"
$publishArgs = (@{
        Repository   = "DevExpress.XAF"
        ReleaseName  = $version
        ReleaseNotes = $notes
        Files        = $zip
        Draft        = $false
        Prerelease   = $true
    } + $cred)
$publishArgs | Write-Output | Format-Table
Publish-GitHubRelease @publishArgs 