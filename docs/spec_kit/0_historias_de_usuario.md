# Historias de usuario — Cátedras Abiertas

**Versión 2.0**

Universidad de San Buenaventura, Medellín

> **Este documento es el `0` del spec kit**, y el número no es decorativo: las
> **necesidades van antes que las reglas**. La constitución dice cómo se
> construye; esto dice para quién y para qué.
>
> | Vecino | Qué contiene |
> |---|---|
> | [`1_constitution.md`](1_constitution.md) | Las reglas permanentes — incluida la identidad visual |
> | [`versiones/0_mapa_versiones.md`](versiones/0_mapa_versiones.md) | En qué versión entra cada historia |
> | [`versiones/v1_sede/2_spec.md`](versiones/v1_sede/2_spec.md) | Los requisitos que salen de las historias 1 a 4 |
>
> La versión en Word, que es la que se entrega, está en la raíz del
> repositorio: `HISTORIAS_DE_USUARIO.docx`. **Se genera desde este archivo**,
> no al contrario: si los dos difieren, manda este.

---

## Historial de Revisiones

| Fecha | Versión | Descripción | Autor | Revisor |
|---|---|---|---|---|
| 03/09/2026 | 1.0 | Primera versión de las historias de usuario del sistema de cátedras abiertas, derivadas del modelo entregado y del ejemplo de referencia de la versión 1 | Equipo del proyecto de aula | Carlos Arturo Castro Castro |
| 03/09/2026 | 1.1 | Se alinea la columna de iteración con el mapa de versiones y con las cuatro versiones que evalúa el curso. Se deja explícito que el proyecto versiona back y front en paralelo | Equipo del proyecto de aula | Carlos Arturo Castro Castro |
| 03/09/2026 | 2.0 | **Reescritura desde la fuente primaria.** Las historias pasan a estar enunciadas por el profesor Hugo Nelson Castañeda, director del CIDEH, con sus citas literales y el minuto de la reunión. Se retiran los usuarios que se habían supuesto. Entran dos historias que estaban en la fuente y faltaban: el archivo plano del ASIS y la excepción de Rutas de Paz | Carlos Arturo Castro Castro | Hugo Nelson Castañeda |

---

## Introducción

Este documento sirve como una guía integral para identificar y definir las historias de usuario esenciales que contribuirán al éxito del proyecto de **Cátedras Abiertas**. A través de esta guía se busca proporcionar una comprensión clara y detallada de las necesidades y expectativas de los usuarios, lo que permitirá a los equipos de desarrollo y gestión alinear sus esfuerzos de manera efectiva. Al seguir las recomendaciones y procesos descritos en este documento, se facilitará la creación de un producto final que cumpla con los objetivos.

### De dónde salen estas historias

**Las enunció el profesor Hugo Nelson Castañeda**, en las reuniones de
levantamiento del proyecto, como usuario experto del proceso.

Tiene **dos papeles a la vez**, y por eso sus historias cubren tanto:

| Como… | Pide… |
|---|---|
| **Director del CIDEH** | Que el proceso funcione: programar cátedras, saber quién asistió, sustentar el alcance ante la Universidad — historias 1 a 5, 8 y 9 |
| **Administrador del sistema** | Que la herramienta se pueda operar: cargar el catálogo, generar el archivo del ASIS, controlar quién entra — historias 2, 7 y 10 |

Que las dos cosas recaigan en la misma persona explica por qué varias
historias mezclan la necesidad del proceso con la del operador: **no son dos
usuarios distintos que hubiera que conciliar, es uno con dos
responsabilidades**.
No son suposiciones de quien programa: son lo que él pidió, y en varios casos
están **citadas textualmente con el minuto de la grabación**.

Esa trazabilidad importa, y conviene decir por qué:

| | |
|---|---|
| **Se puede discutir con la fuente** | Si un criterio parece raro, se va a la cita y se resuelve preguntándole a él — no debatiendo qué habrá querido decir |
| **Se sabe qué es requisito y qué es interpretación** | Lo que está entre comillas lo dijo él. Lo que está en «Observaciones» lo entendimos nosotros, y puede estar mal |
| **Aparece de dónde viene cada tabla** | La sede, el periodo académico y el correo personal **no salieron del modelo**: salieron de tres frases suyas. Están señaladas en cada historia |

Las referencias `[D1]` a `[D17]` remiten a la tabla de decisiones de
[`material_dado/PLAN-BD-CATEDRAS-ABIERTAS.md`](../../material_dado/PLAN-BD-CATEDRAS-ABIERTAS.md),
donde cada una tiene su cita, su minuto y su consecuencia en el modelo.

> **Una sola historia tiene otro usuario, y se dice por qué:** la 6 (el
> registro de la propia asistencia) **la enunció él**, pero el usuario es
> **quien asiste**. Una historia se escribe desde quien la vive, aunque la
> haya pedido otro.
>
> Las **nueve restantes son suyas**, y eso incluye la 10 (el control de
> acceso): **él es el administrador del sistema**, así que cuando pide que
> cada rol vea solo lo suyo, lo pide como quien va a operarlo.

### Cómo se lee una historia

Cada historia es una **tarjeta**: quién la necesita, qué quiere, para qué, y —lo más importante— **cómo se sabrá que quedó lista**. Esa última parte son los criterios de aceptación, y no son una formalidad: son la definición de «terminado». Una historia sin criterios verificables no se puede cerrar, porque nadie puede decir si funciona.

Los criterios están escritos **en el lenguaje del usuario, no del programador**: dicen *«que la sede retirada desaparezca del catálogo»*, no *«que el DELETE haga un UPDATE de activo»*. El cómo es del equipo; el qué es de quien lo necesita.

### Relación con las versiones del proyecto

La columna **Iteración asignada** dice en qué versión entra cada historia. No es un orden arbitrario: sigue el mapa de versiones del proyecto, donde cada versión es una rebanada completa que se puede mostrar y usar.

| Versión | Historias | Qué queda funcionando — **API y pantallas** |
|---|---|---|
| **v1** | 1, 2, 3, 4 | Las tablas sin llave foránea, con sus pantallas. *Este ejemplo construye una: el catálogo de sedes, completo* |
| **v2** | 5, 9 | Todas las demás tablas —cátedras, sesiones y catálogos— con las listas desplegables, y la excepción de Rutas de Paz |
| **v3** | 10 | El ingreso con usuario y el control de acceso por rol |
| **v4** | 6, 7, 8 | El registro de asistencia, **el archivo plano del ASIS** y el informe de externos |

**Este proyecto versiona back y front EN PARALELO.** Cada versión entrega su
parte de la API *y* sus pantallas: no hay una versión "de back" y otra "de
front". La razón, con sus costos, está en el
[mapa de versiones](versiones/0_mapa_versiones.md).

Lo que eso significa para estas historias: **una historia no está cumplida si
el dato se puede consultar por la API pero no se ve en una pantalla.** Sus
criterios de aceptación están escritos así a propósito — hablan de lo que ve
quien usa el sistema, no de lo que responde un endpoint.

> **La versión 1 está construida** y se puede ejecutar: es el ejemplo de referencia de este repositorio. Las historias 1 a 4 tienen sus criterios verificados contra el sistema corriendo, y el detalle técnico está en [`versiones/v1_sede/`](versiones/v1_sede/2_spec.md).

### Nota sobre la imagen corporativa

Varias historias piden que la pantalla cumpla el **Manual de Identidad Visual Corporativa** (Resolución de Rectoría General N.º 404 del 14 de mayo de 2024), que está en la raíz de este repositorio como `Manual-de-Marca.pdf`. En concreto, y sin margen de interpretación:

| Qué | Valor | Fuente |
|---|---|---|
| Naranja institucional | `#EF7D00` | Manual, p. 5 |
| Negro institucional | `#1D1D1B` | Manual, p. 5 |
| Fuentes secundarias autorizadas | **Montserrat** y **Raleway** | Manual, p. 6 |
| Tamaño mínimo del logo en pantalla | 93,2 × 28,3 px (horizontal) | Manual, p. 7 |
| Área de reserva | La altura del texto del propio logosímbolo | Manual, p. 7 |

El manual es explícito: **«por ningún motivo se deben cambiar los colores corporativos»**. En el ejemplo de referencia esos valores están en un archivo aparte —`front_flask/static/marca.css`— precisamente para que sean una restricción y no una preferencia de quien programa.

**El archivo del logosímbolo no está en el repositorio**, y es a propósito: en el manual es un dibujo vectorial, y recortarlo de una página produciría exactamente lo que su sección de *usos incorrectos* prohíbe. El archivo oficial lo entrega Comunicaciones de la Universidad; mientras llega, la pantalla reserva su sitio respetando el tamaño mínimo y el área de reserva.

---

## Historias

### Historia de Usuario 1 — Consulta del catálogo de sedes

| | |
|---|---|
| **Número:** 1 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Consulta del catálogo de sedes ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Bajo |
| **Puntos estimados:** 1 · **Horas estimadas:** 6 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero ver en una pantalla las sedes donde se puede dictar una cátedra abierta —con su nombre, su dirección y si es virtual— para poder programar dos o tres cátedras el mismo día en sitios distintos sin equivocarme de campus.

La necesidad está dicha textualmente en la reunión, y de ella nace esta tabla:

> *«El mismo día sí, a la misma hora no… sí es posible: una cátedra en San Benito, otra virtual y otra en Bello.»* — `1:03:33` **[D14]**

**Observaciones:**

- **Esta historia es el origen de la primera versión del sistema.** Antes de esa frase el modelo no tenía sede: las cátedras se programaban «en la universidad», y bastaba. Cuando el director dice que puede haber tres cátedras el mismo día en tres sitios, la sede deja de ser un dato de adorno y se vuelve necesaria para no cruzarlas.
- La sede virtual **no tiene dirección física**, y eso no es un dato que falte: es lo que la distingue.

**Criterios de aceptación:**

- Que la pantalla liste únicamente las sedes activas.
- Que la sede virtual se muestre con una raya (—) en la columna de dirección, y no con una celda vacía que parezca un error.
- Que cada sede indique si es presencial o virtual con una etiqueta legible, no con un 1 o un 0.
- Que cuando no haya sedes activas la pantalla lo diga con un mensaje neutro: una lista vacía no es una falla.
- Que los colores, los tipos de letra y los logotipos cumplan el Manual de Identidad Visual Corporativa vigente (Resolución de Rectoría General N.º 404 de 2024).
- Que la pantalla siga cargando y explique el problema si el servicio de datos no responde.

---

### Historia de Usuario 2 — Registro de una sede nueva

| | |
|---|---|
| **Número:** 2 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Registro de una sede nueva ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Bajo |
| **Puntos estimados:** 1 · **Horas estimadas:** 6 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero registrar una sede nueva desde un formulario —su código, su nombre, su dirección si la tiene y si es virtual— para poder programar cátedras en un campus recién habilitado sin depender de que alguien escriba una instrucción en la base de datos.

**Observaciones:**

- El código de la sede lo define quien la registra: es un identificador como `SAN_BENITO`, no un número consecutivo. Por eso se digita y no se genera.

**Criterios de aceptación:**

- Que el código y el nombre sean obligatorios, y que la dirección pueda quedar vacía cuando la sede es virtual.
- Que la dirección vacía quede registrada como «sin dirección» y NO como un texto en blanco: son cosas distintas.
- Que el sistema rechace el registro y diga cuál campo falta, sin perder lo que ya se había escrito.
- Que NO permita dos sedes con el mismo código.
- Que NO permita dos sedes con el mismo nombre, aunque tengan códigos distintos: dos «Campus Bello» en la lista no le sirven a nadie.
- Que esas dos comprobaciones las garantice la base de datos y no solo la pantalla, para que se cumplan también si alguien escribe por otro camino.

---

### Historia de Usuario 3 — Corrección de los datos de una sede

| | |
|---|---|
| **Número:** 3 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Corrección de los datos de una sede ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Media | **Riesgo en desarrollo:** Medio |
| **Puntos estimados:** 2 · **Horas estimadas:** 8 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero corregir los datos de una sede ya registrada —un nombre mal escrito, una dirección que cambió— sin tener que borrarla y volver a crearla, porque borrarla arrastraría las sesiones que ya están programadas allí.

**Observaciones:**

- Esta historia tiene **dos formas de guardar**, y las dos se pidieron porque las dos se usan: rehacer la ficha completa, o corregir un solo dato.

**Criterios de aceptación:**

- Que el código se muestre pero no se pueda cambiar: identifica la fila.
- Que al REEMPLAZAR la ficha el sistema exija todos los campos obligatorios, y rechace la operación si falta uno.
- Que al ACTUALIZAR solo lo diligenciado escriba únicamente esos campos y deje los demás como estaban.
- Que el mismo formulario a medio llenar sea rechazado al reemplazar y aceptado al actualizar: la diferencia debe ser visible para quien lo usa.
- Que si no se diligencia ningún campo el sistema avise y no haga nada.
- Que corregir una sede que no existe responda «no encontrada» y no cree una nueva.

---

### Historia de Usuario 4 — Retiro de una sede del catálogo

| | |
|---|---|
| **Número:** 4 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Retiro de una sede del catálogo ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Media | **Riesgo en desarrollo:** Alto |
| **Puntos estimados:** 2 · **Horas estimadas:** 6 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero retirar del catálogo una sede que la Universidad dejó de usar, para que nadie programe cátedras allí por equivocación, pero **sin que desaparezcan** las sesiones y las asistencias que ya se registraron en ella.

**Observaciones:**

- **Este es el riesgo alto del grupo.** Un borrado de verdad rompería los registros históricos de asistencia, que son la razón de existir del sistema: lo que se le reporta a Registro Académico y lo que sustenta la acreditación.

**Criterios de aceptación:**

- Que la sede retirada desaparezca del catálogo que se usa para programar.
- Que la fila SIGA EXISTIENDO en la base, de modo que las sesiones y las asistencias históricas conserven a qué sede pertenecen.
- Que retirar dos veces la misma sede responda «no encontrada» la segunda vez, y no un éxito silencioso.
- Que consultar una sede ya retirada responda «no encontrada».
- Que el retiro pida confirmación antes de ejecutarse.
- Que el retiro no pueda dispararse por el solo hecho de abrir o precargar una dirección web.

---

### Historia de Usuario 5 — Programación de la cátedra y sus sesiones

| | |
|---|---|
| **Número:** 5 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Programación de la cátedra y sus sesiones ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Medio |
| **Puntos estimados:** 3 · **Horas estimadas:** 16 | **Iteración asignada:** v2 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero registrar una cátedra y programar sus sesiones indicando el número de reunión, la fecha, la hora, la modalidad, la sede y el periodo, para poder generar después el enlace o el código de cada una.

> *«Necesitamos el número de reunión, que eso lo podríamos hacer previo.»* — `1:03:50` **[D16]**

> *«Cuando es virtual enviamos el enlace; si es presencial, el QR.»* — `1:06:53` **[D15]**

**Observaciones:**

- La modalidad **no es un dato descriptivo: decide el canal de entrega**. Virtual manda enlace; presencial proyecta un código. Por eso no puede quedar vacía.
- El número de reunión puede venir del ASIS o calcularse, pero **existe antes** de la sesión: es lo que después viaja en el archivo plano.

**Criterios de aceptación:**

- Que la sede, la modalidad, el tipo de evento y el periodo se seleccionen de una lista cargada del sistema, no se escriban a mano.
- Que no permita una sesión cuya hora de fin sea anterior o igual a la de inicio.
- Que el identificador de la cátedra en el ASIS se valide con el formato que ese sistema exige, y se rechace si no lo cumple.
- Que dos sesiones de la misma cátedra no puedan tener el mismo número de reunión.
- Que una sede retirada no aparezca en la lista para programar sesiones nuevas.

---

### Historia de Usuario 6 — Registro de la propia asistencia

| | |
|---|---|
| **Número:** 6 | **Usuario:** El asistente a la cátedra (estudiante, docente, egresado o externo) |
| **Nombre historia:** Registro de la propia asistencia ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Alto |
| **Puntos estimados:** 5 · **Horas estimadas:** 24 | **Iteración asignada:** v4 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, como persona que asiste a una cátedra abierta, quiero registrar mi asistencia escaneando el código o abriendo el enlace, identificándome con **mi código, mi cédula o mi correo** —el que recuerde— y confirmando con una clave que me llegue al correo, para que mi asistencia quede certificada sin firmar una planilla que después alguien transcribe.

La razón de la clave la dio el director, y no es la que uno supondría:

> *«Yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo… si no, yo te registro a vos y vos me registrás a mí.»* — `1:04:51`

> *«A veces los estudiantes, como no se saben el ID, colocan la cédula; toca buscar en ASIS con la cédula para obtener el ID.»* — `42:01` **[D11]**

**Observaciones:**

- **Esta historia la enunció el director, pero el usuario no es él:** es quien asiste. Se deja así porque una historia se escribe desde quien la vive, aunque la haya pedido otro.
- **La clave al correo NO es autenticación: es prevención de suplantación.** Su límite se reconoció en la misma reunión —se puede pedir el código por teléfono— y el riesgo residual se aceptó a cambio de seriedad. Conviene que quede escrito, para que nadie la presente como algo que no es.
- Aceptar los **tres identificadores** es lo que elimina el trabajo manual de buscar el ID en el ASIS a partir de la cédula.

**Criterios de aceptación:**

- Que se pueda entrar con el código del ASIS, la cédula o el correo: cualquiera de los tres.
- Que solo pueda registrarse quien esté en la tabla cargada del ASIS — «solo los que estén en esa tabla pueden ingresar» (`55:52`).
- Que una misma persona no quede registrada dos veces en la misma sesión.
- Que la clave se envíe al correo de la persona y tenga vigencia limitada.
- Que las claves NO se guarden en texto legible.
- Que quede registrado a qué correo se envió, cuándo, y cuándo se usó: no basta con saber que alguien se registró.
- Que el formulario llegue **ya diligenciado**: la persona no digita sus datos otra vez (`1:50:43`).
- Que funcione en el teléfono, porque es donde se va a usar: en la puerta del auditorio.
- Que la pantalla cumpla el Manual de Identidad Visual Corporativa: es la cara del sistema ante los estudiantes (`59:10`).

---

### Historia de Usuario 7 — Generación del archivo plano para el ASIS

| | |
|---|---|
| **Número:** 7 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Generación del archivo plano para el ASIS ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Alto |
| **Puntos estimados:** 5 · **Horas estimadas:** 20 | **Iteración asignada:** v4 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero que el sistema me genere, al terminar una sesión, el archivo plano listo para subir al ASIS, para no volver a transcribir a mano lo que ya está registrado.

> *«Que la persona se registre y de una vez nos genere el archivo plano para pasarlo.»* — `1:04:38`

Y la forma del archivo está cerrada:

> *«El archivo plano son tres: la reunión consecutivo, el ID y el código del programa.»* — `32:34` **[D9]**

**Observaciones:**

- **Esta es la razón de existir del proyecto.** Hoy la asistencia se recoge en un formulario anónimo y alguien la transcribe al ASIS a mano; eliminar esa transcripción es lo que se está comprando.
- **Tres columnas, ni una más.** La cédula y los nombres están en el modelo, pero **no viajan**: *«en el ASIS está el número de identificación, la cédula… pero no es la información que se monta como archivo plano»* (`44:01`, **[D10]**).
- Los **externos se cuentan pero no viajan**: *«si son externos… eso lo podemos depurar antes de pasarlo»* (`43:37`, **[D5]**).

**Criterios de aceptación:**

- Que el archivo tenga exactamente tres columnas: número de reunión, ID del ASIS y código de programa.
- Que NO incluya cédula, nombres ni correos, aunque el sistema los tenga.
- Que los asistentes externos **queden excluidos** del archivo, sin dejar de estar registrados en el sistema.
- Que el programa que viaja sea el que imputa la asistencia — *«después le da información a Registro de qué programas hizo el estudiante»* (`50:14`, **[D12]**).
- Que el archivo se pueda descargar por sesión.
- Que si una asistencia no tiene ID del ASIS, el sistema lo señale **antes** de generar el archivo, y no produzca una línea inválida.

---

### Historia de Usuario 8 — Informe de externos por periodo

| | |
|---|---|
| **Número:** 8 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Informe de externos por periodo ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Media | **Riesgo en desarrollo:** Bajo |
| **Puntos estimados:** 2 · **Horas estimadas:** 10 | **Iteración asignada:** v4 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero poder descargar cuántas personas externas asistieron a las cátedras en un periodo, para sustentar el alcance de las cátedras abiertas fuera de la Universidad — aunque esas personas no vayan en el archivo del ASIS.

> *«Que nos genere un registro de externos, pero que no nos lo arroje en el archivo plano; que sí podamos descargar cuántos externos han ingresado en 2026-2.»* — `56:16` **[D6]**

**Observaciones:**

- **Esta frase es la justificación del periodo académico en el modelo.** Sin ella, «2026-2» sería un texto suelto; con ella, es la unidad en la que se cuenta.
- Es la otra cara de la historia 7: el externo **se captura y se cuenta**, pero **se filtra** del archivo. Las dos reglas salen de la misma conversación y hay que leerlas juntas.

**Criterios de aceptación:**

- Que el informe se pueda filtrar por periodo académico.
- Que cuente a los externos **por separado** de los internos.
- Que las cifras salgan de los registros de asistencia y no de un archivo aparte que alguien mantenga en paralelo.
- Que se pueda descargar.
- Que las sesiones de sedes retiradas sigan contando en los periodos en que se dictaron: retirar una sede no reescribe la historia.

---

### Historia de Usuario 9 — La excepción de Rutas de Paz

| | |
|---|---|
| **Número:** 9 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** La excepción de Rutas de Paz ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Media | **Riesgo en desarrollo:** Medio |
| **Puntos estimados:** 3 · **Horas estimadas:** 10 | **Iteración asignada:** v2 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero que las personas del programa Rutas de Paz puedan registrar su asistencia **sin programa académico y con un correo personal**, porque no tienen ni lo uno ni lo otro, pero sí asisten a las cátedras.

> *«Para el tema de Rutas de Paz sí sería una excepción: ellos entrarían sin programa, pero solo ellos.»* — `41:16` **[D7]**

> *«Los que están en Rutas de Paz no tienen correo institucional.»* — `53:42` **[D8]**

**Observaciones:**

- **«Pero solo ellos»** es la parte que hay que respetar: la excepción es de un tipo de vinculación, no una puerta abierta para todos.
- El correo personal **no es un caso raro**: para esta población es la única vía de contacto, y sin ella no hay cómo enviarle la clave. Por eso el modelo exige *al menos un* correo, no el institucional.
- Cuando aparece una excepción así, la pregunta correcta no es «¿cómo la salto?» sino **«¿qué dice el nulo?»**. Aquí el programa vacío significa algo concreto: *esta persona entra por Rutas de Paz*.

**Criterios de aceptación:**

- Que el programa académico pueda quedar vacío **solo** para los tipos de vinculación que lo permitan.
- Que para los demás tipos el programa siga siendo obligatorio.
- Que una persona sin correo institucional pueda registrarse con su correo personal.
- Que ninguna persona quede sin al menos una vía de contacto: sin correo no hay cómo enviarle la clave.
- Que el informe de la historia 8 pueda distinguir a esta población.

---

### Historia de Usuario 10 — Control de acceso por rol

| | |
|---|---|
| **Número:** 10 | **Usuario:** profesor Hugo Nelson Castañeda · Administrador del sistema y director del CIDEH |
| **Nombre historia:** Control de acceso por rol ||
| **Diseñada por:** Enunciadas por el profesor Hugo Nelson Castañeda (usuario experto) · Redactadas por Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Alto |
| **Puntos estimados:** 5 · **Horas estimadas:** 20 | **Iteración asignada:** v3 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo, Hugo Nelson Castañeda, como administrador del sistema y director del CIDEH, quiero que cada persona entre con su usuario y vea únicamente lo que le corresponde según su rol, para que un asistente no pueda modificar el catálogo de sedes ni consultar la asistencia de los demás.

**Observaciones:**

- **Ojo con una confusión frecuente: esconder una opción del menú NO es controlar el acceso.** Mientras el control no esté en el servicio que entrega los datos, cualquiera que escriba la dirección web llega igual. Por eso esta historia **no se considera cumplida con un menú filtrado**.
- Un sistema que aparenta seguridad es peor que uno que no la tiene, porque el segundo al menos no engaña a quien lo opera.

**Criterios de aceptación:**

- Que el sistema pida usuario y contraseña, y que toda pantalla distinta del ingreso exija haber entrado.
- Que las contraseñas se guarden cifradas y nunca se devuelvan.
- Que el mensaje de error al fallar el ingreso sea el mismo si el usuario no existe y si la contraseña está mal: decir cuál de los dos falló revela qué usuarios existen.
- Que el menú muestre solo lo que el rol puede usar.
- Que el control se aplique **también** cuando alguien escribe la dirección a mano.
- Que las contraseñas solo puedan ser inicializadas por el administrador y deban cambiarse en el primer ingreso.

---
## Anexo: qué NO es una historia de usuario

Se deja anotado porque al escribir este documento aparecieron tres candidatas que se descartaron, y saber por qué ahorra discusiones:

| Se propuso | Por qué NO es una historia |
|---|---|
| «Crear la tabla `sede` en PostgreSQL» | Es una tarea técnica, no una necesidad de alguien. Ningún usuario quiere una tabla: quiere consultar sedes |
| «Migrar los datos del sistema institucional» | Es un trabajo real, pero no tiene un usuario que lo pida para algo suyo. Va como tarea del plan, no como historia |
| «Que el sistema sea rápido» | No es verificable como está escrito. Convertida en criterio de una historia concreta —*que el catálogo cargue en menos de un segundo con 50 sedes*— sí sirve |
| «Que la clave al correo autentique al usuario» | **La fuente dice lo contrario.** En la reunión se reconoció que se puede pedir el código por teléfono: *«esa trampa se puede hacer»* (`1:05:18`). Escribirla como autenticación sería prometer algo que el sistema no da. Va como lo que es: prevención de suplantación, con su límite dicho |

> La prueba para saber si algo es una historia: **¿se puede nombrar a la persona que la necesita, y decir qué gana cuando esté lista?** Si no, es una tarea — y las tareas van en el plan.
