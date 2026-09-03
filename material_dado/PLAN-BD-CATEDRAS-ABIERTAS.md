# Plan de diseño de la base de datos — Cátedras Abiertas

**Proyecto:** registro y control de asistencia a cátedras abiertas · Universidad de San Buenaventura, Medellín
**Interlocutores:** el profesor Hugo Nelson Castañeda Ruiz y Andrea (usuarios expertos) · profesor Carlos Arturo Castro (dirección técnica) · Carlos (ASIS) · Piedad (servidores)
**Motor:** PostgreSQL 14 o superior · UTF-8 · esquema `public`
**Estructura del entregable:** la misma de [`proyectoMesaDeAyuda/SOLUCIONES/`](../proyectoMesaDeAyuda/SOLUCIONES/) — conceptual, lógico y físico, en tres carpetas
**Fecha:** 10 de agosto de 2026

---

## 0 · Las fuentes

Este es el **plan**: qué se va a modelar, en qué orden, con qué criterio y con qué entregables. No es todavía el modelo.

### 0.1 · Orden de autoridad

| # | Fuente | Qué aporta |
|---|---|---|
| **1** | `trascripción del video.txt` | La reunión completa: el método que exige el profesor Carlos Castro, las reglas del negocio y los acuerdos. **Es la fuente normativa** |
| **2** | `USBME_LCONTROL_CATEDRAS_1076195337.xlsx` | La estructura real del evento: ID, reunión, descripción, tipo. **Define el bloque de cátedras** |
| **3** | `PRIMERA VERSIÓN Ideas software.docx` | El acta de la reunión: el flujo, los dos roles, el QR con ventana, los cuatro informes |
| **4** | `Cätedras abiertas DIagrama Entidad -relación.xlsx` | El punto de partida del modelo: la entidad *Asistente*, construida en vivo durante la reunión |
| — | `Documentación de migración… .pdf` | Apoyo: el proceso manual que se reemplaza y los cinco estados del ASIS |
| — | `USBME_EMPLID_CATED_V1…xlsx` | Apoyo: el maestro de personas que **va a ser reemplazado** por el informe ampliado |
| — | `Pedagogía Electoral(1-164).xlsx` | Apoyo: la calidad real de lo que hoy se captura |
| — | `Trabajo_final_análisis8_IES.ipynb` | **No pertenece a este proyecto.** Es el trabajo final del curso de IA de TalentoTech |

> **El `.docx` no es un documento de requisitos: es un prompt.** Lo dice el profesor Carlos Castro en `58:52` — *«esto va a ser para la IA… así se va a hacer el prompt para la IA; entre menos espacios tenga, más cortico es el prompt»*. Por eso está escrito en frases cortas y sin adornos. **Este plan es lo que le falta a ese prompt para producir una base de datos correcta en vez de una plausible.**

### 0.2 · Cobertura de la transcripción

De una reunión de 1h53m está transcrito `0:00–1:07:41` y `1:46:42–1:52:32`. **Queda un hueco de 39 minutos entre `1:07:41` y `1:46:42`**, más microcortes menores.

El tramo `1:46:42–1:49:13` resultó ser logística —duración de las grabaciones, y la cita de seguimiento **dentro de 8 días a las 3:00 p. m.**—, así que no aporta reglas. Lo que sigue faltando son los 39 minutos centrales, donde con alta probabilidad se discutieron los informes y la parametrización. **Ya no bloquea**: hay material suficiente para el conceptual completo.

> **Hay una segunda grabación.** En `1:47:35` el profesor Hugo Nelson localiza y comparte por el chat de la reunión la grabación de **otra sesión, del 24 de marzo** —*«antes de Semana Santa»*—, que el profesor Carlos Castro pedía. El profesor Hugo Nelson advierte que esas grabaciones **caducan a los 2 o 3 meses salvo que se amplíe el plazo**. Si contiene requisitos, es la única fuente primaria que aún puede perderse por inacción. **Recuperarla y ampliarle la vigencia es urgente, y es independiente del resto del plan.**

---

## 1 · El método que exige el profesor Carlos Castro

Antes de modelar hay que registrar **cómo** pidió que se modele. No es preferencia estética: es el criterio con el que va a revisar.

| Cita | Instrucción |
|---|---|
| `0:03` | *«Hacer un modelo entidad-relación… para mí es de las cosas más importantes, y algunos las subestiman»* |
| `0:11` | *«Con la inteligencia artificial ya no se codifica… uno interactúa con los requerimientos y ya va entregando el código»* → **el modelo es el entregable** |
| `5:44` | *«Cada entidad representa un solo objeto de estudio… es la información que vamos a guardar para después consultar»* |
| `5:59` | *«Hay que identificar qué atributos necesitamos… y cuál de esos atributos es el identificador»* |
| `7:22` | *«Estos rombos son las relaciones, que son acciones. La idea es que esas relaciones sean verbos»* |
| `7:34` | *«Lo más parecidos posibles a la realidad. La idea es no usar verbos como haber o tener»* — con excepciones cuando cuadra |
| `7:59` – `9:11` | La cardinalidad, ejemplificada con autor / libro / ejemplar / usuario |
| `18:30` | *«El círculo significa que debe o puede… lo que significa muchos es esta patica de gallina»* — **opcionalidad y cardinalidad son dos preguntas distintas** |
| `19:11` | *«Por eso es que a mí no me gustan este tipo de modelos»*, sobre un diagrama de pata de gallina → **entregar en notación de Chen** |
| `34:10` · `35:06` | *«Ni en descripción ni en número de identidad: sin espacios y sin tildes»* · *«Código programa, póngale todo pegado»* → **convención de nombres obligatoria** |
| `24:21` · `24:59` | Toda entidad y todo atributo llevan **descripción escrita**, y la descripción se ajusta a medida que cambia el entendimiento |

**Consecuencias directas sobre los entregables:**

1. La carpeta `MER/` es el entregable principal, no un paso previo al SQL.
2. Los diagramas se entregan en **Chen**, no en pata de gallina. Mermaid queda como formato de mantenimiento.
3. Cada relación se nombra con un **verbo** y se escribe su frase en español en las dos direcciones.
4. **Cardinalidad y opcionalidad se documentan por separado**, con min-max.
5. **Nombres sin tildes y sin espacios.** En el MER se conservan las etiquetas que él mismo dictó (`ID`, `NumeroIdentidad`, `Codigoprograma`); en el físico se usa `snake_case` en minúscula, que cumple la misma regla y es la convención de PostgreSQL. Esa equivalencia se declara en el diccionario de datos.
6. Toda entidad y todo atributo llevan descripción, y el archivo de definiciones es un **documento vivo**.

---

## 2 · El problema

### 2.1 Cómo funciona hoy

| Paso | Quién | Cómo | Costo |
|---|---|---|---|
| 1 | Asistente | Llena un Microsoft Forms **anónimo**, con texto libre | Sin identidad verificada |
| 2 | Gestor | Descarga `USBME_LCONTROL_CATEDRAS` y **busca a mano** el último número de reunión | Manual, 5.711 filas |
| 3 | Gestor | Cruza a mano cada asistente contra `USBME_EMPLID_CATED` para obtener ID y programa | Manual, 16.093 filas de referencia |
| 4 | Gestor | Arma un Excel de **exactamente tres columnas**, sin encabezado ni texto | Un carácter de más rompe la carga |
| 5 | Gestor | Sube en *Carga Info Cátedra*, ejecuta en `PSUNX01`, vigila *Monitor Procesos* | Sin trazabilidad de qué fila falló |
| 6 | Gestor | Verifica en *Asistencia a Eventos* | Verificación visual |

**El proyecto consiste en dejar solo los pasos 5 y 6**, y el profesor Hugo Nelson pide más: *«que la persona se registre y de una vez nos genere el archivo plano para pasarlo»* (`1:04:38`).

### 2.2 El flujo acordado en la reunión

Reconstruido de `54:22` a `1:05:40` y contrastado con el `.docx`:

```
El administrador descarga del ASIS el archivo de personas       (52:37)
        ↓  con códigos, nombres y correos — no solo la cédula
Se carga en la base de datos como una tabla                     (52:57)
        ↓
El administrador carga o actualiza la tabla de cátedras
        ↓
Genera con un botón el QR y la URL de una cátedra específica
        ↓  con hora de inicio y hora de cierre configurables
Presencial → QR proyectado    ·    Virtual → enlace enviado     (1:06:53)
        ↓
El asistente escanea o abre el enlace                           (54:22)
        ↓
Pantalla de acceso: digita CÓDIGO, CÉDULA o CORREO — cualquiera (56:13, 57:20)
        ↓  «solo los que estén en esa tabla pueden ingresar»     (55:52)
El sistema le envía una clave al correo                         (58:07)
        ↓  como los desprendibles de nómina
El asistente digita la clave e ingresa                           (58:21)
        ↓
Pantalla con imagen corporativa y el nombre de la cátedra        (59:10, 1:05:40)
        ↓  el formulario llega diligenciado: no digita nada más  (1:50:43)
Responde la encuesta rápida de calidad
        ↓
El sistema genera el archivo plano de tres columnas              (1:04:38)
```

### 2.3 Por qué la clave al correo — la razón, no el mecanismo

Está dicha textualmente en `1:04:51`:

> *«Yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo… si no, yo te registro a vos y vos me registrás a mí.»*

**El código al correo no es autenticación: es prevención de suplantación.** Y el profesor Carlos Castro reconoce su límite en `1:05:18`, cuando el profesor Hugo Nelson señala que igual se puede pedir el código por teléfono: *«esa trampa se puede hacer»*. Se acepta el riesgo residual a cambio de seriedad y personalización.

Esto importa para el modelo porque define qué hay que **guardar**: no basta con saber que alguien se registró; hay que poder mostrar que se le envió un código a *su* correo, a qué dirección, cuándo, y cuándo lo usó.

### 2.4 Los tres problemas de fondo

1. **Identidad.** Hoy el asistente escribe quién es. Mañana el sistema lo valida contra la tabla del ASIS y contra su correo.
2. **Consecutivo de reunión.** Hoy es un número que un humano busca en un Excel. Es una restricción de unicidad.
3. **Trazabilidad de la migración.** Hoy, si el ASIS rechaza una fila, no queda constancia de cuál ni por qué.

---

## 3 · Las reglas duras que salieron de la reunión

Estas no son decisiones de diseño: son restricciones del negocio, dichas por quien las conoce. Van primero porque **condicionan todo lo demás**.

| # | Regla | Cita | Consecuencia |
|---|---|---|---|
| **D1** | *«Para poder inscribir la cátedra en ASIS, cualquier persona debe estar registrada en ASIS con ID. Si no, no lo deja registrar»* | profesor Hugo Nelson, `26:46` | El ID del ASIS es **el identificador de la entidad Asistente**. No hay asistencia migrable sin él |
| **D2** | *«Solo los que estén en esa tabla pueden ingresar al sistema. Si no, no pueden ingresar»* | profesor Carlos Castro, `55:52` | La autenticación se resuelve **contra la tabla cargada**, no contra un registro abierto |
| **D3** | *«Él lo digita; si no está en ASIS, no puede seguir»* | profesor Carlos Castro, `42:19` | Confirma D2 desde el otro lado |
| **D4** | *«Sí o sí, el que vaya para cátedra tiene un código en ASIS, así sea que venga de otra universidad»* | profesor Carlos Castro, `43:17`, ratificado por el profesor Hugo Nelson | Al externo recurrente **se le crea un ID en ASIS**. Es un procedimiento administrativo, no un caso del modelo |
| **D5** | *«Si son externos, nosotros en el formulario sí preguntamos si es externo o no; eso lo podemos depurar antes de pasarlo»* | profesor Hugo Nelson, `43:37` | El externo se **captura y se cuenta**, pero se **filtra** antes del archivo plano |
| **D6** | *«Que nos genere un registro de externos, pero que no nos lo arroje en el archivo plano; que sí podamos descargar cuántos externos han ingresado en 2026-2»* | profesor Hugo Nelson, `56:16` | Informe explícito de externos por periodo. **Es la justificación de `periodo_academico`** |
| **D7** | *«Para el tema de Rutas de Paz sí sería una excepción: ellos entrarían sin programa, pero solo ellos»* | profesor Hugo Nelson, `41:16` | `Codigoprograma` es **opcional**, y el nulo significa algo concreto |
| **D8** | *«Los que están en Rutas de Paz no tienen correo institucional»* | profesor Hugo Nelson, `53:42` | El correo personal **no es un caso raro**: es la única vía para una población entera |
| **D9** | *«El archivo plano son tres: la reunión consecutivo, el ID y el código del programa»* | profesor Hugo Nelson, `32:34` | La salida está cerrada. Ni una columna más |
| **D10** | *«En el ASIS está el número de identificación, la cédula… pero no es la información que se monta como archivo plano»* | profesor Hugo Nelson, `44:01` | La cédula existe en el modelo para **buscar**, no para migrar |
| **D11** | *«A veces los estudiantes, como no se saben el ID, colocan la cédula; toca buscar en ASIS con la cédula para obtener el ID»* | profesor Hugo Nelson, `42:01` | Es exactamente el trabajo manual que el acceso por tres identificadores elimina |
| **D12** | *«Las cátedras siempre le van a quedar por el ID… el programa es importante porque después le da información a Registro de qué programas hizo el estudiante»* | profesor Hugo Nelson, `50:14` | El programa que viaja **no es un adorno**: es el que imputa la asistencia |
| **D13** | *«Es importante los nombres… para que la persona no sea un código»* — y por los **homónimos** | profesor Carlos Castro `52:45`, profesor Hugo Nelson `52:54` | El nombre entra al modelo por una razón operativa, no cosmética |
| **D14** | *«El mismo día sí, a la misma hora no… sí es posible: una cátedra en San Benito, otra virtual y otra en Bello»* | profesor Hugo Nelson, `1:03:33` | **Aparece la sede.** Y aparece la posibilidad de cátedras simultáneas |
| **D15** | *«Cuando es virtual enviamos el enlace; si es presencial, el QR»* | profesor Hugo Nelson, `1:06:53` | La modalidad **determina el canal de entrega**. QR y URL no son lo mismo |
| **D16** | *«Necesitamos el número de reunión, que eso lo podríamos hacer previo»* — el código de reunión se genera **antes**, en el ASIS | profesor Hugo Nelson, `1:03:50`, `1:07:32` | El consecutivo puede venir del ASIS o calcularse. Ver §8, decisión 3 |
| **D17** | Todos los que interactúan con la universidad tienen ID: docentes, estudiantes, egresados. Formatos `30000…` y `300000…`, y códigos antiguos de 6 dígitos | profesor Hugo Nelson, `27:47`, `33:25` | Un solo espacio de identificadores para todos los roles |

### 3.1 El conflicto que hay que resolver

**D2 y D4 dicen que sin ID del ASIS no se entra. D5 y D6 dicen que hay que contar externos.** Las dos cosas no pueden ser ciertas a la vez si el externo nunca entra al sistema.

Hay tres salidas, y **es la decisión más importante que queda abierta**:

| Salida | Qué implica | Costo |
|---|---|---|
| **A · Al externo se le crea ID en ASIS antes de la cátedra** | Es lo que dice D4. El modelo se simplifica: `ID` obligatorio siempre | Carga administrativa previa por cada externo. Inviable para público abierto |
| **B · El externo se registra en el sistema sin ID y nunca migra** | Es lo que pide D5 y D6. `ID` nullable, con marca de externo | Rompe D2: hay que abrir una segunda vía de acceso, sin validación contra la tabla |
| **C · Dos vías declaradas** — quien está en la tabla entra por código/cédula/correo; el externo entra por un formulario reducido, marcado como tal, que **nunca** toca el archivo plano | Cumple D2 para internos, D5 y D6 para externos, y deja el límite explícito en el modelo | Una columna nullable y una regla condicional. **Es la recomendación** |

**Recomendación: C.** Es la única que satisface las cuatro citas sin contradecir ninguna, y el costo es una columna. **Confirmar con el profesor Hugo Nelson y Andrea antes de cerrar la Fase 1.**

---

## 4 · Perfilado de los datos reales

Cada hallazgo se traduce en una decisión de modelado. Se presentan en el orden de autoridad del §0.1.

### 4.1 `USBME_LCONTROL_CATEDRAS` — el listado de reuniones

| Medida | Valor |
|---|---:|
| Filas | 5.711 |
| Eventos distintos | 5.496 |
| Máximo de reuniones en un evento | **59** (`000035428`) |

| # | Hallazgo | Consecuencia |
|---|---|---|
| **H1** | El ID de evento es `000035392` — **nueve caracteres con ceros a la izquierda** | `char(9)`. Como entero se vuelve `35392` y deja de servir para el ASIS |
| **H2** | Las descripciones vienen **truncadas a 30 caracteres**: `REMOCIÓN DE METALES PESADOS DE`, `CURSO FORMATIVO LÓGICO MATEMAT` | Se guarda el nombre completo y se **deriva** el corto de 30. Nunca al revés |
| **H3** | Hay **8 tipos de evento**: `CAAB` (5.449), `DLLH` (188), `DEPR` (44), `SLDI` (16), `ARCU` (5), `MTG` (5), `DIIB` (3), `EIIC` (1) | Catálogo cerrado con clave foránea |
| **H4** | El par `(Evento, Reunión)` **es único en las 5.711 filas** | La clave `UNIQUE (catedra, numero_reunion)` no es una suposición: está verificada contra el dato |
| **H5** | La misma descripción se repite en todas las reuniones de un evento | La descripción pertenece a la **cátedra**, no a la sesión. Justifica separarlas |
| **H6** | La columna *Reunión* llega como `1.0` — **flotante de Excel** | `smallint` en destino, con conversión explícita |
| **H7** | El 95 % son `CAAB` con una sola reunión | El consecutivo hay que garantizarlo, pero el caso normal es reunión 1 |

### 4.2 `Cätedras abiertas DIagrama Entidad -relación` — el punto de partida

Una entidad, *Asistente*, con tres atributos, construida en vivo entre `24:02` y `35:14`.

| Lo que dice | Estado | Por qué |
|---|---|---|
| **Asistente** — *«persona que asiste a las cátedras de forma presencial o virtual; pueden ser estudiantes, docentes o público externo»* | **Conservar** | Es la definición correcta y la dictó el usuario experto |
| *«Una persona es toda aquella que está registrada en Asís»* | **Conservar como restricción** | profesor Carlos Castro en `27:24`: *«eso es importante porque esa es una restricción»*. Es D1 |
| `ID` — código ASIS, *«máximo 10 dígitos»* | **Corregir a 15** | Se acordó el tope a ojo (`33:50` — *«pongámosle un tope»*). El dato real tiene **9.553 filas de 11 caracteres** y valores alfanuméricos como `1000513C`. Ver §4.3 |
| `NumeroIdentidad` — máx. 20, opcional | **Conservar, mover a tabla** | H10: una persona tiene varios documentos históricos. Y por D10 y D11 sirve para **buscar**, no para migrar |
| `Codigoprograma` — máx. 10, opcional | **Conservar opcional, mover a tabla** | D7 justifica el nulo (Rutas de Paz) y H12 obliga al `N:M` |
| — | **Agregar** | `nombre` (D13, homónimos), `correo_institucional` y `correo_personal` (acuerdo de `1:50:43`) |
| — | **Agregar** | Los tres identificadores de acceso son **claves candidatas** consultables por igual (D11) |

> **El archivo tiene una entidad y el modelo va a tener treinta y tres.** Eso no lo descalifica: *Asistente* es la entidad correcta por dónde empezar. Las demás salen de preguntar qué es lo que el asistente asiste, con qué autoridad se afirma quién es, y qué se hace después con ese registro.

### 4.3 `USBME_EMPLID_CATED_V1` — el maestro de personas · *apoyo*

Este es el archivo que la reunión acordó **reemplazar** por uno de seis columnas. Se perfila igual, porque las tres columnas nuevas llegarán con los mismos vicios.

| Medida | Valor |
|---|---:|
| Filas | 16.093 |
| Documentos distintos | 15.517 |
| **ID distintos** | **14.808** |
| Códigos de programa distintos | **105** |

| # | Hallazgo | Consecuencia |
|---|---|---|
| **H8** | El ID **no siempre es numérico**: `1000513C`, `970577C` | `varchar`, nunca `integer`. Un tipo numérico habría rechazado esas filas |
| **H9** | El ID mide entre **6 y 11 caracteres** (223 de 6 · 6.225 de 7 · 9.553 de 11) | Confirma lo que el profesor Hugo Nelson intuyó en `33:36` (*«es variable»*) y desmiente el tope de 10 que se fijó a ojo |
| **H10** | **707 ID tienen más de un número de documento**; ningún documento tiene más de un ID | El documento es **multivaluado** → tabla propia con un solo vigente. La dependencia va `documento → ID`, no al revés |
| **H11** | Hay pares `(ID, programa)` **repetidos**, hasta tres veces | El archivo no es único por esa pareja. La carga **debe deduplicar** |
| **H12** | Un mismo ID aparece con **varios programas** | `N:M` con atributos → tabla. Coincide con lo que el profesor Carlos Castro preguntó en `50:07` sobre estudiar un doctorado siendo profesor |
| **H12b** | De los 105 códigos de programa, **`MCDER` tiene 5 caracteres y `MCCP` tiene 4** — no todos son `M`+4 dígitos | `varchar(5)`, **no `char(5)`**: `char` rellenaría `MCCP` a `MCCP␣` y ese espacio viajaría al archivo plano, justo lo que el manual prohíbe |
| **H13** | El documento mide entre **5 y 11 dígitos** | `varchar(20)`. Un entero habría perdido los de 11 y los ceros a la izquierda |

### 4.4 `Pedagogía Electoral` — el formulario actual · *apoyo*

164 respuestas. Es la evidencia de por qué el sistema hace falta. El profesor Hugo Nelson lo mostró en la reunión (`1:06:25`) como ejemplo de una cátedra única.

| # | Hallazgo | Consecuencia |
|---|---|---|
| **H14** | La columna *Correo electrónico* dice `anonymous` en **todas** las filas | El formulario es anónimo: **no hay identidad**. Es justo lo que resuelve la clave al correo |
| **H15** | El tipo de documento aparece de más de diez formas: `Cedula`, `CC`, `C.c`, `Cédula de cuidadania`… | Catálogo con clave foránea. El asistente **selecciona**, no escribe |
| **H16** | El código llega contaminado: `ID:30000141979` | En el sistema nuevo ni se digita: sale de la sesión autenticada |
| **H17** | El programa viene en texto libre y con errores: `Psicológica`, `Entrenamiento Deportivo.`, una celda con `Facultad de artes integradas` y `Arquitectura` en dos líneas | Tabla **`alias_programa`** que mapea texto libre → código `M0xxx` |
| **H18** | Las horas de inicio y fin están a segundos entre asistentes | Registro presencial simultáneo: ventana corta y concurrida. Índices desde el diseño |
| **H19** | Sobran las columnas *Total de puntos*, *Puntos: X*, *Comentarios: X* | Artefactos de cuestionario de Forms. Se descartan |

---

## 5 · El modelo — 33 entidades → 37 tablas

La diferencia entre entidades y tablas son las relaciones `N:M` con atributos, que en Chen son rombos y solo se vuelven tabla al transformar.

| Bloque | De qué trata | Tablas | En el MVP |
|---|---|---:|---:|
| **A · Asistentes e identidad** | Quién es cada asistente y con qué autoridad se afirma | 6 | 5 |
| **B · Estructura académica** | Programas, facultades, periodos y quién estudia qué | 4 | 3 |
| **C · Cátedras, sesiones y sedes** | El evento, sus reuniones, dónde y cuándo | 7 | 5 |
| **D · Acceso y registro** | El QR, el enlace, la clave al correo y el acto de registrarse | 3 | 3 |
| **E · Encuesta de calidad** | Cuestionario parametrizable y sus respuestas | 6 | 4 |
| **F · Integración con el ASIS** | Cargas de entrada, lotes de salida y su resultado | 6 | 2 |
| **G · Seguridad, configuración y auditoría** | Roles, parámetros y bitácora | 5 | 3 |
| | | **37** | **25** |

### 5.1 · Bloque A — Asistentes e identidad

| Tabla | Contenido | Punto de diseño |
|---|---|---|
| `asistente` | `id_asistente` sustituto · **`id_asis`** único · nombres · apellidos · `correo_institucional` · `correo_personal` · celular · `es_externo` · `activo` | Conserva el nombre que dictó el usuario. `id_asis` es la **clave candidata natural** (D1). Los dos correos por acuerdo de `1:50:43`; el personal por D8 |
| `tipo_documento` | CC, TI, CE, PA, PEP | Cierra el desorden de H15 |
| `documento_asistente` | `fk_asistente` · `fk_tipo_documento` · `numero` · `vigente` | H10 y D10. Multivaluado → tabla. `UNIQUE (tipo, numero)` |
| `tipo_vinculacion` | Estudiante, Docente, Administrativo, Egresado, Rutas de Paz, Externo · **`es_interno`** · **`exige_programa`** | Los tres tipos que enumera la definición del usuario, más los que salieron en la reunión. `exige_programa` en falso para Rutas de Paz resuelve D7 **como dato, no como excepción codificada** |
| `vinculacion_asistente` | `fk_asistente` · `fk_tipo_vinculacion` · **`fecha_ini`** · `fecha_fin` | `fecha_ini` **en la clave primaria**: un egresado fue estudiante y puede volver a serlo |
| `consentimiento_datos` | `fk_asistente` · versión de la política · `aceptado_en` · IP | Ley 1581 de 2012. Se guardan cédulas y correos personales de externos |

### 5.2 · Bloque B — Estructura académica

| Tabla | Contenido | Punto de diseño |
|---|---|---|
| `facultad` | `id_facultad` · nombre · `fk_facultad_padre` **recursiva** | Permite el roll-up del informe por programa y da la consulta recursiva |
| `programa_academico` | **`codigo` `char(5)` PK natural** (`M0221`, `M0286`) · nombre · `fk_facultad` · nivel · `activo` | Los 105 códigos de H12. Clave natural porque **es la que viaja al ASIS** |
| `periodo_academico` | `2026-1`, `2026-2` · fecha inicio · fecha fin | Lo pidió el profesor Hugo Nelson por su nombre en D6 |
| `programa_asistente` | `fk_asistente` · `fk_programa` · `fk_periodo` · estado | H11 y H12. `N:M` con atributos → tabla. La clave impide el duplicado del archivo |

### 5.3 · Bloque C — Cátedras, sesiones y sedes

| Tabla | Contenido | Punto de diseño |
|---|---|---|
| `tipo_evento` | Los 8 códigos de H3 | Catálogo cerrado |
| `sede` | San Benito · Bello · Virtual | **Aparece por D14.** Sin ella no se puede distinguir entre cátedras simultáneas |
| `modalidad` | Presencial · Virtual · Telepresencial · Híbrida | **Por D15 determina el canal de entrega**, así que no es decorativa |
| `dependencia` | Unidad que organiza · `fk_dependencia_padre` recursiva | Bienestar, Pastoral, facultades |
| `catedra` | `id_catedra` sustituto · **`id_evento_asis` `char(9)` único** · `nombre` completo · `nombre_asis` **derivado a 30** · `fk_tipo_evento` · `fk_dependencia` | H1 y H2. La columna derivada impide guardar el nombre truncado |
| `sesion` | `id_sesion` · `fk_catedra` · **`numero_reunion`** · título · `inicio` · `fin` · `fk_modalidad` · `fk_sede` · lugar o enlace · cupo · `fk_periodo` · estado | **`UNIQUE (fk_catedra, numero_reunion)`** — verificado en H4. Aquí muere el paso 2 del manual |
| `ponencia` | `fk_sesion` · `fk_asistente` · rol | `N:M` con atributo → tabla |

### 5.4 · Bloque D — Acceso y registro · **el núcleo**

| Tabla | Contenido | Punto de diseño |
|---|---|---|
| `enlace_registro` | `id_enlace` · `fk_sesion` · **`token` único aleatorio** · `url_publica` · `ruta_imagen_qr` · **`canal`** (QR o enlace) · `ventana tstzrange` · `usos_maximos` · `revocado_en` · `fk_usuario_crea` | `canal` por D15. La ventana como **rango**, no dos columnas sueltas: habilita el `EXCLUDE` y el operador de contención |
| `clave_acceso` | `id_clave` · `fk_asistente` · `fk_enlace` · **`clave_hash`** · `enviado_a` · **`es_correo_institucional`** · `generado_en` · `expira_en` · `usado_en` · `intentos` · `ip` | **Nunca la clave en claro.** `es_correo_institucional` es la columna que responde a `55:32` — *«a mí no me gusta el correo que no sea institucional; déjame, yo lo resuelvo»*. El modelo deja el dato listo para cuando se resuelva |
| `registro_asistencia` | `id_registro` · `fk_sesion` · `fk_asistente` · `fk_enlace` · `registrado_en` · **`fk_programa_snapshot`** · **`fk_tipo_vinculacion_snapshot`** · `origen` · IP · `user_agent` | `UNIQUE (fk_sesion, fk_asistente)`. **Las dos columnas de instantánea son la decisión más importante del bloque:** por D12 el programa que viaja al ASIS es el que la persona tenía el día de la cátedra |

### 5.5 · Bloque E — Encuesta de calidad

| Tabla | Contenido | Punto de diseño |
|---|---|---|
| `encuesta` | Nombre · versión · vigencia | *«El administrador parametriza los valores que considere»* |
| `tipo_pregunta` | Escala 1-5 · opción única · opción múltiple · texto libre · sí/no | Determina dónde se guarda la respuesta |
| `pregunta` | `fk_encuesta` · enunciado · orden · `fk_tipo_pregunta` · `obligatoria` | |
| `opcion_pregunta` | `fk_pregunta` · etiqueta · valor · orden | Solo para las de opción |
| `respuesta_encuesta` | `fk_registro` **único** · `respondida_en` · `completa` | Una encuesta por asistencia |
| `respuesta_item` | `fk_respuesta` · `fk_pregunta` · `valor_numerico` · `valor_texto` · `fk_opcion` | **`CHECK` condicional:** exactamente una columna de valor según el tipo |

### 5.6 · Bloque F — Integración con el ASIS

| Tabla | Contenido | Punto de diseño |
|---|---|---|
| `lote_carga_asistente` | Archivo · fecha · usuario · filas leídas, aceptadas y rechazadas | *«Ese archivo lo cargamos en la base de datos como una tabla»* (`52:57`). Necesita **evidencia**, no un mensaje en pantalla |
| `novedad_carga` | `fk_lote` · número de fila · contenido crudo · motivo del rechazo | Sin esto, H8 y H11 se manifiestan como *«cargó menos filas de las que tenía»* |
| `alias_programa` | `texto_normalizado` único · `fk_programa` · origen | H17. Permite migrar lo histórico y lo que siga llegando por Forms |
| `estado_proceso` | En cola · En curso · Error · Correcto · Incorrecto | **Los cinco estados literales del manual**, página 6 |
| `lote_migracion` | `fk_sesion` · nombre del proceso (`ME_MIGRACION_CATEDRA`) · archivo generado · `instancia_proceso_asis` · `fk_estado_proceso` · totales · `fk_usuario` | Cierra el ciclo con el *Monitor Procesos* |
| `detalle_migracion` | `fk_lote` · `fk_registro` · `id_asis_enviado` · `programa_enviado` · `reunion_enviada` · resultado · mensaje | **Se guarda lo que se envió**, no lo que hoy dice la tabla. Es la única forma de auditar un rechazo seis meses después |

### 5.7 · Bloque G — Seguridad, configuración y auditoría

| Tabla | Contenido | Punto de diseño |
|---|---|---|
| `usuario` | `fk_asistente` · usuario único · `clave_hash` · `activo` · último acceso | El administrador **es** una persona del ASIS: no se duplican nombres ni correos |
| `rol` | Administrador · Coordinador de dependencia · Consulta | |
| `rol_por_usuario` | `fk_usuario` · `fk_rol` · **`fecha_ini`** · `fecha_fin` | Sin la fecha en la clave, nadie puede recuperar un rol que ya tuvo |
| `parametro` | Clave · valor · tipo · descripción · quién y cuándo lo cambió | Vigencia de la clave, longitud, intentos máximos, minutos de apertura y cierre por defecto |
| `bitacora` | Fecha · usuario · tabla · operación · llave · `datos_antes jsonb` · `datos_despues jsonb` | Obligatoria por el tipo de dato que se maneja |

---

## 6 · Las reglas de negocio

Las **D1–D17** del §3 son el insumo. Aquí se numeran como reglas implementables. Se marcan con ◆ las que salen textualmente de la reunión.

| # | Regla | Origen | Mecanismo |
|---|---|---|---|
| **RN-01** ◆ | Nadie se registra si no está en la tabla del ASIS | D1, D2, D3 | Clave foránea + procedimiento de acceso |
| **RN-02** ◆ | El `id_asis` es único y es la clave candidata natural del asistente | D1 | `UNIQUE` |
| **RN-03** | El `id_asis` es alfanumérico de 6 a 15 caracteres | H8, H9 | Dominio + `CHECK` |
| **RN-04** | Un número de documento identifica a lo sumo un asistente | H10 | `UNIQUE (tipo, numero)` |
| **RN-05** | Un asistente puede tener varios documentos, **solo uno vigente** | H10 | Índice único parcial |
| **RN-06** ◆ | El acceso se puede intentar por **código, documento o correo**, indistintamente | D11, `57:20` | Tres índices únicos + función de resolución |
| **RN-07** ◆ | El programa es obligatorio salvo para las vinculaciones que no lo exigen | D7 | **`CHECK` condicional** contra `tipo_vinculacion.exige_programa` |
| **RN-08** ◆ | El asistente externo se registra y se cuenta, pero **nunca entra al archivo plano** | D5, D6 | Vista + `WHERE` en la exportación |
| **RN-09** | El ID de evento del ASIS son 9 caracteres con ceros a la izquierda | H1 | `char(9)` + `CHECK` |
| **RN-10** ◆ | El número de reunión es consecutivo por cátedra y empieza en 1 | H4, D16 | `UNIQUE` + función `fn_siguiente_reunion` |
| **RN-11** | El nombre corto que viaja al ASIS se **deriva** a 30 caracteres | H2 | Columna generada |
| **RN-12** ◆ | Pueden existir cátedras simultáneas en sedes distintas | D14 | Sin restricción de exclusión entre sedes; **sí** dentro de la misma |
| **RN-13** ◆ | Una sesión presencial se difunde por QR; una virtual, por enlace | D15 | `CHECK` entre `modalidad` y `enlace_registro.canal` |
| **RN-14** | Cada sesión tiene a lo sumo un enlace vigente | — | Índice único parcial |
| **RN-15** | Solo se admiten registros dentro de la ventana | `.docx` | `CHECK` sobre el rango + disparador |
| **RN-16** | El token es aleatorio, único y no adivinable | `.docx` | `gen_random_uuid()` / `pgcrypto` |
| **RN-17** ◆ | La clave se envía al correo **para impedir que uno registre a otro** | `1:04:51` | Procedimiento de emisión |
| **RN-18** | La clave se guarda **solo cifrada**, expira y admite un máximo de intentos | — | `digest()` + `CHECK` + disparador |
| **RN-19** ◆ | Si el correo no es institucional, **queda marcado** | `55:32`, D8 | Columna `es_correo_institucional` derivada por disparador |
| **RN-20** | Una clave usada no se reutiliza | — | Disparador |
| **RN-21** ◆ | Un asistente se registra **a lo sumo una vez** por sesión | `1:04:51` | `UNIQUE (sesion, asistente)` |
| **RN-22** ◆ | El registro guarda **copia** del programa y la vinculación del momento | D12 | Disparador de derivación |
| **RN-23** | Una encuesta por registro, como máximo | `.docx` | `UNIQUE` |
| **RN-24** | Solo se responden preguntas de la encuesta de esa sesión | — | Clave foránea compuesta |
| **RN-25** | El tipo de pregunta determina la columna de la respuesta | — | **`CHECK` condicional** |
| **RN-26** | Toda pregunta obligatoria debe tener respuesta | — | **No declarativa.** Procedimiento de cierre |
| **RN-27** ◆ | El archivo plano lleva **exactamente tres columnas**: reunión, ID, programa | D9, PDF | Función de exportación, probada carácter a carácter |
| **RN-28** ◆ | Solo se migran registros con ID y con programa | D9, D12 | Vista + procedimiento |
| **RN-29** | Un registro puede intentarse varias veces pero solo queda **aceptado en un lote** | — | Índice único parcial |
| **RN-30** | Los estados del proceso del ASIS son los cinco del manual | PDF | Clave foránea |
| **RN-31** | Un usuario puede volver a tener un rol que ya tuvo | — | **`fecha_ini` en la clave primaria** |
| **RN-32** | Nadie se elimina: baja lógica | — | `activo` + revocación de `DELETE` |
| **RN-33** | Todo dato personal exige consentimiento vigente | Ley 1581 | Vista de control |
| **RN-34** | Ninguna clave en claro | — | Revisión de esquema |
| **RN-35** | Toda modificación de un registro de asistencia queda en bitácora | — | Disparador `AFTER` |
| **RN-36** | Dos enlaces de la misma sesión no se solapan en el tiempo | — | **`EXCLUDE USING gist`** |
| **RN-37** | El fin de una sesión no puede ser anterior a su inicio | — | `CHECK` |
| **RN-38** | Si la sesión tiene cupo, no se admiten más registros | — | **No declarativa.** Disparador con bloqueo |

**Reparto previsto:** ~18 declarativas · ~5 parciales · ~15 por disparador, función o procedimiento.

---

## 7 · Los informes

Los cuatro del `.docx` en negrita; los pedidos en la reunión marcados con ◆.

| # | Informe | Origen |
|---|---|---|
| **I1** | Asistentes de una sesión, con programa y vinculación | Operación diaria |
| **I2** | **Estadísticas por programa** | Informe 1 del `.docx` |
| **I3** | Estadísticas por facultad — `WITH RECURSIVE` | Roll-up de I2 |
| **I4** | **Internos contra externos** | Informe 2 del `.docx` |
| **I5** ◆ | **Externos que ingresaron en un periodo** — *«cuántas personas externas han ingresado en 2026-2»* | profesor Hugo Nelson, `56:16` |
| **I6** | **Evaluación de las cátedras** — promedio por pregunta, sesión y cátedra | Informe 3 del `.docx` |
| **I7** | **Archivo plano del ASIS** — tres columnas exactas | Informe 4 del `.docx` · D9 |
| **I8** ◆ | Siguiente número de reunión de una cátedra | Reemplaza el paso 2 del manual |
| **I9** ◆ | Asistentes que digitaron cédula y hubo que resolver a ID | D11 · mide el trabajo manual eliminado |
| **I10** | Registrados sin ID o sin programa — los que bloquean la migración | Cola de trabajo del gestor |
| **I11** | Asistentes con más de un documento — los 707 casos de H10 | Calidad de datos |
| **I12** | Tasa de respuesta de la encuesta por sesión | Mide si la encuesta estorba |
| **I13** | Embudo: enlaces → claves enviadas → claves usadas → registros → encuestas | Dónde se cae la gente |
| **I14** ◆ | Asistencia por sede y por modalidad | D14, D15 |
| **I15** | Asistentes que van a más de *n* cátedras | Fidelización |
| **I16** | Cátedras con sesiones sin migrar | Deuda operativa |
| **I17** | Registros fuera de ventana — **debe dar cero** | Control de RN-15 |
| **I18** ◆ | Claves enviadas a correo **no institucional** | `55:32` · insumo para la decisión pendiente |
| **I19** | **Trazabilidad completa:** asistente → enlace → clave → registro → encuesta → lote → resultado del ASIS | Justifica el bloque F |
| **I20** | Comparativo de evaluación entre periodos | Requiere `periodo_academico` |

---

## 8 · Decisiones que hay que poder defender

| # | Decisión | Alternativa | Por qué |
|---|---|---|---|
| 1 | **Claves sustitutas** en `asistente`, `catedra`, `sesion`, `registro` | `id_asis` e `id_evento_asis` como claves primarias naturales | Los naturales se conservan como **claves candidatas con `UNIQUE`**, con lo que D1 se cumple igual. Pero un formato que ya cambió dos veces (H9, D17) no debe propagarse por todo el modelo |
| 2 | **Clave natural** en `programa_academico` y en los catálogos | Sustituta también aquí | Es el código que **viaja al ASIS** (D9). Un sustituto obligaría a un `JOIN` en la consulta más crítica |
| 3 | ~~El consecutivo lo calcula el sistema~~ → **RESUELTO POR EL DATO (H12d):** el ASIS lleva un contador propio; el sistema solo **propone** para cátedras nuevas | Derivarlo siempre con `max+1` | Se comprobó sobre las 5.711 filas: solo 588 de 5.481 eventos de una reunión empiezan en 1. `numero_reunion_asis` es la autoridad. **Ya no hay que preguntarlo** |
| 4 | `sede` como entidad | Atributo de texto en `sesion` | D14: la sede es lo que distingue dos cátedras a la misma hora. Como texto, I14 no se puede escribir |
| 5 | **Instantánea** de programa y vinculación en el registro | Derivar siempre de `programa_asistente` | D12: la asistencia se imputa al programa de ese día, y el archivo debe ser reproducible meses después |
| 6 | `exige_programa` como **columna del catálogo** de vinculación | `CHECK` con la lista de excepciones escrita | D7 habla de Rutas de Paz hoy; mañana será otra. Habilitar una excepción debe ser un `UPDATE`, no un `ALTER` |
| 7 | Ventana horaria como **`tstzrange`** | Dos columnas `timestamptz` | Habilita RN-36 y RN-15 de forma declarativa |
| 8 | Encuesta **parametrizable** en cuatro tablas | Columnas fijas `pregunta_1`…`pregunta_5` | El `.docx` dice que el administrador parametriza |
| 9 | `documento_asistente` como tabla | Columna en `asistente` | H10: 707 casos reales lo romperían |
| 10 | `alias_programa` como tabla viva | Script de migración de una vez | H17: los formularios en texto libre seguirán llegando durante la transición |
| 11 | `id_asis` **nullable** solo para externos, según la salida C del §3.1 | Obligatorio siempre (salida A) | Es la decisión abierta. **No se implementa hasta confirmarla** |
| 12 | Bitácora en `jsonb` | Una tabla espejo por tabla | Una tabla contra treinta y siete |

---

## 9 · El plan de trabajo

### Fase 0 · Levantamiento y perfilado — **ejecutada**

Lectura de las ocho fuentes y perfilado de los tres Excel. Salida: los §1 a §4 de este documento.

**Pendientes:** confirmar la salida del §3.1 y la decisión 3 del §8 con el profesor Hugo Nelson y Andrea · conseguir el tramo `1:07:41 – 1:49:13` · gestionar con Carlos el informe ampliado del ASIS.

### Fase 1 · Diseño conceptual — `SOLUCION/MER/`

Es el entregable principal, por `0:03`. Once documentos.

| # | Archivo | Contenido |
|---|---|---|
| 00 | `00-INDICE.md` | Índice y el modelo en una tabla |
| 01–06 | Entidad · Atributo · Tipos de atributo · Relación · Cardinalidad · Opcionalidad | Los seis conceptos, **con los ejemplos que usó el profesor Carlos Castro en la reunión** — autor, libro, ejemplar — y su traducción al dominio de cátedras |
| 07 | `07-Entidades-del-Proyecto.md` | Las 33 entidades por bloque, **cada una con su descripción escrita**, su identificador y por qué es entidad y no atributo |
| 08 | `08-Atributos-del-Proyecto.md` | Compuestos, multivaluados, derivados y **los nulos que significan algo** — `Codigoprograma` de Rutas de Paz a la cabeza |
| 09 | `09-Relaciones-del-Proyecto.md` | Las relaciones **con verbo**, su frase en español en ambas direcciones, cardinalidad y min-max |
| 10 | `10-Diagramas-MER.md` | Vista general y seis vistas temáticas, **en notación de Chen** |
| **11** | **`11-MER-de-Acceso-y-Registro.md`** | **El centro:** el flujo enlace → clave → registro, y las tres estructuras difíciles |

**Las tres estructuras difíciles de este proyecto:**

1. **La instantánea contra la referencia.** `registro_asistencia` apunta a `programa_academico` *y* el asistente tiene programas en `programa_asistente`. No es redundancia: son dos hechos distintos, y D12 lo exige.
2. **La regla condicional entre atributos.** Programa obligatorio salvo para quien no lo exige (RN-07), y el tipo de pregunta que decide la columna de respuesta (RN-25). Ninguna clave foránea las expresa.
3. **La participación mínima de uno.** Toda pregunta obligatoria debe tener respuesta (RN-26). Una clave foránea garantiza que *lo que se inserte exista*, no que *se inserte algo*.

**Además, y como entregable propio:** se **actualiza el archivo `Cätedras abiertas DIagrama Entidad -relación.xlsx`** con las 33 entidades y sus descripciones, respetando el formato y la convención de nombres que fijó el profesor Carlos Castro. Él pidió explícitamente que ese archivo se mantenga vivo (`24:59`).

### Fase 2 · Diseño lógico — `SOLUCION/MR/`

| # | Archivo | Contenido |
|---|---|---|
| 00 | `00-INDICE.md` | Resumen numérico |
| 01 | `01-Esquema-Relacional.md` | Las 37 tablas con primarias, candidatas y foráneas |
| 02 | `02-Dependencias-y-Normalizacion.md` | Dependencias funcionales, claves candidatas por el método del cierre, 1FN → BCNF |
| 03 | `03-Transformacion-MER-a-MR.md` | Una fila por entidad y por relación, con la regla aplicada |
| 04 | `04-Estructuras-de-Acceso.md` | Las tres estructuras difíciles, con alternativas y decisión |
| 05 | `05-Trazabilidad.md` | Cobertura tabla × informe · las 38 reglas · **las 17 citas D1–D17 y dónde se cumple cada una** · matriz CRUD |
| 06 | `06-Sustentacion.md` | Las preguntas de sustentación, respondidas |

**El caso de normalización viene regalado.** No hay que inventarlo: `USBME_EMPLID_CATED` *es* una tabla no normalizada. Sus 16.093 filas `(documento, ID, programa)` tienen la dependencia parcial `documento → ID` sobre la clave `(documento, programa)`, y de ahí salen las tres anomalías de libro:

- **De inserción** — no se puede registrar a alguien que aún no tiene programa. **Que es exactamente el caso de Rutas de Paz (D7).**
- **De actualización** — corregir un ID exige tocar todas sus filas de programa. **Los 707 casos de H10.**
- **De borrado** — dar de baja el último programa borra a la persona.

La descomposición en `asistente` + `programa_asistente` las elimina. Es el mejor ejemplo pedagógico del proyecto, y es real.

### Fase 3 · Diseño físico — `SOLUCION/fisico_postgres/`

| Script | Contenido |
|---|---|
| `00-crear-bd.sql` | Base, codificación, esquema y extensiones: **`pgcrypto`** (tokens y hash de la clave), **`btree_gist`** (RN-36), **`citext`** (correos), **`unaccent`** y **`pg_trgm`** (el emparejamiento difuso de H17) |
| `01-ddl-asistentes.sql` | Bloque A |
| `02-ddl-academico.sql` | Bloque B |
| `03-ddl-catedras.sql` | Bloque C, con la columna generada de RN-11 |
| `04-ddl-registro.sql` | Bloque D, con el `tstzrange` y el `EXCLUDE` de RN-36 |
| `05-ddl-encuesta.sql` | Bloque E, con el `CHECK` condicional de RN-25 |
| `06-ddl-integracion.sql` | Bloque F |
| `07-ddl-seguridad.sql` | Bloque G |
| `08-constraints-fk.sql` | Las claves foráneas, con nombre y política de borrado **declarada una por una** |
| `09-indices.sql` | Cada índice **justificado por un informe**, con su plan. Incluye los tres de RN-06 — código, documento y correo — y el `gin_trgm_ops` de `alias_programa` |
| `10-triggers.sql` | RN-10, RN-15, RN-18, RN-19, RN-20, RN-22, RN-35, RN-38 |
| `11-funciones-procedimientos.sql` | `fn_siguiente_reunion` · `fn_generar_token` · **`fn_resolver_asistente`** (los tres identificadores de RN-06) · `sp_emitir_enlace` · `sp_solicitar_clave` · `sp_validar_clave_y_registrar` · **`fn_exportar_asis`** · `sp_cerrar_encuesta` · `fn_resolver_programa` |
| `12-datos-catalogos.sql` | Tipos de documento y de vinculación, los 8 tipos de evento, los 5 estados del proceso, sedes, modalidades, roles, parámetros |
| `13-carga-asis.sql` | **Carga real** de los 105 programas, los 5.496 eventos y las 16.093 filas del maestro, vía `COPY` a tablas de paso, con depuración documentada |
| `14-datos-prueba.sql` | Pedagogía Electoral reconstruida: una cátedra, su sesión, su enlace, sus claves, sus 164 registros y sus encuestas |
| `15-vistas.sql` | `v_asistencia_completa` · `v_pendiente_migracion` · `v_evaluacion_sesion` · `v_asistente_vigente` · `v_embudo_registro` · `v_control_ventana` |
| `16-consultas-informes.sql` | Los 20 informes |
| `17-usuarios-permisos.sql` | Roles `admin_catedras`, `coordinador`, `consulta`, `app_registro`. **Con las pruebas que deben fallar** |
| `18-backup-restore.md` | Respaldo, retención y evidencia de restauración |
| `ejecutar-todo.sql` | Todo en orden, con `ON_ERROR_STOP` y verificaciones finales |

**Lo específico de PostgreSQL que este proyecto sí aprovecha:**

| Necesidad | PostgreSQL | Qué costaría en otro motor |
|---|---|---|
| RN-36 · no solapamiento de ventanas | `EXCLUDE USING gist` sobre `tstzrange` | Disparador con bloqueo explícito |
| RN-05, RN-14, RN-29 · unicidad condicional | Índice único **parcial** | En MySQL no existen: hay que emular con columnas generadas |
| RN-11 · nombre corto del ASIS | Columna **generada** `STORED` | Disparador |
| RN-06 · acceso por tres identificadores | `citext` + índices únicos, sin `lower()` disperso por el código | Índices sobre expresiones |
| H17 · texto libre → código de programa | `pg_trgm` + `unaccent` + `GIN` | Tabla de equivalencias exacta, o trabajo manual |
| RN-18 · hash de la clave | `pgcrypto` | Se resuelve en la aplicación |
| I3, I19 · jerarquías | `WITH RECURSIVE` | `CONNECT BY` en Oracle |
| Bitácora | `jsonb` | Una tabla espejo por tabla |

### Fase 4 · Carga real y validación

No se da por buena hasta que los datos reales entren.

1. Cargar los 105 programas, las 5.496 cátedras y sus 5.711 reuniones.
2. Cargar las 16.093 filas del maestro y **verificar que los 707 asistentes con documento múltiple queden en una sola fila** y sus documentos en `documento_asistente`.
3. Reproducir Pedagogía Electoral: mapear las 164 respuestas con `alias_programa` y **dejar registrado cuántas no se resolvieron automáticamente**.
4. **Generar el archivo plano y compararlo carácter por carácter** con uno de los que se cargaron a mano en el ASIS. Es el criterio de aceptación duro, y depende de conseguir un archivo plano de ejemplo — que en la reunión no se tenía a la mano (`44:36`).
5. Ejecutar I17 y las verificaciones de `ejecutar-todo.sql`: deben dar cero.

### Fase 5 · Entrega

`SOLUCION/README.md` y `SOLUCION/MODELO-INTEGRADO.md`: el modelo en una página. Y, por `1:52:02`, un **`PROMPT-PARA-IA.md`**: el modelo redactado como contexto para Gemini, que es el uso que el profesor Carlos Castro le va a dar.

---

## 10 · Cronograma

> ### Estado a 10 de agosto de 2026
>
> **Fases 1, 2, 3 y 5 ejecutadas.** La solución está en [`SOLUCION/`](SOLUCION/) y se construye entera con `psql -f ejecutar-todo.sql`: 37 tablas, 52 claves foráneas, ~41.000 filas reales del ASIS, código de salida 0 y los cuatro controles en cero. Queda la **Fase 4** —validar el archivo plano contra uno real del ASIS—, que depende de que el profesor Hugo Nelson consiga un ejemplo.

| Fase | Entregable | Esfuerzo | Depende de |
|---|---|---:|---|
| 0 | Perfilado — **hecho** | — | — |
| 0b | Confirmar §3.1 y §8.3 con el profesor Hugo Nelson y Andrea | 1 conversación | — |
| 1 | `MER/` — 11 documentos, 7 diagramas de Chen y el Excel actualizado | 2–3 días | 0b |
| 2 | `MR/` — 6 documentos y 4 diagramas | 2 días | 1 |
| 3 | `fisico_postgres/` — 20 archivos | 3–4 días | 2 |
| 4 | Carga real y validación contra el ASIS | 1–2 días | 3 · un archivo plano de ejemplo · el informe ampliado |
| 5 | `README`, `MODELO-INTEGRADO` y `PROMPT-PARA-IA` | medio día | 4 |

**El prototipo de 8 días que anunció el profesor Carlos Castro** (`1:49:55`) cabe con las fases 1 a 3 sobre el **MVP de 25 tablas**. Los bloques F y G completos van después sin tocar lo construido: nada del MVP cambia de forma al agregarlos.

---

## 11 · Riesgos

| # | Riesgo | Impacto | Qué se hace |
|---|---|---|---|
| 1 | El informe del ASIS **no se puede ampliar** con nombre y correos | Sin correo no hay clave: **el mecanismo central deja de funcionar** | Riesgo número uno. El profesor Hugo Nelson lo gestiona con Carlos. Plan B: el asistente digita su correo la primera vez y queda asociado a su ID tras verificarlo |
| 2 | **Correos personales** — Rutas de Paz no tiene institucional (D8) | profesor Carlos Castro dijo *«déjame, yo lo resuelvo»* (`55:52`) y sigue abierto | El modelo marca cada envío (RN-19) e I18 lo cuantifica. **La política se decide con el dato a la vista** |
| 3 | La clave se puede pedir por teléfono — *«esa trampa se puede hacer»* (`1:05:18`) | Suplantación posible | **Riesgo aceptado explícitamente por el director técnico.** Se mitiga con la ventana horaria corta y con I13 |
| 4 | El conflicto interno–externo del §3.1 sin resolver | Bloquea el bloque A | Es el primer punto de la Fase 0b |
| 5 | Registro presencial **concurrente** — 164 personas en 60 segundos (H18) | Contención | Índices desde el diseño; el registro es un solo `INSERT`; probar con carga sintética |
| 6 | Los formatos del ASIS **cambian** — ya cambiaron dos veces (D17) | Rompe la carga | Tablas de paso, `novedad_carga`, y nada de suponer tipos: todo entra como texto y se convierte con evidencia |
| 7 | Datos personales de externos | Ley 1581 de 2012 | `consentimiento_datos` desde el primer día |
| 8 | Los servidores de la unidad de tecnologías **se caen** (`1:49:13`) | Pérdida de operación en vivo | Respaldo documentado y despliegue inicial en el servidor propio del profesor Carlos Castro, como se acordó. Piedad los sube *«cuando esté organizadito»* |

---

## 12 · Lo que hay que confirmar antes de la Fase 1

1. **§3.1 — internos y externos.** ¿Salida A, B o C? Es la decisión que más estructura mueve.
2. ~~**§8.3 — el consecutivo de reunión.**~~ **Resuelto por el dato (H12d):** lo emite el ASIS. Ya no requiere consulta.
3. **El informe ampliado del ASIS.** ¿Carlos puede entregarlo con nombre, correo institucional y correo personal?
4. **Un archivo plano de ejemplo**, para el criterio de aceptación de la Fase 4.
5. **La encuesta.** ¿Cuáles son las preguntas de la primera versión?
6. **La ventana horaria por defecto.** ¿Cuántos minutos antes y después de la sesión?
7. **Las sedes.** ¿San Benito, Bello y Virtual son todas? ¿Hay más?
8. **El tramo `1:07:41 – 1:46:42`** de esta reunión, si aparece.
9. ⏳ **La grabación del 24 de marzo** — el enlace está en el chat de esta reunión. **Descargarla y ampliarle la vigencia antes de que caduque.** Es lo único de la lista que tiene fecha de vencimiento.

---

## 13 · La próxima reunión

El profesor Carlos Castro fijó el seguimiento **dentro de 8 días, hacia las 3:00 p. m.** (`1:48:45`), para mostrar el prototipo corriendo en su servidor. Lo que conviene llevar:

| Qué | Por qué |
|---|---|
| El `MER/` completo, en Chen | Es el entregable que él considera principal (`0:03`) |
| El Excel de entidades actualizado | Él pidió mantenerlo vivo (`24:59`) |
| Las 8 preguntas del §12, en una hoja | Cuatro de ellas mueven estructura; en 8 días no se resuelven solas |
| El cuadro D1–D17 del §3 | Para que confirme que se le entendió, y para dejar por escrito el conflicto del §3.1 |
