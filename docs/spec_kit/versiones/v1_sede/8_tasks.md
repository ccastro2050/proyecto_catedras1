# Tareas — Versión 1: el orden de construcción

> **Versión 1** ([mapa](../0_mapa_versiones.md)) · Rige la
> [constitución](../../1_constitution.md).
>
> | Documento | Contenido |
> |---|---|
> | [2_spec.md](2_spec.md) | QUÉ construir y los criterios de aceptación |
> | [3_plan.md](3_plan.md) | CÓMO: el stack, las capas y sus decisiones |
> | [4_research.md](4_research.md) | Las decisiones, con lo que se descartó |
> | [5_data_model.md](5_data_model.md) | La tabla, sus datos y quién escribe qué |
> | [6_contracts.md](6_contracts.md) | Los endpoints y las pantallas |
> | [7_quickstart.md](7_quickstart.md) | Arranque y smoke test |
> | [8_tasks.md](8_tasks.md) | El orden de construcción por fases |
> | [9_checklist.md](9_checklist.md) | La compuerta 3: se firma ANTES de programar |
> | [GUIA_IA1.md](GUIA_IA1.md) | Construirla con ayuda de una IA |
>
> Las **historias de usuario** que originan estos requisitos están en
> [`0_historias_de_usuario.md`](../../0_historias_de_usuario.md).

---

## Cómo están organizadas estas fases, y por qué

**Cada fase de la 2 a la 6 entrega UNA capacidad completa: su endpoint y su
pantalla.** No hay «las fases del back» y después «la fase del front».

Es el [Artículo 1.1](../../1_constitution.md) aplicado al orden del trabajo, y
la diferencia es concreta:

| Si las fases fueran secuenciales | Como están aquí |
|---|---|
| Fases 1-6: la API completa. Fase 7: el front | Fase 2: consultar (endpoint **y** pantalla). Fase 3: registrar (endpoint **y** pantalla)… |
| Al terminar la fase 5 hay **medio sistema** y nada que mostrar | Al terminar **cualquier** fase hay algo que se puede abrir en el navegador |
| El contrato se descubre incómodo en la fase 7, con seis endpoints ya escritos | El contrato se ejercita **en la misma fase** en que se escribe |
| Si se acaba el tiempo, queda una API sin usar | Si se acaba el tiempo, quedan **menos capacidades, pero completas** |

> **La regla de verificación:** una fase con pantalla **se verifica en el
> navegador**. Que el endpoint responda en `curl` no cierra la fase.

---

## Fase 0 — La base de datos

*No entrega capacidad: prepara el terreno. Es la única fase sin pantalla.*

- [ ] Derivar `db/init.sql` del script dado, con **los tres cambios**
      declarados en su cabecera: sin la carga real (C1), con datos hipotéticos
      (C2), y sin crear la base (C3).
- [ ] Montarlo en `/docker-entrypoint-initdb.d/`.

**Verificación:**

```powershell
docker compose up -d postgres
docker compose exec postgres psql -U catedras -d catedras `
  -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'"
#  → 37 tablas
docker compose exec postgres psql -U catedras -d catedras -c "SELECT * FROM sede"
#  → 3 filas, la Virtual con direccion nula
```

> **Y una verificación que no es de conteo:** buscar en el repositorio que
> **no quede ningún dato de persona real**. Es el Artículo 8, y no se
> comprueba con un `COUNT`.

---

## Fase 1 — Los cimientos de los DOS procesos

*Tampoco entrega capacidad, pero deja **los dos** en pie. A propósito: si el
front nace en la fase 6, para entonces ya nadie lo va a nacer.*

**En la API**
- [ ] `ApiCatedras.csproj` con **Npgsql**, Dapper y Swashbuckle, y con
      `pruebas/` excluido de la compilación.
- [ ] `Dockerfile` con la imagen del **SDK** (para `dotnet watch`) y
      `DOTNET_USE_POLLING_FILE_WATCHER=1`.
- [ ] `Program.cs` con **solo** el diagnóstico `GET /` (RF7).

**En el front**
- [ ] `requirements.txt`, `Dockerfile`, y `app.py` con una sola ruta que
      responda.
- [ ] `cliente_api.py` con `_llamar`, `_cuerpo` y `_mensajes` — que ya conoce
      **el sobre plano de esta API**, distinto del de otros frameworks.
- [ ] `base.html`, `marca.css` y `estilos.css`.

**En el compose**
- [ ] Los **tres** servicios, con `depends_on` y el healthcheck de la base.

**Verificación:** `GET http://localhost:8037/` responde `"version":"v1"` **y**
`http://localhost:8038/` responde. *Todavía no hay datos en ninguno.*

---

## Fase 2 — Consultar el catálogo · **RF1 y RF2**

**En la API**
- [ ] `Modelos/Sede.cs` — **sin** la propiedad `Activo`.
- [ ] `IRepositorioSede` e `IServicioSede`.
- [ ] `ServicioSede` con `ObtenerTodos` y `ObtenerPorId`, que lanza
      `ArgumentException` y `NoEncontradoExcepcion` — **nunca códigos HTTP**.
- [ ] `RepositorioSedePostgreSql` con Dapper y `@parametro`, filtrando por
      `activo = TRUE` y con `LIMIT @Limite` **al final** (no `TOP`).
- [ ] El ensamblador en `Program.cs`.
- [ ] Los dos `GET` del controlador. El listado vacío responde **204**.

**En el front**
- [ ] `listar_sedes()` y `obtener_sede()` en `cliente_api`.
- [ ] La pantalla `/sedes` con la tabla, la **raya** en la dirección nula y las
      etiquetas *virtual*/*presencial*.
- [ ] El mensaje neutro cuando la API responde 204.

**Verificación: criterio 2, en el navegador.** Las tres sedes del script se
ven, y la Virtual sin dirección.

---

## Fase 3 — Registrar una sede · **RF3**

**En la API**
- [ ] `Peticiones/SedeCrear.cs` con sus `[Required]` y sus `[MaxLength]`.
- [ ] **Reemplazar `InvalidModelStateResponseFactory`** para que el 422 tenga
      el sobre del contrato. **Sin esto sale un 400 con ProblemDetails.**
- [ ] `Crear` en el servicio y el repositorio.
- [ ] El `POST` del controlador, con `NpgsqlException` → 500.

**En el front**
- [ ] `crear_sede()` en `cliente_api`.
- [ ] `formulario.html` (servirá también para editar).
- [ ] La ruta `/sedes/nueva`, que **conserva lo digitado** ante un 422.
- [ ] La dirección en blanco **se envía nula**, no como cadena vacía.

**Verificación: criterios 3 y 4.** El primero desde el formulario; el segundo
**mirando la base**, porque el efecto que se comprueba está ahí.

---

## Fase 4 — Corregir una sede · **RF4 y RF5** · *la fase de la lección*

**En la API**
- [ ] `SedeReemplazo` (campos `[Required]`) y `SedeActualizar` (anulables):
      **dos clases**, no una con banderas.
- [ ] El record `SedeCampos` con su `HayAlguno`.
- [ ] `Reemplazar` y `ActualizarParcial` en el servicio y el repositorio.
- [ ] El `PUT` y el `PATCH` del controlador. Cuerpo vacío → **400**.

**En el front**
- [ ] `reemplazar_sede()` y `actualizar_sede()`.
- [ ] **Los dos botones** con `name="verbo"` en el mismo formulario.
- [ ] El botón PUT envía todo; el PATCH filtra lo vacío.

**Verificación: criterio 5, con los dos botones en el navegador.** Con el
nombre borrado, uno deja el 422 en pantalla y el otro guarda. *Es la fase que
da sentido a la versión: si esto no se ve en la pantalla, no está hecho.*

---

## Fase 5 — Retirar una sede · **RF6**

**En la API**
- [ ] `EliminarLogico` en el repositorio: **una sola consulta**, con
      `activo = FALSE ... AND activo = TRUE`.
- [ ] `Eliminar` en el servicio y el `DELETE` del controlador.

**En el front**
- [ ] `eliminar_sede()` en `cliente_api`.
- [ ] El botón por **POST** con `confirm()`, nunca un enlace.

**Verificación: criterio 7.** El botón, después `curl` para el segundo
`DELETE`, y **la base** para ver que la fila sigue ahí.

---

## Fase 6 — Las dos pruebas que sostienen la arquitectura

**La prueba de capas**
- [ ] `pruebas/PruebaCapas.csproj` que compila **solo** el servicio, la
      entidad, las interfaces y la excepción — **sin referenciar Npgsql ni
      Dapper**.
- [ ] `pruebas/Programa.cs` con el repositorio de mentiras.

**La prueba del proyecto**
- [ ] Comprobar que `front_flask/` **no menciona** PostgreSQL, ni una cadena
      de conexión, ni el lenguaje de la API.

**Verificación: criterios 8 y 9.** El 9 con la base apagada; el 8 apagando la
API y viendo la pantalla **cargar sin datos**.

---

## Fase 7 — Los desenlaces que el formulario no deja construir

- [ ] `?limite=0` → **400**.
- [ ] `PATCH {}` → **400** (no 404).
- [ ] Un código repetido → **500** (`pk_sede`).
- [ ] Un **nombre** repetido → **500** (`uq_sede_nombre`).
- [ ] `esVirtual` no booleano → **422**.

**Verificación: criterio 6, con `curl`.** Y esta fase **sí es solo de API**,
con razón: son casos que la pantalla no permite armar —no hay forma de
escribir un `limite` negativo en un formulario que no tiene ese campo—. Lo que
la pantalla sí debe hacer es **mostrarlos si ocurren**, y eso ya quedó
verificado en las fases 3 y 4.

---

## Fase 8 — Cierre

- [ ] Los 9 criterios corridos **por una persona**, cada uno por la vía que
      dice [2_spec §5](2_spec.md).
- [ ] [9_checklist.md](9_checklist.md) firmada.
- [ ] La colección de Postman, el README y el `PLAN_V1.md`.
- [ ] Commit y **tag `v1`**.

> **Y una regla que se aprendió cerrando esta versión:** una vez que hay tag,
> **lo que llega después es de la versión siguiente**. Agregarle un criterio a
> una versión etiquetada deja el documento prometiendo lo que el tag no
> contiene — ver la nota de [2_spec §6.1](2_spec.md).
