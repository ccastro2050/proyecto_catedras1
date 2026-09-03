# Plan de construcción — ApiCatedrasUsbmed

**API REST específica y tipada** para el sistema de cátedras abiertas de la Universidad de San Buenaventura, Medellín.
**Referencia arquitectónica:** [`ApiEvalFormativaUsbmed`](../proyectoEvalFormativa/ApiEvalFormativaUsbmed) — API en producción del proyecto EvalFormativa.
**Base de datos:** `catedras`, esquema `public`, **37 tablas + 6 vistas + 10 rutinas**, ya construida y verificada en [`SOLUCION/fisico_postgres/`](SOLUCION/fisico_postgres/).
**Fecha:** 10 de agosto de 2026

---

## 0 · De qué parte este plan

No se parte de cero por partida doble:

1. **La base de datos ya existe y corre.** Las 37 tablas, 52 claves foráneas, 47 restricciones, 7 disparadores y 10 rutinas están construidas y cargadas con datos reales del ASIS. `ejecutar-todo.sql` termina con código 0.
2. **La arquitectura ya está probada en producción.** `ApiEvalFormativaUsbmed` sirve a 42 tablas del proyecto EvalFormativa con el mismo patrón. No hay que diseñarla: hay que **replicarla y adaptarla**.

Este documento dice exactamente **qué se copia**, **qué cambia**, y sobre todo **dónde la referencia no alcanza** — porque el sistema de cátedras tiene un flujo que EvalFormativa no tiene.

---

## 1 · La API de referencia, tal como es

Lo que sigue está verificado leyendo el código, no supuesto.

### 1.1 · Stack

| Componente | Versión | Papel |
|---|---|---|
| .NET | **`net10.0`** *(el README dice 9.0; el `.csproj` dice 10.0 — manda el `.csproj`)* | Plataforma |
| ASP.NET Core | 10 | Web API, controladores |
| **Dapper** | 2.1.66 | Micro-ORM. **No Entity Framework** |
| Npgsql | 9.0.3 | Driver PostgreSQL |
| BCrypt.Net-Next | 4.0.3 | Hash de contraseñas |
| JwtBearer | 10.0.8 | Autenticación |
| Swashbuckle | 9.0.4 | Swagger. **No `Microsoft.AspNetCore.OpenApi`** — choca con Swashbuckle |
| SqlClient · MySqlConnector · Oracle · Sqlite | — | Multi-proveedor |

### 1.2 · La decisión de diseño fundamental

> **Una clase por tabla. Sin genéricos, sin reflexión en runtime.**

Cada tabla produce **seis archivos**: modelo, interfaz de repositorio, repositorio, interfaz de servicio, servicio y controlador. Con 42 tablas eso son ~250 archivos y ~110 registros de inyección de dependencias. Es deliberado, y `docs/principios_diseno.md` lo argumenta con una tabla comparativa: tipado en compilación, refactorización trazable por el IDE, SQL parametrizado fijo, mocks simples.

### 1.3 · Las capas, verificadas

```
Cliente ──JWT──► Controller ──► IServicio ──► IRepositorio ──Dapper──► PostgreSQL
                 [Authorize]     lógica +       SQL fijo por tabla
                 try/catch       BCrypt         [Column] real
                 traceId
```

- **Controller:** enruta, captura excepciones, devuelve `500 { mensaje, traceId }`. Nunca toca SQL.
- **Servicio:** delega casi todo al repositorio; su única lógica propia es `EncriptarCampos` (BCrypt por reflexión sobre los campos que pida `?camposEncriptar=`).
- **Repositorio:** construye el SQL. Multi-proveedor por `switch` sobre `DatabaseProvider`. **Valida la lista blanca de columnas** antes de interpolar cualquier nombre, y valida el esquema con expresión regular.

### 1.4 · El contrato REST — once endpoints por tabla

| Verbo | Ruta | Devuelve |
|---|---|---|
| `GET` | `/api/{tabla}?esquema=&limite=` | Array plano |
| `GET` | `/api/{tabla}/{pk}` | Objeto o `404 { mensaje }` |
| `POST` | `/api/{tabla}?camposEncriptar=` | `{ mensaje: "Registro creado" }` |
| `PUT` | `/api/{tabla}/{pk}` | `{ mensaje: "Registro actualizado" }` |
| `DELETE` | `/api/{tabla}/{pk}` | `{ mensaje: "Registro eliminado" }` |
| `GET` | `/api/{tabla}/por/{columna}/{valor}` | Array filtrado |
| `POST` | `/api/{tabla}/masivo` | `{ mensaje, filas }` |
| `PUT` | `/api/{tabla}/lote` | `{ mensaje, filas }` |
| `PUT` | `/api/{tabla}/masivo/por/{columna}/{valor}` | `{ mensaje, filas }` |
| `DELETE` | `/api/{tabla}/masivo/por/{columna}/{valor}` | `{ mensaje, filas }` |

**Convenciones:**
- Rutas en **snake_case** igual al nombre real de la tabla (`SnakeCaseRouteTransformer`).
- JSON en **snake_case** igual a las columnas (`JsonNamingPolicy.SnakeCaseLower`).
- `[Table]` y `[Column]` en los modelos; Dapper los honra con un `CustomPropertyTypeMap` global.
- Columnas `date` → `DateOnly`, con `DateOnlyTypeHandler`.

### 1.5 · Los tres helpers

| Helper | Qué hace |
|---|---|
| `ConexionHelper` | Genera `INSERT` y `UPDATE` leyendo `[Column]` y `[Key]` por reflexión. **La reflexión ocurre al construir el SQL, no en cada request** |
| `SnakeCaseRouteTransformer` | `ClaseTematica` → `clase_tematica` |
| `DateOnlyTypeHandler` | `date` ↔ `DateOnly` |

### 1.6 · Seguridad, verificada

- **Fail-fast:** sin `Jwt:Key` la API **no arranca** (`throw` en `Program.cs`).
- `appsettings.json` trae `ConnectionStrings.Postgres` y `Jwt.Key` **vacíos**.
- **CORS por configuración**: sin orígenes, se pone uno inválido a propósito. Nunca `AllowAnyOrigin`.
- `[Authorize]` en todo excepto `AutenticacionController`.
- Listas blancas de columnas y validación del esquema contra inyección.
- Los módulos opcionales (`Agente`, `Conocimiento`) están **apagados por configuración**, *fail-closed*.

---

## 2 · Qué se copia y qué cambia

| # | Aspecto | Decisión |
|---|---|---|
| 1 | Stack, versiones y paquetes | **Copiar idéntico** |
| 2 | Capas y nombres de carpetas | **Copiar idéntico** |
| 3 | Los tres helpers | **Copiar**, con una ampliación obligatoria — §4.3 |
| 4 | Contrato de 11 endpoints por tabla | **Copiar** |
| 5 | snake_case en rutas y JSON | **Copiar** |
| 6 | `AutenticacionController` con JWT + BCrypt | **Copiar**, y **añadir un segundo camino** — §5 |
| 7 | `EstructuraController` | **Copiar** |
| 8 | Controladores de vista de solo lectura | **Copiar el patrón**, seis veces |
| 9 | Módulos `Agente` y `Conocimiento` | **No incluir en la v1.** Dejar el hueco |
| 10 | **Capa de procesos** | **NUEVO.** No existe en la referencia — §6 |
| 11 | Tipos `long`, `uuid`, `bytea`, `inet`, `jsonb`, `tstzrange` | **NUEVO.** La referencia solo usa `int`, `string`, `bool`, `DateOnly` — §4 |
| 12 | Claves primarias compuestas sin sustituto | **NUEVO** — §4.4 |
| 13 | Puerto | **7045** (https 7046). La referencia usa 7035 y **debe seguir libre** |

> ### La diferencia que importa
>
> **`ApiEvalFormativaUsbmed` es CRUD puro más autenticación.** Todo su valor está en exponer 42 tablas de forma tipada.
>
> **ApiCatedrasUsbmed no puede serlo.** El registro de un asistente no es un `INSERT`: es *pedir clave → validarla → registrar con instantáneas → dentro de la ventana → respetando el cupo*. Eso vive en procedimientos de la base, y exponerlos como CRUD sobre `registro_asistencia` **saltaría todas las reglas**.
>
> Por eso el plan añade una **capa de procesos** que respeta las mismas capas y principios, pero cuyos repositorios llaman a funciones y procedimientos en vez de escribir `INSERT`.

---

## 3 · Inventario — qué hay que generar

### 3.1 · Resumen

| Familia | Cantidad | Archivos por unidad | Archivos |
|---|---:|---:|---:|
| Tablas (CRUD completo) | **37** | 6 | 222 |
| Vistas (solo lectura) | **6** | 5 | 30 |
| Autenticación de administrador | 1 | 5 | 5 |
| Acceso de asistente (OTP) | 1 | 5 | 5 |
| Procesos | 4 | 5 | 20 |
| Estructura (`information_schema`) | 1 | 5 | 5 |
| Helpers | 3 | 1 | 3 |
| **Total aproximado** | **50 controladores** | | **~290 archivos** |

Registros de inyección de dependencias: **~98 pares**.

### 3.2 · Las 37 tablas, por tipo de clave

**A · Clave sustituta `bigint` — 20 tablas**

`asistente` · `documento_asistente` · `consentimiento_datos` · `catedra` · `sesion` · `enlace_registro` · `clave_acceso` · `registro_asistencia` · `encuesta` · `pregunta` · `opcion_pregunta` · `respuesta_encuesta` · `respuesta_item` · `lote_carga_asistente` · `novedad_carga` · `alias_programa` · `lote_migracion` · `detalle_migracion` · `usuario` · `bitacora`

> **Todas son `bigint`, no `int`.** En C# eso es **`long`**, y las rutas van `{id:long}`. La referencia usa `int` en todas partes porque su esquema usa `serial`. **Copiar `int` aquí sería un error silencioso que solo aparecería al pasar de 2.147.483.647.**

**B · Clave natural de texto — 13 tablas**

`tipo_documento` · `tipo_vinculacion` · `facultad` · `programa_academico` · `periodo_academico` · `tipo_evento` · `sede` · `modalidad` · `dependencia` · `tipo_pregunta` · `estado_proceso` · `rol` · `parametro`

> Se generan con **`pkAutogenerada: false`**: el valor llega en el cuerpo y **entra en el `INSERT`**. Es el caso que `ConexionHelper` ya contempla.

**C · Clave compuesta, sin sustituto — 4 tablas**

| Tabla | Clave |
|---|---|
| `vinculacion_asistente` | `(fk_asistente, fk_tipo_vinculacion, fecha_ini)` |
| `programa_asistente` | `(fk_asistente, fk_programa, fk_periodo)` |
| `ponencia` | `(fk_sesion, fk_asistente, rol)` |
| `rol_por_usuario` | `(fk_usuario, fk_rol, fecha_ini)` |

> **Aquí la referencia no sirve de molde.** Su única tabla de unión, `rol_usuario`, tiene un `id` sustituto y se resuelve como cualquier otra. Las nuestras no lo tienen — y **no se les debe añadir**: `fecha_ini` está en la clave por una razón de negocio (que alguien pueda recuperar un rol o una vinculación que ya tuvo). Ver §4.4.

### 3.3 · Las 6 vistas — solo lectura

`v_asistente_vigente` · `v_asistencia_completa` · `v_pendiente_migracion` · `v_evaluacion_sesion` · `v_embudo_registro` · `v_control_ventana`

Patrón de `VCalificacionesDetalleController`: **solo `GET`** y `GET por/{columna}/{valor}`. Sin `POST`, `PUT` ni `DELETE`.

`v_asistencia_completa` es la que va a sostener casi todos los informes del front.

### 3.4 · Las 10 rutinas — la capa de procesos

| Rutina | Se expone en |
|---|---|
| `fn_resolver_asistente(text)` | `AccesoController` |
| `sp_solicitar_clave(...)` | `AccesoController` |
| `sp_validar_clave_y_registrar(...)` | `AccesoController` |
| `sp_responder_encuesta(...)` | `RegistroController` |
| `sp_cerrar_encuesta(...)` | `RegistroController` |
| `sp_emitir_enlace(...)` | `EnlaceController` |
| `fn_siguiente_reunion(char)` | `EnlaceController` |
| `fn_exportar_asis(bigint)` | `MigracionController` |
| `sp_generar_lote_migracion(...)` | `MigracionController` |
| `fn_resolver_programa(text, real)` | `CargaController` |

---

## 4 · Los seis problemas técnicos que la referencia no resuelve

Esta es la parte del plan que no se puede copiar. Cada uno con su decisión.

### 4.1 · Tipos de PostgreSQL que la referencia nunca vio

| Tipo en la BD | Dónde | Tipo C# | Decisión |
|---|---|---|---|
| `bigint` identity | 20 tablas | **`long`** | Directo. Rutas `{id:long}` |
| `smallint` | `numero_reunion`, `orden`, `intentos`, `valor_numerico` | `short` | Directo |
| `citext` | `correo_institucional`, `correo_personal`, `enviado_a` | `string` | Npgsql lo entrega como `string`. **Requiere `CREATE EXTENSION citext` en la BD** — ya está |
| `uuid` | `enlace_registro.token` | **`Guid`** | Directo. Serializa como texto en JSON |
| `bytea` | `clave_acceso.clave_hash` | **`byte[]`** | ⚠️ **Excluir del JSON de salida** — §7.2 |
| `inet` | `ip`, `ip_solicitud` | **`string`** | Npgsql lo entrega como `IPAddress`, que serializa mal. **`TypeHandler` propio `IPAddress ↔ string`** |
| `jsonb` | `bitacora.datos_antes/despues` | **`string`** | Se expone el JSON como texto. Alternativa: `JsonDocument`, más caro y sin ganancia |
| `timestamptz` | por todas partes | **`DateTimeOffset`** | Preserva la zona. `DateTime` la perdería, y aquí importa: la ventana del enlace es horaria |
| `date` | `fecha_ini`, `fecha_fin`, `vigente_desde` | `DateOnly` | Ya resuelto por `DateOnlyTypeHandler` |
| **`tstzrange`** | `enlace_registro.ventana` | **ninguno directo** | **§4.2 — es el caso difícil** |

### 4.2 · `tstzrange`: el tipo que rompe el molde

`enlace_registro.ventana` es un rango de tiempo. Npgsql lo mapea a `NpgsqlRange<DateTimeOffset>`, que **no serializa a JSON de forma útil** y que un cliente REST no sabe construir.

| # | Alternativa | Veredicto |
|---|---|---|
| A | Exponer `NpgsqlRange<DateTimeOffset>` tal cual | ❌ JSON ilegible; el front tendría que conocer el tipo de Npgsql |
| B | Quitar el rango de la BD y volver a dos columnas | ❌ **Destruye `EXCLUDE USING gist` y la contención `@>`**. Dos reglas dejarían de ser declarativas |
| C | Vista `v_enlace_registro` que proyecte `lower(ventana)` y `upper(ventana)` | ⚠️ Sirve para leer, no para escribir |
| **D** | **Modelo con `ventana_inicio` y `ventana_fin` (`DateTimeOffset`), y SQL del repositorio que construya el `tstzrange`** | ✅ **La elegida** |

**Cómo se implementa D.** `EnlaceRegistroRepositorio` **no usa `ConexionHelper`**: escribe su propio `INSERT`/`UPDATE`/`SELECT`. Es el único repositorio con SQL a mano, y lleva un comentario que explica por qué.

```sql
-- SELECT
SELECT id_enlace, fk_sesion, token, url_publica, ruta_imagen_qr, canal,
       lower(ventana) AS ventana_inicio,
       upper(ventana) AS ventana_fin,
       usos_maximos, revocado_en, fk_usuario_crea, creado_en
  FROM public.enlace_registro

-- INSERT
INSERT INTO public.enlace_registro (..., ventana, ...)
VALUES (..., tstzrange(@VentanaInicio, @VentanaFin, '[)'), ...)
```

> **Por qué no se toca la base de datos.** La alternativa B es la tentación fácil: cambiar el modelo para que quepa en el molde de la API. Sería invertir la relación correcta — **la API se adapta al modelo, no al revés**. El rango existe porque hace declarativas dos reglas que si no serían código.

### 4.3 · Columnas generadas: `ConexionHelper` las rompe

`catedra.nombre_asis` es `GENERATED ALWAYS AS (left(nombre,30)) STORED`. PostgreSQL **rechaza cualquier `INSERT` o `UPDATE` que la mencione**.

`ConexionHelper` de la referencia solo excluye las propiedades con `[Key]`. Si el modelo `Catedra` incluye `NombreAsis`, **todo `POST /api/catedra` falla con error 42601**.

**Corrección obligatoria** — ampliar `ConexionHelper`:

```csharp
using System.ComponentModel.DataAnnotations.Schema;

// Excluye PK autogenerada Y columnas calculadas por la BD.
private static bool EsGenerada(PropertyInfo p) =>
    p.GetCustomAttribute<DatabaseGeneratedAttribute>()?.DatabaseGeneratedOption
        == DatabaseGeneratedOption.Computed;

var props = todas.Where(p => !EsGenerada(p) &&
                             (!pkAutogenerada || !p.IsDefined(typeof(KeyAttribute), true)))
                 .ToArray();
```

Y en el modelo:

```csharp
[Column("nombre_asis")]
[DatabaseGenerated(DatabaseGeneratedOption.Computed)]
public string NombreAsis { get; set; } = string.Empty;   // solo lectura
```

> **Esta corrección va también al generador**, no solo a este proyecto. Es exactamente lo que dice el README de la referencia: *«no parchear los controladores a mano: cualquier corrección va al generador»*.

### 4.4 · Claves compuestas: rutas de varios segmentos

Cuatro tablas sin PK sustituta. La decisión:

```
GET    /api/vinculacion_asistente/{fkAsistente:long}/{fkTipoVinculacion}/{fechaIni}
PUT    /api/vinculacion_asistente/{fkAsistente:long}/{fkTipoVinculacion}/{fechaIni}
DELETE /api/vinculacion_asistente/{fkAsistente:long}/{fkTipoVinculacion}/{fechaIni}
```

| # | Alternativa | Veredicto |
|---|---|---|
| A | Añadir una PK sustituta a las cuatro tablas | ❌ **Cambia la base para acomodar la API.** Y `fecha_ini` está en la clave por diseño |
| B | Clave compuesta en la *query string* | ❌ Rompe la convención de la referencia, que pone la PK en la ruta |
| **C** | **Segmentos de ruta en el orden de la clave** | ✅ **La elegida.** Mantiene la convención y no toca la BD |

Y una comodidad, siguiendo el precedente de `RutaController` (que ya acepta `?valorClave=` para valores con barras):

```
GET /api/vinculacion_asistente/buscar?fk_asistente=123&fk_tipo_vinculacion=ESTUDIANTE&fecha_ini=2026-01-19
```

### 4.5 · Los disparadores derivan columnas: el `POST` no puede exigirlas

Al insertar en `registro_asistencia`, el disparador `fn_trg_registro_validar` **rellena** `fk_vinculacion_snapshot` y `fk_programa_snapshot`, valida la ventana y el cupo. Al insertar en `sesion`, otro disparador **asigna** `numero_reunion`.

Consecuencias para los modelos:

| Columna | En el `POST` | Por qué |
|---|---|---|
| `sesion.numero_reunion` | **Opcional** (`short?`), se envía `0` o se omite | Lo pone el disparador |
| `registro_asistencia.fk_vinculacion_snapshot` | **Opcional** | Lo pone el disparador |
| `registro_asistencia.fk_programa_snapshot` | **Opcional** | Lo pone el disparador, o lo deja nulo a propósito |
| `clave_acceso.es_correo_institucional` | **Opcional** | Lo deriva el disparador del dominio del correo |

**Y las excepciones de los disparadores hay que traducirlas.** Un `RAISE EXCEPTION 'RN-15: ...'` llega a .NET como `PostgresException` con `SqlState = 23514` (`check_violation`). Devolverlo como `500` sería mentir: es un error del cliente.

**Se añade un filtro de excepciones global**, `FiltroExcepcionPostgres`:

| `SqlState` | Significado | HTTP |
|---|---|---|
| `23505` unique_violation | Ya existe | **409 Conflict** |
| `23503` foreign_key_violation | Referencia inexistente | **400** |
| `23514` check_violation | **Regla de negocio (RN-xx)** | **422 Unprocessable Entity** |
| `23502` not_null_violation | Falta un campo | **400** |
| `P0002` no_data_found | No encontrado | **404** |
| resto | — | **500** con `traceId` |

El mensaje del `RAISE EXCEPTION` ya viene redactado en español y con su número de regla: se devuelve tal cual en `{ mensaje }`. **Es la mejor documentación de errores que puede tener el front**, y sale gratis porque las reglas ya están escritas así en la base.

### 4.6 · `DELETE` está revocado en la base

`17-usuarios-permisos.sql` **revoca `DELETE` en todas las tablas y para todos los roles** (RN-32: nadie se elimina).

Los `DELETE` que el molde genera por tabla **fallarían con error de permisos**. Dos opciones:

| # | Alternativa | Veredicto |
|---|---|---|
| A | Generar los `DELETE` igual y que fallen en runtime | ❌ Contrato mentiroso: Swagger anuncia algo que nunca funciona |
| **B** | **Generar los `DELETE`, pero que el servicio devuelva `405 Method Not Allowed` con el motivo** | ✅ **La elegida.** El contrato es honesto y el motivo queda documentado |

```json
{ "mensaje": "RN-32: en este sistema no se elimina. Use PUT sobre la columna 'activo'." }
```

**Excepción:** las tablas de catálogo donde el borrado sí tiene sentido operativo (`alias_programa`, `parametro`) conservan su `DELETE` real, si el rol de base de datos lo permite. Se decide tabla por tabla en la Fase 2.

---

## 5 · Autenticación: dos caminos, no uno

La referencia tiene **un solo** endpoint anónimo. ApiCatedrasUsbmed necesita **dos caminos**, y la razón está en la reunión.

### 5.1 · Camino A — administrador (idéntico a la referencia)

```http
POST /api/autenticacion/token
{ "usuario": "admin.catedras", "contrasena": "****" }
→ { "estado": 200, "token": "eyJ...", "expiracion": "..." }
```

Contra la tabla `usuario` (`clave_hash` con BCrypt). Idéntico al patrón de la referencia salvo que allí la clave de entrada es `email` y aquí es `usuario` — porque así está la tabla.

### 5.2 · Camino B — asistente por clave al correo · **NUEVO**

Es el flujo del `.docx` y de la reunión. **No es autenticación: es antisuplantación** — *«yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo; si no, yo te registro a vos y vos me registrás a mí»* (`1:04:51`).

```http
POST /api/acceso/solicitar-clave            [AllowAnonymous]
{ "identificador": "30000118518", "token": "8f3c…-uuid-del-QR" }
→ 200 { "id_clave": 4711, "enviado_a": "a***@usbmed.edu.co", "expira_en": "...", "institucional": true }

POST /api/acceso/validar                    [AllowAnonymous]
{ "id_clave": 4711, "clave": "482913" }
→ 200 { "id_registro": 88231, "catedra": "...", "sesion": "...", "token": "eyJ..." }
```

**Cinco reglas que este camino debe cumplir:**

1. **`identificador` acepta las tres vías** — código, documento o correo. Lo resuelve `fn_resolver_asistente`, que ya limpia prefijos como `ID:` y busca en documentos vigentes **y no vigentes**.
2. **La clave en claro nunca se guarda.** `sp_solicitar_clave` la devuelve para que la API la envíe por correo, y almacena solo el hash.
3. **El correo se enmascara en la respuesta.** Devolver `juan.perez@usbmed.edu.co` a un anónimo sería filtrar el directorio.
4. **`AllowAnonymous` con límite de tasa.** Son los dos únicos endpoints públicos junto al token: por IP y por identificador. Se usa el `RateLimiter` nativo de ASP.NET Core, no un paquete.
5. **Respuesta uniforme ante identificador inexistente.** Si contestara «no existe», el endpoint sería un **oráculo de enumeración** del maestro de 14.808 personas. Devuelve siempre `200` con un mensaje neutro y no envía nada.

> **Punto 5: la referencia hace lo contrario a propósito.** Su `AutenticacionController` distingue `404 Usuario no encontrado` de `401 Contraseña incorrecta`, porque es una pantalla de administración interna. Aquí el endpoint es **público en un QR proyectado en un auditorio**, y la amenaza es otra. **Es una desviación deliberada del molde, y hay que justificarla en la revisión.**

### 5.3 · El envío del correo

La base **no envía correos**: guarda la evidencia de que se enviaron. El envío es de la API.

- `IServicioCorreo` con una implementación SMTP (`System.Net.Mail`) y otra `NoOp` para desarrollo.
- Config-gated como el `Agente` de la referencia: **sin `Correo:Activo=true`, no se envía nada** y `sp_solicitar_clave` sigue registrando el intento. Fail-closed.
- Plantilla con imagen corporativa — el profesor Carlos Castro tiene el PDF de Comunicaciones (`59:10`).

---

## 6 · La capa de procesos — lo que la referencia no tiene

Cuatro controladores que **no son CRUD**. Respetan las mismas capas; lo que cambia es que sus repositorios **llaman a rutinas** en vez de componer `INSERT`.

### 6.1 · `AccesoController` — público

| Verbo | Ruta | Auth |
|---|---|---|
| `GET` | `/api/acceso/enlace/{token:guid}` | anónimo — devuelve la cátedra, la sesión y si la ventana está abierta |
| `POST` | `/api/acceso/solicitar-clave` | anónimo |
| `POST` | `/api/acceso/validar` | anónimo |

`GET enlace/{token}` es lo que alimenta la **pantalla con imagen corporativa y el nombre de la cátedra** que pidió el profesor Carlos Castro en `1:05:40`.

### 6.2 · `RegistroController` — mixto

| Verbo | Ruta | Auth |
|---|---|---|
| `POST` | `/api/registro/{idRegistro:long}/encuesta` | token de asistente |
| `GET` | `/api/registro/sesion/{idSesion:long}` | admin — la lista del día |
| `POST` | `/api/registro/manual` | admin — el externo, o quien no pudo con el QR |

### 6.3 · `EnlaceController` — solo administrador

| Verbo | Ruta | Qué hace |
|---|---|---|
| `POST` | `/api/enlace/emitir` | **El botón del `.docx`.** Llama a `sp_emitir_enlace`, revoca el anterior, devuelve `url_publica` |
| `GET` | `/api/enlace/{idEnlace:long}/qr` | Devuelve el PNG del QR — **lo genera la API**, no la base |
| `DELETE` | `/api/enlace/{idEnlace:long}` | Revoca (marca `revocado_en`; no borra) |
| `GET` | `/api/enlace/siguiente-reunion/{idEventoAsis}` | `fn_siguiente_reunion` |

> **Generación del QR.** Hace falta una biblioteca: `QRCoder` (MIT, sin dependencias nativas) es la opción sensata. La ruta relativa se guarda en `ruta_imagen_qr`; la restricción `chk_enlace_ruta_qr` **rechaza rutas absolutas**, así que la API debe guardar `qr/{token}.png` y nunca `C:\...`.

### 6.4 · `MigracionController` — solo administrador

| Verbo | Ruta | Qué hace |
|---|---|---|
| `GET` | `/api/migracion/pendientes` | `v_pendiente_migracion` |
| `GET` | `/api/migracion/sesion/{idSesion:long}/previsualizar` | `fn_exportar_asis` en JSON |
| `GET` | `/api/migracion/sesion/{idSesion:long}/archivo` | **El archivo plano.** `.xlsx` de tres columnas |
| `POST` | `/api/migracion/sesion/{idSesion:long}/generar` | `sp_generar_lote_migracion` |
| `PUT` | `/api/migracion/lote/{idLote:long}/resultado` | Registra la instancia del ASIS y el estado |

> ### El endpoint del archivo plano es el más delicado de toda la API
>
> El manual de migración es explícito: *«únicamente haya información en las tres columnas correspondientes»* y *«verificar que el archivo esté limpio y que no se haya agregado ningún texto adicional»*.
>
> **Requisitos no negociables**, que van a prueba automática:
> - **Sin fila de encabezado.**
> - **Exactamente tres columnas**: reunión, ID, código de programa.
> - **Sin espacios sobrantes** — por esto `codigo` es `varchar(5)` y no `char(5)`.
> - El ID **como texto**, no como número: Excel convertiría `0000123` y `1000513C` reventaría.
> - Sin externos ni registros sin programa — ya lo filtra `fn_exportar_asis`.
>
> Biblioteca: **ClosedXML** o **EPPlus**. ClosedXML es MIT; EPPlus exige licencia comercial desde la versión 5. **Se elige ClosedXML.**

### 6.5 · `CargaController` — solo administrador

| Verbo | Ruta | Qué hace |
|---|---|---|
| `POST` | `/api/carga/asistentes` | Sube el Excel del ASIS. Crea el lote, carga y devuelve el resumen |
| `GET` | `/api/carga/{idLote:long}/novedades` | Las filas rechazadas, con su motivo |
| `POST` | `/api/carga/catedras` | Sube `USBME_LCONTROL_CATEDRAS` |
| `GET` | `/api/carga/programa/resolver?texto=` | `fn_resolver_programa` — para depurar los alias a mano |

Este controlador **reimplementa en C# lo que hoy hace `preparar-datos.py`**, con la misma lógica de validación de dominios y de novedades. El script de Python queda como herramienta de carga inicial; la API lo sustituye para el uso corriente.

---

## 7 · Seguridad

### 7.1 · Lo que se hereda

Fail-fast sin `Jwt:Key` · secretos vacíos en `appsettings.json` · CORS por lista · `[Authorize]` por defecto · listas blancas de columnas · validación de esquema con expresión regular · SQL parametrizado.

### 7.2 · Lo que hay que añadir, por el tipo de dato

| # | Riesgo | Medida |
|---|---|---|
| 1 | **`clave_acceso.clave_hash` se serializaría en el `GET`** | `[JsonIgnore]` en la propiedad. Y el `GET /api/clave_acceso` **solo para el rol administrador** |
| 2 | **`usuario.clave_hash`**, lo mismo | `[JsonIgnore]` |
| 3 | **`GET /api/asistente` devuelve 14.808 personas con documento y correo** | Paginación **obligatoria** con tope duro, y `[Authorize(Roles="ADMIN")]` |
| 4 | El endpoint público podría **enumerar el maestro** | §5.2, punto 5: respuesta uniforme |
| 5 | Fuerza bruta sobre la clave de 6 dígitos | La base ya limita a 3 intentos (`CLAVE_MAX_INTENTOS`); la API añade límite por IP |
| 6 | **Ley 1581**: los datos personales salen por la API | Autorización por rol + bitácora. `consentimiento_datos` se consulta antes de exponer datos de externos |
| 7 | La API se conecta con un usuario con demasiados permisos | **Usar `u_app_web`** (rol `rol_app_registro`) para el camino público y `u_gestor_catedras` para el administrativo. **Dos cadenas de conexión** |

> **El punto 7 es el que más aprovecha el trabajo ya hecho.** `17-usuarios-permisos.sql` creó cuatro roles con permisos comprobados —incluido que la aplicación **no puede leer `asistente`**—. Si la API se conecta como `postgres`, todo ese diseño **se pierde**. Dos cadenas de conexión, y la del camino público con el rol mínimo.

### 7.3 · Autorización por rol

La referencia solo distingue autenticado de anónimo. Aquí hacen falta roles, y la base ya los tiene (`rol`, `rol_por_usuario`): `ADMIN`, `COORDINADOR`, `CONSULTA`.

El JWT lleva los roles vigentes como *claims*, y los controladores usan `[Authorize(Roles = "ADMIN")]`. `AutenticacionServicio` los consulta al emitir el token — con la fecha, porque `rol_por_usuario` es histórico y solo cuentan los de `fecha_fin IS NULL`.

---

## 8 · Estructura del proyecto

```
ApiCatedrasUsbmed/
├── ApiCatedrasUsbmed.csproj
├── Program.cs                       ~98 pares de DI, CORS, JWT, Swagger, RateLimiter
├── appsettings.json                 secretos VACÍOS
├── appsettings.Development.json
├── Properties/launchSettings.json   puerto 7045 / 7046
├── Helpers/
│   ├── ConexionHelper.cs            + soporte de columnas generadas (§4.3)
│   ├── SnakeCaseRouteTransformer.cs
│   ├── DateOnlyTypeHandler.cs
│   ├── InetTypeHandler.cs           NUEVO — inet ↔ string
│   └── FiltroExcepcionPostgres.cs   NUEVO — SqlState → HTTP (§4.5)
├── Modelos/                         37 + 6 vistas + DTOs de proceso
├── Repositorios/
│   ├── Abstracciones/               ~48 interfaces
│   └── *.cs                         ~48 implementaciones
├── Servicios/
│   ├── Abstracciones/
│   ├── *.cs
│   └── ServicioCorreo.cs            NUEVO
├── Controllers/                     ~50
├── docs/
│   ├── arquitectura.md
│   ├── api_referencia.md
│   ├── principios_diseno.md
│   ├── modelo_datos.md              → apunta a SOLUCION/MR/
│   ├── instalacion.md
│   └── diferencias_con_evalformativa.md   NUEVO — §2 y §4
└── pruebas/
    ├── contrato.http
    └── certificacion.ps1
```

---

## 9 · Plan de trabajo

### Fase 1 · Esqueleto y contrato — *medio día*

1. `dotnet new webapi -n ApiCatedrasUsbmed`, paquetes idénticos a la referencia más `QRCoder` y `ClosedXML`.
2. Copiar y adaptar `Program.cs`, los tres helpers y `appsettings`.
3. **Ampliar `ConexionHelper`** con el soporte de columnas generadas (§4.3).
4. Añadir `InetTypeHandler` y `FiltroExcepcionPostgres`.
5. `AutenticacionController` con roles en los *claims*.
6. `EstructuraController`.
7. **Criterio de salida:** arranca, Swagger responde, `POST /api/autenticacion/token` devuelve un JWT con roles.

### Fase 2 · Los 37 cuartetos CRUD — *2 días*

1. Generar con el generador, apuntando a `public.catedras`.
2. **Revisar a mano los seis casos difíciles** (§4): `enlace_registro`, `catedra`, las cuatro de clave compuesta.
3. Decidir tabla por tabla qué pasa con el `DELETE` (§4.6).
4. Poner `[JsonIgnore]` en los dos `clave_hash`.
5. **Criterio de salida:** las 37 tablas responden `GET` y `GET/{pk}`; `POST` funciona en `catedra` — la de la columna generada.

### Fase 3 · Vistas y procesos — *2–3 días*

1. Los 6 controladores de vista.
2. `AccesoController` con el flujo completo y el límite de tasa.
3. `EnlaceController` con generación de QR.
4. `MigracionController` con el archivo plano.
5. `CargaController`.
6. `IServicioCorreo`, config-gated.
7. **Criterio de salida:** el recorrido completo por HTTP — emitir enlace, pedir clave, validar, registrar, responder encuesta, generar lote, descargar el archivo.

### Fase 4 · Certificación — *1 día*

Ver §10.

### Fase 5 · Documentación y despliegue — *1 día*

`docs/` completo, `README.md` con el mismo formato de la referencia, y despliegue.

**Total: 6 a 8 días.**

---

## 10 · Certificación — cómo se sabe que está bien

### 10.1 · Batería de contrato

Por cada una de las 37 tablas: `GET` devuelve array · `GET/{pk}` devuelve objeto o 404 · `POST` devuelve `{mensaje}` · `PUT` idem · `GET por/{columna}/{valor}` filtra · una columna inexistente devuelve **400**, no 500.

### 10.2 · Las once pruebas que importan de verdad

Estas no las cubre ningún molde. Salen de las reglas del negocio.

| # | Prueba | Debe |
|---|---|---|
| 1 | `POST /api/catedra` con `nombre` de 200 caracteres | **Crear**, y `nombre_asis` salir con 30 |
| 2 | `POST /api/sesion` sin `numero_reunion` | **Crear**, y el disparador asignarlo |
| 3 | `POST /api/acceso/solicitar-clave` fuera de la ventana | **422** con el texto de RN-15 |
| 4 | Validar la misma clave dos veces | La segunda, **422** con RN-20 |
| 5 | Registrar dos veces al mismo asistente en la sesión | **409** por `uq_registro_sesion_asis` |
| 6 | Registrar a un participante de Rutas de Paz | **Crear**, con `fk_programa_snapshot` **nulo** |
| 7 | Registrar a un estudiante sin programa activo | **422** con RN-07 |
| 8 | `GET /api/migracion/.../archivo` | **Tres columnas, sin encabezado, sin espacios**, ID como texto |
| 9 | `DELETE /api/registro_asistencia/{id}` | **405** con el motivo de RN-32 |
| 10 | `POST /api/acceso/solicitar-clave` con un identificador inexistente | **200 neutro**, sin revelar nada |
| 11 | `GET /api/clave_acceso` como rol `CONSULTA` | **403** |

> **La prueba 8 se compara carácter a carácter contra un archivo real** cargado a mano en el ASIS, en cuanto el profesor Hugo Nelson consiga un ejemplo. **Es el criterio de aceptación duro de todo el proyecto**, y sigue siendo la Fase 4 pendiente del plan de base de datos.

### 10.3 · Barrido de humo

Script que recorra los ~50 controladores con un token válido y reporte cualquier `500`. Es la prueba que la referencia llama *«barrido del front»*.

---

## 11 · Despliegue

Igual que la referencia: **AWS Lightsail**, servicio `systemd`, escuchando **solo en localhost** detrás de un proxy inverso.

| | ApiEvalFormativa | **ApiCatedras** |
|---|---|---|
| Servicio | `eval-api-usbmed` | **`catedras-api-usbmed`** |
| Puerto | 7035 | **7045** |
| Front | 7102 | **7112** *(propuesto)* |

**Los puertos 7035 y 7102 no se tocan**: la producción de EvalFormativa corre en paralelo y no debe verse afectada.

Variables de entorno en la unidad de `systemd`, **no en `appsettings.json`**:

```ini
Environment=ConnectionStrings__Postgres=...
Environment=ConnectionStrings__PostgresApp=...
Environment=Jwt__Key=...
Environment=Correo__Activo=true
Environment=Correo__Smtp__Usuario=...
```

> **Nota del profesor Carlos Castro (`1:49:13`):** los servidores de la unidad de tecnologías *«se caen mucho»*. El prototipo se muestra primero en su servidor propio; Piedad los sube *«cuando esté organizadito»*. El servicio de `systemd` debe llevar `Restart=always` y `RestartSec=5`.

---

## 12 · Riesgos

| # | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| 1 | **El informe del ASIS no se amplía** con nombre y correos | **Sin correo no hay clave: el camino B no funciona** | Es el riesgo 1 del proyecto. Plan B: el asistente digita su correo la primera vez y se verifica |
| 2 | El generador no sabe de `tstzrange`, `bigint` ni columnas generadas | Genera código que no compila o que falla al insertar | **Corregir el generador**, no el código emitido. §4 lista exactamente qué |
| 3 | El archivo plano sale con un carácter de más | El ASIS rechaza la carga entera | Prueba 8, automatizada |
| 4 | 164 registros en 60 segundos | Contención en el disparador de cupo | Ya hay índices; probar con carga sintética antes de la primera cátedra |
| 5 | El endpoint público enumera el maestro | Fuga de 14.808 documentos | §5.2 punto 5 + límite de tasa + rol mínimo |
| 6 | La API se conecta como `postgres` | Se pierde todo el diseño de permisos | §7.2 punto 7: dos cadenas, roles reales |
| 7 | Un correo no institucional dispara alarmas de seguridad | Bloqueo del envío | El asunto sigue **abierto** desde `55:32`. `I18` lo cuantifica |

---

## 13 · Lo que hay que decidir antes de la Fase 1

| # | Decisión | Por qué bloquea |
|---|---|---|
| 1 | **¿Se usa el generador o se escribe a mano?** | Cambia el orden de las fases. Recomendación: **generador**, corrigiéndolo primero con lo del §4 |
| 2 | **§3.1 del plan de BD: internos y externos** | Si se cierra en «solo con ID del ASIS», el camino B se simplifica y `es_externo` sobra |
| 3 | **Servidor SMTP** | Sin él, el camino B no se puede probar de punta a punta |
| 4 | Puertos 7045 y 7112 | Confirmar que están libres en el Lightsail |
| 5 | ¿Se incluye `Agente` y `Conocimiento`? | **Recomendación: no en la v1.** Dejar el hueco en `Program.cs` |
| 6 | ¿Front específico `FrontCatedrasUsbmed`? | Fuera del alcance de este plan, pero condiciona el CORS |

---

## 14 · Resumen en cinco líneas

1. **Se replica la arquitectura de `ApiEvalFormativaUsbmed`**: una clase por tabla, Dapper, JWT, snake_case, sin genéricos ni reflexión en runtime.
2. **37 tablas + 6 vistas** producen ~48 cuartetos con el contrato de once endpoints.
3. **Se añade lo que la referencia no tiene:** una capa de procesos de cuatro controladores para el flujo QR → clave → registro → migración, que llama a las rutinas de la base en vez de escribir `INSERT`.
4. **Seis problemas técnicos no se pueden copiar** y están resueltos en el §4: `tstzrange`, columnas generadas, `bigint`, claves compuestas, excepciones de disparador y el `DELETE` revocado.
5. **El criterio de aceptación** no es que compile: es que el archivo plano salga idéntico, carácter a carácter, al que hoy se carga a mano en el ASIS.

---

**La base de datos:** [`SOLUCION/`](SOLUCION/) · **El plan que la originó:** [`PLAN-BD-CATEDRAS-ABIERTAS.md`](PLAN-BD-CATEDRAS-ABIERTAS.md) · **La API de referencia:** `../proyectoEvalFormativa/ApiEvalFormativaUsbmed`
