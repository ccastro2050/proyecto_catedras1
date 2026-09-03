# 4 · Relación

---

## Definición

> **Una relación es una asociación entre entidades. Se nombra con un verbo, porque una relación es una acción.**

Es literal del profesor Carlos Castro, `7:22`:

> *«Estos rombos son las relaciones, que son acciones. Es decir, por ejemplo, el autor escribe libros. Entonces la idea es que esas relaciones sean verbos.»*

En Chen se dibuja como un **rombo** entre los rectángulos.

---

## La regla del verbo, y su excepción declarada

El profesor Carlos Castro la dio completa en `7:34`, con la excepción incluida:

> *«Lo más parecidos posibles a la realidad. La idea es no usar verbos como haber o tener, pero en ocasiones cuadra bien, como en este caso cuadra bien: un libro tiene ejemplares.»*

Esto tiene dos partes y las dos son instrucciones:

1. **Evitar *haber* y *tener*.** Son verbos vacíos: no dicen qué pasa entre las dos cosas. `AUTOR — tiene — LIBRO` no informa; `AUTOR — escribe — LIBRO` sí.
2. **Pero no ser dogmático.** *Tener* vale cuando la relación **es** de composición y no hay verbo mejor. `LIBRO — tiene — EJEMPLAR` es correcta porque el ejemplar no hace nada: simplemente forma parte.

### Cómo se aplicó aquí

| Mala | Buena | Por qué |
|---|---|---|
| `ASISTENTE — tiene — REGISTRO` | **`ASISTENTE — se registra en — SESION`** | Dice qué ocurre, y quién lo hace |
| `SESION — tiene — ENLACE` | **`SESION — se difunde mediante — ENLACE`** | Nombra el propósito del enlace |
| `ASISTENTE — tiene — CLAVE` | **`SISTEMA — envía — CLAVE — a — ASISTENTE`** | Hace visible que hay un envío, que es lo que se audita |
| `CATEDRA — tiene — SESION` | **`CATEDRA — se dicta en — SESION`** | — pero *tiene* también valdría: es composición pura |
| `LOTE — tiene — DETALLE` | **`LOTE — migra — REGISTRO`** | El verbo revela para qué existe la tabla |

> **La prueba del verbo.** Si al leer el rombo en voz alta no se entiende qué pasa en el negocio, el verbo está mal elegido. Un modelo bien nombrado **se lee como frases**, y por eso el profesor Hugo Nelson pudo reconocer «biblioteca» sin que se lo dijeran.

---

## Cómo se lee una relación: las dos frases

Una relación se lee **en las dos direcciones**, y las dos frases deben ser ciertas. El profesor Carlos Castro lo hizo así todo el tiempo:

> *«Un autor puede escribir muchos libros y un libro puede ser escrito por muchos autores.»* — `7:59`
> *«Un libro tiene muchos ejemplares, pero un ejemplar es de un solo libro.»* — `8:13`

Fíjese en el **«pero»**. Ese «pero» es donde vive la cardinalidad: marca que las dos direcciones **no** son simétricas.

**En esta carpeta, toda relación se documenta con sus dos frases.** Están en [09 · Relaciones del proyecto](09-Relaciones-del-Proyecto.md).

---

## Grado de una relación

| Grado | Qué es | En este modelo |
|---|---|---|
| **Binaria** | Entre dos entidades | 32 de las 34 |
| **Reflexiva** | Una entidad consigo misma | **2**: la jerarquía de `FACULTAD` y la de `DEPENDENCIA` |
| **Ternaria** | Entre tres | **Ninguna** — ver abajo |

### Las relaciones reflexivas

Una facultad puede estar dentro de otra; una dependencia también. Se dibujan como un rombo que sale de la entidad y vuelve a ella, **con los dos extremos etiquetados con roles distintos** —«es padre de» y «depende de»—, porque si no, el diagrama es ilegible.

Producen un **árbol**, no un grafo: cada nodo tiene un solo padre. Eso importa porque un árbol se resuelve con una columna en la misma tabla, y un grafo necesitaría tabla aparte. Al consultarlo hace falta recursión.

### Por qué no hay ninguna ternaria

Había una candidata: *un asistente se registra en una sesión con un programa*. Tres entidades en un mismo hecho.

**Se descartó, y hay que poder defender por qué.** Una relación ternaria afirma que las tres participan **simultánea e inseparablemente**. Aquí no es el caso: el programa **no es un participante del acto de registrarse**, es una **propiedad del asistente en ese instante** que se copia al registro. La prueba: un asistente de Rutas de Paz se registra **sin programa** (`41:16`), y la relación sigue existiendo. En una ternaria verdadera, quitar un participante destruye el hecho.

→ Es una relación **binaria** `ASISTENTE — se registra en — SESION`, con el programa como **atributo de la relación**.

---

## Relaciones con atributos

Cuando el hecho de asociarse tiene datos propios, esos datos cuelgan del **rombo**. Y esa es la señal de que al transformar habrá una tabla nueva.

Este modelo tiene **seis**:

| Relación | Atributos del rombo | Por qué son del rombo |
|---|---|---|
| `ASISTENTE — cursa — PROGRAMA` | `periodo`, `estado` | El periodo no es de la persona ni del programa: es de la matrícula |
| `ASISTENTE — se vincula como — TIPO_VINCULACION` | **`fecha_ini`**, `fecha_fin` | La fecha en que empezó a ser estudiante no es un dato del catálogo |
| `ASISTENTE — se registra en — SESION` | `registrado_en`, programa e instantánea de vinculación, origen, IP | El instante del registro no pertenece a ninguna de las dos |
| `ASISTENTE — participa como ponente en — SESION` | `rol` | Puede ser ponente o moderador |
| `USUARIO — desempeña — ROL` | **`fecha_ini`**, `fecha_fin` | Igual que la vinculación |
| `LOTE_MIGRACION — migra — REGISTRO` | `id_asis_enviado`, `programa_enviado`, `resultado`, `mensaje` | **Lo que se envió**, que puede diferir de lo que hoy dice la tabla |

> ### La `fecha_ini` dentro del identificador
>
> Dos de esas seis relaciones llevan `fecha_ini` **dentro del identificador**, no como atributo suelto. La razón:
>
> Sin ella, el identificador sería el par (asistente, tipo de vinculación). Eso significa que **una persona no podría volver a tener una vinculación que ya tuvo**. Un egresado que se matricula en una maestría vuelve a ser estudiante, y el sistema lo rechazaría. Con `fecha_ini` en el identificador, el segundo tramo entra sin problema.
>
> Lo mismo con los roles de usuario: quien fue administrador, dejó de serlo y vuelve, no puede quedar bloqueado.
>
> **Es el error que no falla ruidosamente.** No aparece un mensaje: aparece un `INSERT` rechazado o, peor, un histórico que nunca se pudo escribir y consultas que devuelven vacío sin explicar por qué.

---

## Relaciones identificadoras

Cuando una entidad **débil** depende de otra para existir, la relación que las une es **identificadora**: en Chen se dibuja con doble rombo.

Aquí hay dos:

| Débil | Depende de | Su identificador |
|---|---|---|
| `SESION` | `CATEDRA` | La cátedra **más** el número de reunión |
| `RESPUESTA_ITEM` | `RESPUESTA_ENCUESTA` | La respuesta **más** la pregunta |

`SESION` es el caso de manual: la «reunión 3» no significa nada suelta. Es la reunión 3 **de un evento concreto**, y por eso el consecutivo se reinicia en cada cátedra.

---

## Lo que se descartó

| Relación propuesta | Por qué no |
|---|---|
| `ASISTENTE — pertenece a — SEDE` | Un asistente no es de una sede: **va** a sesiones que ocurren en sedes. La sede es de la sesión |
| `CATEDRA — ocurre en — SEDE` | Va en `SESION`, no en `CATEDRA`. La misma cátedra puede tener una sesión en Bello y otra virtual |
| `ENLACE — genera — CLAVE` | La clave la pide **una persona** sobre un enlace. Sin la persona, el hecho está incompleto |
| `REGISTRO — produce — ARCHIVO_PLANO` | El archivo es una salida, no una entidad. La relación real es con el **lote** |

---

**Anterior:** [03 · Tipos de atributos](03-Tipos-de-Atributos.md) · **Siguiente:** [05 · Cardinalidad](05-Cardinalidad.md)
