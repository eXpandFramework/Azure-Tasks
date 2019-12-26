param(
    $GithubUserName = $env:GitHubToken,
    $GithubPass = $env:GithubPass
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.192.25
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Write-HostFormatted "Find Repository" -Section
$RepositoryName="eXpand"
if ((Get-XpandVersion -Latest).Revision -gt 0){
    $RepositoryName="eXpand.lab"
}
$RepositoryName
$rArgs = @{
    Organization = "eXpandFramework"
    Token        = $GithubUserName
}
$release = Get-GitHubRelease -Repository $RepositoryName @rArgs | Select-Object -First 1
$version=$release.Name
Set-VsoVariable updatebuildnumber $version

$regex = [regex] '(?isx)```ps1(.*)```'
$result = ($regex.Match($release.Body).Groups[1].Value).Trim()

$regex = [regex] '(?isx)(.*)(\#.*)'
$result = $regex.Replace($result, '$1 -Quiet"')

Write-HostFormatted "Uninstalling Xpand.VSIX" -Section

("Local", "Roaming" | ForEach-Object{Get-ChildItem "$env:USERPROFILE\AppData\$_\Microsoft\VisualStudio" Xpand.VSIX.pkgdef -Recurse}).Count
Write-HostFormatted "Install Script" -Section
Invoke-Expression $result 
$vsixInstalls=("Local", "Roaming" | ForEach-Object{Get-ChildItem "$env:USERPROFILE\AppData\$_\Microsoft\VisualStudio" Xpand.VSIX.pkgdef -Recurse}).Count
Start-Sleep 5
if ($vsixInstalls -eq 0){
    throw "VSIx not installed"
}

& "$([Environment]::GetFolderPath('MyDocuments'))\eXpandFramework\Uninstall-Xpand.ps1"
Start-Sleep 5
$vsixInstalls=("Local", "Roaming" | ForEach-Object{Get-ChildItem "$env:USERPROFILE\AppData\$_\Microsoft\VisualStudio" Xpand.VSIX.pkgdef -Recurse}).Count
if ($vsixInstalls -gt 0){
    throw "VSIX not uninstalled"
}