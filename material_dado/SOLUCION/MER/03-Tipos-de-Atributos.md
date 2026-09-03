# 3 · Tipos de atributos

Cinco tipos. Cada uno se dibuja distinto en Chen y cada uno se transforma distinto al pasar al modelo relacional.

| Tipo | Símbolo en Chen | Qué pasa al transformar |
|---|---|---|
| **Simple** | Óvalo | Columna |
| **Compuesto** | Óvalo con óvalos colgando | Se descompone en columnas, o se aplana |
| **Multivaluado** | Óvalo de doble línea | **Tabla nueva** |
| **Derivado** | Óvalo de línea punteada | Columna calculada, o nada |
| **Identificador** | Óvalo con el nombre subrayado | Clave primaria |

---

## 3.1 · Simple

El caso normal: un valor atómico, indivisible para el negocio.

`celular` · `cupo` · `orden` · `activo`

**Atómico «para el negocio» es la clave.** Un celular se puede partir en indicativo y número, pero si nadie va a consultar por indicativo, partirlo es trabajo sin retorno.

---

## 3.2 · Compuesto

Un atributo que se descompone en partes con sentido propio.

### El caso del proyecto: el nombre de la persona

El maestro del ASIS entrega **un solo campo de nombre completo**. El formulario actual, también. Y sin embargo hay que decidir:

| Alternativa | A favor | En contra |
|---|---|---|
| **Un campo** `nombre_completo` | Es como llega del ASIS. Cero transformación en la carga | No se puede ordenar por apellido, que es como se leen las listas de asistencia |
| **Dos campos** `nombres` + `apellidos` | Ordenar e imprimir listados. Detectar homónimos mejor | Hay que partir el texto en la carga, y **partir nombres en español es ambiguo**: dos nombres y dos apellidos, o uno y dos, o compuestos con preposición |

**Decisión: dos campos, con el original conservado.** Se guardan `nombres` y `apellidos` para operar, y `nombre_completo_asis` tal como llegó, sin tocar. Si la partición se equivoca, el dato original sigue ahí y se puede rehacer.

> **El motivo es el de `52:45`:** los nombres entran *«para que la persona no sea un código»* y **por los homónimos** (`52:54`). Detectar un homónimo exige comparar apellidos, no cadenas completas.

---

## 3.3 · Multivaluado

Un atributo que admite **varios valores a la vez** para el mismo ejemplar. En Chen, doble línea. **Siempre se convierte en tabla.**

### El caso del proyecto: el número de documento

En el archivo de entidades, `NumeroIdentidad` quedó como atributo simple de `Asistente`. **El dato real dice que no puede serlo.**

| Medida sobre `USBME_EMPLID_CATED_V1` | Valor |
|---|---:|
| Filas | 16.093 |
| ID distintos | 14.808 |
| **ID con más de un número de documento** | **707** |
| Documentos con más de un ID | **0** |

Setecientas siete personas tienen dos o más números de documento asociados: correcciones de digitación, paso de tarjeta de identidad a cédula, cambios de nacionalidad. **Como atributo simple solo cabe uno, y elegir cuál es perder información.**

Y la dirección importa: **de documento se llega al ID, pero de ID no se llega a un solo documento.** Esa asimetría es una dependencia funcional que reaparece en la normalización.

→ Se convierte en la entidad **`DOCUMENTO_ASISTENTE`**, con un solo documento marcado como vigente.

> **Por qué esto no es purismo.** El profesor Hugo Nelson describió el trabajo manual en `42:01`: *«a veces los estudiantes, como no se saben el ID, colocan la cédula; entonces toca buscar en ASIS con la cédula para obtener el ID»*. Ese es exactamente el caso de uso del atributo. Si la persona busca con un documento antiguo y el modelo solo guarda el nuevo, **la búsqueda falla y el gestor vuelve al trabajo manual**.

### El otro multivaluado: el correo

Dos correos por persona, institucional y personal, acordados en `1:50:37`. **Se resolvieron como dos atributos simples, no como multivaluado**, porque son exactamente dos, tienen roles distintos y el sistema debe poder preferir uno sobre otro. Es una decisión declarada: si mañana hicieran falta *n* correos, se convertiría en tabla.

---

## 3.4 · Derivado

Un atributo cuyo valor **se calcula** a partir de otros. En Chen, línea punteada. La regla es simple: **si se puede calcular, no se digita**.

### Los cinco derivados del modelo

| Derivado | De dónde sale | Por qué no se digita |
|---|---|---|
| **`nombre_asis`** | Los primeros 30 caracteres de `nombre` | El ASIS trunca a 30. Se comprueba en el dato: `REMOCIÓN DE METALES PESADOS DE`, `CURSO FORMATIVO LÓGICO MATEMAT`. Si se digitara el corto, **se perdería el largo para siempre** |
| **`numero_reunion`** | El máximo del consecutivo de esa cátedra, más uno | **Es el paso 2 completo del manual de migración.** Un humano buscándolo en 5.711 filas |
| **`es_correo_institucional`** | El dominio de la dirección a la que se envió | Si se digitara, alguien lo marcaría mal justo en el caso que importa vigilar |
| **`es_interno`** | Del tipo de vinculación | Informe 2 del enunciado: internos contra externos |
| **`asistentes_registrados`** | Cuenta de registros de la sesión | Se calcula. Materializarlo solo si el rendimiento lo exige, y entonces con disparador |

> **La instantánea NO es un derivado.** `fk_programa_snapshot` en el registro de asistencia *parece* derivable del programa vigente del asistente, y no lo es: el programa vigente **cambia**, y la asistencia hay que imputarla al que tenía ese día. Un derivado se recalcula y da lo mismo; una instantánea se recalcula y **da otra cosa**. Ver [11 · Acceso y registro](11-MER-de-Acceso-y-Registro.md).

---

## 3.5 · Identificador

El atributo, o conjunto de atributos, que distingue un ejemplar de otro. **Subrayado** en Chen.

### Identificador natural frente a sustituto

| | Natural | Sustituto |
|---|---|---|
| Qué es | Un dato del negocio que ya identifica | Un número que inventa el sistema |
| Ejemplo aquí | `id_asis`, `codigo` de programa | `id_asistente`, `id_sesion` |
| Ventaja | No hay que traducir para hablar con el ASIS | Estable frente a cambios de formato |
| Riesgo | **Si el formato cambia, se propaga a todo el modelo** | Un `JOIN` más para llegar al dato del negocio |

### La decisión de este proyecto

**Sustitutos en las entidades grandes, naturales en los catálogos.** Y los naturales se conservan siempre como **identificadores alternativos con unicidad**, para que la restricción del negocio siga vigente.

| Entidad | Identificador | Alternativo |
|---|---|---|
| `ASISTENTE` | `id_asistente` sustituto | **`id_asis` único** |
| `CATEDRA` | `id_catedra` sustituto | **`id_evento_asis` único** |
| `SESION` | `id_sesion` sustituto | **(`catedra`, `numero_reunion`) único** |
| `PROGRAMA_ACADEMICO` | **`codigo` natural** (`M0221`, `M0286`) | — |
| Catálogos | **Natural** | — |

**Por qué sustituto en `ASISTENTE` si el profesor Hugo Nelson dijo que el identificador es el ID.** No lo contradice: `id_asis` sigue siendo único y obligatorio para todo interno, que es lo que él afirmó. Pero ese formato **ya cambió dos veces** —códigos de 6 dígitos, `30000…`, `300000…` (`27:47`, `33:25`)— y admite letras. Un identificador que ha cambiado dos veces no debe quedar copiado en las diez tablas que lo referencian.

### El identificador de la entidad débil

`SESION` es débil: se identifica **por su cátedra más su número de reunión**. Y ese par se verificó contra el dato:

> **En las 5.711 filas de `USBME_LCONTROL_CATEDRAS`, el par (Evento, Reunión) es único.** No es una suposición del diseñador: está comprobado.

---

## Resumen aplicado

| Tipo | Cuántos hay | Los importantes |
|---|---:|---|
| Simple | la mayoría | — |
| Compuesto | 1 | `nombre`, partido en `nombres` + `apellidos` y conservado íntegro |
| **Multivaluado** | **1** | **`numero` de documento → entidad `DOCUMENTO_ASISTENTE`** |
| **Derivado** | **5** | `nombre_asis`, `numero_reunion`, `es_correo_institucional`, `es_interno`, conteo |
| Identificador | 31 | 12 sustitutos · 19 naturales · 1 débil compuesto |

---

**Anterior:** [02 · Atributo](02-Atributo.md) · **Siguiente:** [04 · Relación](04-Relacion.md)
