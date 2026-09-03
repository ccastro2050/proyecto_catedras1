# 1 · Entidad

---

## Definición

> **Una entidad es un objeto de estudio del que necesitamos guardar información para poder consultarla después.**

Es la definición que dio el profesor Carlos Castro en `5:44`, y conviene citarla completa porque trae dentro el criterio de decisión:

> *«Cada entidad representa un solo objeto de estudio. ¿A qué se refiere objeto de estudio? Que es la información que vamos a guardar para después consultar. O sea, si nosotros guardamos información es con la idea de consultarla luego. Mira qué sentido común.»*

Las tres partes de esa frase son tres pruebas distintas:

| Parte de la frase | Prueba que impone |
|---|---|
| *«un solo objeto de estudio»* | **Prueba de unidad.** Si la cosa se parte en dos ideas distintas, son dos entidades |
| *«información que vamos a guardar»* | **Prueba de persistencia.** Si no hay nada que guardar, no es entidad |
| *«para después consultar»* | **Prueba de utilidad.** Si nadie va a preguntar nunca por ella, sobra |

En el diagrama de Chen la entidad se dibuja como un **rectángulo**.

---

## Cómo se distingue una entidad de otra: el identificador

No basta con nombrar la entidad. Hay que decir **cómo se distingue un ejemplar de otro**. El profesor Carlos Castro lo pidió en `5:59` y en `6:53`:

> *«Hay que identificar qué atributos necesitamos… y cuál de esos atributos es el identificador. Por ejemplo, aquí dice que el identificador del autor es el código.»*
> *«El código es el identificador, el que está subrayado.»*

**En Chen, el identificador va subrayado.** Una entidad sin identificador declarado está incompleta, aunque tenga veinte atributos.

---

## El ejemplo con el que se explicó

El profesor Carlos Castro usó un modelo de biblioteca. Vale la pena conservarlo porque es el vocabulario compartido de la reunión:

| Entidad | Por qué es entidad | Identificador |
|---|---|---|
| `AUTOR` | Persona que escribe. Tiene datos propios y se consulta por ella | `codigo` |
| `LIBRO` | La obra. Cinco atributos, entre ellos título, ISBN y editorial | `codigo` |
| `EJEMPLAR` | **La copia física.** No es lo mismo que el libro | identificador propio |
| `USUARIO` | Quien presta | `codigo` |

> **La lección está en `LIBRO` contra `EJEMPLAR`.** Son dos entidades, no una. *El Quijote* es un libro; los cuatro tomos que hay en el estante son cuatro ejemplares. Confundirlos hace imposible saber cuál está prestado. **Esta distinción reaparece exactamente igual en nuestro proyecto**, entre `CATEDRA` y `SESION`.

Cuando el profesor Carlos Castro preguntó a qué se parecía el modelo, profesor Hugo Nelson respondió *«a una editorial»*, y después, al ver `EJEMPLAR`, corrigió: *«entonces biblioteca, sí»* (`6:39`). **El modelo se reconoce solo.** Ese es el estándar de calidad: si alguien lo lee sin conocer el negocio y adivina de qué se trata, está bien hecho.

---

## Las cuatro pruebas para decidir si algo es entidad

Aplicadas en el orden en que ahorran trabajo.

### 1 · ¿Tiene atributos propios?

Si lo único que se guarda es el nombre, probablemente es un **atributo** de otra cosa, no una entidad.

- La `modalidad` de una sesión parecía un simple texto. **Es entidad** porque tiene un atributo propio que decide el comportamiento del sistema: el canal de difusión — QR si es presencial, enlace si es virtual (`1:06:53`).
- El `celular` del asistente no tiene nada propio. **Es atributo.**

### 2 · ¿Se consulta por ella?

Si ningún informe agrupa, filtra ni ordena por esa cosa, no es entidad.

- La `SEDE` **es entidad** porque el profesor Hugo Nelson necesita saber cuántos asistieron en San Benito, en Bello y en la virtual, y porque son lo que distingue dos cátedras a la misma hora (`1:03:33`).

### 3 · ¿Puede existir por sí sola, o necesita a otra para tener sentido?

Si necesita a otra, sigue siendo entidad, pero es **débil**: su identificador incluye el de aquella.

- `SESION` **no existe sin** `CATEDRA`. La reunión número 3 no significa nada suelta: es la reunión 3 *de un evento*. Es entidad débil.

### 4 · ¿Cambia con el tiempo de una manera que hay que recordar?

Si sí, casi siempre aparece una entidad o una relación con fecha que no se había visto.

- La `VINCULACION` de una persona cambia: estudiante hoy, egresado mañana, estudiante de posgrado pasado mañana. Guardarla como una columna que se sobrescribe **pierde el histórico**, y con él la posibilidad de decir con qué vinculación asistió a una cátedra de hace dos años.

---

## Entidad frente a atributo: los tres casos que costaron discusión

| Candidato | Decisión | Por qué |
|---|---|---|
| `NumeroIdentidad` | **Entidad** (`DOCUMENTO_ASISTENTE`) | En los datos reales, **707 personas tienen más de un número de documento**. Como atributo solo cabe uno. Ver [03 · multivaluados](03-Tipos-de-Atributos.md) |
| `Codigoprograma` | **Relación con atributos** | Una persona puede estar en varios programas a la vez, y eso cambia por periodo. No es un dato del asistente: es un hecho entre dos entidades |
| `correo institucional` y `correo personal` | **Atributos**, no entidad | Son dos, están acotados, y no se consulta *por correo* como categoría. Si mañana hubiera *n* correos por persona, se convertiría en entidad |

---

## Lo que **no** es entidad en este proyecto

Vale tanto como la lista de las que sí. Declararlo evita que alguien lo proponga de nuevo en la sustentación.

| Descartado | Por qué no |
|---|---|
| **El QR y la URL como entidades separadas** | Son **dos presentaciones del mismo enlace**. El token es uno; lo que cambia es cómo se entrega. Separarlos duplicaría la ventana horaria y permitiría que se contradijeran |
| **El archivo plano** | Es la **salida** de una consulta, no un objeto de estudio. Lo que sí es entidad es el **lote** en que se envió y su resultado |
| **«Estudiante», «Docente» y «Externo» como entidades** | Son **valores** de un catálogo de vinculación. Habilitar un cuarto tipo debe ser un `INSERT`, no un `CREATE TABLE` |
| **El correo enviado** | Lo que importa no es el mensaje, sino **la clave que iba dentro**: cuándo se generó, a qué dirección, cuándo se usó |
| **La imagen corporativa** | Es un recurso de presentación. No se consulta por ella |
| **El «formulario»** | No es una cosa del negocio: es la pantalla. Lo que se guarda es el **registro** que produce |

---

## Cómo se documenta cada entidad

El profesor Carlos Castro fue explícito en `24:21` y en `24:59`:

> *«Al frente de asistente describamos qué es, hagamos una descripción qué es un asistente.»*
> *«En la medida en que vaya cambiando la definición, vamos ajustando este archivito.»*

De ahí salen dos reglas de esta carpeta:

1. **Toda entidad lleva descripción escrita en prosa**, no solo nombre.
2. **La descripción es un documento vivo.** Cuando el entendimiento cambia, se actualiza — y se actualiza también el archivo `Cätedras abiertas DIagrama Entidad -relación.xlsx`, que es donde el usuario experto lo lee.

---

**Siguiente:** [02 · Atributo](02-Atributo.md) · **Aplicación:** [07 · Entidades del proyecto](07-Entidades-del-Proyecto.md)
