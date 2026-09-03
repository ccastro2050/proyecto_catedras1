# 5 · Trazabilidad

Cuatro cuadros: de la reunión al modelo, de las reglas al mecanismo, de los informes a las tablas, y quién puede hacer qué.

---

## 1 · De la reunión al modelo — las 17 reglas duras

Cada afirmación del usuario experto, con el sitio exacto donde se cumple.

| # | Cita | Dónde se cumple |
|---|---|---|
| **D1** | *«Debe estar registrado en ASIS con ID»* `26:46` | `asistente.id_asis` + `chk_asistente_externo` + `sp_solicitar_clave` |
| **D2** | *«Solo los que estén en esa tabla pueden ingresar»* `55:52` | `fn_resolver_asistente` devuelve `NULL` → el procedimiento aborta |
| **D3** | *«Si no está en ASIS, no puede seguir»* `42:19` | idem |
| **D4** | *«Sí o sí tiene un código en ASIS»* `43:17` | `chk_asistente_externo` |
| **D5** | *«Si son externos… lo depuramos antes»* `43:37` | `fn_exportar_asis` filtra `es_externo = false` |
| **D6** | *«Cuántos externos en 2026-2»* `56:16` | `periodo_academico` + informe **I5** |
| **D7** | *«Entrarían sin programa, pero solo ellos»* `41:16` | `tipo_vinculacion.exige_programa` + `fn_trg_registro_validar` |
| **D8** | *«Rutas de Paz no tiene correo institucional»* `53:42` | `correo_personal` nullable + `chk_asistente_correo` |
| **D9** | *«El archivo plano son 3»* `32:34` | `fn_exportar_asis` devuelve **exactamente** 3 columnas |
| **D10** | *«La cédula está en ASIS pero no se monta»* `44:01` | `documento_asistente` existe; **no** aparece en la exportación |
| **D11** | *«Toca buscar en ASIS con la cédula»* `42:01` | `fn_resolver_asistente`, vía 3 — busca en documentos **vigentes y no vigentes** |
| **D12** | *«El programa le da información a Registro»* `50:14` | `fk_programa_snapshot` — la instantánea |
| **D13** | *«Es importante los nombres… homónimos»* `52:45` | `nombres` + `apellidos` separados |
| **D14** | *«San Benito, virtual y Bello»* `1:03:33` | Tabla `sede` + informe **I14** |
| **D15** | *«Virtual el enlace; presencial el QR»* `1:06:53` | `modalidad.canal_difusion` + `fn_trg_enlace_canal` |
| **D16** | *«Necesitamos el número de reunión»* `1:03:50` | `fn_siguiente_reunion` + `numero_reunion_asis` — **ver el hallazgo del §3** |
| **D17** | Códigos `30000…`, `300000…` y de 6 dígitos `27:47` | `id_asis varchar(15)` + `chk_asistente_idasis` |

---

## 2 · Las 38 reglas y su mecanismo

| Mecanismo | Reglas | Cuántas |
|---|---|---:|
| **Declarativo** — lo garantiza el motor | RN-02, 03, 04, 05, 09, 11, 14, 16, 21, 23, 24, 25(parcial), 27, 29, 30, 31, 36, 37 | **18** |
| **Parcial** — declarativo + código | RN-01, 07, 08, 25, 28 | 5 |
| **Disparador** | RN-10, 13, 15, 19, 22, 32, 35, 38 | 8 |
| **Procedimiento** | RN-06, 12, 17, 18, 20, 26, 33, 34 | 8 |
| **Convención revisable** | RN-34 (ninguna clave en claro) | 1 |

### Las cinco que hay que vigilar porque **no** son declarativas

| Regla | Riesgo si el código falla | Cómo se detecta |
|---|---|---|
| RN-15 · dentro de la ventana | Registros fuera de hora | **`v_control_ventana` debe dar cero** |
| RN-26 · preguntas obligatorias | Encuestas incompletas marcadas como completas | Consulta de control en `ejecutar-todo.sql` |
| RN-08 · externos fuera del archivo | Un externo llega al ASIS y lo rechaza | Consulta de control: **cero** |
| RN-22 · instantáneas | El archivo deja de ser reproducible | Comparar dos exportaciones de la misma sesión |
| RN-38 · cupo | Sesión sobrevendida | `count(*) > cupo` por sesión |

> **Las cuatro primeras están automatizadas** al final de [`ejecutar-todo.sql`](../fisico_postgres/ejecutar-todo.sql) y **dan cero** en la ejecución actual.

---

## 3 · Cobertura informe × tabla

| Informe | Tablas que usa | Vista |
|---|---|---|
| I1 · asistentes de una sesión | registro, sesión, cátedra, asistente, programa | `v_asistencia_completa` |
| **I2 · por programa** | + programa_academico | idem |
| I3 · por facultad | + facultad **recursiva** | idem |
| **I4 · internos/externos** | + tipo_vinculacion | idem |
| I5 · externos por periodo | + periodo_academico | idem |
| **I6 · evaluación** | respuesta_item, pregunta, tipo_pregunta | `v_evaluacion_sesion` |
| **I7 · archivo plano** | registro, sesión, asistente | `fn_exportar_asis` |
| I8 · siguiente reunión | cátedra, sesión | `fn_siguiente_reunion` |
| I9 · tres puertas de acceso | asistente, documento_asistente | `fn_resolver_asistente` |
| I10 · no migrables | + lote_migracion | `v_pendiente_migracion` |
| I11 · documentos múltiples | documento_asistente | — |
| I12 · tasa de respuesta | + respuesta_encuesta | `v_embudo_registro` |
| I13 · embudo | + enlace, clave | idem |
| I14 · por sede y modalidad | + sede, modalidad | `v_asistencia_completa` |
| I15 · fidelización | registro, cátedra | idem |
| I16 · deuda de migración | lote_migracion | `v_pendiente_migracion` |
| I17 · control de ventana | registro, enlace | `v_control_ventana` |
| I18 · correos no institucionales | clave_acceso | — |
| I19 · trazabilidad completa | **7 tablas encadenadas** | — |
| I20 · jerarquía | dependencia **recursiva** | — |

**Tablas que no aparecen en ningún informe:** `bitacora`, `novedad_carga`, `parametro`, `consentimiento_datos`, `ponencia`, `opcion_pregunta`, `alias_programa`.

> **Eso no es un defecto.** Cinco son de **soporte** —auditoría, configuración, cumplimiento legal— y dos alimentan procesos, no informes. Lo que sí sería defecto es una tabla de negocio que nadie consulta: no hay ninguna.

---

## 4 · Matriz CRUD por rol

| Tabla | `app_registro` | `coordinador` | `admin` | `consulta` |
|---|:--:|:--:|:--:|:--:|
| `asistente` | — | R | RU | R |
| `documento_asistente` | — | R | RU | R |
| `catedra` · `sesion` | R | **RU + C** | RU + C | R |
| `enlace_registro` | R | **RU + C** | RU + C | R |
| **`clave_acceso`** | **CRU** | **—** | RU | **—** |
| `registro_asistencia` | **C** | RU + C | RU + C | R |
| `respuesta_encuesta` · `respuesta_item` | **C** | R | RU | R |
| `encuesta` · `pregunta` | R | **RU + C** | RU + C | R |
| `lote_migracion` · `detalle_migracion` | — | R | RU + C | R |
| `parametro` | R | R | RU | R |
| **`bitacora`** | — | R | **R** | **—** |

**`D` (borrado) está revocado en todas las tablas y para todos los roles**, incluido el administrador: RN-32, nadie se elimina.

### Las tres cosas que esta matriz dice y hay que poder defender

1. **`app_registro` no puede leer `asistente`.** Resuelve la identidad llamando a `fn_resolver_asistente`, que devuelve solo un identificador. Así la aplicación web **no puede volcarse el maestro de 14.808 personas** aunque la comprometan.
2. **`coordinador` y `consulta` no ven `clave_acceso`.** Los hash de las claves no son información de gestión.
3. **Ni el administrador puede modificar `bitacora`.** Una auditoría que el auditado puede editar no es una auditoría.

> Las tres están **probadas** al final de [`17-usuarios-permisos.sql`](../fisico_postgres/17-usuarios-permisos.sql), con tres bloques que **deben fallar**. Un permiso que no se ha visto fallar no está comprobado.

---

**Anterior:** [04 · Estructuras de acceso](04-Estructuras-de-Acceso.md) · **Siguiente:** [06 · Sustentación](06-Sustentacion.md)
