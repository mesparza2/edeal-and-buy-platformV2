# Plan de migración eDeal&Buy → V2

Reescritura de `SistemaInventarioSupplyChain` (ASP.NET MVC 5 / .NET Framework 4.7.2) en el stack nuevo
(.NET 10 LTS + Angular estable), conservando la lógica de negocio y corrigiendo lo exigido por la
*Evaluación técnica de eDeal&Buy v1.2* (hallazgos `XXX-nn`, requisitos `RQ-*`, umbrales en su Anexo C).
`supply-wms-2026` es **solo referencia** de estructura, scripts y convenciones.

## Decisiones tomadas

| # | Decisión |
|---|---|
| 1 | **Base de datos nueva** con claves sustitutas, llaves foráneas, únicos y dominios (RQ-DAT-01..03). Migración de datos por módulo. |
| 2 | Migración **módulo por módulo**. Los SP se revisan solo los que use cada módulo; los sin uso se descartan. La lógica extraída se documenta en el catálogo de reglas. |
| 3 | Identidad por **OIDC** con MFA obligatorio a roles internos, federación con directorio corporativo y bloqueo/contraseñas según Anexo C (RQ-SEC-01). Se sigue el informe, no la referencia. |
| 4 | Sistema **independiente** de SupplyWMS: sin integración ni reutilización de su dominio. |
| 5 | Solo se migra lo necesario: sin circuito anterior (OrdenCompra, Recepcion, AplicarRecepcion, OrdenPedido), ni tablas vacías o sin uso. |
| 6 | APIs, bots y procesos del lado de SAP quedan fuera y se trabajan al final: ver `PENDIENTES-FUERA-DE-ALCANCE.md`. |

## Estructura del repositorio (réplica de la referencia, sin multiempresa)

```
backend/   EDealBuy.slnx · src/{Api, Domain, Infrastructure} · tests/
frontend/  Angular (standalone) + Vitest
scripts/   deploy-package.ps1, set-iis-env.ps1 (adaptados)
docs/      plan, catálogo de reglas, manuales, diccionario (generado)
```
Se descartan `Platform`, tenancy, consola IT y marca por empresa. Se conserva: capas, permisos por política,
auditoría, importación de Excel, pruebas con WebApplicationFactory, despliegue a IIS con SPA en `wwwroot`.

## Fase 0 — Fundaciones (antes de cualquier módulo)

- Scaffolding backend/frontend, `.gitignore`, README, scripts de despliegue, EF Core con migraciones (RQ-ENG-01).
- Canalización CI/CD: build, pruebas, cobertura, SAST (incl. regla anti-concatenación SQL), escaneo de secretos,
  SBOM + SCA, puerta de duplicación <3 %, límites 500/60 líneas (RQ-ENG-03/08, RQ-SEC-06/08, RQ-PLT-05).
- Repo: `main` protegida, PR con revisor distinto, etiquetas por versión, sin binarios versionados (RQ-ENG-02).
- Secretos en almacén, cuenta SQL por componente, configuración versionada por ambiente, sin `debug` en producción (RQ-ENG-05, RQ-SEC-07).
- Preproducción con base propia y sin ruta hacia producción; datos enmascarados (RQ-ENG-06).
- Observabilidad base: logs estructurados con correlación, `/health`, métricas, alertas (RQ-OPE-01).
- Pruebas de arquitectura (ningún controlador toca la base), una biblioteca por función Excel/PDF (RQ-PLT-03/05).
- Respaldos automáticos RPO ≤15 min, copia externa, prueba de restauración (RQ-DAT-05).
- Línea base del sistema actual en producción: 5 semanas con un cierre mensual (RQ-MIG-01). **Arrancar ya: tarda semanas.**

## Fase 1 — Identidad, autorización y auditoría (módulo Seguridad y usuarios)

- OIDC, MFA, política de sesión (30 min inactividad / 12 h absoluta), bloqueo progresivo (RQ-SEC-01).
- Alta solo por usuario con permiso, por invitación de un solo uso (24 h), sin contraseña por correo (RQ-SEC-02).
- Autorización deny-by-default, matriz de permisos administrable, menú desde la misma fuente (RQ-SEC-03).
- Aislamiento por proveedor y contexto empresa/bodega/proyecto en cada petición (RQ-SEC-04).
- Antiforgery/cookies/CORS/TLS/HSTS/CSP (RQ-SEC-05). Auditoría de seguridad y de negocio (RQ-AUD-01/02).
- Prueba automática que recorre todas las rutas por rol.
- Mapeo de los 7 roles legados: Administrador, Cliente, Proveedor, Operativo, Proveedor GE, Financiero, Compras.

## Fase 2 — Núcleo de datos y parámetros

- Diseño del esquema nuevo: cabecera de orden, línea, confirmación, proveedor, artículo, guía con claves
  sustitutas; catálogos de estado con FK/CHECK; únicos de negocio (RQ-DAT-01..02).
- Parámetros de negocio administrables y auditados (NC 5 %, series, establecimiento, cortes, feriados,
  plazos, copias) (RQ-DOM-02). Servicio de correo transaccional con cola (RQ-INT-07).
- Motor de trabajos asíncronos con estado consultable (cargas, exportaciones, reportes) (RQ-OPE-03).
- Diccionario de datos generado del esquema (RQ-DAT-03). Retención/archivado de bitácoras (RQ-DAT-04).

## Fases 3–8 — Módulos (orden por dependencia)

Cada módulo repite el mismo ciclo: **(a)** revisar controladores, servicios y SP que usa → **(b)** entrada al
catálogo de reglas + pruebas de caracterización del legado → **(c)** modelo de datos → **(d)** backend con pruebas
→ **(e)** frontend → **(f)** paridad y pruebas e2e → **(g)** migración de datos del módulo con conciliación.

| Fase | Módulo | Origen en legado | Correcciones clave |
|---|---|---|---|
| 3 | Catálogo y stock de proveedor | ProveedorArticulos, ActualizacionStockMasiva(+Service), Proveedores/ProveedoresInfoSap, UsuarioProveedor | Servicio único de stock y ventana 120 min configurable con alerta (RQ-DOM-04); cliente único de Miles detrás de un puerto; carga masiva asíncrona con informe por fila (RQ-DOM-05). |
| 4 | Órdenes y portal de proveedor | OrdenPedidoCliente, OrdenPedidoProveedorItem (+GrupoEntregas, +ProductosDigitales), OrdenPedidoSC, Historial*, ConfirmacionOrdenSeries | **Un solo portal** en vez de 3 copias; solicitud/pedido a SAP con intención + idempotencia, candado fail-closed, estado por paso, bandeja de excepciones (RQ-CON-01..03). |
| 5 | WMS y bodega | Cliente, MasivoArticulo, CrearBodega, Inventario, InventarioDinamico, Kardex, KardexGerencial, KitsDescargo | Kardex con clave de idempotencia y único filtrado (RQ-DAT-02); índices (RQ-OPE-05). |
| 6 | Despacho y guías | EscaneoGuiasSupply (+sp_Validar*/Confirmar*/Revertir*) | **Máquina de estados** (puntos 0,1,4,5; BPP/BPC) con tabla de transiciones y pruebas por transición (RQ-DOM-03); entrada/salida SAP con compensación y candado; PDF de guías. Acceso a Sonder tras un puerto aislado. |
| 7 | Reportes y finanzas | ReporteGeneralEDB/PPM, SapCompras, Facturación, ConciliaciónCompras(+Auto), OCDigitales, VentasDiarias, ProductosActivos, NotasCreditoSAP, CargaMasivaAuditoria | Exportación a Excel de todos (RQ-DOM-05); paginación en servidor; datos personales con permiso explícito y cifrado (RQ-AUD-03); conciliación diaria SAP↔local (RQ-CON-03). |
| 8 | Transversales de cierre | Dashboard, Home | Inventario único de procesos programados (RQ-OPE-02). |

El orden 6 depende de 5 (kardex) y de 4 (órdenes). Un módulo no se da por cerrado sin sus pruebas de aceptación.

## Fase 9 — Cierre y salida a producción

- Plan de migración y corte: ≥2 ensayos completos, conciliación de conteos, existencias por SKU/bodega, órdenes
  abiertas y saldos contra origen y SAP, ventana de corte y vuelta atrás (RQ-MIG-03).
- Pruebas de carga (p95 del Anexo C), recuperación (RTO ≤4 h), TLS, penetración por tercero sin hallazgos altos (RQ-OPE-05, RQ-SEC-08).
- LOPDP: registro de tratamiento, retención, enmascarado en no-prod (RQ-AUD-03).
- Manuales y runbooks sin campos por confirmar; reinstalación de preproducción por alguien ajeno (RQ-OPE-06).
- **Puesta en producción a más tardar nov-2027** (soporte de .NET 10 hasta nov-2028, ≥12 meses restantes) y plan de
  actualización al siguiente LTS (RQ-PLT-01).

## Después de la V2

Trabajar `PENDIENTES-FUERA-DE-ALCANCE.md` (APIs, bots y procesos del lado de SAP).

## Riesgos y dependencias

- **Sonder:** hoy se lee por servidor vinculado. La V2 no puede usarlo (RQ-INT-02). Interino: puerto/adaptador
  aislado; definir con Sonder el contrato definitivo.
- **SAP:** la V2 consume `ApisInventarios` tal cual (sin corregir hasta el final) mediante un adaptador único;
  la idempotencia y el candado se hacen en el lado V2.
- **Coexistencia:** mientras haya módulos sin migrar, el legado sigue escribiendo en su base. Cada módulo migra
  con conciliación; definir si hay doble escritura o corte por módulo antes de la Fase 3.
- **Secretos del legado:** `Web.config` trae credenciales reales commiteadas; rotarlas y no copiarlas.
- **Proveedor OIDC por definir** (directorio corporativo, ¿Entra ID u otro?) antes de la Fase 1.
