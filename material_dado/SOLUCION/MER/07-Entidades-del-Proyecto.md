# 7 · Las 33 entidades del proyecto

Cada entidad con su **descripción escrita** —como pidió el profesor Carlos Castro en `24:21`—, su identificador, y la razón por la que es entidad y no atributo.

Se marcan con ◆ las que salen directamente de una cita de la reunión.

---

## Bloque A · Asistentes e identidad — 5 entidades

### `ASISTENTE` ◆

> **Persona que asiste a las cátedras abiertas, de forma presencial o virtual. Puede ser estudiante, docente, administrativo, egresado, participante de rutas de formación o público externo.**

Es la definición que dictó el profesor Hugo Nelson en el archivo original, ampliada con los tipos que aparecieron después en la conversación. **Se conserva su nombre**: el usuario experto la llamó `Asistente` y así se queda.

| | |
|---|---|
| **Identificador** | `id_asistente` sustituto · **alternativo `id_asis` único** |
| **Por qué entidad** | Es el objeto de estudio central. Todo lo demás existe para saber quién asistió a qué |
| **Restricción heredada** | *«Una persona es toda aquella que está registrada en ASIS»* (`27:07`). El profesor Carlos Castro: *«eso es importante porque esa es una restricción»* |

### `TIPO_DOCUMENTO`

> **Clase de documento de identidad con que se identifica una persona: cédula de ciudadanía, tarjeta de identidad, cédula de extranjería, pasaporte, permiso especial de permanencia.**

| | |
|---|---|
| **Identificador** | `id_tipo_documento` natural (`CC`, `TI`, `CE`, `PA`, `PEP`) |
| **Por qué entidad** | En el formulario actual el tipo aparece escrito de **más de diez formas** distintas: `Cedula`, `CC`, `C.c`, `Cédula de cuidadania`… Un catálogo cerrado lo elimina de raíz |

### `DOCUMENTO_ASISTENTE` ◆

> **Número de documento de identidad asociado a un asistente. Una misma persona puede tener varios a lo largo del tiempo; solo uno está vigente.**

| | |
|---|---|
| **Identificador** | `id_documento` sustituto · **alternativo (`tipo`, `numero`) único** |
| **Por qué entidad** | **707 personas del maestro real tienen más de un documento.** Como atributo simple solo cabría uno |
| **Para qué sirve** | `42:01` — *«a veces los estudiantes, como no se saben el ID, colocan la cédula; toca buscar en ASIS con la cédula para obtener el ID»*. Es una de las tres vías de acceso |

### `TIPO_VINCULACION` ◆

> **Relación institucional de una persona con la universidad. Determina si cuenta como interna o externa y si su asistencia exige programa académico.**

| | |
|---|---|
| **Identificador** | `id_tipo_vinculacion` natural |
| **Atributos que deciden** | `es_interno` → informe 2 del enunciado · **`exige_programa`** → la excepción de Rutas de Paz |
| **Por qué entidad y no tres entidades** | Estudiante, docente y externo son **valores**, no clases. Habilitar un cuarto tipo debe ser un `INSERT` |
| **Valores iniciales** | Estudiante · Docente · Administrativo · Egresado · **Rutas de Paz** · Externo · Colegio invitado |

> **`exige_programa` es la traducción exacta de `41:16`.** El profesor Hugo Nelson dijo *«ellos entrarían sin programa, pero solo ellos»*. Escribir «solo ellos» en el esquema lo congela; escribirlo como columna del catálogo lo deja vivo.

### `CONSENTIMIENTO_DATOS`

> **Aceptación por parte de un asistente de la política de tratamiento de datos personales, en una versión concreta y en un momento concreto.**

| | |
|---|---|
| **Identificador** | `id_consentimiento` sustituto |
| **Por qué entidad** | Ley 1581 de 2012. El sistema guarda documentos, nombres y correos personales de externos. **El consentimiento es un hecho que se registra**, no un aviso de pantalla |

---

## Bloque B · Estructura académica — 3 entidades

### `FACULTAD`

> **Unidad académica que agrupa programas. Puede estar contenida en otra facultad o escuela.**

| | |
|---|---|
| **Identificador** | `id_facultad` natural |
| **Relación reflexiva** | `fk_facultad_padre` — produce un **árbol**, no un grafo |
| **Por qué entidad** | Permite el roll-up del informe por programa, que es el informe 1 del enunciado |

### `PROGRAMA_ACADEMICO` ◆

> **Programa académico en el que un asistente está o estuvo matriculado. Su código es el que viaja al archivo plano del ASIS.**

| | |
|---|---|
| **Identificador** | **`codigo` natural** — `M0221`, `M0286`, `M0700` |
| **Por qué natural** | Es lo que el ASIS espera recibir (`32:34`). Un sustituto obligaría a un `JOIN` en la consulta más crítica del sistema |
| **Volumen real** | **105 códigos distintos** en el maestro |
| **Para qué sirve** | `50:14` — *«el programa es importante porque después le da información a Registro de qué programas hizo el estudiante»* |

### `PERIODO_ACADEMICO` ◆

> **Periodo académico en que ocurre una sesión y en que se cursa un programa.**

| | |
|---|---|
| **Identificador** | `id_periodo` natural — `2026-1`, `2026-2` |
| **Por qué entidad** | profesor Hugo Nelson lo pidió por su nombre: *«cuántas personas externas han ingresado, no sé, en 2026-2»* (`56:16`). Sin él no hay comparativo entre semestres |

---

## Bloque C · Cátedras, sesiones y sedes — 6 entidades

### `TIPO_EVENTO`

> **Clasificación del evento en el ASIS.**

| | |
|---|---|
| **Identificador** | `id_tipo_evento` natural, `char(4)` |
| **Valores reales** | `CAAB` (5.449) · `DLLH` (188) · `DEPR` (44) · `SLDI` (16) · `ARCU` (5) · `MTG` (5) · `DIIB` (3) · `EIIC` (1) |
| **Por qué entidad** | Ocho valores cerrados que vienen del ASIS. Como texto libre se degradaría en la primera carga |

### `SEDE` ◆

> **Lugar físico o virtual donde se dicta una sesión.**

| | |
|---|---|
| **Identificador** | `id_sede` natural |
| **Valores iniciales** | San Benito · Bello · Virtual |
| **Por qué entidad** | `1:03:33` — *«puede que una cátedra esté en San Benito, otra esté virtual y otra esté en Bello»*. **La sede es lo que distingue dos cátedras a la misma hora.** Como texto en la sesión, el informe por sede no se puede escribir |

### `MODALIDAD` ◆

> **Forma en que se dicta una sesión, y que determina cómo se difunde el registro.**

| | |
|---|---|
| **Identificador** | `id_modalidad` natural |
| **Valores** | Presencial · Virtual · Telepresencial · Híbrida |
| **Atributo que decide** | `canal_difusion` — **QR** o **enlace** |
| **Por qué entidad** | `1:06:53` — *«cuando es virtual enviamos el enlace; si es presencial, el QR»*. La modalidad **gobierna comportamiento**, no es una etiqueta |

### `DEPENDENCIA`

> **Unidad organizadora de la cátedra: bienestar, pastoral, una facultad, un centro. Puede depender de otra.**

| | |
|---|---|
| **Identificador** | `id_dependencia` natural |
| **Relación reflexiva** | `fk_dependencia_padre` |

### `CATEDRA` ◆

> **Evento formativo abierto, registrado en el ASIS con un identificador propio. Se dicta en una o varias sesiones.**

| | |
|---|---|
| **Identificador** | `id_catedra` sustituto · **alternativo `id_evento_asis` único** |
| **`id_evento_asis`** | **`char(9)` con ceros a la izquierda** — `000035392`. Como entero se convierte en `35392` y deja de servir |
| **Atributo derivado** | `nombre_asis` — los primeros 30 caracteres, porque el ASIS trunca ahí |
| **Por qué entidad separada de `SESION`** | Es la distinción `LIBRO` / `EJEMPLAR` del ejemplo del profesor Carlos Castro. Verificado en el dato: **la misma descripción se repite en todas las reuniones de un evento** |

### `SESION` ◆ — *entidad débil*

> **Cada una de las reuniones en que se dicta una cátedra. Se numera con un consecutivo propio dentro de su cátedra, que es el que exige el ASIS.**

| | |
|---|---|
| **Identificador** | `id_sesion` sustituto · **alternativo (`catedra`, `numero_reunion`) único** |
| **Débil de** | `CATEDRA` — la «reunión 3» no significa nada suelta |
| **Verificado en el dato** | El par (Evento, Reunión) **es único en las 5.711 filas**. Máximo observado: 59 reuniones en un evento |
| **Por qué entidad** | Sin ella no hay número de reunión que enviar, y el archivo plano lo exige (`32:34`) |

---

## Bloque D · Acceso y registro — 3 entidades

### `ENLACE_REGISTRO` ◆

> **Punto de entrada al registro de una sesión, materializado como QR o como URL. Tiene una ventana horaria de apertura y cierre, y no es reutilizable entre sesiones.**

| | |
|---|---|
| **Identificador** | `id_enlace` sustituto · **alternativo `token` único** |
| **Atributo clave** | `ventana` como **rango de tiempo**, no dos columnas sueltas |
| **Por qué QR y URL no son dos entidades** | Son **dos presentaciones del mismo token**. Separarlos duplicaría la ventana y permitiría que se contradijeran |

### `CLAVE_ACCESO` ◆

> **Clave de un solo uso que el sistema envía al correo del asistente para verificar que es él quien se registra.**

| | |
|---|---|
| **Identificador** | `id_clave` sustituto |
| **Se guarda cifrada** | El atributo se llama `clave_hash`. **Nunca la clave en claro** |
| **Atributo que vigila** | `es_correo_institucional` — derivado del dominio de destino |
| **Por qué existe** | `1:04:51` — *«yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo; si no, yo te registro a vos y vos me registrás a mí»*. **No es autenticación: es antisuplantación** |

### `REGISTRO_ASISTENCIA` ◆

> **Hecho de que un asistente quedó registrado en una sesión, en un instante concreto, con el programa y la vinculación que tenía en ese momento.**

| | |
|---|---|
| **Identificador** | `id_registro` sustituto · **alternativo (`sesion`, `asistente`) único** |
| **Atributos de instantánea** | `fk_programa_snapshot` · `fk_tipo_vinculacion_snapshot` |
| **Por qué instantánea y no referencia** | `50:14` — la asistencia se imputa al programa **de ese día**. Y el archivo plano tiene que ser **reproducible meses después** |

---

## Bloque E · Encuesta de calidad — 6 entidades

| Entidad | Descripción | Identificador |
|---|---|---|
| `ENCUESTA` | **Cuestionario de calidad, en una versión concreta, que se aplica a las sesiones de un periodo.** | `id_encuesta` · alt. (`nombre`, `version`) |
| `TIPO_PREGUNTA` | **Clase de pregunta, que determina cómo se captura y dónde se guarda la respuesta.** Escala 1-5, opción única, opción múltiple, texto libre, sí/no | natural |
| `PREGUNTA` | **Cada uno de los enunciados de una encuesta, con su orden y su obligatoriedad.** | `id_pregunta` · alt. (`encuesta`, `orden`) |
| `OPCION_PREGUNTA` | **Alternativa de respuesta de una pregunta de opción.** | `id_opcion` |
| `RESPUESTA_ENCUESTA` | **Cabecera del formulario que un asistente respondió tras registrarse.** | `id_respuesta` · alt. `registro` único |
| `RESPUESTA_ITEM` | **Respuesta concreta a una pregunta.** *Entidad débil de `RESPUESTA_ENCUESTA`* | alt. (`respuesta`, `pregunta`) |

> **Por qué la encuesta se parametriza en cuatro tablas y no en cinco columnas fijas.** El enunciado dice que *«el administrador configura o parametriza los valores que considere»*. Con columnas fijas, cambiar una pregunta es un `ALTER TABLE` en producción y **rompe la comparabilidad histórica**: las respuestas viejas quedarían bajo un enunciado que ya no es el que se preguntó.

---

## Bloque F · Integración con el ASIS — 6 entidades

| Entidad | Descripción | Por qué entidad |
|---|---|---|
| `LOTE_CARGA_ASISTENTE` | **Cada ejecución de la carga del archivo de personas descargado del ASIS.** | `52:57` — *«ese archivo lo cargamos en la base de datos como una tabla»*. Una carga de 16.093 filas necesita **evidencia** |
| `NOVEDAD_CARGA` | **Fila del archivo que no se pudo cargar, con su contenido crudo y el motivo.** | Sin esto, los IDs alfanuméricos y los pares duplicados se manifiestan como *«cargó menos filas de las que tenía»* |
| `ALIAS_PROGRAMA` | **Texto libre con que se ha escrito un programa, y el código al que corresponde.** | Los 164 registros del formulario traen `Psicológica`, `Entrenamiento Deportivo.`, `Ingenieria de datos y software`. **Es una tabla viva**, no un script de una vez |
| `ESTADO_PROCESO` | **Estado de una ejecución del proceso de carga en el ASIS.** En cola · En curso · Error · Correcto · Incorrecto | **Los cinco estados literales** del manual de migración, página 6 |
| `LOTE_MIGRACION` | **Cada generación del archivo plano de una sesión y su envío al ASIS.** | Cierra el ciclo con el *Monitor Procesos* |
| `DETALLE_MIGRACION` | **Cada fila enviada en un lote, tal como se envió, y el resultado que dio.** | **Se guarda lo enviado, no lo que hoy dice la tabla.** Es la única forma de auditar un rechazo seis meses después |

---

## Bloque G · Seguridad y configuración — 4 entidades

| Entidad | Descripción | Nota |
|---|---|---|
| `USUARIO` | **Persona con credenciales para operar el sistema.** | Se apoya en `ASISTENTE`: el administrador **es** una persona del ASIS, y así no se duplican nombres ni correos |
| `ROL` | **Conjunto de permisos.** Administrador · Coordinador de dependencia · Consulta | |
| `PARAMETRO` | **Valor de configuración que el administrador puede cambiar sin tocar el código.** | Vigencia y longitud de la clave, intentos máximos, minutos de apertura y cierre por defecto. Del `.docx`: *«el administrador configura o parametriza los valores que considere»* |
| `BITACORA` | **Registro de toda modificación sobre datos sensibles, con el antes y el después.** | Obligatoria por el tipo de dato que se maneja |

---

## Lo que se descartó, y por qué

| Candidata | Por qué no |
|---|---|
| **`QR` y `URL` como entidades separadas** | Dos presentaciones del mismo token. Ver `ENLACE_REGISTRO` |
| **`ARCHIVO_PLANO`** | Es la salida de una consulta. Lo que sí es entidad es el **lote** y su resultado |
| **`ESTUDIANTE`, `DOCENTE`, `EXTERNO` como entidades** | Son valores de `TIPO_VINCULACION` |
| **`CORREO` como entidad** | Son exactamente dos, con roles distintos. Si fueran *n*, cambiaría |
| **`IMAGEN_CORPORATIVA`** | Recurso de presentación. No se consulta por ella |
| **`FORMULARIO`** | Es la pantalla, no un objeto del negocio. Lo que se guarda es el registro que produce |
| **`ASISTENCIA` separada de `REGISTRO`** | Serían la misma cosa. Registrarse **es** la evidencia de asistencia en este sistema |
| **`NIVEL_FORMACION` como entidad** | Pregrado y posgrado son dos valores sin datos propios. Queda como atributo de `PROGRAMA_ACADEMICO`. **Decisión revisable** si más adelante hay que agrupar informes por nivel |

---

**Anterior:** [06 · Opcionalidad](06-Opcionalidad-y-Participacion.md) · **Siguiente:** [08 · Atributos del proyecto](08-Atributos-del-Proyecto.md)
