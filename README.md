# eDeal&Buy Platform V2

Reescritura de `SistemaInventarioSupplyChain` sobre el stack nuevo: Web API en .NET 10 (LTS) + Angular. Plan y alcance en `docs/`.

## Estructura

```
backend/    EDealBuy.slnx · src/{EDealBuy.Api, EDealBuy.Domain, EDealBuy.Infrastructure} · tests/
frontend/   Angular (componentes standalone)
scripts/    deploy-package.ps1 (paquete para IIS: API + SPA en wwwroot)
docs/       plan de migración, pendientes fuera de alcance
```

## Ejecutar

```powershell
cd backend; dotnet run --project src/EDealBuy.Api     # API
cd frontend; npm start                                 # servidor de desarrollo de Angular
```

Los secretos locales van en `backend/src/EDealBuy.Api/appsettings.secrets.json` (ignorado por git). Salud: `GET /health`.

## Requisitos

.NET SDK 10 (fijado en `backend/global.json`), Node 24, npm 11.
