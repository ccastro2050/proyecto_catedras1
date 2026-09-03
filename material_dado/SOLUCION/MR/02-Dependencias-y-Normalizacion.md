# 2 · Dependencias funcionales y normalización

> **Este proyecto trae el ejemplo de normalización regalado.** No hay que inventarlo: el archivo `USBME_EMPLID_CATED_V1` **es** una tabla sin normalizar, con 16.093 filas reales, y sus tres anomalías son de libro.

---

## 1 · El punto de partida real

El maestro que se descarga del ASIS tiene tres columnas:

```
USBME_EMPLID_CATED(documento, id_asis, codigo_programa)
```

### 1.1 · Las dependencias funcionales, medidas

No se postulan: se comprobaron contra las 16.093 filas.

| # | Dependencia | ¿Se cumple? | Evidencia |
|---|---|---|---|
| **DF1** | `documento → id_asis` | **Sí** | **0** documentos con más de un ID |
| **DF2** | `id_asis → documento` | **NO** | **707** ID con más de un documento |
| **DF3** | `(id_asis, codigo_programa)` no determina nada más | Sí | Es todo lo que hay |

**La asimetría entre DF1 y DF2 es el corazón del problema.** De un documento se llega a la persona; de la persona no se llega a *un* documento.

### 1.2 · Las claves candidatas, por el método del cierre

Atributos: `{documento, id_asis, codigo_programa}`

Probamos `(documento, codigo_programa)`:

```
(documento, codigo_programa)+
  = {documento, codigo_programa}
  ∪ {id_asis}                        por DF1
  = {documento, id_asis, codigo_programa}   ← todos
```

**`(documento, codigo_programa)` es clave candidata.**

¿Y `(id_asis, codigo_programa)`?

```
(id_asis, codigo_programa)+
  = {id_asis, codigo_programa}       DF2 no existe, no se llega a documento
  ≠ todos
```

**No es clave.** Y además, el dato lo confirma por otra vía: hay **pares `(id_asis, codigo_programa)` repetidos hasta tres veces**, así que ni siquiera es superclave del archivo tal como llega.

---

## 2 · Primera forma normal

**Se cumple.** Todos los valores son atómicos: un documento, un código, un programa por fila.

> Pero el precio de esa atomización es la **repetición**: una persona con dos programas ocupa dos filas, y su documento se repite en las dos. Eso es exactamente lo que 2FN viene a arreglar.

---

## 3 · Segunda forma normal — **aquí está el fallo**

**Definición:** ningún atributo no primo depende **parcialmente** de la clave.

- Clave: `(documento, codigo_programa)`
- Atributo no primo: `id_asis`
- Y por DF1: **`documento → id_asis`**

`documento` es **una parte** de la clave. Luego `id_asis` depende de **parte** de la clave, no de toda.

> ### 🔴 Viola 2FN.

### 3.1 · Las tres anomalías, con su caso real

| Anomalía | Qué pasa | El caso real de este proyecto |
|---|---|---|
| **De inserción** | No se puede registrar a alguien que aún no tiene programa: la clave exige `codigo_programa` | **Es exactamente Rutas de Paz** — *«ellos entrarían sin programa, pero solo ellos»* (`41:16`). El archivo actual **no los puede representar** |
| **De actualización** | Corregir un `id_asis` obliga a tocar todas las filas de esa persona | **Son los 707 casos.** Si una queda sin actualizar, la persona se parte en dos |
| **De borrado** | Dar de baja el último programa **borra a la persona** | Un egresado que cierra su matrícula desaparece del maestro y ya no puede asistir a una cátedra |

**Las tres son reales y las tres ocurren hoy.** No son ejemplos de manual.

### 3.2 · La descomposición

```
asistente(id_asistente, id_asis‡, ...)
documento_asistente(id_documento, fk_asistente, fk_tipo_documento, numero‡, vigente)
programa_asistente(fk_asistente, fk_programa, fk_periodo, estado)
```

- **DF1** queda dentro de `documento_asistente`: el número es único y apunta a una persona.
- **DF2**, que no existía, deja de hacer falta: una persona tiene *n* documentos, y eso ahora se puede representar.
- La matrícula se independiza y **acepta el caso «persona sin programa»**.

**Es descomposición sin pérdida** (la reunión por `fk_asistente` reconstruye el original) **y conserva las dependencias**.

---

## 4 · Tercera forma normal

**Se cumple en las 37 tablas.** No hay dependencias transitivas de atributos no primos.

Los dos casos que parecen violarla y no la violan:

| Aparente transitividad | Por qué no lo es |
|---|---|
| `registro → programa_snapshot → nombre_programa` | La instantánea guarda **el código**, no el nombre. El nombre vive solo en `programa_academico` |
| `sesion → catedra → tipo_evento` | `sesion` **no** guarda el tipo de evento. Se llega por reunión |

### El caso que sí habría violado 3FN

Poner `es_interno` en `registro_asistencia` — porque `registro → vinculacion_snapshot → es_interno`. Se resistió la tentación: `es_interno` vive **solo** en `tipo_vinculacion`, y el informe 2 lo alcanza con una reunión.

---

## 5 · Boyce-Codd

**Se cumple en las 37 tablas.** En todas, el determinante de cada dependencia no trivial es superclave.

Las tres tablas con claves candidatas solapadas —las candidatas a violar BCNF— se revisaron una por una:

| Tabla | Candidatas | ¿Solapan? | Veredicto |
|---|---|---|---|
| `documento_asistente` | `id_documento` · `(tipo, numero)` · `(asistente) WHERE vigente` | **Sí** | El único determinante es la clave completa. **En BCNF** |
| `sesion` | `id_sesion` · `(catedra, numero_reunion)` | No comparten atributos | **En BCNF** |
| `respuesta_item` | `id_item` · `(respuesta, pregunta)` | No | **En BCNF** |

> **El modelo ya estaba en BCNF antes de buscar el caso.** Eso no es casualidad: es consecuencia de haber usado claves sustitutas y de haber sacado los multivaluados a tabla propia desde el conceptual.

---

## 6 · Lo que la normalización **no** resuelve, y por qué está bien

Hay dos redundancias deliberadas en el modelo. **No son fallos de normalización: son decisiones con motivo.**

### 6.1 · Las instantáneas del registro

`registro_asistencia.fk_programa_snapshot` duplica información que también está en `programa_asistente`.

**No es una dependencia funcional violada**, porque no es el mismo hecho: uno dice *«está matriculado»* y el otro *«esta asistencia se imputó a»*. Normalizar aquí significaría **borrar información histórica**, no eliminar redundancia.

### 6.2 · Las tres columnas de `detalle_migracion`

Igual. `id_asis_enviado` no es «el ID de la persona»: es **el ID que salió en el archivo**. Si la persona cambia, los dos valores divergen legítimamente.

> **La regla general:** cuando una copia y su origen **pueden divergir legítimamente**, no son redundancia. Son dos hechos.

---

## 7 · Cuadro final

| Forma | Tablas que la cumplen |
|---|---|
| 1FN | 37 de 37 |
| 2FN | 37 de 37 |
| 3FN | 37 de 37 |
| **BCNF** | **37 de 37** |

Y el archivo de origen, para contraste:

| | `USBME_EMPLID_CATED` |
|---|---|
| 1FN | ✅ |
| **2FN** | ❌ **`documento → id_asis` es dependencia parcial** |
| 3FN | ❌ (por arrastre) |

---

**Anterior:** [01 · Esquema relacional](01-Esquema-Relacional.md) · **Siguiente:** [03 · Transformación MER → MR](03-Transformacion-MER-a-MR.md)
