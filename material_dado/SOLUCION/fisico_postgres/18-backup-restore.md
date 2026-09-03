# 18 · Respaldo y restauración

**Por qué este documento existe.** El profesor Carlos Castro lo dijo en `1:49:13`: *«la unidad de tecnologías sí le entrega unos servidores… pero no sé qué pasa y se caen mucho, los aplicativos ahí se me reinician mucho»*. Una base que guarda evidencia de asistencia y datos personales, en servidores que se caen, necesita una estrategia de respaldo escrita — no improvisada el día que haga falta.

---

## 1 · Qué hay que poder recuperar, y en cuánto tiempo

| Dato | Si se pierde | Objetivo de recuperación |
|---|---|---|
| **Registros de asistencia** | **Irrecuperable.** Nadie va a volver a escanear el QR | **RPO ≤ 5 min** |
| Claves de acceso | Se vuelven a pedir. Molesto, no grave | RPO ≤ 1 día |
| Maestro de personas | Se vuelve a descargar del ASIS | RPO ≤ 1 semana |
| Cátedras y sesiones | Se vuelven a cargar del ASIS | RPO ≤ 1 día |
| Bitácora | **Irrecuperable**, y es la evidencia de cumplimiento | **RPO ≤ 5 min** |

**RTO objetivo: 1 hora.** El día de una cátedra, una hora de caída es una cátedra sin registrar.

> **La conclusión operativa:** un volcado diario **no basta** para lo que importa. Hace falta archivado de WAL.

---

## 2 · Estrategia en tres capas

### Capa 1 · Volcado lógico diario

```bash
pg_dump -U postgres -d catedras -F c -Z 6 \
        -f /respaldo/catedras_$(date +%F).dump
```

- Formato `custom` (`-F c`): permite restaurar **tablas sueltas**.
- Retención: **30 días** en disco, **12 meses** en almacenamiento frío.

Solo el esquema, para comparar cambios de estructura entre versiones:

```bash
pg_dump -U postgres -d catedras --schema-only -f /respaldo/esquema_$(date +%F).sql
```

### Capa 2 · Archivado de WAL — lo que da los 5 minutos

En `postgresql.conf`:

```conf
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /respaldo/wal/%f && cp %p /respaldo/wal/%f'
archive_timeout = 300          # fuerza un segmento cada 5 minutos
```

Base física semanal:

```bash
pg_basebackup -U postgres -D /respaldo/base_$(date +%F) -F t -z -P -X stream
```

**Con esto se puede restaurar a un instante concreto** — por ejemplo, al minuto anterior a un borrado accidental.

### Capa 3 · Copia fuera del servidor

El respaldo en la misma máquina que la base **no es un respaldo**. Copia diaria a otro equipo o a almacenamiento institucional, cifrada: contiene documentos de identidad y correos personales.

---

## 3 · Restauración

### 3.1 · Completa

```bash
dropdb -U postgres catedras
createdb -U postgres catedras
pg_restore -U postgres -d catedras -j 4 /respaldo/catedras_2026-08-10.dump
```

### 3.2 · Una sola tabla

```bash
pg_restore -U postgres -d catedras -t registro_asistencia --data-only \
           /respaldo/catedras_2026-08-10.dump
```

### 3.3 · A un instante concreto

En `recovery.signal` + `postgresql.conf` del directorio restaurado:

```conf
restore_command = 'cp /respaldo/wal/%f %p'
recovery_target_time = '2026-08-10 14:35:00-05'
recovery_target_action = 'promote'
```

---

## 4 · La prueba de restauración

> **Un respaldo que no se ha restaurado nunca no es un respaldo: es un archivo.**

**Trimestralmente**, y siempre antes de una cátedra grande:

```bash
# 1 · restaurar en una base aparte
createdb -U postgres catedras_prueba
pg_restore -U postgres -d catedras_prueba /respaldo/catedras_2026-08-10.dump

# 2 · verificar objetos
psql -U postgres -d catedras_prueba -c "
SELECT (SELECT count(*) FROM information_schema.tables
         WHERE table_schema='public' AND table_type='BASE TABLE') AS tablas,
       (SELECT count(*) FROM public.registro_asistencia)          AS registros,
       (SELECT count(*) FROM public.asistente)                    AS asistentes;"
```

**Debe dar 37 tablas** y los mismos conteos que la base viva.

```bash
# 3 · verificar que las REGLAS siguen vivas, no solo los datos
psql -U postgres -d catedras_prueba -c "
SELECT 'fuera de ventana' AS control, count(*) FROM public.v_control_ventana
UNION ALL
SELECT 'reuniones duplicadas',
       (SELECT count(*) FROM (SELECT fk_catedra, numero_reunion
                                FROM public.sesion GROUP BY 1,2
                              HAVING count(*)>1) q);"

# 4 · limpiar
dropdb -U postgres catedras_prueba
```

**Los dos controles deben dar cero.** Si los datos volvieron pero los disparadores no, el paso 3 lo revela y el paso 2 no.

---

## 5 · Evidencia de la última prueba

| Fecha | Volcado probado | Tablas | Registros | Controles | Resultado |
|---|---|---:|---:|---|---|
| 2026-08-10 | Construcción completa desde `ejecutar-todo.sql` | 37 | 166 | 4 en cero | ✅ |

> **Pendiente:** la primera restauración desde un `pg_dump` real, que solo se puede hacer cuando la base esté desplegada en el servidor del profesor Carlos Castro. Hasta entonces, lo verificado es que **la construcción completa desde cero es reproducible y da los mismos números**, que es la mitad del problema.

---

## 6 · Lo que hay que decidir al desplegar

1. **Dónde vive `/respaldo`.** No en el mismo disco que los datos.
2. **Quién recibe la alerta** cuando `archive_command` falla. Un archivado que falla en silencio llena el disco y tumba la base.
3. **Cuánto se retienen los datos personales.** La Ley 1581 obliga a suprimirlos cuando ya no son necesarios: hay que fijar un plazo para los asistentes externos que nunca volvieron.
4. **Si los respaldos se cifran.** Contienen cédulas y correos. La respuesta debería ser sí.

---

**Anterior:** [`17-usuarios-permisos.sql`](17-usuarios-permisos.sql) · **Índice:** [`README.md`](README.md)
