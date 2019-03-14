param(
    $DXApiFeed=(get-feed -dx),
    $TwitterAPIKey,
    $TwitterAPISecret,
    $TwitterAccessToken,
    $TwitterAccessTokenSecret
)
$VerbosePreference="continue"
if (!(Get-Module MyTwitter -ListAvailable)){
    $webclient = New-Object System.Net.WebClient
    $url = "https://github.com/MyTwitter/MyTwitter/archive/master.zip"
    Write-Host "Downloading latest version of MyTwitter from $url" -ForegroundColor Cyan
    $file = "$($env:TEMP)\MyTwitter.zip"
    $webclient.DownloadFile($url,$file)
    Write-Host "File saved to $file" -ForegroundColor Green
    $targetondisk = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
    New-Item -ItemType Directory -Force -Path $targetondisk | out-null
    $shell_app=new-object -com shell.application
    $zip_file = $shell_app.namespace($file)
    Write-Host "Uncompressing the Zip file to $($targetondisk)" -ForegroundColor Cyan
    $destination = $shell_app.namespace($targetondisk)
    $destination.Copyhere($zip_file.items(), 0x10)
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Rename-Item -Path ($targetondisk+"\MyTwitter-master") -NewName "MyTwitter" -Force
    Write-Host "Module has been installed" -ForegroundColor Green
}
Import-Module -Name MyTwitter
$yaml = @"
- Name: XpandPosh
  Version: 1.1.5
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml

$dxVersion=Get-DevExpressVersion -Latest -Sources $DXApiFeed
$message="New @DevExpresss_XAF version $dxVersion is out."
New-MyTwitterConfiguration -APIKey "$TwitterAPIKey" -APISecret "$TwitterAPISecret" -AccessToken "$TwitterAccessToken" -AccessTokenSecret "$TwitterAccessTokenSecret"
$timeline=Get-TweetTimeline -Username eXpandFramework 
if(!($timeline|Where-Object{$_.user.id -eq "245344230" -and $_.full_text -like "*$message*"})){
    $xpandVersion=Get-XpandVersion -Release
    if ($xpandVersion -notlike "$dxVersion*"){
        Write-Host $message -f Green
        Send-Tweet -Message $message
        Write-Host "DM toliss"            
        Send-TwitterDm -Message $message -Username "tolisss"
        
    }
}
Remove-MyTwitterConfiguration 