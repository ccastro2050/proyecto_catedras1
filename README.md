# Cátedras Abiertas — ejemplo de referencia

Sistema de registro y control de asistencia a cátedras abiertas de la
Universidad de San Buenaventura, Medellín.

Este repositorio contiene **dos cosas distintas**, y conviene no confundirlas:

| | Qué es |
|---|---|
| [`material_dado/`](material_dado/) | **Lo que entregó el equipo del proyecto**: el modelo entidad-relación, sus diagramas, el script original de la base y los planes |
| Todo lo demás | **El ejemplo de referencia**: la versión 1, construida siguiendo la metodología del curso al pie de la letra |

El ejemplo no es un sistema para descargar: es un **molde de método**. Se
ejecuta, se estudia, y se reconstruye.

---

## ⚠️ Este repositorio NO contiene datos de personas reales

El material original traía siete archivos con **14.808 asistentes** —nombre,
apellido y correo institucional— y **15.517 números de documento de
identidad**.

**Ese bloque se quitó.** Publicar la identidad de quince mil personas en un
repositorio público es un problema de protección de datos, y ninguna necesidad
didáctica lo justifica: para aprender el método no hacen falta personas
reales.

En su lugar hay **cinco registros evidentemente inventados**. Lo que se quitó
son **los datos, no el mecanismo**: las tablas de paso, el procedimiento de
carga y las tablas de lote y novedad siguen en la base, se pueden leer y se
pueden ejercitar con datos propios.

Está escrito como [Artículo 8](docs/spec_kit/1_constitution.md) de la
constitución, en la cabecera de [`db/init.sql`](db/init.sql), y como decisión
[D3](docs/spec_kit/versiones/v1_sede/4_research.md) — porque esta es la clase de cosa que no se deja a la
memoria de nadie.

---

## 1. Arranque: un solo comando

Solo hace falta **Docker Desktop**. No hay que instalar .NET, ni Python, ni
PostgreSQL.

```powershell
git clone https://github.com/ccastro2050/proyecto_catedras1.git
cd proyecto_catedras1
docker compose up -d --build
```

**La primera vez tarda**, y por dos motivos: .NET restaura sus paquetes, y el
script crea 37 tablas con sus rutinas y disparadores — y los ejercita. Si
parece colgado, no lo está.

| Qué | Dónde |
|---|---|
| **EL FRONT** (lo que ve el usuario) | http://localhost:8038 |
| La API — documentación interactiva | http://localhost:8037/swagger |
| La API — diagnóstico | http://localhost:8037/ |
| PostgreSQL (DBeaver o pgAdmin, opcional) | `localhost:15461` · usuario `catedras` |

### Los días siguientes

```powershell
docker compose up -d          # encender
docker compose down           # apagar (los datos se conservan)
docker compose down -v        # resetear la base a su estado original
```

Si edita un `.cs` o un `.py`, **no hay que hacer nada**: el código está montado
y los dos servicios recargan solos.

## 2. Lo primero que hay que entender de este ejemplo

```
FRONT (Flask, Python) ──HTTP──> API (C#, .NET) ──SQL──> PostgreSQL
```

**El front está en Python y la API en C#. No es un descuido: es la lección.**

Todo el curso repite que las capas están separadas y que el front solo habla
por HTTP. Con front y API en el mismo lenguaje eso hay que creerlo — siempre
queda la duda de si en algún punto se comparte una clase o un modelo. **Con
dos lenguajes distintos, compartir algo es imposible**, y la afirmación pasa
de promesa a hecho verificable.

Y se verifica así:

```powershell
docker compose stop api-catedras
```

La pantalla http://localhost:8038/sedes **sigue cargando** —cabecera, estilos,
pie— y dice *"El servicio no está disponible"*, **sin una sola sede**. Si el
front pudiera llegar a PostgreSQL por su cuenta, seguiría mostrando datos.

## 3. Qué construye la versión 1

El CRUD completo de **`sede`** de punta a punta: controlador, servicio,
repositorio, interfaces, peticiones por verbo, una prueba que corre **sin base
de datos**, y sus pantallas.

`sede` no es la tabla más grande de las 37: es la que **enseña más por fila**.
En cinco campos tiene un **campo opcional** (la sede virtual no tiene
dirección), un **booleano** nativo del motor, y **dos** restricciones de
unicidad distintas —la llave primaria y el nombre— que dan **dos 500 por
motivos diferentes**.

**La v1 del modelo pide once tablas sin clave foránea.** Este repositorio
construye **una sola, completa**: es el molde. Las otras diez son el mismo
patrón con otros nombres. El equipo que tome este ejemplo lo revisa y, **si
está de acuerdo, lo retoma y lo completa; si no, lo rehace a su manera**. Lo
que no puede es cambiar la especificación sin pasar por sus compuertas.

## 4. Estructura

```
proyecto_catedras1/
├── db/init.sql                  la base COMPLETA (37 tablas, artefacto DADO)
├── api_catedras/                LA API — C# / ASP.NET Core
│   ├── Program.cs               el ensamblador y la fábrica del 422
│   ├── Controllers/             CAPA 1: HTTP — códigos de estado y JSON
│   ├── Peticiones/              la frontera: valida el cuerpo → 422
│   ├── Modelos/                 la entidad, lo que viaja entre capas
│   ├── Servicios/               CAPA 2: negocio — no conoce HTTP ni el motor
│   ├── Repositorios/            CAPA 3: datos — el SQL con Dapper
│   ├── Excepciones/             cómo el negocio avisa un 404 sin hablar de HTTP
│   └── pruebas/                 el servicio con un repositorio de mentiras
├── front_flask/                 EL FRONT — Python / Flask
│   ├── app.py                   las vistas
│   ├── cliente_api.py           el ÚNICO que habla HTTP
│   └── templates/ static/
├── docs/spec_kit/               LA FUENTE DE VERDAD (ver abajo)
├── postman/                     los endpoints listos para probar con clics
├── docker-compose.yml           TODO el sistema declarado en un archivo
└── material_dado/               el modelo y el script originales
```

## 5. Las especificaciones

| Documento | Contenido |
|---|---|
| [PLAN_V1.md](PLAN_V1.md) | **El plan con el que se construyó esta versión**: los hallazgos, las decisiones y los pasos |
| [1_constitution.md](docs/spec_kit/1_constitution.md) | Las 12 reglas permanentes — **incluido el Artículo 8, sobre datos personales** |
| [0_mapa_versiones.md](docs/spec_kit/versiones/0_mapa_versiones.md) | La ruta v1 → v4 y qué tablas entran en cada versión |
| [2_spec.md](docs/spec_kit/versiones/v1_sede/2_spec.md) | QUÉ construir, los 9 criterios y las **Clarificaciones** |
| [3_plan.md](docs/spec_kit/versiones/v1_sede/3_plan.md) | CÓMO: el stack, las capas y el **chequeo de constitución** |
| [4_research.md](docs/spec_kit/versiones/v1_sede/4_research.md) | Las decisiones con la alternativa que se descartó |
| [5_data_model.md](docs/spec_kit/versiones/v1_sede/5_data_model.md) | La tabla, sus datos y quién no puede escribir qué |
| [6_contracts.md](docs/spec_kit/versiones/v1_sede/6_contracts.md) | Los endpoints y las pantallas, con TODOS sus códigos |
| [7_quickstart.md](docs/spec_kit/versiones/v1_sede/7_quickstart.md) | El smoke test, comando por comando |
| [8_tasks.md](docs/spec_kit/versiones/v1_sede/8_tasks.md) | Las 10 fases, cada una con su verificación |
| [9_checklist.md](docs/spec_kit/versiones/v1_sede/9_checklist.md) | **La compuerta 3**: se firma ANTES de programar |
| [GUIA_IA1.md](docs/spec_kit/versiones/v1_sede/GUIA_IA1.md) | Reconstruir la versión con IA, con el prompt listo |

## 6. Lo que hay que mirar del código

| Si quiere entender… | Abra |
|---|---|
| Por qué el 422 **no sale solo** | `api_catedras/Program.cs`, la fábrica de respuestas |
| Por qué PUT y PATCH se comportan distinto | las **tres** clases de `Peticiones/`: la diferencia es el tipo, no un `if` |
| Dónde está el SQL, y las tres diferencias con SQL Server | `api_catedras/Repositorios/RepositorioSedePostgreSql.cs` |
| Por qué el servicio no sabe qué es un 404 | `api_catedras/Servicios/ServicioSede.cs` |
| Que las capas son de verdad | `api_catedras/pruebas/PruebaCapas.csproj` — **no referencia Npgsql ni Dapper** |
| Que el front no sabe en qué lenguaje está la API | `front_flask/cliente_api.py` — no lo menciona ni una vez |
