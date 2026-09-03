# Modelo Entidad-Relación — Cátedras Abiertas

**Diseño conceptual · Fase 1**
**Notación:** Chen (Peter Chen, 1976), complementada con min-max
**Modelo:** 33 entidades · 35 relaciones · 37 tablas
**Documento de origen:** [`../../PLAN-BD-CATEDRAS-ABIERTAS.md`](../../PLAN-BD-CATEDRAS-ABIERTAS.md)

---

## Por qué esta carpeta es el entregable principal

Lo dijo el director técnico en el primer minuto de la reunión:

> *«Hacer un modelo entidad-relación… para mí es de las cosas más importantes, y algunos las subestiman. Con la inteligencia artificial ya no se codifica; lo que se hace es interactuar con los requerimientos y ya va entregando el código.»* — `0:03` y `0:11`

Si el código sale de un modelo, **el modelo es el producto**. Un error aquí no se arregla programando: se propaga.

---

## Los seis conceptos, en el orden en que se entienden

Cada archivo separa deliberadamente lo que es **definición** —no negociable— de lo que es **decisión de diseño** —defendible, con alternativas y costos declarados—.

| # | Archivo | Concepto | Pregunta que responde |
|---|---|---|---|
| 1 | [01-Entidad.md](01-Entidad.md) | **Entidad** | ¿De qué cosas guardo datos y cómo distingo una de otra? |
| 2 | [02-Atributo.md](02-Atributo.md) | **Atributo** | ¿Qué describe a esa cosa y qué es una cosa aparte? |
| 3 | [03-Tipos-de-Atributos.md](03-Tipos-de-Atributos.md) | **Tipos de atributo** | ¿Es simple, compuesto, multivaluado, derivado o identificador? |
| 4 | [04-Relacion.md](04-Relacion.md) | **Relación** | ¿Cómo se asocian las entidades y con qué **verbo** se llama eso? |
| 5 | [05-Cardinalidad.md](05-Cardinalidad.md) | **Cardinalidad** | ¿**Cuántas**? `1:1`, `1:N`, `N:M` |
| 6 | [06-Opcionalidad-y-Participacion.md](06-Opcionalidad-y-Participacion.md) | **Opcionalidad** | ¿Es **obligatorio** o **puede** no estar? |

> **Sobre el concepto 6.** El profesor Carlos Castro lo explicó en `18:30`: *«el círculo significa que debe o puede… lo que significa muchos es esta patica de gallina»*. Son **dos preguntas distintas** —*cuántas* frente a *si es obligatorio*— y se responden por separado. En Chen la primera va en la arista y la segunda en el min-max.

---

## La aplicación al proyecto

| # | Archivo | Contenido |
|---|---|---|
| 7 | [07-Entidades-del-Proyecto.md](07-Entidades-del-Proyecto.md) | Las **33 entidades** agrupadas en siete bloques, con su descripción escrita, su identificador y por qué es entidad y no atributo. Incluye **lo que se descartó y por qué** |
| 8 | [08-Atributos-del-Proyecto.md](08-Atributos-del-Proyecto.md) | Los atributos de cada entidad, con los compuestos, los derivados y **los nulos que significan algo** |
| 9 | [09-Relaciones-del-Proyecto.md](09-Relaciones-del-Proyecto.md) | Las **35 relaciones** con su verbo, sus frases en español en ambas direcciones, su cardinalidad y su min-max |
| 10 | [10-Diagramas-MER.md](10-Diagramas-MER.md) | Los diagramas: **el archivo de Draw.io de 7 páginas** más las seis vistas en Mermaid |
| **11** | **[11-MER-de-Acceso-y-Registro.md](11-MER-de-Acceso-y-Registro.md)** | **El centro de la carpeta:** el flujo enlace → clave → registro, y las **tres estructuras difíciles** del modelo |

> **El archivo 11 es el corazón.** El acceso verificado por correo es lo que distingue este sistema del formulario anónimo que hay hoy, y concentra las tres estructuras que el resto del modelo no tiene: una **instantánea que convive con su referencia**, una **regla condicional entre atributos** y una **participación mínima de uno** que ninguna clave foránea garantiza.

---

## El modelo en una tabla

| Bloque | De qué trata | Entidades |
|---|---|---:|
| **A · Asistentes e identidad** | Quién es cada asistente y con qué autoridad se afirma | 5 |
| **B · Estructura académica** | Programas, facultades, periodos | 3 |
| **C · Cátedras, sesiones y sedes** | El evento, sus reuniones, dónde y cuándo | 6 |
| **D · Acceso y registro** | El QR, el enlace, la clave al correo y el acto de registrarse | 3 |
| **E · Encuesta de calidad** | Cuestionario parametrizable y sus respuestas | 6 |
| **F · Integración con el ASIS** | Cargas de entrada, lotes de salida y su resultado | 6 |
| **G · Seguridad y configuración** | Usuarios, roles, parámetros y bitácora | 4 |
| | | **33** |

Más **6 relaciones con atributos** que se vuelven tabla al transformar → **37 tablas**.

---

## Las convenciones, y de dónde salen

Todas fueron dictadas por el director técnico durante la reunión. No son gusto: son el criterio de revisión.

| Convención | Cita |
|---|---|
| Cada entidad representa **un solo objeto de estudio** | `5:44` |
| Toda entidad y todo atributo llevan **descripción escrita**, que se ajusta con el entendimiento | `24:21`, `24:59` |
| Las relaciones se nombran con **verbos**, evitando *haber* y *tener* | `7:22`, `7:34` |
| Nombres **sin tildes y sin espacios** | `34:10`, `35:06` |
| Notación de **Chen**, no de pata de gallina | `19:11` |
| Cardinalidad y opcionalidad, **por separado** | `18:30` |

---

## Trazabilidad

| Nivel | Carpeta |
|---|---|
| **Conceptual** | Esta carpeta |
| **Lógico** | [`../MR/`](../MR/) — esquema relacional, dependencias, normalización, transformación y matriz CRUD |
| **Físico** | [`../fisico_postgres/`](../fisico_postgres/) — los veinte scripts ejecutables |
| **El modelo en una página** | [`../MODELO-INTEGRADO.md`](../MODELO-INTEGRADO.md) |
| **El plan que originó todo** | [`../../PLAN-BD-CATEDRAS-ABIERTAS.md`](../../PLAN-BD-CATEDRAS-ABIERTAS.md) |
