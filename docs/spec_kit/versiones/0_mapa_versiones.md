# Mapa de versiones — Cátedras Abiertas

> La ruta completa del ejemplo. Cada versión es una **rebanada vertical** y se
> cierra con un tag; una versión cerrada no se reabre.

---

## La estrategia de este proyecto: back y front EN PARALELO

**Este repositorio es el piloto de una forma de versionar: cada versión
entrega su parte de la API *y* su parte del front.** No hay una versión "de
back" y otra "de front".

Conviene decir por qué, porque la alternativa es la que siguen otros ejemplos
del curso —construir la API en varias versiones y meter el front al final— y
no es una decisión obvia.

### Por qué en paralelo

| | |
|---|---|
| **Lo "terminado" se le puede mostrar a alguien** | Una versión que solo trae endpoints se sustenta con Postman. Una versión que trae pantallas se le muestra a la coordinadora de Bienestar, que es quien la pidió |
| **El contrato se ejercita de inmediato** | Uno descubre que el JSON es incómodo **cuando le toca pintarlo**. Si el front llega tres versiones después, el contrato lleva tres versiones equivocado |
| **No hay front de golpe al final** | Es el error que se paga caro: seis entidades de API esperando un front que nace con una sola, y una versión entera dedicada a que se alcancen |
| **Es lo que se le pide al equipo** | `0_METODOLOGIA.md` §2 dice, textual: *«v1 — CRUD de las tablas sin FK del módulo — **API REST + Frontend funcionando**»* |

### Y qué cuesta, que también hay que decirlo

| El precio | Cómo se paga |
|---|---|
| **Cada versión es el doble de grande** | Se acepta a cambio de que cada una sea demostrable. Y se compensa recortando el alcance: la v1 toma **una** tabla, no las once |
| **Cada compuerta revisa dos stacks** | El checklist se corre igual, pero la sección de contratos ahora incluye pantallas |
| **Si la v2 cambia el contrato, el front de la v1 hay que ajustarlo** | Eso **no es un costo: es la regresión**. Que duela es la señal de que el contrato importa |
| **Las lecciones propias del front hay que darlas en la v1** | Que es otro proceso, que no toca la base. Cabe, y en esta v1 está: el criterio 8 lo comprueba apagando la API |

> **La regla operativa:** una versión **no está cerrada** si la API responde y
> la pantalla no. Media versión no es una versión.

---

## Las cuatro versiones

Alineadas con las cuatro que el curso evalúa
(`ProyectosDeAula` → `0_METODOLOGIA.md` §2), porque son las que el equipo
entrega y sustenta.

| Versión | Carpeta | Qué EXISTE al terminarla — **API y front** | Historias | Qué concepto nuevo enseña |
|---|---|---|---|---|
| **v1** | [v1_sede/](v1_sede/2_spec.md) — **Cerrada** (tag `v1`) | El CRUD de las tablas **sin clave foránea**, con sus pantallas. *Este ejemplo construye una: `sede`* | [1, 2, 3, 4](../0_historias_de_usuario.md) | Tres capas con interfaces · y que **el front y la API pueden estar en lenguajes distintos** porque solo los une el contrato |
| **v2** | v2_todas_las_tablas/ | **Todas** las demás tablas: los catálogos, `catedra`, `sesion` y las puente — con las **listas desplegables cargadas de la API** y sus pantallas | [5](../0_historias_de_usuario.md) | Integridad referencial **en pantalla**: las llaves foráneas se **eligen**, no se digitan · y cuándo conviene **generalizar** el patrón en vez de copiarlo |
| **v3** | v3_acceso/ | `usuario`, `rol` y `rol_por_usuario`: ingreso, contraseñas cifradas y **control de acceso por rol**, en la API y en el front | [8](../0_historias_de_usuario.md) | Dónde vive la autenticación · y que **esconder un menú NO protege nada**: mientras el control no esté en el servicio, quien escriba la URL entra igual |
| **v4** | v4_aplicativo/ | El **registro de asistencia** completo (clave de acceso, enlace, QR), las **consultas multitabla**, el **dashboard**, la **imagen corporativa completa** —el manual de marca ya está aplicado desde la v1, y aquí se evalúa— y la **publicación** | [6, 7](../0_historias_de_usuario.md) | Las **rutinas de la base** como parte del contrato · y las reglas de negocio que **no viven en la API** |

**La trazabilidad va en los dos sentidos:** de la versión a sus historias
—columna de arriba— y de la historia a su versión, en la columna *Iteración
asignada* de
[`0_historias_de_usuario.md`](../0_historias_de_usuario.md).

> **Un desajuste que hubo que corregir, y que vale como advertencia.** La
> primera versión de este mapa asignaba a la v2 «los demás catálogos», a la v3
> «cátedra y sesión» y a la v4 «la asistencia» — y las historias de usuario
> decían otra cosa. **Dos documentos del mismo proyecto describiendo rutas
> distintas.** Ninguno estaba «mal» por sí solo: lo que estaba mal era que no
> se hubieran leído el uno contra el otro. Se alinearon los dos contra lo que
> el curso evalúa, que es el único árbitro que hay.

---

## Lo que este ejemplo construye

La v1 del modelo pide el CRUD de las **once tablas sin clave foránea** de las
37 que tiene. **Este repositorio construye una sola, completa**: `sede`, con su
API y sus pantallas.

`sede` no es la más grande: es la que **enseña más por fila**. Tiene un **campo
opcional** —la sede virtual no tiene dirección, y viene así desde el script
dado—, un **booleano** nativo del motor, y **dos restricciones de unicidad
distintas** —la llave primaria y el nombre— que dan **dos 500 por motivos
diferentes**, en la misma pantalla.

Las otras diez son **ese mismo patrón** con otros nombres. El equipo que tome
este ejemplo lo revisa, y **si está de acuerdo lo retoma y lo completa; si no,
lo rehace a su manera**. Lo que no puede es cambiar la especificación sin pasar
por sus compuertas.

## Reglas del mapa

1. **La constitución no se toca entre versiones.** Si una versión exige
   cambiar una regla, eso es una enmienda y se discute aparte (Artículo 12).
2. **Cada carpeta de versión es autocontenida**: con la constitución más esa
   carpeta se puede construir la versión desde el estado anterior.
3. **El código de una versión no anticipa a la siguiente.** En la v1 no se
   escribe la fábrica multi-motor "por si acaso": se escribe la interfaz, y la
   fábrica llegará cuando un segundo motor la justifique.
4. **Cada versión termina en verde**: criterios verificables, corridos por una
   persona, y tag al cerrarla.
5. **Una versión incluye su front.** No está cerrada si la API responde y la
   pantalla no.
6. **Cada versión pasa la regresión de las anteriores**, y desde la v2 eso
   incluye las **pantallas** de las anteriores, no solo sus endpoints.
7. La spec de la versión siguiente **parte del estado real** que dejó la
   anterior. Si el código divergió de la spec, primero se reconcilia.
