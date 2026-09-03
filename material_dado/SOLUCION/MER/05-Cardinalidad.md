# 5 · Cardinalidad

---

## Definición

> **La cardinalidad responde a una sola pregunta: ¿cuántas?**
>
> Dado un ejemplar de una entidad, ¿con cuántos ejemplares de la otra puede estar asociado?

Tres respuestas posibles: `1:1`, `1:N`, `N:M`.

---

## La lección de la reunión, entera

El profesor Carlos Castro la explicó con la biblioteca entre `7:59` y `9:11`, y el tramo incluye **una equivocación del profesor Hugo Nelson que es exactamente el error que todo el mundo comete**. Vale la pena reconstruirlo completo.

### `N:M` — autor y libro

> *«La relación entre autor y libro es muchos a muchos. Un autor puede escribir muchos libros y un libro puede ser escrito por muchos autores.»* — `7:59`

Las dos frases son simétricas. Cuando las dos direcciones admiten «muchos», es `N:M`.

### `1:N` — libro y ejemplar

> *«Un libro tiene muchos ejemplares, pero un ejemplar es de un solo libro.»* — `8:13`
> *«Exacto, no puede ser el ejemplar de varios libros.»* — `8:23`

Aquí aparece el **«pero»**. Una dirección admite muchos, la otra no. Eso es `1:N`.

### El error, y la corrección

En `8:59` el profesor Hugo Nelson resume y se equivoca:

> El profesor Hugo Nelson: *«¿Entonces sería autor a libro muchos a muchos, cierto, libro a ejemplar sería muchos a uno?»*
> El profesor Carlos Castro: *«No… libro a ejemplar, uno a muchos. Un libro puede tener muchos ejemplares.»* — `9:11`

**¿Por qué importa si «muchos a uno» y «uno a muchos» describen la misma realidad?** Porque la cardinalidad **se lee en el orden en que se nombran las entidades**. Si se escribe `LIBRO — 1:N — EJEMPLAR`, se está diciendo que del libro salen muchos ejemplares. Si se escribe `LIBRO — N:1 — EJEMPLAR`, se está diciendo lo contrario: que muchos libros van a un ejemplar. **Y esa es la que decide dónde va la clave foránea al transformar.**

Ponerla al revés produce un modelo que compila, se carga, y **guarda mentiras**.

> **La regla que evita el error:** léala siempre como dos frases completas, en voz alta, empezando por «un». *Un libro tiene muchos ejemplares. Un ejemplar es de un solo libro.* La primera frase da el lado izquierdo; la segunda, el derecho.

### El caso que parecía `N:M` y traía historia dentro

En `8:28` el profesor Carlos Castro añade algo que en este proyecto reaparece:

> *«Entre usuario y ejemplar es muchos a muchos. Un usuario puede sacar muchos ejemplares, y un ejemplar puede ser sacado por muchos usuarios. Puede ser que en el mismo momento no —vos y yo no podemos ir a la biblioteca y sacar en el mismo momento el mismo ejemplar—, pero sí lo podemos sacar en fechas diferentes. **Esos son asuntos históricos.**»*

Es la observación más fina de toda la reunión. La relación es `N:M` **a lo largo del tiempo**, pero en un instante dado está restringida a uno. La cardinalidad sola no lo expresa: hace falta la fecha en el identificador.

**En este modelo eso ocurre tres veces:** vinculación del asistente, rol del usuario y enlace vigente de una sesión.

---

## Las tres cardinalidades en este proyecto

### `1:1` — dos

| Relación | Las dos frases |
|---|---|
| `REGISTRO_ASISTENCIA — es evaluado en — RESPUESTA_ENCUESTA` | Un registro se evalúa en **a lo sumo una** encuesta. Una respuesta de encuesta corresponde a **un solo** registro |
| `ASISTENTE — opera como — USUARIO` | Un asistente puede ser **a lo sumo un** usuario del sistema. Un usuario es **una sola** persona |

> **`1:1` casi siempre es sospechoso.** Si dos entidades están en `1:1` obligatorio por los dos lados, suelen ser la misma entidad partida sin razón. Las dos de arriba sobreviven porque **son opcionales de un lado**: la mayoría de registros no tienen encuesta y la inmensa mayoría de asistentes no son usuarios administradores.

### `1:N` — veintiuna

Las principales:

| Relación | Las dos frases |
|---|---|
| `CATEDRA — se dicta en — SESION` | Una cátedra se dicta en **muchas** sesiones. Una sesión es de **una sola** cátedra |
| `SESION — se difunde mediante — ENLACE_REGISTRO` | Una sesión puede difundirse por **varios** enlaces a lo largo del tiempo. Un enlace pertenece a **una sola** sesión |
| `SEDE — aloja — SESION` | Una sede aloja **muchas** sesiones. Una sesión ocurre en **una sola** sede |
| `FACULTAD — agrupa — PROGRAMA_ACADEMICO` | Una facultad agrupa **muchos** programas. Un programa es de **una sola** facultad |
| `LOTE_CARGA — produce — NOVEDAD_CARGA` | Un lote produce **muchas** novedades. Una novedad es de **un solo** lote |
| `ENCUESTA — se compone de — PREGUNTA` | Una encuesta tiene **muchas** preguntas. Una pregunta es de **una sola** encuesta |

### `N:M` — seis

Son exactamente las seis que llevan atributos, y son las que se vuelven tabla:

| Relación | Las dos frases | Atributos |
|---|---|---|
| `ASISTENTE — cursa — PROGRAMA_ACADEMICO` | Un asistente cursa **varios** programas. Un programa es cursado por **muchos** asistentes | periodo, estado |
| `ASISTENTE — se vincula como — TIPO_VINCULACION` | Un asistente tiene **varias** vinculaciones en el tiempo. Un tipo agrupa **muchos** asistentes | **fecha_ini**, fecha_fin |
| **`ASISTENTE — se registra en — SESION`** | Un asistente se registra en **muchas** sesiones. Una sesión recibe **muchos** asistentes | instante, instantáneas, origen |
| `ASISTENTE — expone en — SESION` | Un ponente expone en **varias** sesiones. Una sesión tiene **varios** ponentes | rol |
| `USUARIO — desempeña — ROL` | Un usuario desempeña **varios** roles en el tiempo. Un rol lo tienen **varios** usuarios | **fecha_ini**, fecha_fin |
| `LOTE_MIGRACION — migra — REGISTRO_ASISTENCIA` | Un lote migra **muchos** registros. Un registro puede intentarse en **varios** lotes | lo enviado, resultado |

> **`ASISTENTE — cursa — PROGRAMA` es `N:M` por dato comprobado**, no por prudencia: en el maestro del ASIS el mismo ID aparece con **varios códigos de programa**. Y el profesor Carlos Castro dio el caso él mismo en `50:07`: *«si yo vuelvo a estudiar un doctorado en la universidad, ¿cómo me registran las cátedras si estoy registrado en ingeniería de datos?»*.

---

## La cardinalidad que hubo que verificar contra el dato

`CATEDRA — se dicta en — SESION` es `1:N`. Pero *¿cuántas sesiones puede tener realmente una cátedra?* De eso depende el tipo del consecutivo.

| Medida sobre `USBME_LCONTROL_CATEDRAS` | Valor |
|---|---:|
| Filas | 5.711 |
| Eventos distintos | 5.496 |
| **Máximo de reuniones en un evento** | **59** |
| Eventos con una sola reunión | ~95 % |

**El caso normal es una sola reunión; el extremo son 59.** Eso confirma que el consecutivo cabe de sobra en un entero pequeño, y que la estructura `CATEDRA` → `SESION` no es sobreingeniería: hay eventos con decenas de sesiones y el número de reunión los distingue.

---

## El error de cardinalidad que este proyecto podía cometer

**Modelar `ASISTENTE — se registra en — CATEDRA` en vez de en `SESION`.**

Parece inofensivo y destruye el sistema:

- El archivo plano del ASIS exige **el número de reunión** (`32:34`). Sin sesión no hay reunión que enviar.
- Una cátedra con 59 reuniones tendría a la misma persona registrada 59 veces sin poder distinguir a cuál asistió.
- El informe de evaluación no podría comparar dos sesiones de la misma cátedra.

Es el equivalente exacto de confundir `LIBRO` con `EJEMPLAR`.

---

**Anterior:** [04 · Relación](04-Relacion.md) · **Siguiente:** [06 · Opcionalidad](06-Opcionalidad-y-Participacion.md)
