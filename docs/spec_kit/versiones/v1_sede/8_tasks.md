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

---

> Cada fase termina en algo **que se puede comprobar**. No se pasa a la
> siguiente sin verificar la anterior.

## Fase 1 — La base de datos

- [ ] Derivar `db/init.sql` del script dado, con **los tres cambios**
      declarados en su cabecera: sin la carga real (C1), con datos hipotéticos
      (C2), y sin crear la base (C3).
- [ ] Montarlo en `/docker-entrypoint-initdb.d/`.

**Verificación:**

```powershell
docker compose up -d postgres
docker compose exec postgres psql -U catedras -d catedras `
  -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'"
#  → 37 tablas (más las vistas)
docker compose exec postgres psql -U catedras -d catedras -c "SELECT * FROM sede"
#  → 3 filas, la Virtual con direccion nula
```

> **Y una verificación que no es de conteo:** buscar en el repositorio que
> **no quede ningún dato de persona real**. Es el Artículo 8, y no se
> comprueba con un `COUNT`.

## Fase 2 — El esqueleto de la API

- [ ] `ApiCatedras.csproj` con **Npgsql**, Dapper y Swashbuckle, y con
      `pruebas/` excluido de la compilación.
- [ ] `Dockerfile` con la imagen del **SDK** (para `dotnet watch`) y
      `DOTNET_USE_POLLING_FILE_WATCHER=1`.
- [ ] `Program.cs` con **solo** el diagnóstico `GET /`.

**Verificación:** `GET http://localhost:8037/` responde `"version": "v1"`.
*Todavía no habla con la base.*

## Fase 3 — La entidad y las peticiones

- [ ] `Modelos/Sede.cs` — **sin** la propiedad `Activo`.
- [ ] Las **tres** clases de `Peticiones/`, una por verbo.
- [ ] `Excepciones/NoEncontradoExcepcion.cs`.

**Verificación:** `python -m compileall`… no: `dotnet build` compila. Y
`/swagger` ya muestra los esquemas de las tres peticiones.

## Fase 4 — Las interfaces y el servicio

- [ ] `IRepositorioSede` y el record `SedeCampos` con su `HayAlguno`.
- [ ] `IServicioSede`.
- [ ] `ServicioSede`, que lanza `ArgumentException` y `NoEncontradoExcepcion`
      — **nunca códigos HTTP**.

**Verificación:** el servicio no tiene ningún `using` de ASP.NET ni de Npgsql.

## Fase 5 — El repositorio

- [ ] `RepositorioSedePostgreSql` con Dapper y `@parametro`.
- [ ] **Todas** las consultas filtran por `activo = TRUE`.
- [ ] `LIMIT @Limite` **al final** — no `TOP`, que es de otro dialecto.
- [ ] El borrado lógico, en **una sola** consulta.
- [ ] El ensamblador, en `Program.cs`.

**Verificación:** `GET /api/sede` devuelve las 3 sedes del script.

## Fase 6 — El controlador y el 422

- [ ] Los 6 endpoints de `sede`.
- [ ] El listado vacío responde **204**, no 200 con lista vacía.
- [ ] **Reemplazar `InvalidModelStateResponseFactory`** para que el 422 tenga
      el sobre del contrato. **Sin esto sale un 400 con ProblemDetails.**
- [ ] `NpgsqlException` → 500.

**Verificación:** los criterios 1 a 3, y **los dos 500** del criterio 6.

## Fase 7 — El front

- [ ] `cliente_api.py`, el único que habla HTTP, con el sobre **plano** de
      esta API.
- [ ] `base.html`, `estilos.css`, y las dos plantillas de `sede`.
- [ ] El **opcional en blanco se envía nulo**, no vacío.
- [ ] Los **dos botones** con `name="verbo"`.
- [ ] Eliminar por **POST** con confirmación.

**Verificación:** los criterios 3, 4, 5 y 7 — **desde el navegador**.

## Fase 8 — La prueba de capas

- [ ] `pruebas/PruebaCapas.csproj` que compila **solo** el servicio, la
      entidad, las interfaces y la excepción — **sin referenciar Npgsql ni
      Dapper**.
- [ ] `pruebas/Programa.cs` con el repositorio de mentiras.

**Verificación, y es la que importa:** el criterio 9, con la base apagada.

## Fase 9 — La prueba del proyecto

- [ ] Comprobar que `front_flask/` **no menciona** PostgreSQL, ni una cadena
      de conexión, ni el lenguaje de la API.

**Verificación:** el criterio 8 — apagar la API y ver la pantalla sin datos.

## Fase 10 — Cierre

- [ ] Los 9 criterios corridos **por una persona**.
- [ ] [9_checklist.md](9_checklist.md) firmada.
- [ ] La colección de Postman y el README.
- [ ] Commit y **tag `v1`**.
