# El modelo en una página

**33 entidades → 37 tablas.** Un solo modelo, sin módulos separados.

**Nomenclatura.** Tablas y columnas en minúscula, con guion bajo, en singular. Claves foráneas con prefijo `fk_`. Sin tildes y sin espacios — es la convención que fijó el profesor Carlos Castro en `34:10` y `35:06`. En el MER se conservan sus etiquetas (`ID`, `NumeroIdentidad`, `Codigoprograma`); aquí se usa `snake_case`, que cumple la misma regla y es la convención de PostgreSQL.

---

## 1 · Lo que se corrige del punto de partida

El archivo `Cätedras abiertas DIagrama Entidad -relación.xlsx` tenía una entidad y tres atributos. Es el arranque correcto. Esto es lo que el dato obligó a cambiar:

| # | Lo que decía | Consecuencia real | Corrección |
|---|---|---|---|
| 1 | `ID` — *«máximo 10 dígitos»* | **9.553 filas de 11 caracteres** y valores como `1000513C` quedarían fuera | `varchar(15)` alfanumérico |
| 2 | `NumeroIdentidad` como atributo | **707 personas tienen más de uno**; solo cabría uno | Tabla `documento_asistente` |
| 3 | `Codigoprograma` como atributo | Una persona cursa **varios** programas | Tabla `programa_asistente` |
| 4 | *«Una persona es toda aquella registrada en ASIS»* | El **externo** asiste y no está | `es_externo` + `id_asis` nullable, **revisable** |
| 5 | Sin nombres ni correos | Sin correo **no hay clave que enviar** | `nombres`, `apellidos`, dos correos |
| 6 | Sin sede | *«San Benito, virtual y Bello»* a la misma hora | Tabla `sede` |
| 7 | Sin encuesta | El enunciado la pide parametrizable | Cuatro tablas de definición |

---

## 2 · Las 37 tablas

### 2.1 · A — Asistentes e identidad

| Tabla | Columnas principales |
|---|---|
| `tipo_documento` | `id_tipo_documento` **PK** · `nombre` |
| **`asistente`** | `id_asistente` **PK** · `id_asis` ‡ *nullable = externo* · `nombres` · `apellidos` · `nombre_completo_asis` · `correo_institucional` ‡ · `correo_personal` · `celular` · `es_externo` · `activo` · `fk_lote_carga` |
| `documento_asistente` | `id_documento` **PK** · `fk_asistente` · `fk_tipo_documento` · `numero` ‡ · `vigente` |
| `tipo_vinculacion` | `id_tipo_vinculacion` **PK** · `nombre` · **`es_interno`** · **`exige_programa`** |
| `vinculacion_asistente` | `fk_asistente` · `fk_tipo_vinculacion` · **`fecha_ini`** → **PK de tres** · `fecha_fin` |
| `consentimiento_datos` | `id_consentimiento` **PK** · `fk_asistente` · `version_politica` · `aceptado_en` · `ip` |

> **`exige_programa` es la traducción de una frase.** El profesor Hugo Nelson dijo *«ellos entrarían sin programa, pero solo ellos»* (`41:16`). Escribir «solo ellos» en el esquema lo congela; escribirlo como columna del catálogo lo deja vivo.

### 2.2 · B — Estructura académica

| Tabla | Columnas |
|---|---|
| `facultad` | `id_facultad` **PK** · `nombre` · `fk_facultad_padre` *recursiva* |
| `programa_academico` | **`codigo` PK natural** `varchar(5)` · `nombre` · `fk_facultad` · `nivel` |
| `periodo_academico` | `id_periodo` **PK** (`2026-1`) · `fecha_ini` · `fecha_fin` |
| `programa_asistente` | `fk_asistente` · `fk_programa` · `fk_periodo` → **PK de tres** · `estado` |

### 2.3 · C — Cátedras, sesiones y sedes

| Tabla | Columnas |
|---|---|
| `tipo_evento` | `id_tipo_evento` **PK** `char(4)` — los 8 del ASIS |
| `sede` | `id_sede` **PK** · `nombre` · `es_virtual` |
| `modalidad` | `id_modalidad` **PK** · **`canal_difusion`** QR / ENLACE |
| `dependencia` | `id_dependencia` **PK** · `fk_dependencia_padre` *recursiva* |
| `catedra` | `id_catedra` **PK** · `id_evento_asis` ‡ `char(9)` · `nombre` · **`nombre_asis` generada** · `fk_tipo_evento` · `fk_dependencia` |
| **`sesion`** | `id_sesion` **PK** · `fk_catedra` · **`numero_reunion`** ‡ · `numero_reunion_asis` · `inicio` · `fin` · `fk_modalidad` · `fk_sede` · `fk_periodo` · `fk_encuesta` · `cupo` · `estado` |
| `ponencia` | `fk_sesion` · `fk_asistente` · `rol` → **PK de tres** |

### 2.4 · D — Acceso y registro · **el núcleo**

| Tabla | Columnas |
|---|---|
| `enlace_registro` | `id_enlace` **PK** · `fk_sesion` · `token` ‡ · `url_publica` · `ruta_imagen_qr` · `canal` · **`ventana tstzrange`** · `revocado_en` · `fk_usuario_crea` |
| `clave_acceso` | `id_clave` **PK** · `fk_asistente` · `fk_enlace` · **`clave_hash bytea`** · `enviado_a` · **`es_correo_institucional`** · `expira_en` · `usado_en` · `intentos` |
| **`registro_asistencia`** | `id_registro` **PK** · `fk_sesion` + `fk_asistente` ‡ · `fk_enlace` · `fk_clave` · `registrado_en` · **`fk_programa_snapshot`** · **`fk_vinculacion_snapshot`** · `origen` · `ip` |

### 2.5 · E — Encuesta

`encuesta` · `tipo_pregunta` · `pregunta` · `opcion_pregunta` · `respuesta_encuesta` · `respuesta_item`

**Lo que importa:** `respuesta_item` tiene `valor_numerico`, `valor_texto` y `fk_opcion`, y una restricción que exige **exactamente uno lleno**.

### 2.6 · F — Integración con el ASIS

`lote_carga_asistente` · `novedad_carga` · `alias_programa` · `estado_proceso` · `lote_migracion` · `detalle_migracion`

**Lo que importa:** `detalle_migracion` guarda `id_asis_enviado`, `programa_enviado` y `reunion_enviada` — **copia literal de lo que salió**, no lo que hoy dice la tabla.

### 2.7 · G — Seguridad

`usuario` · `rol` · `rol_por_usuario` *(con `fecha_ini` en la PK)* · `parametro` · `bitacora` *(con `jsonb`)*

---

## 3 · Las siete decisiones, en una línea cada una

| # | Decisión | Por qué |
|---|---|---|
| 1 | **`fecha_ini` en la PK**, dos veces | Sin ella, nadie recupera algo que ya tuvo. Y falla en silencio |
| 2 | **Instantáneas** en el registro | El archivo enviado al ASIS tiene que ser reproducible meses después |
| 3 | **`varchar(5)`** en el código de programa | `MCCP` tiene 4 caracteres; `char` metería un espacio en el archivo plano |
| 4 | **`id_asis` candidata**, no primaria | Ese formato ya cambió dos veces |
| 5 | **La ventana como rango** | Es lo que hace declarativas dos reglas que si no serían código |
| 6 | **Encuesta parametrizable** | Cambiar una pregunta no debe ser un `ALTER TABLE` en producción |
| 7 | **`exige_programa` como dato** | Habilitar una excepción es un `UPDATE`, no un cambio de esquema |

---

## 4 · Lo que el modelo garantiza y lo que no

**Garantiza, y lo hace el motor:**

- Nadie se registra dos veces en la misma sesión.
- Dos enlaces de una sesión no se solapan en el tiempo.
- Un documento identifica a lo sumo una persona; solo uno está vigente.
- Un registro solo puede quedar aceptado en un lote de migración.
- Exactamente una columna de valor por respuesta.
- Nadie borra nada — ni el administrador.

**No garantiza el motor, y hay que programarlo y medirlo:**

- Que el registro esté dentro de la ventana → disparador + `v_control_ventana`
- Que el programa sea obligatorio salvo excepción → disparador
- Que una encuesta respondida tenga al menos un ítem → procedimiento
- Que las preguntas obligatorias estén respondidas → procedimiento
- Que se respete el cupo → disparador con bloqueo

**No garantiza nadie, y está aceptado:**

- Que quien digitó la clave sea el dueño del correo. *«Esa trampa se puede hacer»* — el profesor Carlos Castro, `1:05:18`.

---

## 5 · Los volúmenes reales

| | |
|---|---:|
| Cátedras cargadas del ASIS | 5.496 |
| Sesiones | 5.711 |
| Personas | 14.808 |
| — con más de un documento | **707** |
| Documentos | 15.517 |
| Programas | 105 |
| Matrículas | 15.349 |

**Tiempo de carga completa: menos de 30 segundos**, incluida la construcción del esquema desde cero.

---

**Detalle conceptual:** [`MER/`](MER/) · **Detalle lógico:** [`MR/`](MR/) · **Scripts:** [`fisico_postgres/`](fisico_postgres/)
