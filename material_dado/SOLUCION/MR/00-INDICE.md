# Modelo Relacional — Cátedras Abiertas

**Diseño lógico · Fase 2**
**37 tablas · 52 claves foráneas · 47 restricciones `CHECK` · 1 `EXCLUDE`**
**Todas en BCNF**

---

## Los documentos

| # | Archivo | Contenido |
|---|---|---|
| 1 | [01-Esquema-Relacional.md](01-Esquema-Relacional.md) | Las 37 tablas con sus claves primarias, candidatas y foráneas. Las siete decisiones que hay que poder defender |
| 2 | [02-Dependencias-y-Normalizacion.md](02-Dependencias-y-Normalizacion.md) | Dependencias funcionales **medidas sobre el dato real**, claves candidatas por el método del cierre, y 1FN → BCNF |
| 3 | [03-Transformacion-MER-a-MR.md](03-Transformacion-MER-a-MR.md) | Una fila por cada entidad y cada relación del conceptual, con la regla aplicada |
| 4 | [04-Estructuras-de-Acceso.md](04-Estructuras-de-Acceso.md) | **Las tres estructuras difíciles**, con las alternativas evaluadas y la decisión justificada |
| 5 | [05-Trazabilidad.md](05-Trazabilidad.md) | Cobertura tabla × informe · las 38 reglas · las 17 citas D1–D17 · matriz CRUD por rol |
| 6 | [06-Sustentacion.md](06-Sustentacion.md) | Las preguntas de sustentación, respondidas |

---

## Los números, verificados contra la base construida

No son estimaciones: salen de consultar `information_schema` y `pg_constraint` sobre la base ya creada y cargada.

| | |
|---|---:|
| Tablas | **37** |
| Vistas | 6 |
| Claves foráneas | **52** |
| Restricciones `CHECK` | **47** |
| Restricciones `EXCLUDE` | 1 |
| Índices únicos parciales | 4 |
| Disparadores | 7 |
| Funciones y procedimientos | 10 |
| **Tablas en BCNF** | **37 de 37** |

| Reglas de negocio | 38 |
|---|---:|
| — declarativas | 18 |
| — parciales | 5 |
| — por disparador, función o procedimiento | 15 |

---

## Las cinco cosas que más se revisan

| # | Qué mirar | Dónde | Por qué |
|---|---|---|---|
| 1 | La clave de `vinculacion_asistente` y de `rol_por_usuario` | [01](01-Esquema-Relacional.md) | Sin `fecha_ini` en la clave, **nadie puede recuperar algo que ya tuvo**, y falla en silencio |
| 2 | Las dos columnas de instantánea de `registro_asistencia` | [04](04-Estructuras-de-Acceso.md) | Si se leen del vigente, el archivo enviado al ASIS **deja de ser reproducible** |
| 3 | `programa_academico.codigo` es `varchar(5)`, no `char(5)` | [01](01-Esquema-Relacional.md) | `MCCP` tiene 4 caracteres. Con `char`, el archivo plano sale con **un espacio de más** |
| 4 | La dependencia parcial `documento → id_asis` | [02](02-Dependencias-y-Normalizacion.md) | Es la violación de 2FN del archivo real, con sus tres anomalías **reales** |
| 5 | Las tres reglas que **no** son declarativas | [04](04-Estructuras-de-Acceso.md) | Es donde el modelo deja de garantizar y empieza a depender de código |

---

## Lo que este nivel descubrió y el conceptual no podía

Dos hallazgos salieron de cargar los datos reales, no de dibujar el modelo:

1. **`MCCP` tiene cuatro caracteres.** El tipo `char(5)` habría metido un espacio final en el archivo del ASIS — justo lo que el manual de migración prohíbe.
2. **El número de reunión no es un consecutivo por cátedra.** De 5.481 eventos con una sola reunión, solo 588 llevan el número 1; los demás llegan hasta 4348. **Eso resuelve con dato la decisión que el plan había dejado abierta en §8.3:** la autoridad del consecutivo es el ASIS, no este sistema.

> **Ninguno de los dos se podía ver en el papel.** Aparecieron al ejecutar. Es la razón de que la Fase 3 no sea «escribir el SQL del modelo» sino **una fase de verificación**.

---

**Nivel anterior:** [`../MER/`](../MER/) · **Nivel siguiente:** [`../fisico_postgres/`](../fisico_postgres/) · **El modelo en una página:** [`../MODELO-INTEGRADO.md`](../MODELO-INTEGRADO.md)
