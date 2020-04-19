param(
    $TwitterAPIKey=$env:TwitterAPIKey,
    $TwitterAPISecret=$env:TwitterAPISecret,
    $TwitterAccessToken=$env:TwitterAccessToken,
    $TwitterAccessTokenSecret=$env:TwitterAccessTokenSecret,
    $MyTwitterAPIKey=$env:MyTwitterAPIKey,
    $MyTwitterAPISecret=$env:MyTwitterAPISecret,
    $MyTwitterAccessToken=$env:MyTwitterAccessToken,
    $MyTwitterAccessTokenSecret=$env:MyTwitterAccessTokenSecret,
    $AzureApptwittlicationId = $env:AzApplicationId,
    $AzureTenantId = $env:AzTenantId,
    $XpandBlobOwnerSecret = $env:AzXpandBlobOwnerSecret
)
$VerbosePreference = "continue"
$ErrorActionPreference="stop"
Set-Location $PSScriptRoot
$yaml = @"
- Name: XpandPwsh
  Version: 1.201.11.5  
- Name: PSTwitterAPI
  Version: 0.0.7
"@
& "$PSScriptRoot\Install-Module.ps1" $yaml
Connect-Az -ApplicationSecret $XpandBlobOwnerSecret -AzureApplicationId $AzureApplicationId -AzureTenantId $AzureTenantId
Write-HostFormatted  "Downloading Blob" -Section
$storageAccount = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq "xpandbuildblob" }
Get-AzStorageBlob -Container twitter -Context $storageAccount.Context | Get-AzStorageBlobContent -Destination . -Force 


