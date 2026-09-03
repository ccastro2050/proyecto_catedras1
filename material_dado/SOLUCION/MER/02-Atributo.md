# 2 · Atributo

---

## Definición

> **Un atributo es una propiedad que describe a una entidad y que no tiene existencia propia fuera de ella.**

En Chen se dibuja como un **óvalo** colgando del rectángulo de la entidad. El profesor Carlos Castro lo señaló en `5:03`, cuando el profesor Hugo Nelson describió lo que veía en pantalla: *«lo que está en el óvalo está muy pequeño… veo el rectángulo, veo el rombo»*. Rectángulo, óvalo y rombo son los tres símbolos que hay que saber leer.

---

## La pregunta que decide

**¿Esto describe a la cosa, o es otra cosa?**

Suena trivial y es donde se pierden los modelos. La prueba práctica tiene tres pasos:

1. **¿Cabe uno solo?** Si caben varios, no es atributo simple: es multivaluado, y casi siempre acaba siendo entidad.
2. **¿Tiene datos propios?** Si además del valor hay que guardar cuándo empezó, quién lo puso o si está vigente, no es atributo: es entidad o relación.
3. **¿Se consulta por él como categoría?** Si los informes agrupan por él, conviene que sea entidad para tener un catálogo controlado.

---

## El ejemplo de la reunión

El profesor Carlos Castro recorrió los atributos de `LIBRO` en `6:44`:

> *«Libro tiene uno, dos, tres, cuatro, cinco atributos. El código es el identificador, el que está subrayado. Título, ISBN, editorial.»*

Fíjese en `editorial`. Ahí hay una decisión escondida y sin declarar: **la editorial es un atributo de texto o es una entidad**. En ese modelo se resolvió como atributo. Si mañana hiciera falta la dirección de la editorial o su NIT, dejaría de servir. **No hay respuesta correcta; hay respuesta declarada.**

Es exactamente el mismo dilema que aquí resolvimos al revés con `SEDE`: empezó pareciendo un texto de la sesión y terminó siendo entidad, porque los informes agrupan por ella.

---

## Los atributos que dictó el usuario experto

La construcción del archivo de entidades, entre `25:31` y `35:14`, es un ejemplo de libro de cómo se levantan atributos. Vale la pena reconstruirla:

| Momento | Qué pasó | Lección |
|---|---|---|
| `25:35` | *«¿Cuáles serían los atributos de asistente, los que sí o sí se tengan que manejar, obligatorios?»* | Se pregunta primero por **los obligatorios**. La opcionalidad se decide desde el principio, no al final |
| `25:46` | profesor Hugo Nelson: *«El ID»*. Y enseguida: *«incluso, ese es el identificador»* | El usuario experto **sabe cuál es el identificador**. Hay que preguntárselo |
| `26:26` | *«¿Qué es el ID? Describámoslo.»* | Todo atributo lleva descripción |
| `26:38` | profesor Carlos Castro propone: *«puede ser un carnet, un código, una cédula»* | **La propuesta era incorrecta**, y el usuario la corrigió |
| `26:46` | profesor Hugo Nelson: *«No, solamente es el código de identificación en el sistema ASIS»* | El experto manda sobre el dominio |
| `27:24` | profesor Carlos Castro: *«Debe estar registrado en ASIS; eso es importante porque esa es una restricción»* | Un atributo puede traer **una regla del negocio pegada** |
| `33:21` | *«¿Siempre son cuántos dígitos?»* | Todo atributo necesita **dominio y longitud** |
| `33:36` | profesor Hugo Nelson: *«es variable, hay unos que son como 6 dígitos»* → *«pongámosle un tope»* → *«máximo 10»* | El tope se fijó **a ojo**. Ver la advertencia de abajo |
| `34:10` | *«Ni en descripción ni en número de identidad: sin espacios y sin tildes»* | Convención de nombres, obligatoria |
| `35:06` | *«Código programa, póngale todo pegado»* | De ahí sale `Codigoprograma` |

> ### La lección más cara de esa sesión
>
> El tope de **10 dígitos** para el ID se fijó por acuerdo verbal, sin mirar el dato. Al perfilar el archivo real aparecieron **9.553 filas de 11 caracteres** y valores **alfanuméricos** como `1000513C`. Un modelo construido sobre ese acuerdo habría rechazado más de la mitad del maestro en la primera carga.
>
> **Un atributo no se dimensiona por consenso: se dimensiona midiendo el dato.** El dominio corregido está en [08 · Atributos del proyecto](08-Atributos-del-Proyecto.md).

---

## Atributo de entidad frente a atributo de relación

Un atributo puede colgar de un **rombo**, no solo de un rectángulo. Y eso decide si la relación se vuelve tabla.

| Atributo | ¿De quién es? | Por qué |
|---|---|---|
| `nombres` | De `ASISTENTE` | Describe a la persona, exista o no una cátedra |
| `fecha_ini` de una vinculación | **De la relación** entre asistente y tipo de vinculación | No es propiedad de la persona ni del catálogo: es de la unión de ambos |
| `registrado_en` | **De la relación** entre asistente y sesión | El instante del registro no pertenece ni a uno ni a la otra |
| `numero_reunion` | De `SESION` | La sesión es entidad propia, no una relación |

**Regla práctica:** si al quitar una de las dos entidades el atributo pierde sentido, el atributo es de la relación.

---

## Nulos que significan algo

Un atributo opcional deja un hueco, y el hueco **comunica**. Hay que declarar qué comunica cada uno, porque si no, cada programador inventará su interpretación.

| Atributo | Qué significa que esté vacío | De dónde sale |
|---|---|---|
| `Codigoprograma` | La persona pertenece a una vinculación **que no exige programa** — hoy, Rutas de Paz | `41:16` |
| `correo_institucional` | La persona **no tiene** correo de la universidad. Es el caso de Rutas de Paz | `53:42` |
| `id_asis` | Es un **externo** que no está en el maestro del ASIS. Nunca migrará | §3.1 del plan |
| `fecha_fin` de una vinculación | La vinculación **sigue vigente** | Convención |
| `usado_en` de una clave | La clave **no se ha usado**. Si además ya expiró, es un intento abandonado | Convención |

> **Un nulo sin significado declarado es un defecto de modelado**, no una comodidad. Los cinco de arriba están declarados; cualquier otro nulo del modelo hay que justificarlo o eliminarlo.

---

## Datos personales

Cuatro atributos de este modelo son datos personales bajo la Ley 1581 de 2012: `numero` del documento, `nombres`, `apellidos` y los dos correos. Eso tiene tres consecuencias en el conceptual, no en el físico:

1. Existe una entidad `CONSENTIMIENTO_DATOS` porque **el consentimiento es un hecho que se guarda**, no un aviso de pantalla.
2. Ningún atributo guarda una **clave en claro**. La clave que se envía al correo se guarda cifrada, y por eso el atributo se llama `clave_hash` y no `clave`.
3. El nombre entra al modelo por una razón operativa declarada —**los homónimos**, `52:54`— y no por completitud.

---

**Anterior:** [01 · Entidad](01-Entidad.md) · **Siguiente:** [03 · Tipos de atributos](03-Tipos-de-Atributos.md)
