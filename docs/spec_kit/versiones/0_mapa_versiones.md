# Mapa de versiones — Cátedras Abiertas

> La ruta completa del ejemplo. Cada versión es una **rebanada vertical** y se
> cierra con un tag; una versión cerrada no se reabre.

| Versión | Carpeta | Qué EXISTE al terminarla | Qué concepto nuevo enseña |
|---|---|---|---|
| **v1** | [v1_sede/](v1_sede/2_spec.md) — **Cerrada** (tag `v1`) | El CRUD de **`sede`** de punta a punta: API en C# y front en Flask, contra PostgreSQL | Tres capas con interfaces · y que **el front y la API pueden estar en lenguajes distintos** porque solo los une el contrato |
| v2 | v2_catalogos/ | Las demás tablas **sin clave foránea**: modalidad, tipo_evento, tipo_documento, tipo_vinculacion, periodo_academico, estado_proceso, tipo_pregunta | El mismo patrón repetido — y cuándo conviene **generalizarlo** en vez de copiarlo |
| v3 | v3_catedra_sesion/ | `catedra` y `sesion`, que **sí tienen claves foráneas** y restricciones de solapamiento | Integridad referencial en pantalla: las FK se **eligen**, no se digitan |
| v4 | v4_asistencia/ | El registro de asistencia: clave de acceso, enlace y el flujo completo | Las **rutinas de la base** como parte del contrato, y las reglas que no viven en la API |

## Lo que este ejemplo construye

La v1 de este repositorio se construye sobre **`sede`**: una rebanada vertical
completa —controlador, servicio, repositorio, interfaces, peticiones por verbo,
prueba sin base de datos, y una pantalla— sobre una de las **once tablas sin
clave foránea** de las 37 que tiene el modelo.

`sede` no es la más grande: es la que enseña más por fila. Tiene un **campo
opcional** (la sede virtual no tiene dirección), un **booleano de verdad**, y
un **`UNIQUE` sobre el nombre** que da un 500 demostrable — además del 500 de
la llave primaria. Dos defensas distintas de la base, en la misma pantalla.

Las demás tablas de la v1 del modelo son **ese mismo patrón** con otros
nombres. El equipo que tome este ejemplo lo revisa, y **si está de acuerdo lo
retoma y lo completa; si no, lo rehace a su manera**. Lo que no puede es
cambiar la especificación sin pasar por sus compuertas.

## Reglas del mapa

1. **La constitución no se toca entre versiones.** Si una versión exige
   cambiar una regla, eso es una enmienda y se discute aparte.
2. **Cada carpeta de versión es autocontenida**: con la constitución más esa
   carpeta se puede construir la versión desde el estado anterior.
3. **El código de una versión no anticipa a la siguiente.** En la v1 no se
   escribe la fábrica multi-motor "por si acaso": se escribe la interfaz, y la
   fábrica llegará cuando un segundo motor la justifique.
4. **Cada versión termina en verde**: criterios verificables, corridos por una
   persona, y tag al cerrar.
5. La spec de la versión siguiente **parte del estado real** que dejó la
   anterior. Si el código divergió de la spec, primero se reconcilia.
