# 4 · Las tres estructuras difíciles, resueltas

Cada una con las alternativas evaluadas, la decisión y **su costo declarado**.

---

## 1 · La instantánea que convive con su referencia

### El problema

`registro_asistencia.fk_programa_snapshot` apunta a `programa_academico`. Y el asistente **también** tiene programas, en `programa_asistente`. Parece que la misma información está dos veces.

### Alternativas evaluadas

| # | Alternativa | Costo | Veredicto |
|---|---|---|---|
| A | Leer siempre el programa vigente; no guardar nada en el registro | 0 columnas | ❌ **Reescribe el historial.** Un cambio de carrera altera informes de periodos cerrados |
| B | Guardar el código como texto suelto, sin clave foránea | 1 columna | ❌ Pierde integridad: podría quedar un código inexistente |
| C | Versionar `programa_asistente` con vigencias y consultar «a fecha» | 2 columnas + `JOIN` con rango | ⚠️ **Es más puro y se acepta.** Pero encarece la consulta más frecuente y el archivo plano |
| **D** | **Copiar el código al registro, con clave foránea** | **1 columna** | ✅ **La elegida** |

### Por qué D

Está en `50:14`, del profesor Hugo Nelson:

> *«Las cátedras siempre le van a quedar a usted por el ID… el programa es importante porque después eso le da información a Registro de qué programas hizo el estudiante.»*

**«De qué programas hizo»** es una afirmación **sobre el pasado**. Una referencia viva no puede sostenerla.

### La prueba que lo decide

```sql
-- 1 · el archivo de una sesión, hoy
SELECT * FROM fn_exportar_asis(:sesion);

-- 2 · la persona cambia de programa
UPDATE programa_asistente SET estado='RETIRADO' WHERE ...;
INSERT INTO programa_asistente VALUES (..., 'M0999', '2026-2', 'ACTIVO');

-- 3 · el MISMO archivo, otra vez
SELECT * FROM fn_exportar_asis(:sesion);
```

Con instantánea, los pasos 1 y 3 dan **idéntico**. Con referencia viva, **distinto** — y el ASIS ya recibió la primera versión.

### El costo declarado

- Una columna más y una clave foránea más.
- **Si el código de un programa se corrige, los registros antiguos siguen apuntando al viejo.** Es deliberado, pero hay que saberlo: por eso la clave foránea es `ON UPDATE CASCADE` y `ON DELETE RESTRICT`.

---

## 2 · La regla condicional entre atributos

Aparece **dos veces**, y las dos se resolvieron igual: **convirtiendo la regla en dato**.

### 2.1 · Programa obligatorio, salvo excepción

> *«Para el tema de Rutas de Paz sí sería una excepción: ellos entrarían sin programa, pero solo ellos.»* — `41:16`

| # | Alternativa | Veredicto |
|---|---|---|
| A | `fk_programa` simplemente nullable | ❌ Permite un estudiante sin programa, que es lo que rompe el archivo plano |
| B | `CHECK (vinculacion = 'RUTAS_PAZ' OR programa IS NOT NULL)` | ❌ **Frágil.** «Solo ellos» hoy; mañana otra población y toca `ALTER TABLE` en producción |
| C | Especialización: `asistente_con_programa` / `asistente_sin_programa` | ⚠️ Ortodoxa, se acepta. Cuesta 2 tablas y una unión |
| **D** | **`tipo_vinculacion.exige_programa` + disparador que lo consulta** | ✅ **La elegida.** Habilitar una excepción es un `UPDATE` de una fila |

**Por qué no basta un `CHECK`:** un `CHECK` de PostgreSQL **no puede consultar otra tabla**. La regla depende de `tipo_vinculacion`, así que exige disparador.

```sql
-- fragmento de fn_trg_registro_validar
SELECT tv.exige_programa INTO v_exige_programa
  FROM tipo_vinculacion tv
 WHERE tv.id_tipo_vinculacion = NEW.fk_vinculacion_snapshot;

IF v_exige_programa AND NEW.fk_programa_snapshot IS NULL THEN
    RAISE EXCEPTION 'RN-07: ...';
END IF;
IF NOT v_exige_programa THEN
    NEW.fk_programa_snapshot := NULL;   -- entra SIN programa, a propósito
END IF;
```

> **La lección general:** cuando el usuario experto dice *«solo ellos»*, describe el estado de hoy, no una ley. Hay que modelar **la categoría de la excepción**, no la excepción.

### 2.2 · El tipo de pregunta decide la columna de respuesta

`respuesta_item` tiene tres columnas de valor y **exactamente una** debe estar llena.

Se resolvió en **dos niveles**:

| Nivel | Mecanismo | Qué garantiza |
|---|---|---|
| **Declarativo** | `CHECK (num IS NOT NULL)::int + (txt IS NOT NULL)::int + (opc IS NOT NULL)::int = 1` | Que no haya cero ni dos valores. **Lo garantiza el motor** |
| **Programado** | Disparador que lee `tipo_pregunta` | Que la columna llena sea **la que corresponde al tipo**, y que el número esté en rango |

**La parte declarativa es la que importa**: sin ella, un ítem con las tres columnas vacías se colaría y los promedios del informe de evaluación saldrían mal **sin avisar**.

---

## 3 · La participación mínima de uno

### El enunciado

Tres afirmaciones tienen la forma **«debe haber al menos uno»**:

1. Toda encuesta respondida tiene al menos un ítem (R29).
2. Toda pregunta **obligatoria** tiene respuesta.
3. Todo lote de migración lleva al menos un detalle.

### Por qué ninguna es declarativa

> **Una clave foránea garantiza que *lo que se inserte exista*, no que *se inserte algo*.**

`respuesta_item.fk_respuesta` impide un ítem huérfano. **No impide una cabecera sin ítems**: es el lado contrario de la relación, y no tiene mecanismo declarativo en SQL.

La segunda es aún más dura: no es «al menos uno», es **«uno por cada pregunta marcada obligatoria»** — depende del contenido de otra tabla, que además cambia con cada versión de la encuesta.

### Cómo se resolvieron

| Regla | Mecanismo | Dónde |
|---|---|---|
| Encuesta con al menos un ítem | `sp_responder_encuesta` crea cabecera e ítems **en una transacción**, y rechaza el arreglo vacío | [`11`](../fisico_postgres/11-funciones-procedimientos.sql) |
| Preguntas obligatorias respondidas | `sp_cerrar_encuesta` valida contra el catálogo antes de marcar `completa` | idem |
| Lote con al menos un detalle | `sp_generar_lote_migracion` falla si `fn_exportar_asis` devuelve cero filas | idem |
| **Verificación** | Consulta de control en `ejecutar-todo.sql`: **debe dar cero** | [`ejecutar-todo`](../fisico_postgres/ejecutar-todo.sql) |

### La alternativa que se descartó

**Restricciones diferidas** (`DEFERRABLE INITIALLY DEFERRED`) con un disparador `CONSTRAINT` al final de la transacción. Es más elegante y **más frágil**: cualquier inserción fuera de una transacción explícita se cuela. Con procedimiento, la única vía de entrada es la correcta — y a `rol_app_registro` se le da `EXECUTE` sobre el procedimiento, no `INSERT` directo sobre las tablas.

> **Que no sea declarativa no significa que se pueda omitir.** Significa que hay que declararla aquí para que quien revise no la busque como restricción y concluya que se olvidó — y que hay que **medirla**, porque lo que no es declarativo se degrada.

---

## 4 · Cuadro resumen

| Estructura | Mecanismo | ¿Lo garantiza el motor? |
|---|---|---|
| Instantánea vs. referencia | Columna + clave foránea + disparador de derivación | Parcialmente: la integridad sí, la política de no actualizar es convención |
| Regla condicional 1 (programa) | Columna de catálogo + disparador | No — `CHECK` no puede leer otra tabla |
| Regla condicional 2 (respuesta) | `CHECK` multicolumna + disparador | **Sí** en lo esencial |
| Participación mínima de uno | Procedimiento + consulta de control | No |

**Esa última columna es el entregable de este documento.** Hace visible la frontera entre *lo que el modelo garantiza* y *lo que alguien tiene que mantener*.

---

**Anterior:** [03 · Transformación](03-Transformacion-MER-a-MR.md) · **Siguiente:** [05 · Trazabilidad](05-Trazabilidad.md)
