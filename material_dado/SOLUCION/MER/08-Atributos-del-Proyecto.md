# 8 · Los atributos del proyecto

Identificadores **subrayados**. Los derivados en *cursiva*. Los opcionales marcados con `○`.

---

## Bloque A · Asistentes e identidad

### `ASISTENTE`

| Atributo | Dominio | Op. | Notas |
|---|---|:--:|---|
| <u>`id_asistente`</u> | entero grande | | Sustituto |
| `id_asis` | texto 15 | `○` | **Alternativo único.** Alfanumérico. Nulo solo si es externo |
| `nombres` | texto 100 | | Compuesto: se parte del nombre completo del ASIS |
| `apellidos` | texto 100 | | |
| `nombre_completo_asis` | texto 200 | `○` | **El original tal como llegó**, sin tocar |
| `correo_institucional` | correo | `○` | Único. Nulo en Rutas de Paz (`53:42`) |
| `correo_personal` | correo | `○` | |
| `celular` | texto 20 | `○` | |
| `es_externo` | lógico | | Falso por defecto |
| `activo` | lógico | | Baja lógica: nadie se elimina |
| `creado_en` | fecha y hora | | |

> ### El dominio de `id_asis`, corregido contra el dato
>
> En la reunión se acordó *«máximo 10 dígitos»* (`33:53`), a ojo, después de que el profesor Hugo Nelson advirtiera *«es variable, hay unos que son como 6»* (`33:36`). El dato real dice:
>
> | Longitud | Filas |
> |---:|---:|
> | 6 | 223 |
> | 7 | 6.225 |
> | 8 | 68 |
> | 10 | 24 |
> | **11** | **9.553** |
>
> Y hay **valores alfanuméricos**: `1000513C`, `970577C`, `1039859C`, `1052887C`.
>
> **Con el acuerdo verbal se habrían rechazado 9.553 de 16.093 filas en la primera carga.** El dominio corregido es texto de 15, no numérico. Es la corrección más importante que este documento le hace al archivo original, y hay que llevarla a la próxima reunión.

### `DOCUMENTO_ASISTENTE`

| Atributo | Dominio | Op. | Notas |
|---|---|:--:|---|
| <u>`id_documento`</u> | entero grande | | |
| `fk_asistente` | → `ASISTENTE` | | |
| `fk_tipo_documento` | → `TIPO_DOCUMENTO` | | |
| `numero` | texto 20 | | **Alternativo único** con el tipo. Longitud real: de 5 a 11 dígitos |
| `vigente` | lógico | | **Solo uno vigente por asistente** |

### `TIPO_VINCULACION`

| Atributo | Dominio | Notas |
|---|---|---|
| <u>`id_tipo_vinculacion`</u> | texto 15 | Natural |
| `nombre` | texto 60 | Único |
| `es_interno` | lógico | **Resuelve el informe 2** con un `GROUP BY` |
| `exige_programa` | lógico | **Falso en Rutas de Paz.** Convierte la excepción de `41:16` en dato |

### `VINCULACION_ASISTENTE` — *relación con atributos*

| Atributo | Notas |
|---|---|
| <u>`fk_asistente`</u> · <u>`fk_tipo_vinculacion`</u> · <u>**`fecha_ini`**</u> | **Identificador de tres partes** |
| `fecha_fin` `○` | Nulo = vigente |

---

## Bloque B · Estructura académica

### `PROGRAMA_ACADEMICO`

| Atributo | Dominio | Notas |
|---|---|---|
| <u>`codigo`</u> | `char(5)` | **Natural.** `M0221`, `M0286`. 105 valores reales |
| `nombre` | texto 150 | |
| `fk_facultad` | → `FACULTAD` | |
| `nivel` | texto 20 | Pregrado, especialización, maestría, doctorado, educación continua |
| `activo` | lógico | |

### `PROGRAMA_ASISTENTE` — *relación con atributos*

| Atributo | Notas |
|---|---|
| <u>`fk_asistente`</u> · <u>`fk_programa`</u> · <u>`fk_periodo`</u> | El periodo entra en el identificador: la misma matrícula se repite cada semestre |
| `estado` `○` | Activo, retirado, graduado |

---

## Bloque C · Cátedras y sesiones

### `CATEDRA`

| Atributo | Dominio | Op. | Notas |
|---|---|:--:|---|
| <u>`id_catedra`</u> | entero grande | | |
| `id_evento_asis` | **`char(9)`** | | **Alternativo único.** `000035392` — **con ceros a la izquierda** |
| `nombre` | texto 200 | | El nombre completo, sin truncar |
| *`nombre_asis`* | texto 30 | | **Derivado**: los 30 primeros caracteres |
| `fk_tipo_evento` | → `TIPO_EVENTO` | | |
| `fk_dependencia` | → `DEPENDENCIA` | `○` | |
| `activo` | lógico | | |

> **Por qué `nombre_asis` se deriva y no se digita.** El listado real trae `REMOCIÓN DE METALES PESADOS DE` y `CURSO FORMATIVO LÓGICO MATEMAT`: nombres cortados a mitad de palabra. Si el sistema guardara el corto, **el largo se perdería para siempre**. Guardando el largo y derivando el corto, se recupera la información y se sigue hablando el idioma del ASIS.

### `SESION`

| Atributo | Dominio | Op. | Notas |
|---|---|:--:|---|
| <u>`id_sesion`</u> | entero grande | | |
| `fk_catedra` | → `CATEDRA` | | |
| *`numero_reunion`* | entero pequeño | | **Derivado**: el máximo de la cátedra más uno. **Alternativo único con la cátedra** |
| `numero_reunion_asis` | entero pequeño | `○` | **El que devolvió el ASIS.** Se guarda para conciliar. Ver decisión abierta |
| `titulo` | texto 200 | `○` | El de la sesión concreta, si difiere del de la cátedra |
| `inicio` · `fin` | fecha y hora con zona | | |
| `fk_modalidad` · `fk_sede` | → catálogos | | |
| `lugar` `○` · `enlace_virtual` `○` | texto | `○` | Auditorio, o URL de la sala |
| `cupo` | entero | `○` | Nulo = sin límite |
| `fk_periodo` | → `PERIODO_ACADEMICO` | | |
| `estado` | texto 15 | | Programada · Abierta · Cerrada · Migrada |

---

## Bloque D · Acceso y registro

### `ENLACE_REGISTRO`

| Atributo | Dominio | Op. | Notas |
|---|---|:--:|---|
| <u>`id_enlace`</u> | entero grande | | |
| `token` | UUID | | **Alternativo único.** Aleatorio, no adivinable |
| `fk_sesion` | → `SESION` | | |
| `url_publica` | texto 300 | | |
| `ruta_imagen_qr` | texto 300 | `○` | **Ruta relativa**, nunca absoluta |
| `canal` | texto 10 | | `QR` o `ENLACE` — debe concordar con la modalidad (`1:06:53`) |
| **`ventana`** | **rango de fecha y hora** | | Apertura y cierre en un solo atributo |
| `usos_maximos` | entero | `○` | Nulo = sin límite |
| `revocado_en` | fecha y hora | `○` | Nulo = vigente |
| `fk_usuario_crea` | → `USUARIO` | | |

### `CLAVE_ACCESO`

| Atributo | Dominio | Op. | Notas |
|---|---|:--:|---|
| <u>`id_clave`</u> | entero grande | | |
| `fk_asistente` · `fk_enlace` | → | | |
| **`clave_hash`** | binario | | **Nunca en claro** |
| `enviado_a` | correo | | La dirección concreta a la que salió |
| *`es_correo_institucional`* | lógico | | **Derivado** del dominio de `enviado_a`. Responde a `55:32` |
| `generado_en` · `expira_en` | fecha y hora | | |
| `usado_en` | fecha y hora | `○` | Nulo = no se ha usado |
| `intentos` | entero | | Contra fuerza bruta |
| `ip_solicitud` | dirección IP | `○` | |

### `REGISTRO_ASISTENCIA`

| Atributo | Dominio | Op. | Notas |
|---|---|:--:|---|
| <u>`id_registro`</u> | entero grande | | |
| `fk_sesion` · `fk_asistente` | → | | **Alternativo único el par** |
| `fk_enlace` · `fk_clave` | → | | La traza de por dónde entró |
| `registrado_en` | fecha y hora | | |
| **`fk_programa_snapshot`** | → `PROGRAMA_ACADEMICO` | `○` | **Instantánea.** Nulo si la vinculación no exige programa |
| **`fk_vinculacion_snapshot`** | → `TIPO_VINCULACION` | | **Instantánea** |
| `origen` | texto 15 | | `QR` · `ENLACE` · `MANUAL` · `IMPORTADO` |
| `ip` · `user_agent` | | `○` | Evidencia |

---

## Bloque E · Encuesta

### `PREGUNTA` y `RESPUESTA_ITEM`

| `PREGUNTA` | Notas |
|---|---|
| <u>`id_pregunta`</u> · `fk_encuesta` · `enunciado` · `orden` · `fk_tipo_pregunta` · `obligatoria` · `valor_min` `○` · `valor_max` `○` | El par (`encuesta`, `orden`) es alternativo único |

| `RESPUESTA_ITEM` | Notas |
|---|---|
| <u>`id_item`</u> · `fk_respuesta` · `fk_pregunta` | El par (`respuesta`, `pregunta`) es alternativo único |
| `valor_numerico` `○` · `valor_texto` `○` · `fk_opcion` `○` | **Exactamente uno lleno**, según el tipo de pregunta |

> **Los tres nulos de `RESPUESTA_ITEM` no son opcionalidad: son una regla condicional.** No es que se pueda no responder; es que **el tipo de pregunta decide cuál de los tres se usa**. Una escala llena `valor_numerico`; un texto libre llena `valor_texto`; una opción llena `fk_opcion`. Que los tres estén vacíos, o que haya dos llenos, es un dato corrupto. Ver [11](11-MER-de-Acceso-y-Registro.md).

---

## Bloque F · Integración

### `DETALLE_MIGRACION` — el que guarda lo enviado

| Atributo | Notas |
|---|---|
| <u>`id_detalle`</u> · `fk_lote_migracion` · `fk_registro` | |
| **`id_asis_enviado`** · **`programa_enviado`** · **`reunion_enviada`** | **Copia literal de lo que salió en el archivo.** No se deriva al consultar |
| `resultado` · `mensaje` `○` | `ACEPTADO` · `RECHAZADO` |

> **Por qué se repiten tres columnas que ya están en otras tablas.** Porque no son las mismas. Si el programa del asistente cambia después del envío, la tabla de origen dirá una cosa y el ASIS tendrá otra. **Sin la copia, un rechazo del ASIS es indepurable.**

---

## Los nulos que significan algo — cuadro completo

| Atributo nulo | Qué significa | Origen |
|---|---|---|
| `asistente.id_asis` | Es **externo**, no está en el maestro del ASIS | §3.1 del plan |
| `asistente.correo_institucional` | **No tiene** correo de la universidad — Rutas de Paz | `53:42` |
| `registro.fk_programa_snapshot` | Su vinculación **no exige programa** | `41:16` |
| `vinculacion.fecha_fin` | La vinculación **sigue vigente** | Convención |
| `clave.usado_en` | La clave **no se ha usado** | Convención |
| `enlace.revocado_en` | El enlace **sigue vivo** | Convención |
| `sesion.cupo` | **Sin límite** de asistentes | Convención |
| `sesion.numero_reunion_asis` | **Aún no se ha conciliado** con el ASIS | Decisión abierta |

**Cualquier otro nulo del modelo es un defecto**, no una comodidad.

---

**Anterior:** [07 · Entidades](07-Entidades-del-Proyecto.md) · **Siguiente:** [09 · Relaciones](09-Relaciones-del-Proyecto.md)
