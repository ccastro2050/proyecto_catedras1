# Contratos — Versión 1: endpoints y pantallas

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

## PARTE A — La API: `http://localhost:8037`

### A.0 Convenciones

**Sobre de lectura:**

```json
{ "tabla": "sede", "limite": 1000, "total": 3, "datos": [ … ] }
```

**Sobres de error** — hay **dos**, y la diferencia importa:

```json
{ "estado": 422, "mensaje": "Datos inválidos.",
  "errores": ["El campo nombre es obligatorio."] }

{ "estado": 404, "mensaje": "Sede no encontrada.",
  "detalle": "No existe una sede con el código X." }
```

El 422 trae **`errores[]`** porque puede fallar más de un campo a la vez; los
demás traen **`detalle`**, que es uno.

**Los nombres JSON van en camelCase** (`idSede`, `esVirtual`): es el
comportamiento por defecto de ASP.NET, así que no hay nada que configurar ni
nada que se pueda configurar mal.

> La ruta es `/api/sede` —nombra la tabla— y el cuerpo usa `idSede`, no
> `id_sede`. **El JSON no es una ventana a la tabla.**

**Catálogo de códigos:**

| Situación | Código |
|---|---|
| Lectura o escritura correcta | **200** |
| Lectura sin filas activas | **204** (sin cuerpo) |
| Regla de negocio rota (`limite` ≤ 0, `PATCH` sin campos) | **400** |
| Cuerpo inválido: falta un campo o el tipo no corresponde | **422** |
| El código no existe, o está inactivo | **404** |
| La base rechaza (llave o nombre duplicados) | **500** |

### A.1 `GET /` — Diagnóstico

```
GET /
→ 200 { "mensaje": "API Cátedras Abiertas — módulo de sedes",
        "version": "v1", "contratos": "/swagger" }
```

Sin desenlaces de error: no recibe parámetros ni consulta la base.

### A.2 `GET /api/sede[?limite=N]` — Listar

```
GET /api/sede
→ 200 { "tabla":"sede", "limite":1000, "total":3, "datos":[
          {"idSede":"BELLO","nombre":"Campus Bello",
           "direccion":"Calle 45 61-40, Bello","esVirtual":false},
          {"idSede":"SAN_BENITO", …},
          {"idSede":"VIRTUAL","nombre":"Virtual",
           "direccion":null,"esVirtual":true} ] }

→ 204 si no hay sedes activas
→ 400 si limite <= 0
```

Devuelve **solo** las filas con `activo = TRUE`. El campo `activo` **no viaja
en la respuesta**. Y fíjese en la tercera: `direccion` vuelve como `null`, no
como cadena vacía.

### A.3 `GET /api/sede/{idSede}` — Obtener una

```
GET /api/sede/VIRTUAL
→ 200 {"idSede":"VIRTUAL","nombre":"Virtual","direccion":null,"esVirtual":true}

GET /api/sede/NADA
→ 404 {"estado":404,"mensaje":"Sede no encontrada.",
       "detalle":"No existe una sede con el código NADA."}
```

### A.4 `POST /api/sede` — Crear

```
POST /api/sede
body {"idSede":"ITAGUI","nombre":"Campus Itagui",
       "direccion":"Calle 50 51-20","esVirtual":false}
→ 200 {"estado":200,"mensaje":"Sede creada exitosamente."}

body sin "nombre"
→ 422 {"estado":422,"mensaje":"Datos inválidos.",
       "errores":["El campo nombre es obligatorio."]}

body {"esVirtual":"quizas", …}          ← el tipo también es regla
→ 422

body con un idSede que ya existe        ← pk_sede
→ 500

body con un nombre que ya existe        ← uq_sede_nombre
→ 500 {"estado":500,"mensaje":"No se pudo crear la sede.",
       "detalle":"23505: duplicate key value violates unique constraint
                  \"uq_sede_nombre\" …"}
```

**Los dos 500 son la lección de este endpoint.** Vienen del mismo `catch`, pero
por restricciones distintas: uno por el código, otro por el nombre. Y los dos
los defiende **la base**, no la API — ver [D6](4_research.md).

### A.5 `PUT /api/sede/{idSede}` — Reemplazo COMPLETO

```
PUT /api/sede/ITAGUI
body {"nombre":"Campus Itagui - sur","direccion":"Calle 50 51-20","esVirtual":false}
→ 200 {"estado":200,"mensaje":"Sede reemplazada.","filasAfectadas":1}

body sin "nombre"
→ 422

PUT /api/sede/NADA
→ 404
```

**Los obligatorios lo siguen siendo**: reemplazar es poner todo de nuevo. El
`idSede` no va en el cuerpo.

### A.6 `PATCH /api/sede/{idSede}` — Actualización PARCIAL

```
PATCH /api/sede/ITAGUI
body {"nombre":"Campus Itagui"}         ← solo lo que cambia
→ 200 {"estado":200,"mensaje":"Sede actualizada.","filasAfectadas":1}

body sin "nombre" (el MISMO que el PUT rechazó)
→ 200                                    ← aquí es válido

body {}
→ 400 {"estado":400,"mensaje":"Parámetros inválidos.",
       "detalle":"No se envió ningún campo para actualizar."}
```

**Esta pareja es la lección del contrato:** el mismo cuerpo da 422 en `PUT` y
200 en `PATCH`, y no lo decide un `if` — lo decide el tipo de la clase de
petición.

### A.7 `DELETE /api/sede/{idSede}` — Eliminar (LÓGICO)

```
DELETE /api/sede/ITAGUI
→ 200 {"estado":200,"mensaje":"Sede eliminada.","filasAfectadas":1}

DELETE /api/sede/ITAGUI                 ← segunda vez: ya está inactiva
→ 404
```

**La fila no se borra:** queda con `activo = FALSE`, sale del listado y la
base la conserva — es el criterio 7.

## PARTE B — El front: `http://localhost:8038`

> En la API el contrato son los endpoints. **En el front son las pantallas.**

| Ruta | Método | Qué hace | A qué llama |
|---|---|---|---|
| `/` | GET | Redirige (302) a `/sedes` | — |
| `/sedes` | GET | La tabla | `GET /api/sede` |
| `/sedes/nueva` | GET · POST | Formulario · crear | `POST /api/sede` |
| `/sedes/<cod>/editar` | GET · POST | Formulario · reemplazar **o** actualizar | `PUT` **o** `PATCH` |
| `/sedes/<cod>/eliminar` | POST | Elimina | `DELETE` |

### B.0 Lo que TODA pantalla cumple

Antes de cada pantalla, lo que vale para todas:

| Qué | Valor | De dónde sale |
|---|---|---|
| Naranja | `#EF7D00` | [Artículo 9.1](../../1_constitution.md) · manual p. 5 |
| Negro | `#1D1D1B` | Artículo 9.1 · manual p. 5 |
| Fuentes | **Montserrat** (títulos) y **Raleway** (texto) | Artículo 9.1 · manual p. 6 |
| El sitio del logo | Mínimo 93,2 × 28,3 px, con su área de reserva | Artículo 9.1 · manual p. 7 |
| Los avisos | Rojo para error, verde para éxito — **no son colores de marca**: son señales, y el manual no legisla sobre ellas | — |

Están en [`front_flask/static/marca.css`](../../../../front_flask/static/marca.css),
**aparte** de `estilos.css`: ahí van los valores que fija el manual, y allá
cómo se usan.

**Comprobable:** `curl http://localhost:8038/static/marca.css` los muestra.

### B.1 `/sedes` — el listado

| La API responde | La pantalla muestra |
|---|---|
| **200** | La tabla, con una **raya (—)** donde la dirección es nula, y una etiqueta *virtual* o *presencial* |
| **204** | *"No hay sedes activas"*, en gris — **no es un error** |
| No responde | La página **carga igual**, con el aviso rojo *"El servicio no está disponible"* |

### B.2 `/sedes/nueva` — crear

- La **dirección en blanco se envía como nulo**, no como cadena vacía (C10).
- La casilla *es virtual* llega como `on` si está marcada, y no llega si no.
- Un 422 devuelve el formulario **con lo digitado**.

### B.3 `/sedes/<codigo>/editar` — LA PANTALLA DE LA VERSIÓN

Un formulario, **dos botones**:

```html
<button type="submit" name="verbo" value="put">Reemplazar (PUT)</button>
<button type="submit" name="verbo" value="patch">Actualizar lo diligenciado (PATCH)</button>
```

Con **el mismo formulario**, el nombre borrado:

| Botón | Qué viaja | La API responde | La pantalla |
|---|---|---|---|
| **Reemplazar (PUT)** | nombre, dirección y la casilla — el nombre vacío incluido | **422** `El campo nombre es obligatorio.` | vuelve al formulario con el aviso |
| **Actualizar (PATCH)** | solo lo que tiene contenido | **200** | **302** al listado, guardado |

### B.4 `/sedes/<codigo>/eliminar` — POST, nunca GET

Es un formulario con `confirm()`. **Un GET que borra lo puede disparar el
navegador solo** al precargar la página.
