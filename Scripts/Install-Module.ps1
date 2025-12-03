param(
    [string]$Yaml
)


Write-Host "Starting module synchronization from YAML configuration."


if (!(Get-Module powershell-yaml -ListAvailable)) {
    
    Write-Host "Bootstrap: Installing missing dependency 'powershell-yaml' (0.4.0)."
    
    Install-Module powershell-yaml -RequiredVersion 0.4.0 -Scope CurrentUser -Force -Repository PSGallery
    
}
Import-Module powershell-yaml
($Yaml | ConvertFrom-Yaml) | ForEach-Object {
    
    Write-Host "Evaluating requirements for module: $($_.Name)"
    
    if (!(Get-Module $_.Name -ListAvailable)) {
        $a = @{
            Name       = $_.Name 
            Scope      = "CurrentUser" 
            Force      = $true
            Repository = "PSGallery" 
            AllowClobber=$true
        }
        if ($_.version) {
            $a.Add("RequiredVersion" , $_.Version )
        }
        
        Write-Host "Module '$($_.Name)' not found. Initiating installation (Version: $($_.Version))."
        
        Install-Module @a
    }
    Write-Host "Importing module: $($_.Name)"
    
    Import-Module $_.Name
}