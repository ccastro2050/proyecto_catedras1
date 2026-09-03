# Guía de IA — Versión 1: construirla con ayuda de una IA

> **Versión 1** ([mapa](../0_mapa_versiones.md)) · Rige la
> [constitución](../../1_constitution.md).
>
> | Documento | Contenido |
> |---|---|
> | [2_spec.md](2_spec.md) | QUÉ construir y los criterios de aceptación |
> | [3_plan.md](3_plan.md) | CÓMO: el stack, las capas y sus decisiones |
> | [4_research.md](4_research.md) | Las decisiones, con lo que se descartó |
> | [5_data_model.md](5_data_model.md) | La tabla, sus datos y quién escribe qué |
> | [6_contracts.md](6_contracts.md) | Los endpoints y las pantallas |
> | [7_quickstart.md](7_quickstart.md) | Arranque y smoke test |
> | [8_tasks.md](8_tasks.md) | El orden de construcción por fases |
> | [9_checklist.md](9_checklist.md) | La compuerta 3: se firma ANTES de programar |
> | [GUIA_IA1.md](GUIA_IA1.md) | Construirla con ayuda de una IA |

---

## 1. Antes de abrir el chat

La IA no adivina el contexto: hay que dárselo. Tenga a mano

- La [constitución](../../1_constitution.md).
- Los documentos de **esta** carpeta (2 a 8).
- `db/init.sql` y el `docker-compose.yml`.
- Del material dado: `material_dado/SOLUCION/MER/07-Entidades-del-Proyecto.md`.

**Lo más importante:** la IA **no puede ver su sistema**. Si no le dice que el
motor es PostgreSQL, que el front va en Flask y que **el material original
traía datos personales que no se publican**, va a suponer lo más común — y lo
más común aquí está mal.

## 2. El prompt

Péguelo con los documentos adjuntos. Sirve igual en un chat o en un agente; si
es un agente que puede escribir archivos, agregue la línea final.

```text
Actúa como desarrollador del proyecto adjunto. Vamos a construir la VERSIÓN 1:
el CRUD de la tabla `sede` de punta a punta.

CONTEXTO QUE NO PUEDES DEDUCIR Y NO DEBES INVENTAR:

- La API va en C# / ASP.NET Core .NET 10, con Dapper. NO uses Entity Framework
  ni ningún ORM: el SQL se escribe a mano y va parametrizado con @parametro.
- El motor es PostgreSQL, NO SQL Server. El proveedor es Npgsql, no
  Microsoft.Data.SqlClient. Eso cambia tres cosas y solo tres:
    * NpgsqlConnection en vez de SqlConnection
    * LIMIT @Limite al FINAL, no TOP (@Limite) al principio
    * activo = TRUE, no activo = 1 (PostgreSQL tiene booleanos de verdad)
- EL FRONT VA EN PYTHON CON FLASK, mientras la API es de C#. No es un error
  del enunciado: es deliberado. Lo único que los une es un contrato HTTP, y si
  el front tuviera que estar en C# para funcionar, el acoplamiento estaría en
  algún sitio. No "unifiques" el stack.
- La base viene DADA: 37 tablas, 6 vistas, 22 rutinas y 7 disparadores, en
  db/init.sql. NO la modifiques, no le agregues columnas y no le quites
  restricciones. La tabla `sede` YA tiene la columna activo: no hay que
  agregarla.
- EL REPOSITORIO NO LLEVA DATOS DE PERSONAS REALES. El material original traía
  siete CSV con 14.808 asistentes identificados y 15.517 números de documento;
  ese bloque se quitó y se reemplazó por cinco registros inventados. Si en
  algún momento te parece útil cargar esos archivos, la respuesta es no.

LA TABLA sede: id_sede varchar(15) PK · nombre varchar(80) NOT NULL y UNIQUE ·
direccion varchar(200) NULL · es_virtual boolean · activo boolean.

DOS COSAS QUE HAY QUE RESPETAR DEL CONTRATO:

1. El 422 NO SALE SOLO. Con [ApiController], un cuerpo inválido responde 400
   con ProblemDetails. El contrato exige 422 con {estado, mensaje, errores[]}:
   hay que reemplazar InvalidModelStateResponseFactory en Program.cs.
2. El nombre repetido NO se valida en la API: lo defiende la base con
   uq_sede_nombre y responde 500. No agregues una consulta previa para
   devolver un 409 "más amable": entre esa consulta y el INSERT cabe otra
   petición, y la restricción se violaría igual.

ARQUITECTURA (Artículo 3):
- Tres capas con interfaces: Controller -> IServicio -> IRepositorio.
- El servicio NO conoce HTTP: comunica con ArgumentException (400) y
  NoEncontradoExcepcion (404). Nunca devuelve códigos de estado.
- El repositorio es la ÚNICA clase que sabe cuál es el motor.
- La carpeta pruebas/ tiene su PROPIO .csproj y NO referencia Npgsql ni
  Dapper. Si para probar el negocio hiciera falta el paquete del motor, la
  separación de capas no sería real.

EN EL FRONT:
- cliente_api.py es el ÚNICO que habla HTTP. Ninguna vista usa requests
  directamente.
- El sobre de error de esta API es PLANO: {estado, mensaje, errores[]} o
  {estado, mensaje, detalle}. NO viene anidado bajo "detail" — eso es de otro
  framework.
- La dirección en blanco se envía como NULO, no como cadena vacía: '' y "no lo
  tiene" no son lo mismo, y la base los guarda distinto.
- La pantalla de edición tiene UN formulario con DOS botones submit
  (name="verbo", value="put" y value="patch"). Esa pareja es la lección.
- Eliminar va por POST con confirmación, nunca por un enlace GET.
- TODO en español: rutas, plantillas, avisos, comentarios y nombres.

CRITERIO QUE DEBE PODER CUMPLIRSE: al apagar la API con
`docker compose stop api-catedras`, la pantalla /sedes debe seguir CARGANDO
—con su cabecera y sus estilos— y mostrar el aviso "el servicio no está
disponible", SIN datos. Si tu diseño no puede cumplir esto, está mal.

Empieza por la Fase 1 de 8_tasks.md. Al terminar cada fase, PARA y dime cómo
verificarla. No pases a la siguiente sin que yo confirme.
```

> **Última línea, solo si es un agente con permiso de escribir:**
> `Escribe los archivos en api_catedras/ y front_flask/. NO toques db/init.sql
> ni nada dentro de material_dado/.`

## 3. Qué revisar de lo que entregue

| Revise | Por qué |
|---|---|
| ¿Usó Entity Framework? | El Artículo 2 lo prohíbe: el SQL se ve |
| ¿`SqlConnection` o `TOP`? | Se equivocó de motor: aquí es PostgreSQL |
| ¿`activo = 1`? | Calcó otro dialecto: aquí es `TRUE` |
| ¿Escribió el front en C#? | Se saltó la decisión central (ver [D1](4_research.md)) |
| ¿Dejó el 422 por defecto? | Va a responder 400 con ProblemDetails |
| ¿Validó el nombre único en la API? | Le dio dos dueños a la misma regla, y no funciona |
| ¿`pruebas/` referencia Npgsql? | Entonces la prueba no prueba nada |
| ¿El servicio devuelve `NotFound()`? | La capa 2 no habla HTTP |
| ¿Envía `direccion: ""`? | Vacío y ausente no son lo mismo |
| ¿Alguna vista usa `requests`? | Se saltó `cliente_api` |
| **¿Cargó los CSV del material original?** | **Datos personales: el Artículo 8** |

## 4. Los tres destinos de un error

Cuando algo salga mal, la corrección va a **uno** de tres lugares, y elegir
bien es lo que hace que la próxima vez salga mejor:

| Si… | La corrección va a |
|---|---|
| La IA no podía saberlo (el motor, el front en otro lenguaje, los datos personales) | **La especificación** |
| La spec lo dice, pero la IA se equivoca **siempre** en lo mismo | **El prompt** |
| Falló una vez y al señalarlo lo arregló | **El estudiante**: se corrige y sigue |

Confundirlos sale caro: engordar el prompt con cosas que fallaron una sola vez
lo vuelve ilegible, y parchar a mano lo que la spec no dice condena a repetir
el error en la versión siguiente.

> **Cuatro ejemplos de esta versión, que pasaron de verdad** — y los cuatro
> fueron a la especificación, porque ninguno se podía adivinar:
>
> 1. El `id_evento_asis` de los datos inventados no pasaba: son **exactamente
>    9 dígitos**, lo exige `chk_catedra_asis`.
> 2. **Todo asistente necesita al menos un correo**, y la visitante externa se
>    había quedado sin ninguno.
> 3. Ese `CHECK` **se comprueba al insertar**, así que "arreglarlo" con un
>    `UPDATE` posterior no servía: la fila nunca llegó a entrar.
> 4. **Sin vinculación vigente no se puede registrar asistencia**: lo exige
>    una rutina de la base.
>
> Ninguna de las cuatro estaba en un documento: **las dijo el esquema al
> rechazar los datos**. Por eso ahora están escritas en
> [5_data_model §4](5_data_model.md).
