# Investigación — Versión 1: decisiones y descartes

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

> **Ojo con la numeración, que hay dos series.** Las decisiones de ESTE
> documento son las **del proyecto** y se numeran `D-v1-1` a `D-v1-8`. Las que
> aparecen en
> [`0_historias_de_usuario.md`](../../0_historias_de_usuario.md) como `[D1]` a
> `[D17]` son otras: son **las decisiones de la reunión de levantamiento**, y
> viven en
> [`material_dado/PLAN-BD-CATEDRAS-ABIERTAS.md`](../../../../material_dado/PLAN-BD-CATEDRAS-ABIERTAS.md).
>
> Se distinguen a propósito. Las de la reunión **las dijo el usuario** y no son
> nuestras para renumerar; las de aquí **las tomamos nosotros** al construir.
> Confundirlas sería atribuirle al director decisiones técnicas que no tomó.

---

## D-v1-1 — El front en OTRO lenguaje que la API

**Alternativas:** el front en C# también (Razor Pages o Blazor) · el front en
Python con Flask.

**Se eligió Flask, y la razón no es técnica: es que se pueda comprobar.**

Todo el curso repite que las capas están separadas y que el front solo habla
por HTTP. Con front y API en el mismo lenguaje, eso hay que creerlo: siempre
queda la duda de si en algún punto se comparte una clase, un modelo o una
librería. **Con dos lenguajes distintos, compartir algo es imposible** — y la
afirmación pasa de ser una promesa a ser un hecho verificable.

**Lo que cuesta:** dos stacks que instalar (los resuelve Docker), dos formas
de escribir el código en el mismo repositorio, y que nadie pueda "reutilizar"
un modelo del back en el front. **Los tres precios están bien pagados**, y el
tercero no es un costo: es la garantía.

**Cómo se sabe que la decisión aguanta:** el criterio 8. Con la API apagada, el
front carga y no tiene datos. Si algún día mostrara datos con la API caída,
sería porque encontró otro camino — y ese camino no debería existir.

## D-v1-2 — Dapper con Npgsql, no un ORM

**Alternativas:** Entity Framework Core · Dapper · ADO.NET a pelo.

**Se eligió Dapper.** Un ORM escribiría el SQL por nosotros, y ver ese SQL es
el punto del curso: la consulta está escrita en el repositorio, se lee, se
copia a pgAdmin y se ejecuta igual. ADO.NET a pelo obligaría a mapear cada
columna a mano, que es ruido sin lección.

**Lo que se pierde:** migraciones automáticas y mapeo de relaciones. **No hace
falta**: la base viene dada (Artículo 5).

## D-v1-3 — Los datos reales NO se publican

**Alternativas:** publicar el bloque de carga tal cual · publicarlo con los
nombres cambiados · quitarlo y poner datos inventados.

**Se descartaron las dos primeras.** La primera es un problema de protección
de datos: 14.808 personas identificadas y 15.517 números de documento en un
repositorio público. La segunda —"anonimizar"— suena razonable y es peor de lo
que parece: un archivo con los nombres cambiados pero los mismos códigos,
programas y fechas de asistencia **sigue permitiendo reidentificar** a la
gente, y además da una falsa sensación de que el problema está resuelto.

**Se quitó el bloque y se pusieron cinco registros inventados.** Y se quitaron
**los datos, no el mecanismo**: las tablas de paso, el procedimiento de carga
y las tablas de lote y novedad siguen en la base, se pueden leer y se pueden
ejercitar con datos propios.

> **Esto no es una decisión técnica disfrazada de ética.** Es la clase de
> decisión que aparece de verdad al montar un ejemplo sobre un sistema real, y
> por eso está escrita aquí y no en la cabeza de nadie.

## D-v1-4 — Pocos datos hipotéticos, no muchos

**Alternativa:** generar 15.000 filas sintéticas para que la base "se sienta
real".

**Se descartó.** Un catálogo de 15.000 filas no enseña nada que no enseñen
cinco, y a cambio hace lento cada `docker compose up -d --build` — que es el
comando que un estudiante corre veinte veces en una tarde.

Cinco asistentes, dos cátedras y cuatro sesiones alcanzan para que el sistema
tenga algo que mostrar y para que las versiones siguientes tengan sobre qué
trabajar.

## D-v1-5 — `sede` como tabla de la v1

**Alternativas:** `registro_asistencia`, que es la más grande · `encuesta`,
la más rica en tipos · `sede`.

**Se eligió `sede`**, y no por ser la más fácil. `registro_asistencia` tiene
cinco claves foráneas y es el corazón del sistema: empezar ahí obligaría a
tocar media base en la primera versión. `encuesta` tiene la llave generada por
la base y un `UNIQUE` compuesto, que son buenos temas — pero para después.

`sede` tiene, en cinco campos, **tres cosas que enseñan**:

1. Un **campo opcional** de verdad: la sede virtual no tiene dirección.
2. Un **booleano** nativo del motor, que en el JSON sale como `true`/`false`.
3. **Dos** restricciones de unicidad distintas —la llave primaria y el nombre—
   que dan **dos 500 por motivos diferentes**, en la misma pantalla.

Y encima **viene con tres filas sembradas** por el script dado, así que el
listado no arranca vacío y el front tiene qué mostrar desde el primer arranque.

## D-v1-6 — El nombre repetido lo defiende la BASE, no la API

**Alternativa:** comprobar en el servicio si el nombre ya existe, y responder
un 409 amable.

**Se descartó.** Esa comprobación tendría que hacer una consulta antes de
insertar, y entre las dos cabe otra petición que inserte el mismo nombre: el
409 quedaría bonito y la restricción se violaría igual. **La base es el único
sitio donde esa regla se puede cumplir de verdad**, porque es el único que ve
todas las escrituras a la vez.

**Lo que cuesta:** el usuario recibe un 500 con un mensaje del motor en vez de
un 409 con una frase amable. Se acepta en la v1, y queda anotado: traducir ese
error a un 409 es posible **leyendo el código `23505` de Npgsql**, y será una
decisión de una versión posterior — no algo que se metió antes por si acaso.

## D-v1-7 — La marca va en un archivo aparte, y el logo NO va

**Alternativas para los colores y las fuentes:** elegirlos por criterio propio
(«un azul institucional se ve bien») · ponerlos entre los demás estilos ·
sacarlos del Manual de Identidad Visual Corporativa y **aislarlos**.

**Se eligió la tercera.** La primera está descartada de entrada: el manual dice
*«por ningún motivo se deben cambiar los colores corporativos»*, así que no hay
nada que elegir. La segunda —dejarlos junto a los demás estilos— es la que se
descartó con argumento: **mezclados, un valor de marca parece una preferencia
de diseño**, y el que venga después los va a «mejorar» de buena fe.

Aislados en `marca.css` la distinción es visible en la estructura: **ahí van
los valores que fija el manual, y en `estilos.css` va cómo se usan**. El día
que la Universidad actualice su manual, se cambia un archivo.

**Y el logosímbolo:** se consideró extraerlo del PDF y se descartó.

| Se intentó | Qué salió |
|---|---|
| Buscar el logo como imagen dentro del PDF | Las 17 imágenes del manual son **fotos de campus**. El logosímbolo está dibujado en vectores, no incrustado |
| Rasterizar la página y recortarlo | Daría un logo con **proporciones aproximadas, márgenes arbitrarios y calidad indeterminada** — que es exactamente lo que la sección de *usos incorrectos* del propio manual prohíbe |

**Así que no hay archivo de logo, y eso está dicho** en lugar de disimulado. La
cabecera **reserva su sitio** respetando el tamaño mínimo en pantalla (93,2 ×
28,3 px) y el área de reserva que el manual exige, y el archivo oficial lo
entrega Comunicaciones.

> **La decisión de fondo:** ante una regla que no se puede cumplir del todo,
> **cumplir la parte que sí y declarar la que no** es mejor que aproximarla.
> Un logo casi bien es un incumplimiento que nadie va a revisar; un sitio
> reservado con una nota es una tarea pendiente que se ve.

## D-v1-8 — El opcional en blanco se envía nulo

**Alternativa:** enviar la cadena vacía y que la base la guarde así.

**Se descartó** porque `''` y `NULL` no son lo mismo, y la diferencia se ve:
una sede virtual con dirección `''` parece tener una dirección que nadie
escribió. Es comprobable (criterio 4).
