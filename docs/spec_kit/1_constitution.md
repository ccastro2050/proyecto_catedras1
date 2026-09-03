# Constitución del proyecto — Cátedras Abiertas

> Las reglas **permanentes**. No cambian entre versiones: si una versión
> necesita cambiar una de estas reglas, eso no es una tarea — es una enmienda,
> y se discute aparte (Artículo 11).
>
> **Versión de esta constitución: 1.0.0**

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
