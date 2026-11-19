# Pendientes fuera de alcance (APIs, bots y procesos del lado de SAP)

Origen: *Evaluación técnica de eDeal&Buy v1.2* (PPM). Estos hallazgos pertenecen a las APIs, los bots y los
procesos del lado de SAP, que **se corrigen por separado**. Se retoman cuando termine la migración de
`SistemaInventarioSupplyChain` a esta plataforma (V2). Mientras tanto, la V2 solo debe **respetar sus contratos**
(ver última columna) y no depender de sus defectos.

## Hallazgos diferidos

| ID | Componente | Resumen | Qué debe respetar la V2 mientras tanto |
|---|---|---|---|
| SEC-04 | ApisInventarios | Crea documentos en SAP B1 y sus controladores no exigen token; emisor de tokens con usuario fijo, CORS abierto y HTTP permitido. | La V2 se autentica con credenciales propias de servicio (secreto en almacén, nunca en código) y habla solo HTTPS. |
| PLA-02 / INT-18 | ApisInventarios, bots financieros | Dependencia de DI API (COM, cliente SAP en el equipo); sin gestión de conexiones ni licencias documentadas. Objetivo: Service Layer (RQ-PLT-02). | Ninguna referencia a bibliotecas de SAP fuera del adaptador de la V2. |
| INT-03 / DAT-13 | Procesos del lado de SAP | Alta de artículos y OC automáticas leen/escriben `Inventarios` por el servidor vinculado "Inventario", sin código entregado. | La base nueva **no** expone acceso directo a terceros (RQ-INT-02). Hasta que se rediseñen, el esquema legado sigue vivo para ellos. |
| INT-04 / BAK-07 | Bots EDAB_ImportaFacturasEDeal (físicas y digitales) | Errores solo a consola, sin log, sin estado por paso; si falla un paso intermedio no está documentado. | Bandeja de excepciones y conciliación diaria de la V2 deben poder leer su resultado (RQ-CON-03/04). |
| INT-05 | Bots de facturación | Serie 4 y `EXX_DOCUM_LEG_INTER` sin control de concurrencia (folios repetidos / facturas duplicadas). | Facturación idempotente por orden y tipo de documento; folios serializados (RQ-CON-04). |
| INT-06 | Elogistics, Giftpoint, HANNAPRUEBAS | Apuntan a desarrollo, demo y al esquema de producción. | Ninguna dirección de dev/demo/pruebas en configuración de producción (verificación al arrancar). |
| INT-17 | Bots de facturación | Actualizan la lista de precios 1 de SAP (ITM1) al facturar. | Decisión de negocio pendiente: conservar o eliminar la regla. La V2 no modifica datos maestros de SAP. |
| BAK-09 / OPS-10 | Bots y procesos programados | 4–5 de 7 procesos con frecuencia/servidor "por confirmar"; sin planificador versionado. | Inventario único de procesos sin campos "por confirmar" (RQ-OPE-02). |
| INT-07 | ApisSapConsultas | Sin desplegar según la documentación, aunque `ProveedoresInfoSAP` ya tiene filas; sin commits. | La V2 consume la sincronización de proveedores por interfaz, con fecha/resultado visible y alerta a 24 h. |
| INT-08 / INT-10 | Bot de catálogo Miles, API de stock | Catálogo en páginas de 20 por RUC; PATCH de stock con 20 llamadas en paralelo; copiado en dos componentes. | **Un solo cliente de Miles** con limitador global (RQ-INT-04): definir quién lo implementa para no duplicarlo. |
| SEC-18 / INT-12 | ApiStockProveedoresExterno | Límite de 60 req/min en memoria por instancia; casos de prueba por ejecutar. | Conservar su diseño de llaves (hash, alcance por proveedor, ruta de prueba, auditoría). Límite compartido si hay >1 instancia. |
| INT-11 | APIs propias | Rutas sin versión; dirección productiva de EDYB "por confirmar". | OpenAPI versionado y convivencia de versiones 6 meses (RQ-INT-01). |
| INT-13 | ApisInventariosEDYB | Inserta la orden antes de pedir la solicitud a SAP, sin transacción ni aviso a Miles si SAP falla. | Recepción de órdenes idempotente por número de orden (RQ-CON-01). |
| INT-14 / DAT-14 | Sonder (tracking, `LS_SONDER`) | Escritura por procedimiento de Sonder y lecturas por servidor vinculado con proveedor SQLNCLI, sin contrato versionado. | **Interino:** la V2 accede a Sonder detrás de un puerto/adaptador aislado; el destino es API o mensajería versionada (RQ-INT-02). |
| PLA-13 / OPS-16 | Piezas sin Git | 9 de 11 piezas sin historial de versiones (APIs, bots, notificaciones). | Todo el código de esas piezas entra a repositorios con historial (RQ-ENG-01). |
| SEC-09 / INT-15 (parte) | Servicios de notificación | Buzón Outlook por SMTP con credenciales en texto plano en `Parametros`. | La V2 usa su propio servicio de correo; no lee esas credenciales. |
| INT-16 | Recuperación de fallos | 4 vías de reintento manual, sin cola de fallidos. | La bandeja de excepciones de la V2 las reemplaza para lo que la V2 origine. |

## Cómo retomarlos

1. Terminar la migración módulo por módulo (ver `PLAN-MIGRACION.md`).
2. Para cada pieza: repositorio con historial → secretos y cuentas propias → autenticación/token → idempotencia y
   registro → pruebas → canalización → retiro de accesos directos a base (servidores vinculados).
3. Verificar contra los criterios de aceptación de los `RQ-*` que cita cada hallazgo en el informe.
