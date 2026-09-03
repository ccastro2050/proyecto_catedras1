# Solución — base de datos de Cátedras Abiertas

**Los tres niveles de diseño, ejecutados.**
Universidad de San Buenaventura, Medellín · PostgreSQL 14+ · esquema `public`

---

## 1 · Qué hay en cada carpeta

| Carpeta | Nivel | Contenido |
|---|---|---|
| [`MER/`](MER/) | **Conceptual** | Los seis conceptos del modelo entidad-relación, las **33 entidades** y las **35 relaciones**, y los diagramas en notación de Chen |
| [`MR/`](MR/) | **Lógico** | Esquema relacional, dependencias funcionales **medidas sobre el dato real**, normalización hasta BCNF, transformación MER→MR, trazabilidad y matriz CRUD |
| [`fisico_postgres/`](fisico_postgres/) | **Físico** | Los **19 scripts ejecutables**, con carga de los datos reales del ASIS y evidencia de ejecución |
| [`MODELO-INTEGRADO.md`](MODELO-INTEGRADO.md) | — | El modelo en una página: las 37 tablas y las decisiones |
| [`PROMPT-PARA-IA.md`](PROMPT-PARA-IA.md) | — | El modelo redactado como contexto para Gemini |

> **Por qué el MER es el entregable principal.** Lo dijo el profesor Carlos Castro en el primer minuto de la reunión: *«hacer un modelo entidad-relación… para mí es de las cosas más importantes»*, y *«con la inteligencia artificial ya no se codifica: uno interactúa con los requerimientos y ya va entregando el código»* (`0:03`, `0:11`). Si el código sale de un modelo, el modelo es el producto.

---

## 2 · El estado, en una línea

**Construido y ejecutado sin errores.** `psql -f ejecutar-todo.sql` → código de salida 0.

| | |
|---|---:|
| Tablas | **37** |
| Vistas | 6 |
| Claves foráneas | 52 |
| Restricciones `CHECK` | 47 |
| Disparadores | 7 |
| Funciones y procedimientos | 10 |
| **Filas reales cargadas del ASIS** | **~41.000** |
| Controles de integridad en cero | **4 de 4** |
| Pruebas de permisos que deniegan | **3 de 3** |

---

## 3 · El modelo en una tabla

| Bloque | Tablas |
|---|---|
| **A · Asistentes e identidad** | `tipo_documento` · `asistente` · `documento_asistente` · `tipo_vinculacion` · `vinculacion_asistente` · `consentimiento_datos` |
| **B · Estructura académica** | `facultad` · `programa_academico` · `periodo_academico` · `programa_asistente` |
| **C · Cátedras y sedes** | `tipo_evento` · `sede` · `modalidad` · `dependencia` · `catedra` · `sesion` · `ponencia` |
| **D · Acceso y registro** | **`enlace_registro` · `clave_acceso` · `registro_asistencia`** |
| **E · Encuesta** | `encuesta` · `tipo_pregunta` · `pregunta` · `opcion_pregunta` · `respuesta_encuesta` · `respuesta_item` |
| **F · Integración ASIS** | `lote_carga_asistente` · `novedad_carga` · `alias_programa` · `estado_proceso` · `lote_migracion` · `detalle_migracion` |
| **G · Seguridad** | `usuario` · `rol` · `rol_por_usuario` · `parametro` · `bitacora` |

**33 entidades → 37 tablas.** La diferencia son las cuatro relaciones `N:M` con atributos, que en Chen son rombos y solo se vuelven tabla al transformar.

---

## 4 · Las seis cosas que este trabajo descubrió

Ninguna estaba en los documentos. Todas salieron de perfilar el dato o de ejecutar.

| # | Hallazgo | Consecuencia |
|---|---|---|
| 1 | El `ID` del ASIS **no son 10 dígitos**: es alfanumérico y llega a **11 caracteres** en 9.553 filas | El tope acordado de palabra en la reunión (`33:53`) habría **rechazado más de la mitad del maestro** |
| 2 | **707 personas tienen más de un documento** | `NumeroIdentidad` no puede ser un atributo simple: es una tabla |
| 3 | **`MCCP` tiene cuatro caracteres** | Con `char(5)`, el archivo del ASIS habría salido con **un espacio de más** |
| 4 | **El número de reunión no es un consecutivo por cátedra** — solo 588 de 5.481 eventos empiezan en 1; hay valores hasta 4348 | **Resuelve con dato** la decisión abierta del plan: la autoridad es el ASIS |
| 5 | El formulario actual es **anónimo** — `anonymous` en las 164 filas | Es exactamente lo que resuelve la clave al correo |
| 6 | Las descripciones del ASIS vienen **truncadas a 30 caracteres** | El nombre completo se guarda; el corto se **deriva** |

---

## 5 · Lo que sigue abierto

Cuatro cosas, y **ninguna bloquea** el prototipo:

| # | Pendiente | Quién |
|---|---|---|
| 1 | **§3.1 · internos y externos.** Las citas se contradicen; el modelo implementa la salida C, marcada como revisable | Profesores Hugo Nelson y Carlos Castro |
| 2 | **El informe ampliado del ASIS** con nombre y los dos correos. Es el **riesgo número 1**: sin correo no hay clave | Carlos (ASIS) |
| 3 | **Un archivo plano de ejemplo** para comparar carácter a carácter | Profesor Hugo Nelson |
| 4 | **La grabación del 24 de marzo** — caduca a los 2 o 3 meses | Profesor Hugo Nelson |

---

## 6 · Cómo revisar este trabajo

### Los seis errores que descalificarían rápido

Si aparece alguno, el resto suele venir mal. **Ninguno está presente**, y aquí está dónde comprobarlo:

| # | Qué buscar | Dónde está resuelto |
|---|---|---|
| 1 | ¿La clave de `vinculacion_asistente` **incluye la fecha**? | [MR 01](MR/01-Esquema-Relacional.md) — sin ella, un egresado no puede volver a ser estudiante |
| 2 | ¿El programa del registro **se lee del vigente**? | [MR 04](MR/04-Estructuras-de-Acceso.md) — sería reescribir el historial |
| 3 | ¿El `id_asis` es **numérico** o de 10? | [físico 01](fisico_postgres/01-ddl-asistentes.sql) — `varchar(15)`, alfanumérico |
| 4 | ¿Existe algo que registre **a qué correo** se envió cada clave? | [físico 04](fisico_postgres/04-ddl-registro.sql) — `enviado_a` y `es_correo_institucional` |
| 5 | ¿El programa es **obligatorio siempre**? | [MR 04](MR/04-Estructuras-de-Acceso.md) — Rutas de Paz entra sin él |
| 6 | ¿Se puede **borrar** un registro de asistencia? | [físico 17](fisico_postgres/17-usuarios-permisos.sql) — `DELETE` revocado a todos |

### Las tres preguntas que separan al que entendió

1. **¿En qué se diferencian `fk_programa_snapshot` y `programa_asistente`, si guardan lo mismo?**
   No guardan lo mismo. Uno dice «está matriculado en»; el otro, «esta asistencia se imputó a». Uno cambia cada semestre; el otro nunca. La prueba está en [MR 04](MR/04-Estructuras-de-Acceso.md).

2. **¿Por qué una clave foránea no garantiza que toda encuesta respondida tenga al menos un ítem?**
   Porque garantiza que *lo que se inserte exista*, no que *se inserte algo*. Es una participación mínima de uno, y no es declarativa en SQL.

3. **¿Por qué «solo ellos» no se escribe en el esquema?**
   Porque describe el estado de hoy, no una ley. Se modela **la categoría de la excepción** — `exige_programa` — y habilitar una nueva es un `UPDATE`.

---

## 7 · Trazabilidad de las fuentes a la solución

| Fuente | Dónde se usó |
|---|---|
| `trascripción del video.txt` | Las **17 reglas duras D1–D17** → [MR 05](MR/05-Trazabilidad.md) |
| `USBME_LCONTROL_CATEDRAS` | Bloque C y la carga real → [físico 13](fisico_postgres/13-carga-asis.sql) |
| `PRIMERA VERSIÓN Ideas software.docx` | Los cuatro informes y el flujo → [físico 16](fisico_postgres/16-consultas-informes.sql) |
| `Cätedras abiertas DIagrama…xlsx` | Punto de partida → [MER 07](MER/07-Entidades-del-Proyecto.md) y el Excel actualizado |
| `Documentación de migración.pdf` | Los cinco estados y el archivo de 3 columnas |
| `USBME_EMPLID_CATED_V1` | El caso de normalización → [MR 02](MR/02-Dependencias-y-Normalizacion.md) |
| `Pedagogía Electoral` | La calidad real del formulario → `alias_programa` |

---

**El plan que originó todo:** [`../PLAN-BD-CATEDRAS-ABIERTAS.md`](../PLAN-BD-CATEDRAS-ABIERTAS.md)
