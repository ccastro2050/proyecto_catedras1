# 1 · El esquema relacional — 37 tablas

**Notación:** `TABLA(<u>clave primaria</u>, atributo, *clave foránea*)`
Claves candidatas alternas marcadas con `‡`.

---

## Bloque A · Asistentes e identidad — 6 tablas

```
tipo_documento(id_tipo_documento, nombre‡, activo)

asistente(id_asistente, id_asis‡, nombres, apellidos, nombre_completo_asis,
          correo_institucional‡, correo_personal, celular, es_externo, activo,
          creado_en, *fk_lote_carga*)

documento_asistente(id_documento, *fk_asistente*, *fk_tipo_documento*,
                    numero, vigente, registrado_en)
          ‡ (fk_tipo_documento, numero)
          ‡ (fk_asistente) WHERE vigente        -- índice único parcial

tipo_vinculacion(id_tipo_vinculacion, nombre‡, es_interno, exige_programa, activo)

vinculacion_asistente(*fk_asistente*, *fk_tipo_vinculacion*, fecha_ini, fecha_fin)
          PK = las TRES primeras

consentimiento_datos(id_consentimiento, *fk_asistente*, version_politica,
                     aceptado_en, ip, canal)   ‡ (fk_asistente, version_politica)
```

## Bloque B · Estructura académica — 4 tablas

```
facultad(id_facultad, nombre‡, *fk_facultad_padre*, activo)

programa_academico(codigo, nombre, *fk_facultad*, nivel, activo)

periodo_academico(id_periodo, fecha_ini, fecha_fin, activo)

programa_asistente(*fk_asistente*, *fk_programa*, *fk_periodo*, estado)
          PK = las TRES primeras
```

## Bloque C · Cátedras, sesiones y sedes — 7 tablas

```
tipo_evento(id_tipo_evento, nombre, activo)
sede(id_sede, nombre‡, direccion, es_virtual, activo)
modalidad(id_modalidad, nombre, canal_difusion, activo)
dependencia(id_dependencia, nombre‡, *fk_dependencia_padre*, activo)

catedra(id_catedra, id_evento_asis‡, nombre, [nombre_asis], *fk_tipo_evento*,
        *fk_dependencia*, activo, creado_en)

sesion(id_sesion, *fk_catedra*, numero_reunion, numero_reunion_asis, titulo,
       inicio, fin, *fk_modalidad*, *fk_sede*, *fk_periodo*, *fk_encuesta*,
       lugar, enlace_virtual, cupo, estado, creado_en)
          ‡ (fk_catedra, numero_reunion)

ponencia(*fk_sesion*, *fk_asistente*, rol)   PK = las tres
```

`[nombre_asis]` es **columna generada**: `left(nombre, 30)`.

## Bloque D · Acceso y registro — 3 tablas

```
enlace_registro(id_enlace, *fk_sesion*, token‡, url_publica, ruta_imagen_qr,
                canal, ventana, usos_maximos, revocado_en, *fk_usuario_crea*,
                creado_en)
          ‡ (fk_sesion) WHERE revocado_en IS NULL
          EXCLUDE (fk_sesion =, ventana &&) WHERE revocado_en IS NULL

clave_acceso(id_clave, *fk_asistente*, *fk_enlace*, clave_hash, enviado_a,
             es_correo_institucional, generado_en, expira_en, usado_en,
             intentos, ip_solicitud)

registro_asistencia(id_registro, *fk_sesion*, *fk_asistente*, *fk_enlace*,
                    *fk_clave*, registrado_en, *fk_programa_snapshot*,
                    *fk_vinculacion_snapshot*, origen, ip, user_agent)
          ‡ (fk_sesion, fk_asistente)
```

## Bloque E · Encuesta — 6 tablas

```
encuesta(id_encuesta, nombre, version, vigente_desde, vigente_hasta, activa)
          ‡ (nombre, version)
tipo_pregunta(id_tipo_pregunta, nombre, guarda_numero, guarda_texto, guarda_opcion)
pregunta(id_pregunta, *fk_encuesta*, enunciado, orden, *fk_tipo_pregunta*,
         obligatoria, valor_min, valor_max)      ‡ (fk_encuesta, orden)
opcion_pregunta(id_opcion, *fk_pregunta*, etiqueta, valor, orden)
                                                  ‡ (fk_pregunta, orden)
respuesta_encuesta(id_respuesta, *fk_registro*‡, *fk_encuesta*, respondida_en, completa)
respuesta_item(id_item, *fk_respuesta*, *fk_pregunta*, valor_numerico,
               valor_texto, *fk_opcion*)          ‡ (fk_respuesta, fk_pregunta)
```

## Bloque F · Integración con el ASIS — 6 tablas

```
lote_carga_asistente(id_lote_carga, nombre_archivo, cargado_en, *fk_usuario*,
                     filas_leidas, filas_aceptadas, filas_rechazadas, observaciones)
novedad_carga(id_novedad, *fk_lote_carga*, numero_fila, contenido_crudo, motivo)
alias_programa(id_alias, texto_normalizado‡, *fk_programa*, origen, creado_en)
estado_proceso(id_estado, nombre, es_final, es_exitoso)
lote_migracion(id_lote_migracion, *fk_sesion*, nombre_proceso, nombre_archivo,
               generado_en, *fk_usuario*, instancia_proceso_asis,
               *fk_estado_proceso*, total_filas, observaciones)
detalle_migracion(id_detalle, *fk_lote_migracion*, *fk_registro*,
                  id_asis_enviado, programa_enviado, reunion_enviada,
                  resultado, mensaje)
          ‡ (fk_lote_migracion, fk_registro)
          ‡ (fk_registro) WHERE resultado = 'ACEPTADO'
```

## Bloque G · Seguridad — 5 tablas

```
usuario(id_usuario, *fk_asistente*‡, usuario‡, clave_hash, activo,
        ultimo_acceso, creado_en)
rol(id_rol, nombre‡, descripcion)
rol_por_usuario(*fk_usuario*, *fk_rol*, fecha_ini, fecha_fin)  PK = las tres
parametro(clave, valor, tipo_dato, descripcion, *fk_usuario_modifica*, modificado_en)
bitacora(id_bitacora, ocurrido_en, usuario_bd, *fk_usuario*, nombre_tabla,
         operacion, llave, datos_antes, datos_despues)
```

---

## Las siete decisiones que hay que poder defender

### 1 · `fecha_ini` dentro de la clave primaria — dos veces

`vinculacion_asistente` y `rol_por_usuario`.

Sin ella, la clave sería el par (persona, categoría), y eso significa que **nadie puede volver a tener algo que ya tuvo**. Un egresado que se matricula en una maestría vuelve a ser estudiante; un administrador que dejó el cargo y regresa.

**Es el error que no falla ruidosamente.** No aparece un mensaje: aparece un `INSERT` rechazado o un histórico que nunca se pudo escribir, y consultas que devuelven vacío sin explicar por qué.

### 2 · Las dos columnas de instantánea en `registro_asistencia`

`fk_programa_snapshot` y `fk_vinculacion_snapshot` **parecen** redundantes con `programa_asistente` y `vinculacion_asistente`. No lo son:

| | La tabla de origen | La instantánea |
|---|---|---|
| Afirma | «está matriculado en» | «esta asistencia se imputó a» |
| Cambia | cada semestre | **nunca** |

La prueba: genere el archivo plano de una sesión, deje pasar un cambio de programa, y vuelva a generarlo. Con referencia viva **sale distinto**; con instantánea, idéntico. El ASIS ya recibió la primera versión.

### 3 · `codigo` de `programa_academico` es `varchar(5)`, no `char(5)`

Parece un detalle y no lo es. El maestro real trae **`MCCP`, de cuatro caracteres**. Con `char(5)`, PostgreSQL lo rellena a `MCCP␣`, y ese espacio viaja al archivo plano — justo lo que el manual de migración prohíbe: *«verificar que el archivo esté limpio y que no se haya agregado ningún texto adicional»*.

### 4 · `id_asis` es la clave candidata, no la primaria

La restricción del negocio —*«para poder inscribir la cátedra en ASIS, cualquier persona debe estar registrada en ASIS con ID»*, `26:46`— se cumple igual con `UNIQUE`. Pero ese formato **ya cambió dos veces** y admite letras: no debe quedar copiado en las diez tablas que lo referencian.

### 5 · La ventana es **un** atributo de tipo rango

Con dos columnas `timestamptz`, ni la exclusión de solapamientos ni la contención «¿está este instante dentro?» son declarativas. Con `tstzrange`, las dos lo son.

### 6 · `respuesta_item` tiene tres columnas de valor y una restricción

Alternativa ortodoxa: especialización supertipo/subtipo, una tabla por tipo de respuesta. **Es correcta y se acepta**; cuesta tres tablas y una unión en cada consulta de evaluación.

### 7 · `detalle_migracion` repite tres columnas a propósito

`id_asis_enviado`, `programa_enviado` y `reunion_enviada` ya están en otras tablas. **No son lo mismo**: son lo que *se envió*. Sin la copia, un rechazo del ASIS es indepurable seis meses después.

---

## Resumen numérico — verificado contra la base creada

| | |
|---|---:|
| Tablas | **37** |
| Vistas | 6 |
| Claves primarias sustitutas / naturales / compuestas | 17 / 13 / 7 |
| Claves candidatas alternas | 18 |
| Claves foráneas | **52** |
| — recursivas | 2 |
| Restricciones `CHECK` | **47** |
| Restricciones `EXCLUDE` | 1 |
| Índices únicos parciales | 4 |
| Disparadores | 7 |

Estos números **no están estimados**: salen de consultar `information_schema` y `pg_constraint` sobre la base ya construida. La consulta está al final de [`../fisico_postgres/ejecutar-todo.sql`](../fisico_postgres/ejecutar-todo.sql).

---

**Siguiente:** [02 · Dependencias y normalización](02-Dependencias-y-Normalizacion.md)
