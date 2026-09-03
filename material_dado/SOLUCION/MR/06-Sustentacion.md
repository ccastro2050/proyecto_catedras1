# 6 · Sustentación — veinte preguntas, respondidas

Ninguna se responde copiando. Están ordenadas de la más probable a la más difícil.

---

### 1 · ¿Por qué `SESION` es una entidad aparte y no un atributo de `CATEDRA`?

Es la misma distinción que el profesor Carlos Castro explicó con `LIBRO` y `EJEMPLAR` (`7:03`). Una cátedra puede dictarse muchas veces; el ASIS exige **el número de reunión** en el archivo plano (`32:34`). Sin `SESION` no hay número que enviar, y una cátedra con 59 reuniones tendría a la misma persona registrada 59 veces sin poder distinguir a cuál asistió.

### 2 · ¿Por qué `id_asis` no es la clave primaria, si el usuario experto dijo que es el identificador?

No lo contradice: `id_asis` es **clave candidata única**, y la restricción del negocio se cumple igual. Pero ese formato **ya cambió dos veces** —códigos de 6 dígitos, `30000…`, `300000…` (`27:47`)— y admite letras (`1000513C`). Un identificador que cambió dos veces no debe quedar copiado en las diez tablas que lo referencian.

### 3 · ¿Por qué el número de documento es una tabla y no una columna?

Porque **707 personas del maestro real tienen más de un documento**. Como columna solo cabe uno, y elegir cuál es perder información — justamente la que hace falta cuando alguien digita su cédula antigua, que es el caso de uso que describió el profesor Hugo Nelson en `42:01`.

### 4 · ¿En qué se diferencian `fk_programa_snapshot` y `programa_asistente`, si guardan lo mismo?

**No guardan lo mismo.** Uno afirma «está matriculado en»; el otro, «esta asistencia se imputó a». Uno cambia cada semestre; el otro **nunca**. La prueba: genere el archivo plano de una sesión, deje que la persona cambie de carrera, y vuelva a generarlo. Con instantánea sale idéntico; con referencia viva, distinto — y el ASIS ya recibió la primera versión.

### 5 · ¿Por qué `fecha_ini` está dentro de la clave primaria de `vinculacion_asistente`?

Sin ella, la clave sería (persona, tipo), y eso significa que **nadie puede volver a tener algo que ya tuvo**: un egresado que se matricula en una maestría vuelve a ser estudiante y el `INSERT` se rechaza. Es el error que no falla ruidosamente: no da mensaje, da un histórico incompleto.

### 6 · ¿Por qué una clave foránea no garantiza que toda encuesta respondida tenga al menos un ítem?

Porque **una clave foránea garantiza que lo que se inserte exista, no que se inserte algo**. Es una participación mínima de uno, y no tiene mecanismo declarativo en SQL. Se resuelve con `sp_responder_encuesta`, que crea cabecera e ítems en una transacción, y se **mide** con una consulta de control que debe dar cero.

### 7 · ¿Por qué `programa_academico.codigo` es `varchar(5)` y no `char(5)`?

Porque el maestro real trae **`MCCP`, de cuatro caracteres**. Con `char(5)`, PostgreSQL lo rellena a `MCCP␣`, y ese espacio viajaría al archivo plano — justo lo que el manual de migración prohíbe: *«verificar que el archivo esté limpio y que no se haya agregado ningún texto adicional»*.

### 8 · ¿Por qué el QR y la URL no son dos entidades?

Son **dos presentaciones del mismo token**. Lo que cambia es el canal de entrega, no el objeto: *«cuando es virtual enviamos el enlace; si es presencial, el QR»* (`1:06:53`). Separarlos duplicaría la ventana horaria y permitiría que las dos copias se contradijeran.

### 9 · ¿Por qué la ventana es un solo atributo y no dos columnas?

Con `tstzrange`, dos cosas son **declarativas**: que no se solapen dos enlaces de la misma sesión (`EXCLUDE USING gist`) y que un instante esté contenido (`@>`). Con dos columnas `timestamptz`, las dos serían código que alguien tendría que mantener.

### 10 · ¿La clave enviada al correo autentica al usuario?

**No.** Es **antisuplantación**: *«yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo; si no, yo te registro a vos y vos me registrás a mí»* (`1:04:51`). Y tiene un límite que el propio director técnico reconoció: *«esa trampa se puede hacer»* (`1:05:18`), porque basta pedir el código por teléfono. Es un riesgo **aceptado explícitamente**, no un descuido.

### 11 · ¿Por qué la encuesta está en cuatro tablas y no en cinco columnas?

Porque el enunciado dice que *«el administrador configura o parametriza los valores que considere»*. Con columnas fijas, cambiar una pregunta es un `ALTER TABLE` en producción y **rompe la comparabilidad histórica**: las respuestas viejas quedarían bajo un enunciado que ya no es el que se preguntó.

### 12 · ¿Por qué `respuesta_item` tiene tres columnas de valor?

Porque el tipo de pregunta decide dónde va la respuesta. La alternativa ortodoxa —especialización, una tabla por tipo— **es correcta y se acepta**, y cuesta tres tablas y una unión en cada consulta de evaluación. La restricción `CHECK` que exige exactamente un valor lleno es lo que impide la corrupción silenciosa.

### 13 · ¿Cómo se hace cumplir que Rutas de Paz entre sin programa, pero solo ellos?

**No se escribe «solo ellos» en el esquema.** Se pone `exige_programa` como columna de `tipo_vinculacion`, y el disparador la consulta. Habilitar una nueva excepción es un `UPDATE` de una fila, no un `ALTER TABLE`. Cuando el usuario experto dice «solo ellos», describe el estado de hoy, no una ley.

### 14 · ¿Por qué no se usó un `CHECK` para esa regla?

Porque **un `CHECK` de PostgreSQL no puede consultar otra tabla**. La regla depende del contenido de `tipo_vinculacion`, así que exige disparador.

### 15 · ¿Por qué `detalle_migracion` repite tres columnas que ya están en otras tablas?

Porque **no son las mismas**: son lo que *se envió*. Si el programa de la persona cambia después del envío, la tabla de origen dirá una cosa y el ASIS tendrá otra. Sin la copia, un rechazo del ASIS es indepurable seis meses después.

### 16 · ¿Cuál es la violación de normalización del archivo original, exactamente?

`USBME_EMPLID_CATED(documento, id_asis, codigo_programa)` tiene clave `(documento, codigo_programa)` y la dependencia **`documento → id_asis`**. `documento` es *parte* de la clave, luego `id_asis` depende **parcialmente** de ella: **viola 2FN**. Sus tres anomalías son reales: no se puede insertar a quien no tiene programa *(es Rutas de Paz)*, corregir un ID exige tocar todas sus filas *(son los 707 casos)*, y borrar el último programa borra a la persona.

### 17 · ¿Por qué `sesion.numero_reunion` no es una columna generada?

Porque PostgreSQL exige que una columna generada dependa **solo de la misma fila**, y el consecutivo depende del máximo de las demás filas de la cátedra. Es un derivado *entre filas*, y eso obliga a disparador.

### 18 · El sistema calcula el número de reunión. ¿Es correcto?

**Solo para las cátedras que nazcan en este sistema.** El dato real lo demuestra: de los 5.481 eventos con una sola reunión, **solo 588 tienen el número 1**; los demás llegan hasta 4348. Y los eventos con muchas reuniones empiezan en 1 pero **con huecos**. El ASIS lleva un contador propio. Por eso existe `numero_reunion_asis`, y por eso **la autoridad es el ASIS**. Este hallazgo apareció al ejecutar, no al modelar.

### 19 · ¿Qué pasa si mañana el informe del ASIS nunca se amplía con nombre y correos?

**El mecanismo central deja de funcionar**, porque sin correo no hay clave que enviar. Es el riesgo número 1 del plan. El plan B está declarado: el asistente digita su correo la primera vez y queda asociado a su ID tras verificarlo. El modelo lo soporta sin cambios — `correo_institucional` y `correo_personal` ya son nullables.

### 20 · ¿Qué se pierde al llevar esto a otro motor?

No cambia la forma, cambia **quién responde** por cada regla:

| Necesidad | PostgreSQL | En otro motor |
|---|---|---|
| No solapamiento de ventanas | `EXCLUDE USING gist` | Disparador con bloqueo explícito |
| Unicidad condicional (4 casos) | Índice único **parcial** | En MySQL no existen: columna generada |
| `nombre_asis` | Columna **generada** | Disparador |
| Texto libre → código de programa | `pg_trgm` + `unaccent` | Tabla de equivalencias exactas, o trabajo manual |
| Bitácora | `jsonb` | Una tabla espejo por tabla (37 más) |
| Jerarquías | `WITH RECURSIVE` | `CONNECT BY` en Oracle |

**La conclusión que hay que poder defender:** en un motor sin `EXCLUDE` ni índices parciales, **cinco reglas pasan de ser garantía del motor a ser código que alguien tiene que mantener**.

---

**Anterior:** [05 · Trazabilidad](05-Trazabilidad.md) · **Nivel siguiente:** [`../fisico_postgres/`](../fisico_postgres/)
