if (!(Get-Module powershell-yaml -ListAvailable)){
    Install-Module powershell-yaml -RequiredVersion 0.4.0 -Scope CurrentUser -Force -Repository PSGallery 
    Import-Module powershell-yaml
}

(@"
- Name: XpandPosh
  Version: 1.0.48
- Name: VSTeam
  Version: 6.1.2
"@|ConvertFrom-Yaml)|ForEach-Object{
    if (!(Get-Module $_.Name -ListAvailable)){
        Install-Module $_.Name -RequiredVersion $_.Version -Scope CurrentUser -Force -Repository PSGallery 
    }
}