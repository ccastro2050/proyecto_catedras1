# Contexto para la IA — Cátedras Abiertas

> **Para qué es este archivo.** El profesor Carlos Castro dijo en `58:52` que el documento de requisitos *«va a ser para la IA… así se va a hacer el prompt; entre menos espacios tenga, más cortico es el prompt»*, y en `1:52:02` que abriría el prototipo **con Gemini** para irle metiendo funcionalidades.
>
> Esto es lo que a ese prompt le faltaba: **el modelo de datos, cerrado y verificado**. Péguelo como contexto antes de pedir código. Con esto, la IA no tiene que adivinar la base de datos — y adivinarla es donde se equivoca.

---

## Qué es el sistema

Registro y control de asistencia a cátedras abiertas de la Universidad de San Buenaventura, Medellín. Sustituye un formulario anónimo de Microsoft Forms y una migración manual al sistema académico **ASIS** (PeopleSoft).

**Dos roles:** asistente y administrador.

**Flujo del asistente:** escanea un QR o abre un enlace → digita **su código ASIS, su cédula o su correo** (cualquiera de los tres) → el sistema le envía una clave de un solo uso al correo → entra → ve la imagen corporativa y el nombre de la cátedra → responde una encuesta rápida.

**Flujo del administrador:** carga el archivo de personas del ASIS → carga las cátedras → **con un botón** genera el QR y la URL de una sesión, con hora de apertura y cierre → saca cuatro informes: por programa, internos contra externos, evaluación de las cátedras, y **el archivo plano de tres columnas** que exige el ASIS.

---

## La base de datos

**PostgreSQL 14+**, esquema `public`, **37 tablas**. Extensiones: `pgcrypto`, `btree_gist`, `citext`, `unaccent`, `pg_trgm`.

### Tablas por bloque

```
A · asistente, tipo_documento, documento_asistente,
    tipo_vinculacion, vinculacion_asistente, consentimiento_datos
B · facultad, programa_academico, periodo_academico, programa_asistente
C · tipo_evento, sede, modalidad, dependencia, catedra, sesion, ponencia
D · enlace_registro, clave_acceso, registro_asistencia      <- el núcleo
E · encuesta, tipo_pregunta, pregunta, opcion_pregunta,
    respuesta_encuesta, respuesta_item
F · lote_carga_asistente, novedad_carga, alias_programa,
    estado_proceso, lote_migracion, detalle_migracion
G · usuario, rol, rol_por_usuario, parametro, bitacora
```

### Las claves que hay que respetar

| Tabla | Clave primaria | Únicos |
|---|---|---|
| `asistente` | `id_asistente` | `id_asis`, `correo_institucional` |
| `documento_asistente` | `id_documento` | `(tipo, numero)`; uno vigente por persona |
| `vinculacion_asistente` | **`(asistente, tipo, fecha_ini)`** | — |
| `programa_academico` | **`codigo`** natural | — |
| `catedra` | `id_catedra` | `id_evento_asis` |
| `sesion` | `id_sesion` | **`(catedra, numero_reunion)`** |
| `enlace_registro` | `id_enlace` | `token`; uno vigente por sesión |
| `registro_asistencia` | `id_registro` | **`(sesion, asistente)`** |
| `rol_por_usuario` | **`(usuario, rol, fecha_ini)`** | — |

---

## Las nueve reglas que la IA NO debe romper

Si el código generado contradice alguna de estas, está mal aunque compile.

1. **`id_asis` es `varchar(15)` alfanumérico, no un entero.** Hay valores como `1000513C` y 9.553 filas de 11 caracteres. Nunca lo trate como número.
2. **`id_evento_asis` es `char(9)` con ceros a la izquierda** (`000035392`). Como entero se convierte en `35392` y deja de servir.
3. **`programa_academico.codigo` es `varchar(5)`, no `char(5)`.** `MCCP` tiene 4 caracteres; con `char` sale con un espacio final y el ASIS lo rechaza.
4. **El archivo plano lleva EXACTAMENTE tres columnas**: número de reunión, ID del ASIS, código de programa. Sin encabezado, sin texto adicional, sin espacios.
5. **El programa del registro es una INSTANTÁNEA.** Nunca se actualiza y nunca se lee del programa vigente: es el que la persona tenía el día de la cátedra.
6. **El programa es opcional** cuando `tipo_vinculacion.exige_programa` es falso — hoy, Rutas de Paz. No lo declare obligatorio.
7. **La clave de acceso se guarda cifrada** (`clave_hash bytea`), nunca en claro. Se devuelve en claro solo para enviarla por correo.
8. **Nadie se elimina.** No genere `DELETE`: use `activo = false`.
9. **El acceso admite tres identificadores** — código, documento o correo — y los tres deben resolver igual. Use `fn_resolver_asistente(texto)`.

---

## Las rutinas que ya existen — úselas, no las reescriba

```sql
fn_resolver_asistente(identificador text) -> bigint
    Resuelve por código ASIS, correo o documento. Limpia prefijos como 'ID:'.
    Busca en documentos vigentes y NO vigentes.

fn_siguiente_reunion(id_evento_asis char(9)) -> smallint
    Propone el consecutivo. OJO: para cátedras que ya existen en el ASIS,
    la autoridad es sesion.numero_reunion_asis.

fn_resolver_programa(texto text, umbral real = 0.45) -> varchar(5)
    Texto libre -> código, por alias exacto o similitud de trigramas.

fn_exportar_asis(id_sesion bigint) -> TABLE(reunion, id_asis, programa)
    EL ARCHIVO PLANO. Tres columnas. Excluye externos y sin programa.

CALL sp_emitir_enlace(id_sesion, min_antes, min_despues, usuario, OUT id_enlace)
CALL sp_solicitar_clave(identificador, token, ip, OUT id_clave, OUT clave, OUT correo)
CALL sp_validar_clave_y_registrar(id_clave, clave, ip, user_agent, OUT id_registro)
CALL sp_responder_encuesta(id_registro, respuestas jsonb, OUT id_respuesta)
CALL sp_generar_lote_migracion(id_sesion, usuario, OUT id_lote)
```

**Las vistas:** `v_asistencia_completa` (base de casi todos los informes), `v_asistente_vigente`, `v_pendiente_migracion`, `v_evaluacion_sesion`, `v_embudo_registro`, `v_control_ventana`.

---

## Cómo pedirle a la IA que trabaje sobre esto

**Diga qué construir, no cómo modelar.** El modelo ya está.

Ejemplos que funcionan:

> «Con este esquema, escribe el backend en Python + FastAPI para el flujo de registro: pantalla de acceso con los tres identificadores, envío de la clave por correo y validación. Usa los procedimientos `sp_solicitar_clave` y `sp_validar_clave_y_registrar`; no escribas SQL de inserción directa sobre `registro_asistencia`.»

> «Escribe la pantalla del administrador que genera el QR de una sesión. Llama a `sp_emitir_enlace` y genera la imagen del QR a partir de `url_publica`. La ruta de la imagen se guarda **relativa** en `ruta_imagen_qr`.»

> «Escribe el exportador del archivo plano: llama a `fn_exportar_asis`, escribe un Excel de tres columnas sin encabezado y verifica que ninguna celda tenga espacios.»

**Lo que NO hay que pedirle:** que diseñe las tablas, que invente nombres de columna, o que decida si el programa es obligatorio. Eso ya está decidido, y **está decidido contra el dato real**.

---

## Contexto que la IA no puede adivinar

- El ASIS es **PeopleSoft**. La carga se hace por archivo, en *Carga Info Cátedra*, ejecutando en el servidor `PSUNX01`, y el estado se vigila en *Monitor Procesos*. Los cinco estados son: En cola, En curso, Error, Correcto, Incorrecto.
- **El informe actual del ASIS solo entrega tres columnas.** Se acordó ampliarlo a seis con nombre, correo institucional y correo personal — pero todavía no ocurrió. Mientras tanto, los nombres y correos de la carga son sintéticos.
- **La clave al correo no es autenticación, es antisuplantación:** *«yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo»*. Y tiene un límite aceptado: se puede pedir el código por teléfono.
- Hay **tres sedes** —San Benito, Bello y virtual— y puede haber cátedras simultáneas en las tres.
- **Presencial se difunde por QR; virtual, por enlace.**
- Se manejan datos personales bajo la **Ley 1581 de 2012**. Existe `consentimiento_datos` y hay que registrarlo.

---

**El modelo completo:** [`MODELO-INTEGRADO.md`](MODELO-INTEGRADO.md) · **Los scripts:** [`fisico_postgres/`](fisico_postgres/)
