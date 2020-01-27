param(
    $GithubUserName = "eXpand",
    $GithubPass = $env:eXpandGithubPass,
    # $SubscriberLabels=@("bronze-sponsor", "sponsor", "backer"),
    $PriorityLabels = @("❤ Bronze Sponsor", "❤ Sponsor", "❤ Backer", "Installation", "ShowStopper", "Nuget", "Contribution","BreakingChange", "ReproSample", "Deployment",  "Must-Have")
)

$yaml = @"
- Name: XpandPwsh
  Version: 1.201.5
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
$ErrorActionPreference = "stop"
$cred = @{
    Owner        = $GitHubUserName 
    Pass         = $GithubPass
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
$allLabels=Get-githubLabel @iArgs
$gitHubLabels=$PriorityLabels|ForEach-Object{
    $label=$_
    $allLabels|Where-Object{$_.Name -eq $label}
}
if (($gitHubLabels).Count -ne ($PriorityLabels).Count){
    throw "Labels count missmatch"
}
$labelsText=$gitHubLabels|ForEach-Object{
    $url="https://github.com/eXpandFramework/eXpand/labels/$($_.Name.Replace(' ','%20'))"
    "1. [$($_.Name)]($url)`r`n"
}
$labelsText="We will try to answer all questions that do not require research within 24hr.`r`nTo prioritize cases that require research we use the following labels in order.`r`n$labelsText`r`n`r`n**This case is prioritized.**"
(Get-GitHubIssue @iArgs | Where-Object { !($_.Labels.Name | Select-String priority) -and $_.Assignee.login -eq "apobekiaris" }) | ForEach-Object { 
    $issueNumber = $_.Number
    $issueTitle = $_.Title
    $labels = $_.Labels.Name
    $assignedLabels = ($priorityLabels | ForEach-Object {
            $label = $_
            $labels | Where-Object { $_ -like "*$label*" }
        }) -join ", "
    if ($assignedLabels -and !($_.labels.Name|Where-Object{$_ -eq "priority"})) {
        Write-HostFormatted "Prioritizing $issueNumber. $issueTitle" -ForegroundColor Magenta
        Update-GitHubIssue -IssueNumber $issueNumber -Repository eXpand -Labels "Priority" @cred
        New-GitHubComment -IssueNumber $issueNumber -Comment $labelsText @iArgs
    }     
}
