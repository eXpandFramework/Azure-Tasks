param(
    $directory ="$env:TEMP\dxIndex",
    $GithubUserName ="apobekiaris",
    $GithubPass=$env:GithubPass,
    $GitUserEmail,
    $GitHubUserFullName,
    $DXApiFeed="C:\Program Files (x86)\DevExpress 19.1\Components\System\Components\packages\"
)

$yaml = @"
- Name: XpandPosh
  Version: 1.9.5
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

New-Item $directory -ItemType Directory -Force -ErrorAction SilentlyContinue
$VerbosePreference = "continue"
Set-Location $directory
$url = "https://$GithubUserName`:$GithubPass@github.com/eXpandFramework/DevExpress.PackageContent.git"
git clone $url
Set-Location "$directory\DevExpress.PackageContent"
git config --global user.email $githubuserEmail
git config --global user.name $GithubUserFullName
$dxFeed = $DXApiFeed
if (!(Test-Path ".\VersionList.txt")) {
    Write-Host "Populating versions"
    Get-NugetPackageSearchMetadata -AllVersions -Sources $dxFeed | Select-Object -ExpandProperty metadata | ForEach-Object {
        $_.Version.ToString()
    } | Select-Object -Unique | ForEach-Object {
        Add-Content -Value $_ "VersionList.txt"
    }
    git add -A 
    git commit -m "Version list"
    git push origin
}

#create csv
$latestVersion = @()
$versionListPath = ".\VersionList.txt"
$versionList = Get-Content $versionListPath
$dxVersion = Get-DevExpressVersion -Latest  -LatestVersionFeed $dxFeed

if (($versionList | Select-Object -First 1) -ne $dxVersion) {
    $latestVersion = @("$dxVersion")
}
    
($versionList + $latestVersion) | ForEach-Object {
    $version = $_
    if (!(Test-Path ".\Contents\$version.csv")) {
        $outdirectory = New-Item "$directory\$version" -ItemType Directory -ErrorAction Continue
        Write-host "Downloading $version"
        Get-NugetPackage -OutputFolder $outdirectory.FullName -Source $dxFeed -Versions $version | ForEach-Object {
            [PSCustomObject]@{
                Package         = $_.Package
                Version         = $_.Version.ToString();
                Assembly        = [system.IO.Path]::GetFileName($_.File)
                DotNetFramework = $_.DotNetFramework
            }
            Write-host "Exporting $($_.Package) $($_.DotnetFramework)"
        } | Export-Csv -Path ".\Contents\$version.csv" -NoTypeInformation
          
        if (!($versionlist | Select-String $version)) {
            write-Host "New Version found"
            ($latestVersion + $versionList)
            ($latestVersion + $versionList) | Out-File $versionListPath
        }
        git add -A 
        git commit -m "$_"
        git push -f origin 
        git tag $version
        git push -f --tags
    }
}