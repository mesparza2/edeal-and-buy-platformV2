# eDeal&Buy Platform V2

Rewrite of `SistemaInventarioSupplyChain` on the new stack: .NET 10 (LTS) Web API + Angular. Plan and scope in `docs/`.

## Structure

```
backend/    EDealBuy.slnx · src/{EDealBuy.Api, EDealBuy.Domain, EDealBuy.Infrastructure} · tests/
frontend/   Angular (standalone components)
scripts/    deploy-package.ps1 (IIS package: API + SPA in wwwroot)
docs/       migration plan, out-of-scope backlog
```

## Run

```powershell
cd backend; dotnet run --project src/EDealBuy.Api     # API
cd frontend; npm start                                 # Angular dev server
```

Local secrets go in `backend/src/EDealBuy.Api/appsettings.secrets.json` (git-ignored). Health check: `GET /health`.

## Requirements

.NET SDK 10 (pinned in `backend/global.json`), Node 24, npm 11.
