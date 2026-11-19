<#
.SYNOPSIS
  Configura las variables de entorno de la aplicación en IIS desde un archivo JSON local.

.DESCRIPTION
  Se corre EN EL SERVIDOR IIS, como administrador, en Windows PowerShell 5.1:

    powershell -ExecutionPolicy Bypass -File .\set-iis-env.ps1 -ValuesFile .\iis-env.<ambiente>.secrets.json

  - Escribe las variables en applicationHost.config (<location path="sitio/app">), NO en el web.config
    publicado, que se reemplaza en cada despliegue.
  - Reemplaza las variables con el mismo nombre. Nunca imprime valores, solo nombres.
  - Crea la carpeta de Logs__Directory (si está definida) y da permiso de modificación a la identidad del app pool.

  El archivo de valores (*.secrets.json, nunca al repo) sigue la forma de scripts/iis-env.example.json.
  Borrar la copia del servidor después de correr el script.
#>
param(
    [Parameter(Mandatory = $true)][string]$ValuesFile,
    [switch]$Recycle
)

$ErrorActionPreference = 'Stop'
Import-Module WebAdministration

$config = Get-Content $ValuesFile -Raw -Encoding UTF8 | ConvertFrom-Json
$site = $config.site
$appPool = $config.appPool
$pspath = 'MACHINE/WEBROOT/APPHOST'
$filter = 'system.webServer/aspNetCore/environmentVariables'

if (-not (Get-WebApplication -Site ($site.Split('/')[0]) -Name ($site.Split('/', 2)[1]))) {
    throw "No existe la aplicación IIS '$site'."
}

function Get-ExistingNames {
    @(Get-WebConfigurationProperty -PSPath $pspath -Location $site -Filter $filter -Name 'Collection' |
        ForEach-Object { $_.name })
}

$existing = Get-ExistingNames
foreach ($property in $config.variables.PSObject.Properties) {
    if ($existing -contains $property.Name) {
        Remove-WebConfigurationProperty -PSPath $pspath -Location $site -Filter $filter -Name '.' -AtElement @{ name = $property.Name }
    }
    Add-WebConfigurationProperty -PSPath $pspath -Location $site -Filter $filter -Name '.' -Value @{ name = $property.Name; value = [string]$property.Value }
    Write-Host "Configurada: $($property.Name)" -ForegroundColor Green
}

$logs = $config.variables.Logs__Directory
if (-not [string]::IsNullOrWhiteSpace($logs)) {
    New-Item -ItemType Directory -Path $logs -Force | Out-Null
    & icacls $logs /grant "IIS AppPool\$($appPool):(OI)(CI)M" | Out-Null
    Write-Host "Carpeta de logs lista con permiso para IIS AppPool\$($appPool): $logs" -ForegroundColor Green
}

Write-Host "Variables de ${site}: $((Get-ExistingNames) -join ', ')"

if ($Recycle) {
    Restart-WebAppPool -Name $appPool
    Write-Host "App pool $appPool reciclado." -ForegroundColor Green
} else {
    Write-Host "Recicla el app pool '$appPool' (o corre de nuevo con -Recycle) para aplicar los cambios." -ForegroundColor Cyan
}
