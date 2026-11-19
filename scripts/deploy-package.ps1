<#
.SYNOPSIS
  Arma el paquete completo (backend + frontend) listo para copiar al servidor IIS.

.DESCRIPTION
  1. Publica el backend (dependiente del framework, win-x64).
  2. Compila Angular en modo producción.
  3. Copia el build de Angular dentro del wwwroot del publish del backend.
  El resultado queda en deploy-package/ en la raíz del repo (ignorado por git).

.EXAMPLE
  .\scripts\deploy-package.ps1
#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repoRoot 'deploy-package'

Write-Host "== 1/3 Publicando backend ==" -ForegroundColor Cyan
if (Test-Path $outputDir) { Remove-Item $outputDir -Recurse -Force }
Push-Location (Join-Path $repoRoot 'backend')
try {
    dotnet publish src/EDealBuy.Api -c Release -r win-x64 --self-contained false -o $outputDir
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish falló (código $LASTEXITCODE)" }
}
finally { Pop-Location }

Write-Host "== 2/3 Compilando frontend ==" -ForegroundColor Cyan
Push-Location (Join-Path $repoRoot 'frontend')
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build falló (código $LASTEXITCODE)" }
}
finally { Pop-Location }

Write-Host "== 3/3 Copiando frontend a wwwroot ==" -ForegroundColor Cyan
$frontendDist = Join-Path $repoRoot 'frontend\dist\frontend\browser'
$wwwroot = Join-Path $outputDir 'wwwroot'
New-Item -ItemType Directory -Path $wwwroot -Force | Out-Null
Copy-Item "$frontendDist\*" $wwwroot -Recurse -Force

Write-Host "Listo. Copia esta carpeta al servidor: $outputDir" -ForegroundColor Green
Write-Host "Si el sitio ya corre en IIS, detén el Application Pool antes de sobrescribir las DLL." -ForegroundColor Yellow
