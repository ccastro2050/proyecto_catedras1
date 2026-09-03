# Constitución del proyecto — Cátedras Abiertas

> Las reglas **permanentes**. No cambian entre versiones: si una versión
> necesita cambiar una de estas reglas, eso no es una tarea — es una enmienda,
> y se discute aparte (Artículo 11).
>
> **Todo lo que rige este proyecto está en el spec kit.** Si algo no está
> aquí ni en un documento de versión, **no está especificado** — y eso incluye
> las cosas que "todo el mundo sabe".
>
> | Documento | Qué contiene |
> |---|---|
> | [`0_historias_de_usuario.md`](0_historias_de_usuario.md) | Las necesidades: quién, qué y para qué |
> | **`1_constitution.md`** (este) | Las reglas permanentes — **incluidos el stack, los datos personales y la identidad visual** |
> | [`versiones/0_mapa_versiones.md`](versiones/0_mapa_versiones.md) | La ruta v1 → v4, y la estrategia de back y front en paralelo |
> | [`versiones/v1_sede/`](versiones/v1_sede/2_spec.md) | Los ocho documentos de la versión 1 |
>
> **Versión de esta constitución: 1.2.1**
>
> | Versión | Qué cambió |
> |---|---|
> | 1.0.0 | Los doce artículos originales |
> | 1.1.0 | **Artículo 1.1** — una versión incluye su front (versionado en paralelo) |
> | 1.2.0 | **Artículo 9.1** — la identidad visual, que antes solo estaba en el README |
> | 1.2.1 | Se corrige el Artículo 9.1: **sí hay archivo de logosímbolo**, y es el oficial del sitio de la Universidad |

---

## Artículo 1 — El proyecto se construye POR VERSIONES y la especificación manda

Cada versión es una **rebanada vertical completa** y se cierra con un tag. Una
versión cerrada no se reabre: lo que falte entra en la siguiente.

**No se anticipa.** Si algo pertenece a una versión posterior, no se escribe
hoy "por si acaso" — ni una interfaz, ni una columna, ni un endpoint. Escribir
de más no es prever: es adivinar, y lo que se adivina hay que mantenerlo.

Y al revés: **el código no decide, la especificación decide**. Si al programar
aparece una duda que la spec no resuelve, se para, se resuelve en la spec y se
sigue. Resolverla en el código deja el documento mintiendo.

## Artículo 1.1 — Una versión incluye SU FRONT

**Este proyecto versiona back y front en paralelo.** Cada versión entrega su
parte de la API *y* sus pantallas. No hay una versión "de back" y otra "de
front".

**La regla operativa:** una versión **no está cerrada** si la API responde y la
pantalla no. Media versión no es una versión.

Y desde la v2, la regresión de las versiones anteriores incluye **sus
pantallas**, no solo sus endpoints.

**Por qué:** uno descubre que el JSON es incómodo cuando le toca pintarlo. Si
el front llega tres versiones después, el contrato lleva tres versiones
equivocado. Y porque lo terminado se le puede mostrar a quien lo pidió, no solo
a un Postman.

**Qué cuesta:** cada versión es más grande. Se compensa **recortando el
alcance**, no el rigor — por eso la v1 toma **una** tabla de las once, y no las
once a medias.

> Las razones completas, con sus costos, están en el
> [mapa de versiones](versiones/0_mapa_versiones.md). Este proyecto es el
> **piloto** de esa estrategia en el curso.

## Artículo 2 — Stack: C# y ASP.NET Core sobre PostgreSQL, con el SQL a la vista

- Lenguaje **C#** sobre **ASP.NET Core** (.NET 10): controladores con
  `[ApiController]`, y `Peticiones/` como frontera de entrada.
- Motor **PostgreSQL 16**, con **Npgsql** como proveedor.
- **No se usa un ORM.** El SQL se escribe a mano, queda a la vista y
  **siempre** va parametrizado con `@parametro`. El ejecutor es **Dapper**:
  mapea fila→objeto, pero **no genera SQL por nosotros**.
- Paquetes permitidos: `Npgsql`, `Dapper` y `Swashbuckle.AspNetCore`. Nada más.

> **El front es de otro lenguaje, y eso es deliberado.** Ver el Artículo 4.

## Artículo 3 — Arquitectura en tres capas con interfaces, desde el día 1

```
Controller  →  IServicio<Entidad>   →  IRepositorio<Entidad>
                    ↓                          ↓
              Servicio<Entidad>     Repositorio<Entidad>PostgreSql
                                       (Dapper, SQL a mano)
```

- La capa 1 (HTTP) **solo** traduce: petición → llamada al servicio → código
  de estado. No consulta la base ni decide reglas.
- La capa 2 (negocio) **no conoce HTTP**: comunica los problemas con
  excepciones del lenguaje, no con códigos de estado.
- La capa 3 (datos) es **la única** que sabe cuál es el motor.
- Cada capa depende de la **interfaz** de la siguiente, nunca de la clase.

**Y esto no es decorativo: es comprobable.** El proyecto `pruebas/` ejecuta el
servicio con un repositorio de mentiras, **sin referenciar Npgsql ni Dapper**.
Si esa prueba pasa con la base apagada, la separación es real. Si algún día
hiciera falta el paquete del motor para probar el negocio, la arquitectura se
rompió.

## Artículo 4 — Un solo comando, y tres procesos

```powershell
docker compose up -d --build
```

Eso levanta **la base, la API y el front**. No hay que instalar .NET, ni
Python, ni PostgreSQL.

**El front está escrito en otro lenguaje que la API — a propósito.** La API es
C# y el front es Python con Flask. Lo único que los une es un contrato HTTP:
ninguno de los dos sabe en qué lenguaje está el otro, y ninguno de los dos
tiene por qué saberlo.

Que en el mismo repositorio convivan dos lenguajes **es la demostración de que
la arquitectura no es un dibujo**. Si el front tuviera que estar en C# para
funcionar, el acoplamiento estaría en algún sitio.

## Artículo 5 — La base de datos viene DADA

El script de la base **no lo escribe este proyecto**: lo entregó el equipo que
diseñó el modelo, y viene con sus 37 tablas, sus vistas, sus rutinas, sus
disparadores y sus restricciones.

**Se respeta.** No se le agregan columnas, no se le quitan restricciones y no
se "corrige" lo que incomoda. Lo que se derive de él va **declarado en su
cabecera**, con su razón — y en la v1 hay tres cosas declaradas así.

Lo que crece por versiones es la API, no la base.

## Artículo 6 — Borrado LÓGICO, siempre

Ningún `DELETE` borra filas. Se marca `activo = FALSE` y **todos** los
listados filtran por `activo = TRUE`.

Cero filas afectadas significa "no existe o ya estaba inactiva", y eso es el
404 del contrato: no hace falta consultar antes para saberlo.

**`activo` es `BOOLEAN`**, con `TRUE`/`FALSE`. PostgreSQL tiene booleanos de
verdad: usar `1` y `0` sería calcar el dialecto de otro motor.

## Artículo 7 — Los secretos van en variables de entorno

La cadena de conexión y la clave de sesión llegan por variables de entorno,
nunca escritas en el código.

**Con una excepción declarada, y solo una:** en este repositorio de ejemplo
las contraseñas están **a la vista en el `docker-compose.yml`**, para que
`docker compose up` funcione recién clonado sin pedirle a nadie que adivine
nada. En un proyecto real eso va en un `.env` fuera de git.

Está dicho aquí para que nadie crea que es la forma correcta: **es una
concesión didáctica, y tiene su precio**.

## Artículo 8 — Datos personales: ninguno

**Este repositorio no contiene datos de personas reales, y no los va a
contener.**

El material original traía siete archivos con 14.808 asistentes —nombre,
apellido, correo institucional— y 15.517 números de documento. Ese material
**no se publica**: la v1 los reemplazó por cinco registros evidentemente
inventados.

No es una regla de estilo. Publicar la identidad de quince mil personas en un
repositorio público es un problema de protección de datos, y **ninguna
necesidad didáctica lo justifica**: para aprender el método no hacen falta
personas reales.

Si una versión futura necesita más datos, se inventan más.

## Artículo 9 — Todo en español, y el código sustenta sus decisiones

Nombres de clases, métodos, variables, rutas, mensajes y comentarios: en
español. La única excepción son las palabras del lenguaje y de los paquetes.

Y los comentarios **explican por qué**, no qué. `// suma uno a i` no aporta;
`// se compone la consulta porque el PATCH escribe solo lo que llegó` sí.

## Artículo 9.1 — La identidad visual es una RESTRICCIÓN, no una preferencia

Los colores y las fuentes del sistema **no los elige quien programa**. Salen
del **Manual de Identidad Visual Corporativa** de la Universidad de San
Buenaventura (Resolución de Rectoría General N.º 404 del 14 de mayo de 2024),
que está en la raíz del repositorio como `Manual-de-Marca.pdf`.

| Qué | Valor | Manual |
|---|---|---|
| Naranja institucional | `#EF7D00` | p. 5 |
| Negro institucional | `#1D1D1B` | p. 5 |
| Fuentes secundarias autorizadas | **Montserrat** y **Raleway** | p. 6 |
| Versión a una tinta | El **negro al 30 %**, no el naranja en gris | p. 6 |
| Tamaño mínimo del logo en pantalla | 93,2 × 28,3 px (horizontal) | p. 7 |
| Área de reserva | La altura del texto del propio logosímbolo | p. 7 |
| Marca de agua (blasón) | Opacidad entre 10 % y 30 % | p. 5 |

El manual es explícito, y hay que leerlo como lo que es:

> «Por ningún motivo se deben cambiar los colores corporativos.»

**Dónde viven esos valores.** En `front_flask/static/marca.css`, en un archivo
**aparte** de `estilos.css`. La separación no es de orden: ahí van **los
valores que fija el manual** y allá va cómo se usan. El día que la Universidad
actualice su manual, se cambia un archivo y nada más.

**El logosímbolo es el archivo OFICIAL**, tomado de
[usbmed.edu.co](https://usbmed.edu.co/): 400 × 100 px con transparencia, con
el logosímbolo horizontal y el sello de Acreditación Institucional. Está en
`front_flask/static/logo-usb.png`.

**Va sobre blanco, y eso no es estético: es la norma.** El logosímbolo del
manual es la versión **positiva** —logotipo en tinta oscura—, así que sobre la
barra negra de la aplicación desaparecería. Por eso la cabecera lleva una
**banda blanca** encima. El manual tiene versión negativa (p. 6), pero no la
tenemos como archivo: usar la positiva sobre su fondo correcto es **cumplir la
norma, no rodearla**.

> **Y queda dicho que la primera versión de este artículo se equivocó:** decía
> que no había archivo de logo porque solo se podían extraer fotos de campus.
> Era falso — el logosímbolo estaba en el PDF, y hay una versión mejor en el
> sitio oficial. Ver [`D-v1-7`](versiones/v1_sede/4_research.md), donde el
> error está documentado con lo que enseña.

**En qué versión se evalúa.** El manual se aplica **desde la v1** —era una
mejora, y las mejoras no esperan— pero *«la imagen corporativa completa»* es
criterio de la **v4**, porque ahí la pone el curso
(`ProyectosDeAula` → `0_METODOLOGIA.md` §2), junto con el tablero y la
publicación. Ver la nota de
[`versiones/v1_sede/2_spec.md` §6.1](versiones/v1_sede/2_spec.md).

## Artículo 10 — Contratos exactos

Lo que dice `6_contracts.md` se cumple **al pie de la letra**: los códigos de
estado, los nombres de los campos y la forma del sobre.

Si el sistema responde algo distinto de lo que dice el documento, **se corrige
el documento** — porque el documento se escribe contra lo que el sistema
responde, verificado, no contra lo que uno esperaba.

## Artículo 11 — Convenciones fijas

| Qué | Cómo |
|---|---|
| Nombres en el JSON | **camelCase** (`idSede`, `esVirtual`): es el comportamiento por defecto de ASP.NET, así que no hay nada que configurar ni que se pueda configurar mal |
| La ruta | Nombra la tabla: `/api/sede` |
| Puertos del proyecto | API **8037** · front **8038** · PostgreSQL **15461** |
| Nombres de contenedor | Llevan el prefijo `catedras-`: los nombres, **como los puertos**, no se repiten entre proyectos del semestre — Docker los exige únicos en toda la máquina |
| El sobre de lectura | `{tabla, limite, total, datos[]}` |
| El sobre de error | `{estado, mensaje, detalle}` o `{estado, mensaje, errores[]}` |

## Artículo 12 — Cómo se enmienda esta constitución

1. Se propone el cambio por escrito, con su razón.
2. Se dice **qué versiones ya cerradas quedan afectadas**.
3. Se sube el número de versión de la constitución.
4. La enmienda queda registrada aquí.

**Ninguna enmienda es retroactiva**: una versión cerrada se cerró bajo las
reglas que había.
