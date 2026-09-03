# 3 · Transformación del MER al modelo relacional

Una fila por cada entidad y por cada relación del conceptual, con **la regla aplicada** y el resultado.

---

## Las seis reglas

| # | Regla | Cuándo se aplica |
|---|---|---|
| **T1** | Toda **entidad fuerte** → una tabla; su identificador → clave primaria | Siempre |
| **T2** | Relación **1:N** → la clave del lado «1» baja como clave foránea al lado «N» | Siempre |
| **T3** | Relación **N:M** → **tabla nueva** con las dos claves; los atributos del rombo entran en ella | Siempre |
| **T4** | Relación **1:1** → la clave baja al lado **obligatorio**; si los dos son opcionales, al que se consulta más | Siempre |
| **T5** | Entidad **débil** → tabla propia, con la clave de la fuerte dentro de su identificador | Siempre |
| **T6** | Atributo **multivaluado** → **tabla nueva** con la clave de la entidad y el valor | Siempre |

> **T3 es la que explica los números.** 33 entidades y 37 tablas: la diferencia son las **cuatro relaciones `N:M` con atributos** que no eran ya entidades — `vinculacion_asistente`, `programa_asistente`, `ponencia` y `rol_por_usuario`.

---

## 1 · Las entidades

| Entidad del MER | Regla | Tabla | Nota |
|---|---|---|---|
| `ASISTENTE` | T1 | `asistente` | Clave sustituta; `id_asis` queda como candidata única |
| `TIPO_DOCUMENTO` | T1 | `tipo_documento` | Clave natural |
| `DOCUMENTO_ASISTENTE` | **T6** | `documento_asistente` | Venía de un **multivaluado**, no de una entidad del dibujo inicial |
| `TIPO_VINCULACION` | T1 | `tipo_vinculacion` | |
| `CONSENTIMIENTO_DATOS` | T1 | `consentimiento_datos` | |
| `FACULTAD` | T1 | `facultad` | |
| `PROGRAMA_ACADEMICO` | T1 | `programa_academico` | **Clave natural**: viaja al ASIS |
| `PERIODO_ACADEMICO` | T1 | `periodo_academico` | |
| `TIPO_EVENTO` · `SEDE` · `MODALIDAD` · `DEPENDENCIA` | T1 | idem | Catálogos |
| `CATEDRA` | T1 | `catedra` | `nombre_asis` se resuelve como **columna generada** |
| `SESION` | **T5** | `sesion` | **Débil.** Identificador alterno `(fk_catedra, numero_reunion)` |
| `ENLACE_REGISTRO` | T1 | `enlace_registro` | |
| `CLAVE_ACCESO` | T1 | `clave_acceso` | |
| `REGISTRO_ASISTENCIA` | T1 + **T3** | `registro_asistencia` | Es a la vez entidad y el rombo `N:M` de R21 |
| `ENCUESTA` · `TIPO_PREGUNTA` · `PREGUNTA` · `OPCION_PREGUNTA` | T1 | idem | |
| `RESPUESTA_ENCUESTA` | T1 | `respuesta_encuesta` | |
| `RESPUESTA_ITEM` | **T5** | `respuesta_item` | **Débil** de `respuesta_encuesta` |
| Bloque F · las 6 | T1 | idem | |
| `USUARIO` · `ROL` · `PARAMETRO` · `BITACORA` | T1 | idem | |

**33 entidades → 33 tablas.**

---

## 2 · Las relaciones

### 2.1 · Las `1:N` — regla T2, **no** producen tabla

| Relación | Clave foránea creada | En la tabla |
|---|---|---|
| R01 `ASISTENTE — se identifica con — DOCUMENTO` | `fk_asistente` | `documento_asistente` |
| R02 `DOCUMENTO — es de clase — TIPO_DOCUMENTO` | `fk_tipo_documento` | `documento_asistente` |
| R04 `ASISTENTE — autoriza — CONSENTIMIENTO` | `fk_asistente` | `consentimiento_datos` |
| R06 `FACULTAD — agrupa — PROGRAMA` | `fk_facultad` | `programa_academico` |
| **R07** `FACULTAD — depende de — FACULTAD` | `fk_facultad_padre` | `facultad` — **recursiva** |
| R09 `PROGRAMA_ASISTENTE — corresponde a — PERIODO` | `fk_periodo` | `programa_asistente` |
| **R10** `CATEDRA — se dicta en — SESION` | `fk_catedra` | `sesion` — **identificadora** |
| R11 `CATEDRA — se clasifica como — TIPO_EVENTO` | `fk_tipo_evento` | `catedra` |
| R12 `DEPENDENCIA — organiza — CATEDRA` | `fk_dependencia` | `catedra` |
| **R13** `DEPENDENCIA — depende de — DEPENDENCIA` | `fk_dependencia_padre` | `dependencia` — **recursiva** |
| R14 `SEDE — aloja — SESION` | `fk_sede` | `sesion` |
| R15 `SESION — se dicta en modalidad — MODALIDAD` | `fk_modalidad` | `sesion` |
| R17 `SESION — ocurre en — PERIODO` | `fk_periodo` | `sesion` |
| R18 `SESION — se difunde mediante — ENLACE` | `fk_sesion` | `enlace_registro` |
| R19 `ASISTENTE — solicita — CLAVE` | `fk_asistente` | `clave_acceso` |
| R20 `ENLACE — ampara — CLAVE` | `fk_enlace` | `clave_acceso` |
| R23 `REGISTRO — conserva instantánea de — PROGRAMA` | `fk_programa_snapshot` | `registro_asistencia` |
| R24 `ENCUESTA — se compone de — PREGUNTA` | `fk_encuesta` | `pregunta` |
| R25 `PREGUNTA — se responde según — TIPO_PREGUNTA` | `fk_tipo_pregunta` | `pregunta` |
| R26 `PREGUNTA — ofrece — OPCION` | `fk_pregunta` | `opcion_pregunta` |
| R27 `SESION — se evalúa con — ENCUESTA` | `fk_encuesta` | `sesion` |
| **R29** `RESP_ENCUESTA — detalla — RESP_ITEM` | `fk_respuesta` | `respuesta_item` — **identificadora** |
| R30 `LOTE_CARGA — rechaza — NOVEDAD` | `fk_lote_carga` | `novedad_carga` |
| R31 `ALIAS — resuelve a — PROGRAMA` | `fk_programa` | `alias_programa` |
| R32 `SESION — se migra en — LOTE_MIGRACION` | `fk_sesion` | `lote_migracion` |
| R34 `LOTE_MIGRACION — termina en — ESTADO` | `fk_estado_proceso` | `lote_migracion` |

### 2.2 · Las `1:1` — regla T4

| Relación | Dónde baja la clave | Por qué |
|---|---|---|
| R05 `ASISTENTE — opera como — USUARIO` | `usuario.fk_asistente` | El lado **obligatorio** es el usuario: todo usuario es una persona, no al revés |
| R22 `CLAVE — habilita — REGISTRO` | `registro_asistencia.fk_clave` | Igual: todo registro nace de una clave |
| R28 `REGISTRO — es evaluado en — RESP_ENCUESTA` | `respuesta_encuesta.fk_registro` + `UNIQUE` | Responder es voluntario; el obligatorio es el otro lado |

> **En los tres casos la `UNIQUE` es lo que convierte una `1:N` en `1:1`.** Sin ella, el modelo permitiría dos usuarios para la misma persona.

### 2.3 · Las `N:M` — regla T3, **estas sí producen tabla**

| Relación | Tabla nueva | Clave primaria | Atributos del rombo |
|---|---|---|---|
| R03 `ASISTENTE — se vincula como — TIPO_VINCULACION` | `vinculacion_asistente` | **(asistente, tipo, `fecha_ini`)** | `fecha_fin` |
| R08 `ASISTENTE — cursa — PROGRAMA` | `programa_asistente` | (asistente, programa, periodo) | `estado` |
| R16 `ASISTENTE — expone en — SESION` | `ponencia` | (sesion, asistente, rol) | — |
| R21 `ASISTENTE — se registra en — SESION` | **`registro_asistencia`** | `id_registro` sustituta | instante, 2 instantáneas, origen, IP |
| R33 `LOTE_MIGRACION — migra — REGISTRO` | `detalle_migracion` | `id_detalle` sustituta | lo enviado, resultado |
| R35 `USUARIO — desempeña — ROL` | `rol_por_usuario` | **(usuario, rol, `fecha_ini`)** | `fecha_fin` |

**Seis `N:M`. Dos ya eran entidades** (`registro_asistencia` y `detalle_migracion`), así que solo **cuatro** suman tabla nueva.

> ### Las dos `N:M` con `fecha_ini` en la clave
>
> R03 y R35. La clave «natural» sería el par. **Y con el par, nadie puede recuperar algo que ya tuvo.**
>
> Es el caso que el profesor Carlos Castro describió sin nombrarlo, en `8:37`, hablando de la biblioteca: *«vos y yo no podemos sacar en el mismo momento el mismo ejemplar, pero sí lo podemos sacar en fechas diferentes. **Esos son asuntos históricos**»*.

---

## 3 · Los atributos que cambiaron de forma

| Atributo del MER | Tipo | Cómo quedó |
|---|---|---|
| `nombre` de la persona | Compuesto | **Tres columnas**: `nombres`, `apellidos` y `nombre_completo_asis` con el original intacto |
| `numero` de documento | **Multivaluado** | **Tabla `documento_asistente`** (T6) |
| `nombre_asis` | Derivado | **Columna generada** `STORED`: `left(nombre, 30)` |
| `numero_reunion` | Derivado | Columna normal, **poblada por disparador** — no puede ser generada porque depende de otras filas |
| `es_correo_institucional` | Derivado | Columna normal, **poblada por disparador** — depende de un parámetro configurable |
| `ventana` | Simple | `tstzrange` — un solo atributo, no dos columnas |
| `es_interno`, `exige_programa` | Simples del catálogo | Columnas booleanas que **convierten reglas en datos** |

> **Por qué `numero_reunion` no es columna generada.** PostgreSQL exige que una columna generada dependa **solo de la misma fila**. El consecutivo depende del máximo de las demás filas de la cátedra: es un derivado *entre filas*, y eso obliga a disparador.

---

## 4 · Lo que se perdió y hubo que recuperar

Toda transformación pierde algo. Lo honesto es decir **qué**, y **cómo se recupera**.

| Se pierde al transformar | Cómo se recupera |
|---|---|
| La **participación mínima** `(1,N)` de R29 | No hay mecanismo declarativo. **Procedimiento** `sp_responder_encuesta` |
| El **min-max** en general | Los `(1,1)` se recuperan con `NOT NULL`; los `(0,1)` con `UNIQUE` sobre columna nullable; los `(1,N)`, no |
| La **regla condicional** de RN-07 | `CHECK` no puede consultar otra tabla → **disparador** |
| Que el **verbo** de la relación se lea | Se conserva en el **nombre de la clave foránea** y en el comentario `COMMENT ON` de cada tabla |
| La **notación de Chen** | Los `.mmd` del MER se mantienen como fuente viva |

> **Los `COMMENT ON` no son decoración.** Son el único sitio del modelo físico donde sobrevive el *porqué*. En este proyecto llevan la cita de la reunión que originó cada decisión, y se consultan con `\d+ tabla` en psql.

---

**Anterior:** [02 · Normalización](02-Dependencias-y-Normalizacion.md) · **Siguiente:** [04 · Estructuras de acceso](04-Estructuras-de-Acceso.md)
