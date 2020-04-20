param(
    [string]$Yaml
)

if (!(Get-Module powershell-yaml -ListAvailable)) {
    Install-Module powershell-yaml -RequiredVersion 0.4.0 -Scope CurrentUser -Force -Repository PSGallery
    
}
Import-Module powershell-yaml
($Yaml | ConvertFrom-Yaml) | ForEach-Object {
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
        Install-Module @a
    }
    Import-Module $_.Name
}