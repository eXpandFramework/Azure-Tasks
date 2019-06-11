param(
    [string]$Yaml
)

if (!(Get-Module powershell-yaml -ListAvailable)){
    Install-Module powershell-yaml -RequiredVersion 0.4.0 -Scope CurrentUser -Force -Repository PSGallery -Verbose
    Import-Module powershell-yaml
}

($Yaml|ConvertFrom-Yaml)|ForEach-Object{
    if (!(Get-Module $_.Name -ListAvailable)){
        Install-Module $_.Name -RequiredVersion $_.Version -Scope CurrentUser -Force -Repository PSGallery 
        Import-Module $_.Name
    }
}