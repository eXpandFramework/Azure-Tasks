param(
    $GithubUserName = $env:GitHubToken,
    $PriorityLabels = @("*sponsor*", "installation", "contribution","nuget","breakingchange","ReproSample","Deployment","*Backer*")
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.201.3.2
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
$ErrorActionPreference="stop"
$cred = @{
    Token        = $GitHubUserName 
    Organization = "eXpandFramework"
}
$iArgs = @{
    Repository = "eXpand"
} + $cred
$iArgs
function Update-StandalonePackagesLabels {
    $packages = Find-XpandPackage Xpand.XAF* -PackageSource Lab | ForEach-Object {
        $_.Id.Replace("Xpand.XAF.Modules.", "")
    }
    Write-HostFormatted "Packages" -Section
    $packages
    $issues = Get-GitHubIssue @iArgs | Where-Object {
        $isStandalone = $_.Labels.Name | Where-Object {
            $label = $_
            $packages | Where-Object { $_ -eq $label } 
        } | Select-Object -First 1
        if ($isStandalone) {
            !($_.Labels.Name | Where-Object { $_ -eq "Standalone_XAF_Modules" } | Select-Object -First 1)
        }
    }
    Write-HostFormatted "Issues" -Section
    $issues | ForEach-Object {
        [PSCustomObject]@{
            Number = $_.Number
            Title  = $_.Title
        }
    } | Format-Table 
    if ($issues.Number) {
        $issues.Number | Update-GitHubIssue -Repository eXpand -Labels "Standalone_XAF_Modules" @cred
    }
}
Write-HostFormatted "Update-StandalonePackagesLabels" -Section
Update-StandalonePackagesLabels

(Get-GitHubIssue @iArgs|Where-Object{!($_.Labels.Name|Select-String priority) -and $_.Assignee.login -eq "apobekiaris"}) | ForEach-Object { 
    $issueNumber=$_.Number
    $issueTitle=$_.Title
    $labels=$_.Labels.Name
    $assignedLabels=($priorityLabels | ForEach-Object {
        $label=$_
        $labels|Where-Object{$_ -like $label}
    }) -join ", "
    if ($assignedLabels){
        Write-HostFormatted "Prioritizing $issueNumber. $issueTitle" -ForegroundColor Magenta
        Update-GitHubIssue -IssueNumber $issueNumber -Repository eXpand -Labels "Priority" @cred
        $mLabels=($priorityLabels|ForEach-Object{"**$_**"}) -join ", "
        $comment="Issue is prioritized as it contains one of the following labels $mLabels"
        New-GitHubComment -IssueNumber $issueNumber -Comment $comment -Repository "eXpand" -Token $GithubUserName -Organization "eXpandFramework"
    }     
}
