<#
.SYNOPSIS
  Builds the full package (backend + frontend) ready to copy to the IIS server.

.DESCRIPTION
  1. Publishes the backend (framework-dependent, win-x64).
  2. Builds Angular in production mode.
  3. Copies the Angular build into the backend publish wwwroot.
  Output goes to deploy-package/ at the repo root (git-ignored).

.EXAMPLE
  .\scripts\deploy-package.ps1
#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repoRoot 'deploy-package'

Write-Host "== 1/3 Publishing backend ==" -ForegroundColor Cyan
if (Test-Path $outputDir) { Remove-Item $outputDir -Recurse -Force }
Push-Location (Join-Path $repoRoot 'backend')
try {
    dotnet publish src/EDealBuy.Api -c Release -r win-x64 --self-contained false -o $outputDir
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed (exit code $LASTEXITCODE)" }
}
finally { Pop-Location }

Write-Host "== 2/3 Building frontend ==" -ForegroundColor Cyan
Push-Location (Join-Path $repoRoot 'frontend')
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build failed (exit code $LASTEXITCODE)" }
}
finally { Pop-Location }

Write-Host "== 3/3 Copying frontend into wwwroot ==" -ForegroundColor Cyan
$frontendDist = Join-Path $repoRoot 'frontend\dist\frontend\browser'
$wwwroot = Join-Path $outputDir 'wwwroot'
New-Item -ItemType Directory -Path $wwwroot -Force | Out-Null
Copy-Item "$frontendDist\*" $wwwroot -Recurse -Force

Write-Host "Done. Copy this folder to the server: $outputDir" -ForegroundColor Green
Write-Host "If the site already runs in IIS, stop the Application Pool before overwriting the DLLs." -ForegroundColor Yellow
