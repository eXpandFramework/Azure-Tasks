param(
    $GithubUserName = "apobekiaris",
    $GithubPass = $env:GithubPass
)

$yaml = @"
- Name: XpandPwsh
  Version: 0.3.0
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
$VerbosePreference = "continue"
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GitHubPass 
    Organization = "eXpandFramework"
}
$iArgs = @{
    Repository = "eXpand"
} + $cred
$iArgs
$packages = Find-XpandPackage Xpand.XAF* -PackageSource Lab | ForEach-Object {
    $_.Id.Replace("Xpand.XAF.Modules.", "")
}
"`r`npackages:"
$packages
$issues=Get-GitHubIssue @iArgs | Where-Object {
    $isStandalone = $_.Labels.Name | Where-Object {
        $label = $_
        $packages | Where-Object { $_ -eq $label } 
    } | Select-Object -First 1
    if ($isStandalone) {
        !($_.Labels.Name | Where-Object { $_ -eq "Standalone_XAF_Modules" } | Select-Object -First 1)
    }
}
"`r`nIssues:"
if ($issues.Number){
    $issues.Number|Update-GitHubIssue -Repository eXpand -Labels "Standalone_XAF_Modules" @cred
}


