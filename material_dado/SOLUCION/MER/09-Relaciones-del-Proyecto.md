# 9 · Las 35 relaciones del proyecto

Cada una con su **verbo**, sus **dos frases en español**, su cardinalidad y su min-max — como pidió el profesor Carlos Castro en `7:22`.

**Cómo se lee el min-max:** `(mín, máx)` de ejemplares de la entidad **derecha** con los que se asocia un ejemplar de la **izquierda**.

---

## Bloque A · Asistentes e identidad — 5 relaciones

| # | Izquierda | **Verbo** | Derecha | Card. | Min-max | Las dos frases |
|---|---|---|---|---|---|---|
| R01 | `ASISTENTE` | **se identifica con** | `DOCUMENTO_ASISTENTE` | `1:N` | `(0,N)` / `(1,1)` | Un asistente se identifica con varios documentos a lo largo del tiempo · Un documento identifica a un solo asistente |
| R02 | `DOCUMENTO_ASISTENTE` | **es de clase** | `TIPO_DOCUMENTO` | `N:1` | `(1,1)` / `(0,N)` | Un documento es de una sola clase · Una clase agrupa muchos documentos |
| R03 | `ASISTENTE` | **se vincula como** ◆ | `TIPO_VINCULACION` | `N:M` | `(1,N)` / `(0,N)` | Un asistente se vincula como estudiante, docente o externo, y eso cambia con el tiempo · Un tipo de vinculación agrupa muchos asistentes |
| R04 | `ASISTENTE` | **autoriza** | `CONSENTIMIENTO_DATOS` | `1:N` | `(0,N)` / `(1,1)` | Un asistente autoriza el tratamiento de sus datos una o varias veces, según la versión de la política · Cada autorización es de un solo asistente |
| R05 | `ASISTENTE` | **opera como** | `USUARIO` | `1:1` | `(0,1)` / `(1,1)` | Un asistente puede operar como usuario del sistema · Un usuario es una sola persona |

> **R03 lleva `fecha_ini` en el identificador.** Sin ella, un egresado que vuelve a matricularse no podría recuperar la vinculación de estudiante. Es el caso de los *«asuntos históricos»* que describió el profesor Carlos Castro en `8:37`.

---

## Bloque B · Estructura académica — 4 relaciones

| # | Izquierda | **Verbo** | Derecha | Card. | Min-max | Las dos frases |
|---|---|---|---|---|---|---|
| R06 | `FACULTAD` | **agrupa** | `PROGRAMA_ACADEMICO` | `1:N` | `(0,N)` / `(1,1)` | Una facultad agrupa muchos programas · Un programa pertenece a una sola facultad |
| R07 | `FACULTAD` | **depende de** | `FACULTAD` | `1:N` | `(0,N)` / `(0,1)` | Una facultad puede contener otras · Una facultad depende de a lo sumo una superior. **Reflexiva → árbol** |
| R08 | `ASISTENTE` | **cursa** ◆ | `PROGRAMA_ACADEMICO` | `N:M` | `(0,N)` / `(0,N)` | Un asistente cursa varios programas · Un programa es cursado por muchos asistentes |
| R09 | `PROGRAMA_ASISTENTE` | **corresponde a** | `PERIODO_ACADEMICO` | `N:1` | `(1,1)` / `(0,N)` | Cada matrícula corresponde a un periodo · Un periodo tiene muchas matrículas |

> **R08 es `(0,N)` por la izquierda**, no `(1,N)`. Es la excepción de Rutas de Paz: *«ellos entrarían sin programa, pero solo ellos»* (`41:16`). Declararla `(1,N)` haría imposible registrar a esa población.

---

## Bloque C · Cátedras, sesiones y sedes — 8 relaciones

| # | Izquierda | **Verbo** | Derecha | Card. | Min-max | Las dos frases |
|---|---|---|---|---|---|---|
| R10 | `CATEDRA` | **se dicta en** ◆ | `SESION` | `1:N` | `(0,N)` / `(1,1)` | Una cátedra se dicta en una o varias sesiones · Una sesión pertenece a una sola cátedra. **Identificadora: `SESION` es débil** |
| R11 | `CATEDRA` | **se clasifica como** | `TIPO_EVENTO` | `N:1` | `(1,1)` / `(0,N)` | Una cátedra se clasifica en un solo tipo · Un tipo agrupa muchas cátedras |
| R12 | `DEPENDENCIA` | **organiza** | `CATEDRA` | `1:N` | `(0,N)` / `(0,1)` | Una dependencia organiza muchas cátedras · Una cátedra la organiza a lo sumo una dependencia |
| R13 | `DEPENDENCIA` | **depende de** | `DEPENDENCIA` | `1:N` | `(0,N)` / `(0,1)` | **Reflexiva → árbol.** Da la consulta recursiva I20 |
| R14 | `SEDE` | **aloja** ◆ | `SESION` | `1:N` | `(0,N)` / `(1,1)` | Una sede aloja muchas sesiones · Una sesión ocurre en una sola sede |
| R15 | `SESION` | **se dicta en modalidad** ◆ | `MODALIDAD` | `N:1` | `(1,1)` / `(0,N)` | Una sesión tiene una sola modalidad · Una modalidad se aplica a muchas sesiones |
| R16 | `ASISTENTE` | **expone en** | `SESION` | `N:M` | `(0,N)` / `(0,N)` | Un ponente expone en varias sesiones · Una sesión tiene uno o varios ponentes |
| R17 | `SESION` | **ocurre en** | `PERIODO_ACADEMICO` | `N:1` | `(1,1)` / `(0,N)` | Una sesión ocurre en un solo periodo · Un periodo tiene muchas sesiones |

> **R14 existe por `1:03:33`.** El profesor Hugo Nelson: *«puede que una cátedra esté en San Benito, otra esté virtual y otra esté en Bello»*. La sede va en `SESION` y no en `CATEDRA`, porque la misma cátedra puede tener una sesión en cada sitio.

---

## Bloque D · Acceso y registro — 6 relaciones

| # | Izquierda | **Verbo** | Derecha | Card. | Min-max | Las dos frases |
|---|---|---|---|---|---|---|
| R18 | `SESION` | **se difunde mediante** ◆ | `ENLACE_REGISTRO` | `1:N` | `(0,N)` / `(1,1)` | Una sesión se difunde por uno o varios enlaces a lo largo del tiempo · Un enlace pertenece a una sola sesión |
| R19 | `ASISTENTE` | **solicita** ◆ | `CLAVE_ACCESO` | `1:N` | `(0,N)` / `(1,1)` | Un asistente solicita varias claves, una por sesión o por reintento · Cada clave se emite para un solo asistente |
| R20 | `ENLACE_REGISTRO` | **ampara** | `CLAVE_ACCESO` | `1:N` | `(0,N)` / `(1,1)` | Un enlace ampara muchas claves · Cada clave se pidió sobre un solo enlace |
| R21 | **`ASISTENTE`** | **se registra en** ◆ | **`SESION`** | `N:M` | `(0,N)` / `(0,N)` | **Un asistente se registra en muchas sesiones · Una sesión recibe muchos asistentes** |
| R22 | `CLAVE_ACCESO` | **habilita** ◆ | `REGISTRO_ASISTENCIA` | `1:1` | `(0,1)` / `(1,1)` | Una clave usada habilita un registro · Todo registro nació de una clave |
| R23 | `REGISTRO_ASISTENCIA` | **conserva** | `PROGRAMA_ACADEMICO` | `N:1` | `(0,1)` / `(0,N)` | Un registro conserva el programa que el asistente tenía ese día · **Instantánea, no referencia viva** |

> ### R21 es el rombo central del modelo
>
> Todo lo demás existe para poder escribirlo o para poder consultarlo. Lleva colgando el instante, las dos instantáneas, el origen y la evidencia técnica.
>
> **R22 es lo que impide la suplantación.** Su min-max `(1,1)` por la derecha dice que **no hay registro sin clave usada**. Si se relajara a `(0,1)`, alguien podría registrar a otro, y eso es exactamente lo que el profesor Carlos Castro quería evitar: *«si no, yo te registro a vos y vos me registrás a mí»* (`1:04:51`).

---

## Bloque E · Encuesta — 6 relaciones

| # | Izquierda | **Verbo** | Derecha | Card. | Min-max | Las dos frases |
|---|---|---|---|---|---|---|
| R24 | `ENCUESTA` | **se compone de** | `PREGUNTA` | `1:N` | `(1,N)` / `(1,1)` | Una encuesta se compone de una o más preguntas · Una pregunta es de una sola encuesta |
| R25 | `PREGUNTA` | **se responde según** | `TIPO_PREGUNTA` | `N:1` | `(1,1)` / `(0,N)` | Una pregunta tiene un solo tipo · Un tipo se aplica a muchas preguntas |
| R26 | `PREGUNTA` | **ofrece** | `OPCION_PREGUNTA` | `1:N` | `(0,N)` / `(1,1)` | Una pregunta de opción ofrece varias alternativas · Cada alternativa es de una sola pregunta |
| R27 | `SESION` | **se evalúa con** | `ENCUESTA` | `N:1` | `(0,1)` / `(0,N)` | Una sesión se evalúa con a lo sumo una encuesta · Una encuesta se aplica a muchas sesiones |
| R28 | `REGISTRO_ASISTENCIA` | **es evaluado en** | `RESPUESTA_ENCUESTA` | `1:1` | `(0,1)` / `(1,1)` | Un registro se evalúa a lo sumo una vez · Cada respuesta corresponde a un registro |
| R29 | `RESPUESTA_ENCUESTA` | **detalla** | `RESPUESTA_ITEM` | `1:N` | **`(1,N)`** / `(1,1)` | Una encuesta respondida detalla **al menos una** respuesta · Cada ítem es de una sola encuesta respondida. **Identificadora** |

> **R29 tiene el min-max que ninguna clave foránea puede hacer cumplir.** Ver [11 · Acceso y registro](11-MER-de-Acceso-y-Registro.md), §3.

---

## Bloque F · Integración con el ASIS — 5 relaciones

| # | Izquierda | **Verbo** | Derecha | Card. | Min-max | Las dos frases |
|---|---|---|---|---|---|---|
| R30 | `LOTE_CARGA_ASISTENTE` | **rechaza** | `NOVEDAD_CARGA` | `1:N` | `(0,N)` / `(1,1)` | Un lote rechaza cero o muchas filas · Cada novedad es de un solo lote |
| R31 | `ALIAS_PROGRAMA` | **resuelve a** | `PROGRAMA_ACADEMICO` | `N:1` | `(1,1)` / `(0,N)` | Un alias resuelve a un solo programa · Un programa tiene muchas formas de escribirse |
| R32 | `SESION` | **se migra en** | `LOTE_MIGRACION` | `1:N` | `(0,N)` / `(1,1)` | Una sesión se migra en uno o varios lotes, si hubo reintentos · Cada lote es de una sola sesión |
| R33 | `LOTE_MIGRACION` | **migra** ◆ | `REGISTRO_ASISTENCIA` | `N:M` | `(1,N)` / `(0,N)` | Un lote migra uno o más registros · Un registro puede intentarse en varios lotes, pero **solo puede quedar aceptado en uno** |
| R34 | `LOTE_MIGRACION` | **termina en** | `ESTADO_PROCESO` | `N:1` | `(1,1)` / `(0,N)` | Un lote está en un solo estado · Un estado agrupa muchos lotes |

---

## Bloque G · Seguridad — 1 relación

| # | Izquierda | **Verbo** | Derecha | Card. | Min-max | Las dos frases |
|---|---|---|---|---|---|---|
| R35 | `USUARIO` | **desempeña** | `ROL` | `N:M` | `(1,N)` / `(0,N)` | Un usuario desempeña uno o más roles, y puede recuperarlos tras perderlos · Un rol lo desempeñan varios usuarios |

> **R35 lleva `fecha_ini` en el identificador**, por la misma razón que R03.

---

## Resumen

| Cardinalidad | Cuántas |
|---|---:|
| `1:1` | 3 |
| `1:N` / `N:1` | 26 |
| **`N:M`** | **6** |
| — de ellas, reflexivas | 2 (R07, R13) |
| — de ellas, identificadoras | 2 (R10, R29) |
| **Total** | **35** |

> **Comprobación de la suma:** 5 + 4 + 8 + 6 + 6 + 5 + 1 = **35**.

**Las seis `N:M` son exactamente las seis que llevan atributos**, y son las que producen tabla nueva: R03, R08, R16, R21, R33 y R35.

---

## Los verbos que se rechazaron

| Verbo descartado | Elegido | Por qué |
|---|---|---|
| `CATEDRA` **tiene** `SESION` | **se dicta en** | *Tener* es vacío. Aquí cabía, pero *se dicta en* dice qué ocurre |
| `SESION` **tiene** `ENLACE` | **se difunde mediante** | Nombra el propósito del enlace |
| `ASISTENTE` **tiene** `REGISTRO` | **se registra en** | Pone al asistente como sujeto de la acción |
| `LOTE` **tiene** `DETALLE` | **migra** | El verbo revela para qué existe la tabla |
| `ASISTENTE` **posee** `DOCUMENTO` | **se identifica con** | *Poseer* sugiere propiedad; lo que importa es que sirve para identificarse |

---

**Anterior:** [08 · Atributos](08-Atributos-del-Proyecto.md) · **Siguiente:** [10 · Diagramas](10-Diagramas-MER.md)
