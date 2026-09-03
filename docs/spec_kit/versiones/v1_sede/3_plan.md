# Plan — Versión 1: cómo se arma el sistema

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

## 1. El stack, y por qué

| Pieza | Qué se usa | Por qué |
|---|---|---|
| API | **C# / ASP.NET Core .NET 10** | El del curso |
| Acceso a datos | **Dapper** + **Npgsql** | Un ejecutor, no un ORM: el SQL se ve |
| Motor | **PostgreSQL 16** | El del modelo entregado |
| **Front** | **Python / Flask + Jinja2** | Ver [D1](4_research.md): la mezcla es la lección |
| Documentación | **`/swagger`** | Swashbuckle |
| Todo junto | **`docker compose`** | Un solo comando (Artículo 4) |

## 2. La estructura

```
proyecto_catedras1/
├── db/init.sql                  la base COMPLETA (37 tablas, artefacto DADO)
├── api_catedras/                LA API — C#
│   ├── Program.cs               el ensamblador y la fábrica del 422
│   ├── Controllers/             CAPA 1: HTTP — códigos de estado y JSON
│   ├── Peticiones/              la frontera de entrada: valida el cuerpo → 422
│   ├── Modelos/                 la entidad, lo que viaja entre capas
│   ├── Servicios/               CAPA 2: negocio — no conoce HTTP ni el motor
│   ├── Repositorios/            CAPA 3: datos — el SQL con Dapper
│   ├── Excepciones/             cómo el negocio avisa un 404 sin hablar de HTTP
│   └── pruebas/                 el servicio con un repositorio de mentiras
├── front_flask/                 EL FRONT — Python
│   ├── app.py                   las vistas
│   ├── cliente_api.py           el ÚNICO que habla HTTP
│   └── templates/ static/
├── docs/spec_kit/               LA FUENTE DE VERDAD
├── material_dado/               el modelo, los diagramas y el script original
└── docker-compose.yml           TODO el sistema en un archivo
```

## 3. Las decisiones de diseño de la API

### 3.1 Una clase de petición por verbo

`SedeCrear` (POST), `SedeReemplazo` (PUT) y `SedeActualizar` (PATCH) son **tres
clases**, no una con banderas.

La diferencia entre PUT y PATCH **no la decide un `if` en el servicio: la
decide el tipo**. En `Reemplazo` los campos son `[Required]`; en `Actualizar`
son anulables. El mismo cuerpo responde 422 en uno y 200 en el otro, y no hay
una línea de código que los compare.

### 3.2 El 422 NO sale solo: hay que pedirlo

Con `[ApiController]`, un cuerpo inválido corta la petición y responde **400
con ProblemDetails**. El contrato exige **422** con `{estado, mensaje,
errores[]}`, así que en `Program.cs` se reemplaza la fábrica de respuestas:

```csharp
opciones.InvalidModelStateResponseFactory = contexto => { … StatusCode = 422 };
```

Es la pieza que más sorprende de la versión: **el código correcto no es el que
sale por defecto.**

### 3.3 El servicio no sabe qué es un 404

| El servicio lanza | El controlador responde |
|---|---|
| `ArgumentException` | **400** — la forma es válida, la regla no se cumple |
| `NoEncontradoExcepcion` | **404** |
| `NpgsqlException` | **500** — aquí caen las dos defensas de la base |

Si el servicio devolviera códigos HTTP, quedaría atado a la web — y no se
podría probar sin un servidor.

### 3.4 El repositorio es la ÚNICA clase que sabe cuál es el motor

`RepositorioSedePostgreSql` es la única pieza con Npgsql adentro. Comparada con
su gemela contra SQL Server de los otros ejemplos del curso, las diferencias
son **tres**:

| | SQL Server | PostgreSQL |
|---|---|---|
| La conexión | `SqlConnection` | `NpgsqlConnection` |
| El límite | `TOP (@Limite)`, al principio | `LIMIT @Limite`, al final |
| El booleano | `activo = 1` | **`activo = TRUE`** |

**Que la lista quepa en una tabla de tres filas es el resultado de haber puesto
las interfaces.** Si el servicio conociera esta clase, cambiar de motor tocaría
medio proyecto.

### 3.5 El PATCH compone la consulta, y por qué eso NO es inyección

Lo que se compone son **nombres de columna** de una lista cerrada escrita en el
repositorio. Los **valores** siempre viajan como `@parametro`. Si los nombres
vinieran de lo que alguien mandó, esto sí sería una puerta abierta.

### 3.6 El borrado lógico, en una sola consulta

```sql
UPDATE sede SET activo = FALSE
WHERE id_sede = @IdSede AND activo = TRUE
```

Cero filas afectadas significa **"no existe o ya estaba inactiva"**, que es
exactamente el 404 del contrato.

## 4. Las decisiones de diseño del front

### 4.1 `cliente_api` conoce el sobre de SU API, y nada más

El sobre de esta API es **plano**: `{estado, mensaje, errores[]}`. Un front que
hablara con FastAPI recibiría todo anidado bajo `detail`. **Ese conocimiento
está en un solo archivo**: si el sobre cambia, se cambia ahí.

### 4.2 El front no sabe que la API es de C#

En ninguna línea de `front_flask/` aparece. No lo sabe y no le hace falta: si
esa API se reescribiera en Go, el front no cambiaría —mientras el contrato se
respete—. **Eso es lo que significa "separación a nivel de sistema"**, y aquí
se puede comprobar apagando la API (criterio 8).

### 4.3 El opcional en blanco se envía nulo, no vacío

```python
"direccion": request.form.get("direccion", "").strip() or None,
```

Enviar `""` es decir "ponlo en cadena vacía"; enviar `null` es decir "no lo
tiene". La base los guarda distinto, y es comprobable (criterio 4).

### 4.4 El verbo lo decide el botón

Dos `submit` con el mismo `name="verbo"` y distinto `value`. Lo que cambia no
es una regla: **es qué se envía**.

## 5. Chequeo de constitución

> **La compuerta 2**: antes de programar, cada artículo se revisa contra este
> plan.

| Artículo | ¿Se respeta? | Cómo |
|---|---|---|
| 1 — Por versiones, la spec manda | ✅ | Solo `sede`; las otras 36 tablas no se nombran en el código |
| **1.1 — Una versión incluye su front** | ✅ | La v1 trae la API de `sede` **y sus cuatro pantallas**. Los criterios 3, 4, 5 y 7 se verifican desde el navegador |
| 2 — C#, PostgreSQL y el SQL a la vista | ✅ | Dapper con `@parametro`, sin ORM |
| 3 — Tres capas con interfaces | ✅ | **Y se comprueba**: `pruebas/` no referencia Npgsql |
| 4 — Un solo comando, tres procesos | ✅ | Y el front es de otro lenguaje, a propósito |
| 5 — La base viene dada | ✅ | Las 37 tablas tal cual; los tres cambios van declarados en la cabecera |
| 6 — Borrado lógico | ✅ | `activo = FALSE`, y los listados filtran |
| 7 — Secretos | ⚠️ **Con la excepción declarada** | A la vista en el compose, y dicho en el artículo |
| 8 — Sin datos personales | ✅ | El bloque de la carga real se quitó (C1) |
| 9 — Todo en español | ✅ | Incluidos los comentarios, que explican **por qué** |
| 10 — Contratos exactos | ✅ | [6_contracts](6_contracts.md) escrito contra lo que responde |
| 11 — Convenciones fijas | ✅ | camelCase, `/api/sede`, prefijo `catedras-` |

**Ningún artículo obliga a cambiar el plan.** La compuerta pasa.
