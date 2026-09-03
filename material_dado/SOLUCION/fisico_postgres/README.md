# Diseño físico — PostgreSQL

**Fase 3** · Motor: **PostgreSQL 14 o superior** · UTF-8 · esquema `public`
**Estado: ejecutado de punta a punta sin errores.** Ver §5.

---

## 1 · Cómo ejecutarlo

**Un solo archivo.**

```bash
cd SOLUCION/fisico_postgres

# 1 · generar los CSV desde los Excel reales del ASIS
python preparar-datos.py

# 2 · construirlo todo
psql -U postgres -f catedras.sql
```

En Windows con PowerShell:

```powershell
$env:PGPASSWORD = "..."
python preparar-datos.py
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -f catedras.sql
```

Hay que ejecutarlo **desde esta carpeta**: los `\copy` del bloque 13 buscan `datos/*.csv` por ruta relativa.

**Requisitos:** las extensiones `pgcrypto`, `btree_gist`, `citext`, `unaccent` y `pg_trgm`. Vienen en `postgresql-contrib`, que la mayoría de los instaladores incluye.

> **¿Solo quiere la base ya cargada, sin reconstruirla?** Restaure el respaldo:
> [`../../ApiCatedrasUsbmed/sql/backup/catedras.dump`](../../ApiCatedrasUsbmed/sql/backup/catedras.dump). Son tres órdenes y no necesita ni Python ni los Excel.

---

## 2 · Los archivos

| Archivo | Contenido |
|---|---|
| **`catedras.sql`** | **La base entera, en un solo script.** 18 bloques numerados: extensiones, las 37 tablas, 52 claves foráneas, 7 disparadores, 22 rutinas, catálogos, la carga real del ASIS, 6 vistas, datos de prueba, 30 índices, 4 roles y las funciones envoltorio de la API |
| `preparar-datos.py` | Lee los dos Excel del ASIS y escribe `datos/*.csv`. **Los CSV no se versionan** |
| `16-consultas-informes.sql` | Los 20 informes. **No construye nada**: son consultas, y por eso van aparte — no tiene sentido que la construcción escupa 20 tablas de resultados |
| `18-backup-restore.md` | Respaldo, retención y evidencia de restauración |

### El orden de los 18 bloques no es 00, 01, 02…

| Va donde va | Por qué |
|---|---|
| Los **disparadores antes de los datos** | La carga los ejercita. Es la única forma de comprobar que hacen lo que dicen |
| Los **índices al final**, con los datos ya cargados | Un índice sobre una tabla vacía no dice nada, y su plan de ejecución es inútil |
| Los **datos de prueba después de las vistas** | Algunas comprobaciones las usan |

Cada bloque conserva íntegras sus cabeceras y sus comentarios, con la justificación de cada decisión y el número de regla de negocio que la origina.

### Sobre el esquema

**Todo va en `public`.** Hubo una versión con un esquema propio `catedras`, y se abandonó: obligaba a fijar el `search_path` en la cadena de conexión, en cada sesión de pgAdmin y —lo que de verdad dolió— con un `ALTER FUNCTION` sobre **cada una** de las 22 rutinas, porque el `SET search_path` de un script **no queda horneado** en la función que se crea bajo él. Olvidar uno solo daba «no existe la relación `registro_asistencia`» sobre una tabla que sí existía.

Lo que se pierde es poder revocar permisos sobre `public` de un golpe. Se compensa en el bloque 17, que revoca objeto por objeto.

---

## 3 · Lo específico de PostgreSQL que este proyecto sí aprovecha

Ninguna extensión está por costumbre. Cada una resuelve una regla concreta.

| Necesidad | Mecanismo | Qué costaría en otro motor |
|---|---|---|
| **RN-36** · dos enlaces de una sesión no se solapan | `EXCLUDE USING gist` sobre `tstzrange` | Disparador con bloqueo explícito |
| **RN-05, 14, 29** y el vigente · unicidad condicional | **Índice único parcial** (4 casos) | En MySQL **no existen**: columna generada + `UNIQUE` |
| **RN-11** · el nombre corto del ASIS | Columna **generada** `STORED` | Disparador |
| **RN-06** · acceso por tres identificadores | `citext` + tres índices | Índices sobre expresiones `lower()` |
| **H17** · texto libre → código de programa | `pg_trgm` + `unaccent` + índice `GIN` | Tabla de equivalencias exactas, o trabajo manual |
| **RN-18** · hash de la clave | `pgcrypto` · `digest()` con sal | Se resuelve en la aplicación |
| **RN-35** · bitácora | `jsonb` con el antes y el después | Una tabla espejo por tabla — **37 más** |
| **I3, I20** · jerarquías | `WITH RECURSIVE` | `CONNECT BY` en Oracle |
| **I2, I5** · agregados condicionales | `FILTER (WHERE …)` | `SUM(CASE WHEN … END)` |

> **La conclusión que hay que poder defender:** en un motor sin `EXCLUDE` ni índices parciales, **cinco reglas dejan de ser garantía del motor y pasan a ser código que alguien tiene que mantener**. El modelo no cambia de forma; cambia **quién responde**.

---

## 4 · Qué mirar primero al revisar

Todo está en `catedras.sql`; el número es el del bloque, que aparece en su cabecera.

| Dónde | Qué demuestra |
|---|---|
| Bloque **2** · `chk_asistente_idasis` | El dominio **corregido contra el dato**: alfanumérico de 15, no 10 dígitos |
| Bloque **3** · `codigo varchar(5)` | Por qué `char(5)` habría metido un espacio en el archivo del ASIS |
| Bloque **5** · `ex_enlace_sin_solape` | La única regla que un motor sin `EXCLUDE` no puede declarar |
| Bloque **5** · los dos `_snapshot` | La decisión más importante del modelo |
| Bloque **6** · `chk_respuesta_item_un_valor` | La regla condicional, en su parte declarativa |
| Bloque **10** · `fn_trg_registro_validar` | Cuatro reglas en un disparador, y por qué van juntas |
| Bloque **11** · `fn_resolver_asistente` | Las tres puertas de acceso de `57:27` |
| Bloque **11** · `fn_exportar_asis` | **Tres columnas exactas.** Ni una más |
| Bloque **17** · las pruebas de permisos | Los permisos, aprobados **demostrando un fallo** |

---

## 5 · Evidencia de la última ejecución

Base **destruida y reconstruida entera** desde el script único, el 13 de agosto de 2026:

```
$ psql -U postgres -f catedras.sql
código de salida: 0        errores: 0
```

**Objetos creados**

| tablas | vistas | rutinas propias | disparadores |
|---:|---:|---:|---:|
| 37 | 6 | 22 | 7 |

*«Rutinas propias» descuenta las de las extensiones. Al vivir todo en `public`, las funciones de `pgcrypto`, `citext`, `unaccent` y `pg_trgm` caen en el mismo esquema y la cuenta en bruto da **328**.*

Después de reconstruir, la API pasó sus dos suites contra la base recién creada: **certificación 19/19** y **flujo completo 18/18**.

**Volúmenes cargados, contra lo medido en los Excel**

| objeto | filas | esperado |
|---|---:|---:|
| catedras | 5.497 | 5.497 |
| sesiones | 5.714 | 5.714 |
| programas | 105 | 105 |
| asistentes | 14.811 | 14.811 |
| documentos | 15.517 | 15.517 |
| registros | 166 | 166 |

*Los totales incluyen la cátedra y los tres asistentes de prueba que añade el script 14.*

**Los cuatro controles — todos en cero**

| control | resultado |
|---|---:|
| Registros fuera de ventana (RN-15) | **0** |
| Pares (cátedra, reunión) duplicados (RN-10) | **0** |
| Encuestas completas sin ningún ítem (R29) | **0** |
| Externos colados en el archivo del ASIS (RN-08) | **0** |

**Las tres pruebas de permisos — las tres deniegan**

```
CORRECTO: permiso denegado sobre asistente
CORRECTO: DELETE denegado
CORRECTO: UPDATE sobre bitacora denegado
```

**Comprobación del archivo plano (I7)**

| filas | id con espacios | programa con espacios |
|---:|---:|---:|
| 164 | **0** | **0** |

---

## 6 · Los dos hallazgos que solo aparecieron al ejecutar

Ninguno se veía en el papel. Los dos están documentados en el código, con su evidencia.

### 6.1 · `MCCP` tiene cuatro caracteres

De los 105 códigos de programa reales, 103 tienen la forma `M`+4 dígitos, **`MCDER` tiene cinco caracteres y `MCCP` tiene cuatro**. Con `char(5)`, `MCCP` se rellena a `MCCP␣` y ese espacio viaja al archivo plano — justo lo que el manual prohíbe. → `varchar(5)`.

### 6.2 · El número de reunión **no** es un consecutivo por cátedra

Se creía que empezaba en 1 y crecía de uno en uno dentro de cada evento. El dato dice otra cosa:

- De los **5.481 eventos con una sola reunión, solo 588 tienen el número 1**. Los otros 4.893 traen valores arbitrarios, hasta **4348**.
- Los eventos con muchas reuniones sí empiezan en 1, pero **con huecos**: `000035428` tiene 59 reuniones numeradas de 1 a 60.

**El ASIS lleva un contador propio que este sistema no conoce.** Esto **resuelve con dato** la decisión que el plan había dejado abierta en §8.3: la autoridad del consecutivo es el ASIS. El disparador `fn_trg_sesion_consecutivo` **propone** un número para las cátedras nuevas; `sesion.numero_reunion_asis` manda cuando existe.

> La restricción `UNIQUE (fk_catedra, numero_reunion)` **sí se sostiene**: se verificó sobre las 5.711 filas reales y da cero duplicados. Lo que falla no es el modelo, es la regla de derivación.

---

## 7 · Nota sobre los datos

`preparar-datos.py` **sintetiza nombres y correos** a partir del ID, porque el informe actual del ASIS solo entrega tres columnas. No es un atajo: es la evidencia del **riesgo número 1** del plan. Cuando Carlos amplíe el informe a seis columnas —nombre, correo institucional y correo personal, acordado en `1:50:43`—, basta con cambiar las dos funciones marcadas `SINTETICO` y volver a cargar.

Los **164 nombres y cédulas reales** del formulario de Pedagogía Electoral **no se reproducen** en los datos de prueba. El modelo se demuestra igual de bien sin ellos.

---

**Nivel anterior:** [`../MR/`](../MR/) · **El modelo en una página:** [`../MODELO-INTEGRADO.md`](../MODELO-INTEGRADO.md)
