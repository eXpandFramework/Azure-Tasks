param(
    [string]$AzureToken = $env:AzureToken,
    [string]$Root = "$env:TEMP\Reactive.XAF.GitHub.Release",
    [string]$GitHubToken = "$env:GitHubToken",
    [string]$GitHubPass = $env:GithubPass,
    [string]$DxApiFeed = $env:DxFeed,
    [string]$GitHubUserEmail = $env:GithubUserEmail
)

$ErrorActionPreference = "stop"
if (!(Get-Module eXpandFramework -ListAvailable)) {
    $env:AzureToken = $AzureToken
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
  Version: 1.221.0.18
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Get-Module XpandPwsh -ListAvailable

Write-HostFormatted "Nupkg"
$publishBuild = Get-AzBuilds -Definition PublishNugets-Reactive.XAF -Result succeeded -Status completed -Top 1 -BranchName $null
Get-Variable publishBuild|Out-Variable
$artifact = Get-AzArtifact -BuildId $publishBuild.id -Outpath $Root 
$nupkgsFiles = Get-ChildItem $artifact *.nupkg -Recurse 
$filesDirectory = ($nupkgsFiles | Select-Object -First 1).DirectoryName
$zip = "$filesDirectory\..\packages.zip"
Compress-Files $filesDirectory $zip
$packages = & (Get-NugetPath) search -source $filesDirectory | ConvertTo-PackageObject -NewFormat
$version = ($packages | Select-Object -First 1).Version
Get-Variable version|Out-Variable

Write-HostFormatted "Xpand.XAF.ModelEditor.Desktop"
$publishBuild = Get-AzBuilds -Definition Reactive.XAF -Result succeeded -Status completed -Top 1 -BranchName $null
Get-Variable publishBuild|Out-Variable
$artifact = Get-AzArtifact -BuildId $publishBuild.id -Outpath $Root -ArtifactName Zip

$mePath=Get-ChildItem "$artifact\zip\"

$cred = @{
    Token        = $GitHubToken
    Organization = "eXpandFramework"
}
$preRelease=$publishBuild.sourceBranch -like "*/lab"
Write-HostFormatted "Getting last build" -Section
$lastBuild = (Get-AzBuilds -Definition PublishNugets-Reactive.XAF -Result succeeded -Status completed -BranchName $publishBuild.sourceBranch) | Select-Object -First 1
Write-HostFormatted "Getting version" -Section
$DxPipelineBuildId=($lastBuild.parameters|ConvertFrom-Json).DxPipelineBuildId
$version=(Get-AzBuilds -id $DxPipelineBuildId).Buildnumber.Split("-")[0]
$version

if ($preRelease) {
    
    # $previousBuild = (Get-AzBuilds -Definition PublishNugets-Reactive.XAF -Result succeeded -Status completed  -Top 2 -BranchName $publishBuild.sourceBranch) | Select-Object -Last 1
    # (Get-AzBuilds -id 16425).Buildnumber.Split("-")[0]
    # $lastRelease = Get-GitHubRelease -Repository Reactive.XAF @cred |Select-Object -First 1
    # if (!$lastRelease) {
    #     $version = "$(Get-VersionPart $version Minor).0.0"
    # }
    # else{
    #     $lastReleaseName=$lastRelease.Name
    #     Get-Variable lastReleaseName|Out-Variable
    #     $version=Update-Version -Version $lastReleaseName -Revision
    # }
    $sinceDate=$lastBuild.queueTime
}
else {
    # $lastRelease = Get-GitHubRelease -Repository Reactive.XAF @cred |Select-Object -First 1
    # $lastReleaseName=$lastRelease.Name
    # Get-Variable lastReleaseName|Out-Variable
    # $version=Update-Version -Version $lastReleaseName -Build
    # Get-Variable version|Out-Variable
    $sinceDate=(Get-NugetPackageSearchMetadata Xpand.Extensions -Source (Get-PackageFeed -Nuget) -AllVersions|Select-Object -Skip 1 -First 1).published
}
$a = @{
    Date        = (([System.DateTimeOffset]::Parse($sinceDate)))
    Repository1 = "eXpand"
    Repository2 = "Reactive.XAF"
    GitHubToken = $GitHubToken
    Version     = $version
    Branch      = "lab"
}
. $PSScriptRoot\GitHub-ReleaseNotes.ps1  @a

# if ($lastRelease.Prerelease) {
#     Remove-GitHubRelease -Repository "Reactive.XAF" -ReleaseId $lastRelease.Id
# }
$packagesString = $packages | Sort-Object Id | ForEach-Object {
"1. $(Get-XpandPackageHome $_.Id $_.Version)`r`n"
}
$notes += @"

#### Release Notes
1. To minimize version conflicts we recommend that you switch to PackageReference format and use only the [Xpand.XAF.Core.All](https://www.nuget.org/packages/Xpand.XAF.Core.All), [Xpand.XAF.Win.All](https://www.nuget.org/packages/Xpand.XAF.Win.All), [Xpand.XAF.Web.All](https://www.nuget.org/packages/Xpand.XAF.Web.All) packages. Doing so, all packages will be at your disposal and .NET will add a dependecy only to those packages that you actually use and not to all (see the [Modules installation-registrations](https://youtu.be/LvxQ-U_0Sbg) youtube video).
2. All packages that depend on DevExpress assemblies use the [VersionConverter](https://github.com/eXpandFramework/Reactive.XAF/tree/master/tools/Xpand.VersionConverter) and can run fine against different DX version than $dxVersion.

"@
$releasedPackages=@"


<details>
 <summary>This release contains the following packages:</summary>

$packagesString
</details>
"@
$notes += $releasedPackages
$publishArgs = (@{
        Repository   = "Reactive.XAF"
        ReleaseName  = $version
        ReleaseNotes = $notes
        Files        = @($mePath.FullName)+$zip
        Draft        = !$preRelease
        Prerelease   = $preRelease
    } + $cred)
$publishArgs | Write-Output | Format-Table
Publish-GitHubRelease @publishArgs 
if (!$preRelease){
    $allReleases=Get-GitHubRelease -Repository Reactive.XAF -Organization eXpandFramework -Token $GitHubToken|ForEach-Object{
        [PSCustomObject]@{
            Release = $_
            Version=([version]$_.TagName)
        }
    } |Sort-Object Version -Descending|Select-Object -ExpandProperty Release 
    $latest=$allReleases|Select-Object -First 1
    $allReleases|Foreach-Object{
        if ($_.Prerelease){
            if (([version]$_.TagName) -lt ([version]$latest.TagName)){
                Write-HostFormatted "Removing release $($_.TagName)"
                $_.Body
                Remove-GitHubRelease -Repository Reactive.XAF -Organization eXpandFramework -Token $GitHubToken -ReleaseId $_.Id
            }
        }
    }
    
}