# Historias de usuario — Cátedras Abiertas

**Versión 1.1**

Universidad de San Buenaventura, Medellín

---

## Historial de Revisiones

| Fecha | Versión | Descripción | Autor | Revisor |
|---|---|---|---|---|
| 03/09/2026 | 1.0 | Primera versión de las historias de usuario del sistema de cátedras abiertas, derivadas del modelo entregado y del ejemplo de referencia de la versión 1 | Equipo del proyecto de aula | Carlos Arturo Castro Castro |
| 03/09/2026 | 1.1 | Se alinea la columna de iteración con el mapa de versiones y con las cuatro versiones que evalúa el curso: la v2 pasa a ser TODAS las tablas restantes, no solo cátedra y sesión. Se deja explícito que el proyecto versiona back y front en paralelo | Equipo del proyecto de aula | Carlos Arturo Castro Castro |

---

## Introducción

Este documento sirve como una guía integral para identificar y definir las historias de usuario esenciales que contribuirán al éxito del proyecto de **Cátedras Abiertas**. A través de esta guía se busca proporcionar una comprensión clara y detallada de las necesidades y expectativas de los usuarios, lo que permitirá a los equipos de desarrollo y gestión alinear sus esfuerzos de manera efectiva. Al seguir las recomendaciones y procesos descritos en este documento, se facilitará la creación de un producto final que cumpla con los objetivos.

### Cómo se lee una historia

Cada historia es una **tarjeta**: quién la necesita, qué quiere, para qué, y —lo más importante— **cómo se sabrá que quedó lista**. Esa última parte son los criterios de aceptación, y no son una formalidad: son la definición de «terminado». Una historia sin criterios verificables no se puede cerrar, porque nadie puede decir si funciona.

Los criterios están escritos **en el lenguaje del usuario, no del programador**: dicen *«que la sede retirada desaparezca del catálogo»*, no *«que el DELETE haga un UPDATE de activo»*. El cómo es del equipo; el qué es de quien lo necesita.

### Relación con las versiones del proyecto

La columna **Iteración asignada** dice en qué versión entra cada historia. No es un orden arbitrario: sigue el mapa de versiones del proyecto, donde cada versión es una rebanada completa que se puede mostrar y usar.

| Versión | Historias | Qué queda funcionando — **API y pantallas** |
|---|---|---|
| **v1** | 1, 2, 3, 4 | Las tablas sin llave foránea, con sus pantallas. *Este ejemplo construye una: el catálogo de sedes, completo* |
| **v2** | 5 | Todas las demás tablas —cátedras, sesiones y catálogos— con las listas desplegables cargadas del sistema |
| **v3** | 8 | El ingreso con usuario y el control de acceso por rol |
| **v4** | 6, 7 | El registro de asistencia, las consultas de acreditación y el tablero |

**Este proyecto versiona back y front EN PARALELO.** Cada versión entrega su
parte de la API *y* sus pantallas: no hay una versión "de back" y otra "de
front". La razón, con sus costos, está en el
[mapa de versiones](docs/spec_kit/versiones/0_mapa_versiones.md).

Lo que eso significa para estas historias: **una historia no está cumplida si
el dato se puede consultar por la API pero no se ve en una pantalla.** Sus
criterios de aceptación están escritos así a propósito — hablan de lo que ve
quien usa el sistema, no de lo que responde un endpoint.

> **La versión 1 está construida** y se puede ejecutar: es el ejemplo de referencia de este repositorio. Las historias 1 a 4 tienen sus criterios verificados contra el sistema corriendo, y el detalle técnico está en [`docs/spec_kit/`](docs/spec_kit/versiones/v1_sede/2_spec.md).

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
| **Número:** 1 | **Usuario:** Ana Gómez · Coordinadora de Bienestar Institucional |
| **Nombre historia:** Consulta del catálogo de sedes ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Bajo |
| **Puntos estimados:** 1 · **Horas estimadas:** 6 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Ana Gómez, como coordinadora de Bienestar Institucional, quiero ver en una pantalla la lista de las sedes donde se dictan las cátedras abiertas, con su nombre, su dirección y si son virtuales, para saber dónde se puede programar una sesión sin tener que preguntarle a nadie ni abrir la base de datos.

**Observaciones:**

- La sede virtual no tiene dirección física, y eso NO es un dato faltante: es su naturaleza. La pantalla debe distinguir «no tiene dirección» de «nadie escribió la dirección».

**Criterios de aceptación:**

- Que la pantalla liste únicamente las sedes activas: una sede eliminada no aparece.
- Que la sede virtual se muestre con una raya (—) en la columna de dirección, y no con una celda vacía que parezca un error.
- Que cada sede indique si es presencial o virtual con una etiqueta legible, no con un 1 o un 0.
- Que cuando no haya ninguna sede activa la pantalla lo diga con un mensaje neutro, y no con un aviso de error: una lista vacía no es una falla.
- Que la distribución de colores, tipos de letra y logotipos esté de acuerdo con el Manual de Identidad Visual Corporativa vigente (Resolución de Rectoría General N.º 404 de 2024): naranja #EF7D00, negro #1D1D1B, y Montserrat o Raleway como fuentes.
- Que la pantalla siga cargando y explique el problema si el servicio de datos no responde, en vez de mostrar una pantalla de error del servidor.

---

### Historia de Usuario 2 — Registro de una sede nueva

| | |
|---|---|
| **Número:** 2 | **Usuario:** Ana Gómez · Coordinadora de Bienestar Institucional |
| **Nombre historia:** Registro de una sede nueva ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Bajo |
| **Puntos estimados:** 1 · **Horas estimadas:** 6 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Ana Gómez, como coordinadora de Bienestar Institucional, quiero registrar una sede nueva desde un formulario, indicando su código, su nombre, su dirección si la tiene y si es virtual, para poder programar cátedras en un campus que la Universidad acaba de habilitar sin depender de que alguien escriba una instrucción en la base de datos.

**Observaciones:**

- El código de la sede lo define quien la registra —es un identificador como SAN_BENITO, no un número consecutivo—, así que se digita y no se genera.

**Criterios de aceptación:**

- Que el código y el nombre sean obligatorios, y que la dirección pueda quedar vacía cuando la sede es virtual.
- Que si la dirección se deja vacía quede registrada como «sin dirección» y NO como un texto en blanco: son cosas distintas.
- Que el sistema rechace el registro y diga cuál campo falta, sin perder lo que ya se había escrito en el formulario.
- Que el sistema NO permita dos sedes con el mismo código.
- Que el sistema NO permita dos sedes con el mismo nombre, aunque tengan códigos distintos: dos «Campus Bello» en la lista no le sirven a nadie.
- Que las dos comprobaciones anteriores las garantice la base de datos y no solo la pantalla, para que se cumplan también si alguien escribe por otro camino.

---

### Historia de Usuario 3 — Corrección de los datos de una sede

| | |
|---|---|
| **Número:** 3 | **Usuario:** Ana Gómez · Coordinadora de Bienestar Institucional |
| **Nombre historia:** Corrección de los datos de una sede ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Media | **Riesgo en desarrollo:** Medio |
| **Puntos estimados:** 2 · **Horas estimadas:** 8 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Ana Gómez, como coordinadora de Bienestar Institucional, quiero corregir los datos de una sede ya registrada, para arreglar un nombre mal escrito o actualizar una dirección que cambió, sin tener que borrarla y volver a crearla —porque borrarla arrastraría las sesiones que ya están programadas allí.

**Observaciones:**

- Esta historia tiene DOS formas de guardar, y la diferencia importa: reemplazar todos los datos de la sede, o cambiar solamente los que se diligenciaron. Se pidieron las dos porque en la práctica se usan las dos: una para rehacer la ficha completa y otra para corregir un solo dato.

**Criterios de aceptación:**

- Que el código de la sede se muestre pero no se pueda cambiar: identifica la fila, y cambiarlo sería crear otra sede.
- Que al REEMPLAZAR la ficha completa el sistema exija todos los campos obligatorios, y rechace la operación si falta uno.
- Que al ACTUALIZAR solo lo diligenciado el sistema escriba únicamente esos campos y deje los demás como estaban.
- Que el mismo formulario a medio llenar sea rechazado al reemplazar y aceptado al actualizar: la diferencia debe ser visible para quien lo usa.
- Que si no se diligencia ningún campo el sistema avise y no haga nada.
- Que corregir una sede que no existe responda «no encontrada» y no cree una nueva.

---

### Historia de Usuario 4 — Retiro de una sede del catálogo

| | |
|---|---|
| **Número:** 4 | **Usuario:** Ana Gómez · Coordinadora de Bienestar Institucional |
| **Nombre historia:** Retiro de una sede del catálogo ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Media | **Riesgo en desarrollo:** Alto |
| **Puntos estimados:** 2 · **Horas estimadas:** 6 | **Iteración asignada:** v1 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Ana Gómez, como coordinadora de Bienestar Institucional, quiero retirar del catálogo una sede que la Universidad dejó de usar, para que nadie programe cátedras allí por equivocación, pero SIN que desaparezcan las sesiones y las asistencias que ya se registraron en ella.

**Observaciones:**

- Este es el riesgo alto del grupo: un borrado de verdad rompería los registros históricos de asistencia, que son la razón de existir del sistema. Por eso se pide que la sede se marque como retirada y no que se elimine.

**Criterios de aceptación:**

- Que la sede retirada desaparezca del catálogo que se usa para programar.
- Que la fila SIGA EXISTIENDO en la base de datos, de modo que las sesiones y las asistencias históricas conserven a qué sede pertenecen.
- Que retirar dos veces la misma sede responda «no encontrada» la segunda vez, y no un éxito silencioso.
- Que consultar una sede ya retirada responda «no encontrada»: si no está en el catálogo, para el sistema no existe.
- Que el retiro pida confirmación antes de ejecutarse.
- Que el retiro no pueda dispararse por el solo hecho de abrir o precargar una dirección web.

---

### Historia de Usuario 5 — Programación de una cátedra y sus sesiones

| | |
|---|---|
| **Número:** 5 | **Usuario:** Luis Restrepo · Auxiliar administrativo de Bienestar |
| **Nombre historia:** Programación de una cátedra y sus sesiones ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Medio |
| **Puntos estimados:** 3 · **Horas estimadas:** 16 | **Iteración asignada:** v2 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Luis Restrepo, como auxiliar administrativo de Bienestar, quiero registrar una cátedra abierta y programar sus sesiones indicando fecha, hora, modalidad, sede y periodo académico, para que el sistema sepa qué eventos existen y cuándo, y pueda controlar la asistencia a cada uno.

**Observaciones:**

- La sede, la modalidad y el periodo NO se digitan: se eligen de los catálogos que ya existen. Digitarlos permitiría escribir una sede que no existe.

**Criterios de aceptación:**

- Que la sede, la modalidad, el tipo de evento y el periodo se seleccionen de una lista cargada del sistema, no se escriban a mano.
- Que el sistema no permita una sesión cuya hora de fin sea anterior o igual a la de inicio.
- Que el identificador de la cátedra en el sistema institucional (ASIS) se valide con el formato que ese sistema exige, y se rechace si no lo cumple.
- Que dos sesiones de la misma cátedra no puedan tener el mismo número de reunión.
- Que una cátedra retirada no aparezca en la lista para programar sesiones nuevas.

---

### Historia de Usuario 6 — Registro de la propia asistencia a una sesión

| | |
|---|---|
| **Número:** 6 | **Usuario:** Camila Herrera · Estudiante de Ingeniería de Sistemas |
| **Nombre historia:** Registro de la propia asistencia a una sesión ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Alto |
| **Puntos estimados:** 5 · **Horas estimadas:** 24 | **Iteración asignada:** v4 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Camila Herrera, como estudiante de la Universidad, quiero registrar mi asistencia a una sesión de cátedra abierta escaneando un código o abriendo un enlace, y confirmando con una clave que el sistema me envíe, para que mi asistencia quede certificada sin tener que firmar una planilla en papel que después alguien transcribe a mano.

**Observaciones:**

- Hoy la asistencia se recoge en un formulario anónimo y se migra a mano al sistema institucional. Esta historia es la razón de existir del proyecto: eliminar esa transcripción y con ella los errores que introduce.
- El riesgo es alto porque toca datos personales: quién asistió, cuándo y desde dónde.

**Criterios de aceptación:**

- Que solo pueda registrarse quien tenga una vinculación vigente con la Universidad —estudiante, docente, administrativo, egresado— o esté autorizado como externo.
- Que una misma persona no pueda quedar registrada dos veces en la misma sesión.
- Que la clave de acceso se envíe a un correo de la persona y tenga una vigencia limitada.
- Que las claves NO se guarden en texto legible en la base de datos.
- Que el registro guarde de dónde vino (código QR, enlace o registro manual) para poder auditarlo después.
- Que la pantalla del estudiante funcione en el teléfono, porque es donde se va a usar de verdad: en la puerta del auditorio.
- Que la imagen de la pantalla cumpla el Manual de Identidad Visual Corporativa vigente, porque es la cara del sistema ante los estudiantes.

---

### Historia de Usuario 7 — Informe de asistencia por cátedra y periodo

| | |
|---|---|
| **Número:** 7 | **Usuario:** Diana Osorio · Vicerrectoría Académica |
| **Nombre historia:** Informe de asistencia por cátedra y periodo ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Media | **Riesgo en desarrollo:** Medio |
| **Puntos estimados:** 3 · **Horas estimadas:** 12 | **Iteración asignada:** v4 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Diana Osorio, de la Vicerrectoría Académica, quiero consultar cuántas personas asistieron a cada cátedra en un periodo, discriminadas por programa académico y por tipo de vinculación, para sustentar ante los entes de acreditación el alcance real de las cátedras abiertas.

**Observaciones:**

- Este es el informe que hoy se arma a mano cruzando archivos, y por eso tarda semanas y nadie está seguro de sus cifras.

**Criterios de aceptación:**

- Que el informe se pueda filtrar por periodo académico y por cátedra.
- Que las cifras salgan de los registros de asistencia y no de un archivo aparte que alguien mantenga en paralelo.
- Que el informe distinguya entre asistentes internos y externos.
- Que el informe se pueda exportar para adjuntarlo a un documento de acreditación.
- Que las sesiones de sedes retiradas sigan contando en los periodos en que se dictaron: retirar una sede no reescribe la historia.

---

### Historia de Usuario 8 — Control de acceso por rol

| | |
|---|---|
| **Número:** 8 | **Usuario:** Jorge Marín · Administrador del sistema |
| **Nombre historia:** Control de acceso por rol ||
| **Diseñada por:** Carlos Arturo Castro Castro ||
| **Prioridad:** Alta | **Riesgo en desarrollo:** Alto |
| **Puntos estimados:** 5 · **Horas estimadas:** 20 | **Iteración asignada:** v3 |
| **Programador responsable:** Equipo del proyecto de aula ||

**Descripción:**

Yo Jorge Marín, como administrador del sistema, quiero que cada persona entre con su usuario y vea únicamente lo que le corresponde según su rol, para que un estudiante no pueda modificar el catálogo de sedes ni consultar la asistencia de sus compañeros.

**Observaciones:**

- Ojo con una confusión frecuente: esconder una opción del menú NO es controlar el acceso. Mientras el control no esté en el servicio que entrega los datos, cualquiera que escriba la dirección web llega igual.
- Por eso esta historia NO se considera cumplida con un menú filtrado.

**Criterios de aceptación:**

- Que el sistema pida usuario y contraseña, y que toda pantalla distinta del ingreso exija haber entrado.
- Que las contraseñas se guarden cifradas y nunca se devuelvan, ni en claro ni cifradas.
- Que el mensaje de error al fallar el ingreso sea el mismo si el usuario no existe y si la contraseña está mal: decir cuál de los dos falló revela qué usuarios existen.
- Que el menú muestre solo lo que el rol puede usar.
- Que el control se aplique TAMBIÉN cuando alguien escribe la dirección a mano: el menú solo dibuja, no protege.
- Que las contraseñas solo puedan ser inicializadas por el administrador y deban ser cambiadas por la persona en su primer ingreso.

---

## Anexo: qué NO es una historia de usuario

Se deja anotado porque al escribir este documento aparecieron tres candidatas que se descartaron, y saber por qué ahorra discusiones:

| Se propuso | Por qué NO es una historia |
|---|---|
| «Crear la tabla `sede` en PostgreSQL» | Es una tarea técnica, no una necesidad de alguien. Ningún usuario quiere una tabla: quiere consultar sedes |
| «Migrar los datos del sistema institucional» | Es un trabajo real, pero no tiene un usuario que lo pida para algo suyo. Va como tarea del plan, no como historia |
| «Que el sistema sea rápido» | No es verificable como está escrito. Convertida en criterio de una historia concreta —*que el catálogo cargue en menos de un segundo con 50 sedes*— sí sirve |

> La prueba para saber si algo es una historia: **¿se puede nombrar a la persona que la necesita, y decir qué gana cuando esté lista?** Si no, es una tarea — y las tareas van en el plan.
