param(
    $GithubUserName = "apobekiaris",
    $GithubPass = $env:GithubPass
)

$yaml = @"
- Name: XpandPwsh
  Version: 0.7.1
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
$RepositoryName="eXpand"
if ((Get-XpandVersion -Latest).Revision -gt 0){
    $RepositoryName="eXpand.lab"
}

$rArgs = @{
    Organization = "eXpandFramework"
    Owner        = $GithubUserName
    Pass         = $GithubPass
}
$release = Get-GitHubRelease -Repository $RepositoryName @rArgs | Select-Object -First 1
$version=$release.Name
Write-Verbose -Verbose "##vso[build.updatebuildnumber]$version"
$regex = [regex] '(?isx)```ps1(.*)```'
$result = ($regex.Match($release.Body).Groups[1].Value).Trim()

$regex = [regex] '(?isx)(.*)(\#.*)'
$result = $regex.Replace($result, '$1 -Quiet"')

Write-Host "Uninstalling Xpand.VSIX" -ForegroundColor Blue

("Local", "Roaming" | ForEach-Object{Get-ChildItem "$env:USERPROFILE\AppData\$_\Microsoft\VisualStudio" Xpand.VSIX.pkgdef -Recurse}).Count
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