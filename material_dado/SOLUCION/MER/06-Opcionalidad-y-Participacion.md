# 6 · Opcionalidad y participación

---

## Definición

> **La opcionalidad responde a otra pregunta distinta de la cardinalidad: ¿es obligatorio participar, o puede no participar?**

El profesor Carlos Castro lo dijo en `18:30` y en `18:51`, y lo importante es que **separó los dos conceptos en la misma frase**:

> *«El círculo significa que puede ser que debe o puede, que es requerido o no. Pero lo que significa "muchos" es esta patica de gallina.»*
> *«Es la opcionalidad. Esta bolita puede ser como qué tanta dependencia hay.»*

| | Cardinalidad | Opcionalidad |
|---|---|---|
| Pregunta | **¿Cuántas?** | **¿Debe o puede?** |
| Respuestas | `1`, `N` | obligatoria, opcional |
| En pata de gallina | la patica | la bolita |
| En Chen | la etiqueta de la arista | el **min-max** |

**Son independientes.** Se combinan de cuatro maneras, y las cuatro existen en este modelo.

---

## Los tres nombres de lo mismo

Conviene saberlos porque cada libro usa uno:

| Nombre | Quién lo usa | Cómo lo dice |
|---|---|---|
| **Participación** | Chen | total o parcial |
| **Modalidad** | Elmasri y Navathe | obligatoria u opcional |
| **Opcionalidad** | La práctica profesional, y el profesor Carlos Castro | *«debe o puede»* |

Aquí se usa **min-max**, que los unifica: `(0,N)` es opcional y múltiple; `(1,1)` es obligatoria y única.

---

## Cómo se lee el min-max

Se escribe en cada extremo de la relación y se lee así:

> **Para un ejemplar de esta entidad, ¿cuál es el mínimo y el máximo de ejemplares de la otra con los que se asocia?**

| Min-max | Significa |
|---|---|
| `(0,1)` | Puede no tener ninguno; como mucho uno |
| `(1,1)` | **Tiene exactamente uno.** Obligatorio |
| `(0,N)` | Puede no tener ninguno o tener muchos |
| `(1,N)` | **Tiene al menos uno.** Obligatorio y múltiple |

---

## Las cuatro combinaciones, con ejemplos de este proyecto

### `(1,1)` — obligatoria y única

`SESION` → `CATEDRA` es `(1,1)`: **toda sesión pertenece a exactamente una cátedra.** No existe una reunión huérfana. Es lo que hace de `SESION` una entidad débil.

`REGISTRO_ASISTENCIA` → `SESION` es `(1,1)`: **todo registro es de una sesión concreta.** Sin esto no habría número de reunión que enviar al ASIS.

### `(1,N)` — obligatoria y múltiple

`RESPUESTA_ENCUESTA` → `RESPUESTA_ITEM` es `(1,N)`: **una encuesta respondida tiene al menos un ítem.** Una encuesta sin ninguna respuesta no es una encuesta: es ruido.

> **Esta es la participación que ninguna clave foránea garantiza.** Ver §«La participación mínima de uno», más abajo. Es una de las tres estructuras difíciles del modelo.

### `(0,1)` — opcional y única

`ASISTENTE` → `USUARIO` es `(0,1)`: **casi ningún asistente es usuario administrador.**

`REGISTRO_ASISTENCIA` → `RESPUESTA_ENCUESTA` es `(0,1)`: **responder la encuesta es voluntario.** Si fuera obligatoria, no habría nada que medir en el informe de tasa de respuesta.

### `(0,N)` — opcional y múltiple

`ASISTENTE` → `REGISTRO_ASISTENCIA` es `(0,N)`: **una persona puede estar en el maestro y no haber ido nunca a una cátedra.** De hecho, esa es la situación de la mayoría de las 14.808 personas del archivo.

---

## Las opcionalidades que salieron de la reunión

Estas no son decisiones del diseñador: las dictó el usuario experto, y cada una tiene su cita.

| Relación | Min-max | Cita | Qué significa |
|---|---|---|---|
| `ASISTENTE` → `PROGRAMA_ACADEMICO` | **`(0,N)`** | `41:16` — *«para el tema de Rutas de Paz sí sería una excepción: ellos entrarían sin programa, pero solo ellos»* | **El programa es opcional.** Y el nulo significa una cosa concreta, no «no se sabe» |
| `ASISTENTE` → `correo_institucional` | **opcional** | `53:42` — *«los que están en Rutas de Paz no tienen correo institucional»* | No es un caso raro: es una población entera |
| `ASISTENTE` → `id_asis` | **`(1,1)` para internos** | `26:46` — *«para poder inscribir la cátedra en ASIS, cualquier persona debe estar registrada en ASIS con ID»* | Es una **restricción del negocio**, y el profesor Carlos Castro lo subrayó: *«eso es importante porque esa es una restricción»* (`27:24`) |
| `SESION` → `ENLACE_REGISTRO` | **`(0,N)`** | — | Una sesión puede existir sin enlace todavía: se crea antes de generar el QR |
| `REGISTRO` → `CLAVE_ACCESO` | **`(1,1)`** | `1:04:51` — *«yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo»* | **Todo registro nace de una clave usada.** Si no, no hay antisuplantación |

> ### La opcionalidad más cara de equivocarse
>
> `ASISTENTE → PROGRAMA` parece `(1,N)` obligatoria. Todo estudiante tiene programa; el archivo plano lo exige; el ASIS lo pide.
>
> **Y es falsa.** Rutas de Paz entra sin programa. Si el modelo la declara obligatoria, esa población no puede registrarse — y el fallo aparecerá el día del evento, delante de la gente.
>
> Peor aún: la tentación es resolverlo con un programa ficticio tipo `M0000`. Eso contamina todos los informes por programa, que son el informe número 1 del enunciado.
>
> **La solución correcta es que la obligatoriedad sea un dato**, no una regla escrita en el modelo: el catálogo de vinculación lleva un atributo `exige_programa`, y habilitar una nueva excepción es cambiar una fila, no el esquema.

---

## La participación mínima de uno, y por qué no es declarativa

Hay una diferencia entre estas dos afirmaciones que parece sutil y no lo es:

| Afirmación | ¿Se puede declarar? |
|---|---|
| «Si hay un ítem de respuesta, debe apuntar a una encuesta que exista» | **Sí.** Es una clave foránea |
| «Toda encuesta respondida debe tener al menos un ítem» | **No.** Ninguna clave foránea lo expresa |

**Una clave foránea garantiza que lo que se inserte exista, no que se inserte algo.** El lado «uno o más» de una relación `(1,N)` no tiene mecanismo declarativo en SQL: hay que resolverlo con un procedimiento que cree las dos cosas juntas, o con una verificación diferida.

En este modelo aparece tres veces:

1. **Toda encuesta respondida tiene al menos un ítem.**
2. **Toda pregunta obligatoria de la encuesta tiene respuesta.** Ni siquiera es «al menos uno»: es «uno por cada pregunta marcada obligatoria», que depende del contenido del catálogo.
3. **Todo lote de migración lleva al menos un detalle.** Un lote vacío no se envió: se abandonó.

**Se resuelven en el diseño físico con procedimientos**, y quedan declaradas aquí para que nadie las busque como restricción y concluya que se olvidaron. Ver [11 · Acceso y registro](11-MER-de-Acceso-y-Registro.md).

---

## Cuadro de participación de las entidades principales

| Entidad | Con | Min-max izq. | Min-max der. | Lectura |
|---|---|---|---|---|
| `ASISTENTE` | `REGISTRO` | `(0,N)` | `(1,1)` | Puede no haber ido nunca; todo registro tiene dueño |
| `SESION` | `REGISTRO` | `(0,N)` | `(1,1)` | Una sesión puede quedar vacía |
| `SESION` | `CATEDRA` | `(1,1)` | `(0,N)` | Toda sesión tiene cátedra; una cátedra puede no tener sesiones aún |
| `SESION` | `SEDE` | `(1,1)` | `(0,N)` | Toda sesión ocurre en algún sitio, aunque sea virtual |
| `ENLACE` | `SESION` | `(1,1)` | `(0,N)` | Un enlace sin sesión no significa nada |
| `CLAVE` | `ASISTENTE` | `(1,1)` | `(0,N)` | Toda clave se envía a alguien |
| `REGISTRO` | `ENCUESTA_RESP` | `(0,1)` | `(1,1)` | Responder es voluntario |
| `RESP_ENCUESTA` | `RESP_ITEM` | **`(1,N)`** | `(1,1)` | **No declarativa** |
| `ASISTENTE` | `PROGRAMA` | **`(0,N)`** | `(0,N)` | Rutas de Paz sin programa |
| `ASISTENTE` | `DOCUMENTO` | `(0,N)` | `(1,1)` | Puede no tener documento cargado; los 707 tienen varios |

---

**Anterior:** [05 · Cardinalidad](05-Cardinalidad.md) · **Siguiente:** [07 · Entidades del proyecto](07-Entidades-del-Proyecto.md)
