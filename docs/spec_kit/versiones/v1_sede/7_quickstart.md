# Quickstart — Versión 1: arranque y smoke test

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

## 1. Arranque

```powershell
docker compose up -d --build
```

**La primera vez tarda**, y por dos motivos que conviene saber: .NET restaura
sus paquetes, y el script de la base crea 37 tablas con sus rutinas y
disparadores — y los ejercita. Si parece colgado, no lo está.

| Qué | Dónde |
|---|---|
| **EL FRONT** (lo que ve el usuario) | http://localhost:8038 |
| La API — documentación interactiva | http://localhost:8037/swagger |
| La API — diagnóstico | http://localhost:8037/ |
| PostgreSQL (DBeaver o pgAdmin, opcional) | `localhost:15461` · usuario `catedras` |

> **¿La contraseña?** Está en el `docker-compose.yml`, a la vista: es la
> excepción declarada del Artículo 7. **Para correr el sistema no hace falta.**
> En un proyecto real eso va en un `.env` fuera de git.

**Si cambia la contraseña:** `docker compose down -v` y volver a subir. Sin el
`-v`, el usuario sigue con la clave vieja dentro del volumen — y el script no
se vuelve a ejecutar.

## 2. Smoke test — los 9 criterios

### 1 — Un solo comando

```powershell
curl http://localhost:8037/            # → "version":"v1"
curl -i http://localhost:8038/sedes    # → 200
```

### 2 — El catálogo dado se ve

Abra http://localhost:8038/sedes. Deben aparecer **tres** sedes, y la
**Virtual con una raya** en la columna de dirección — porque su dirección es
nula desde el script dado.

```powershell
curl http://localhost:8037/api/sede
#  → total: 3, y la tercera con "direccion": null
```

### 3 — Crear desde el formulario

En el front, **Nueva sede**:

```
código ITAGUI · nombre Campus Itagui · dirección Calle 50 51-20
```

Y compruebe que **la API la tiene** — que es la prueba de que el front no se
la guardó para él:

```powershell
curl http://localhost:8037/api/sede/ITAGUI
```

### 4 — El opcional en blanco queda NULO

Cree otra sede **dejando la dirección vacía** y marcando *es virtual*. Ahora
mire la base, no la API:

```powershell
docker compose exec postgres psql -U catedras -d catedras `
  -c "SELECT id_sede, coalesce(direccion,'<NULO>'), es_virtual FROM sede WHERE id_sede='SUR'"
#  → <NULO>, no una cadena vacía
```

### 5 — La pareja PUT/PATCH, la lección de la versión

En **Editar** de `ITAGUI`, **borre el nombre** y:

1. Oprima **Reemplazar (PUT)** → aviso rojo:
   `El campo nombre es obligatorio.`
2. Sin tocar nada más, oprima **Actualizar lo diligenciado (PATCH)** → guarda
   y vuelve al listado.

**El mismo formulario, dos respuestas.**

### 6 — Los desenlaces de error

```powershell
$H = @{"Content-Type"="application/json"}

# 400 — cuerpo vacío en PATCH
curl -i -X PATCH http://localhost:8037/api/sede/ITAGUI -H $H -d '{}'

# 400 — limite inválido
curl -i "http://localhost:8037/api/sede?limite=0"

# 404 — no existe
curl -i http://localhost:8037/api/sede/NADA

# 500 — el CÓDIGO ya existe (pk_sede)
curl -i -X POST http://localhost:8037/api/sede -H $H `
  -d '{"idSede":"ITAGUI","nombre":"Otro nombre","esVirtual":false}'

# 500 — el NOMBRE ya existe (uq_sede_nombre)
curl -X POST http://localhost:8037/api/sede -H $H `
  -d '{"idSede":"OTRO","nombre":"Campus San Benito","esVirtual":false}'
#  → el detalle nombra uq_sede_nombre
```

**Los dos últimos son 500 por motivos distintos**, y los dos los defiende la
base. Ver [D6](4_research.md).

### 7 — El borrado es LÓGICO

Elimine `ITAGUI` desde el front. Sale del listado. Ahora:

```powershell
curl -i -X DELETE http://localhost:8037/api/sede/ITAGUI    # → 404, ya está inactiva

docker compose exec postgres psql -U catedras -d catedras `
  -c "SELECT id_sede, activo FROM sede WHERE id_sede='ITAGUI'"
#  → ITAGUI | f     ← LA FILA SIGUE AHÍ
```

### 8 — LA PRUEBA DEL PROYECTO

```powershell
docker compose stop api-catedras
```

Recargue http://localhost:8038/sedes. Debe ver:

- La página **carga** — cabecera, estilos, pie.
- Un aviso rojo: *"El servicio no está disponible. ¿Está arriba la API?"*
- **Ni una sola sede.**

> El front está en Python y la API en C#. Si el front pudiera llegar a
> PostgreSQL por su cuenta, seguiría mostrando datos. **Que no los muestre es
> la demostración de que la separación es real**, y no solo una carpeta aparte.

```powershell
docker compose start api-catedras
```

### 9 — Prueba de capas, sin base y sin el paquete del motor

```powershell
docker compose exec api-catedras dotnet run --project pruebas
```

Todas las comprobaciones en `[OK]`. Y lo que hace que esta prueba valga: su
`PruebaCapas/requirements.txt` —perdón, su `.csproj`— **no referencia Npgsql
ni Dapper**. Si hiciera falta el paquete del motor para probar el negocio, la
separación de capas no sería real.

## 3. Regresión

Primera versión: no hay nada anterior que probar. **Desde la v2**, esta sección
conserva los smokes de las versiones cerradas.

## 4. Si algo falla

| Síntoma | Causa probable |
|---|---|
| `password authentication failed` | Se cambió la contraseña sin `docker compose down -v` |
| El listado responde 200 con `total: 0` en vez de 204 | El controlador no devuelve `NoContent()` con la lista vacía |
| La sede virtual muestra una celda vacía en vez de `—` | La plantilla no distingue `null` de `''` |
| Un 422 llega como 400 con `ProblemDetails` | Falta reemplazar `InvalidModelStateResponseFactory` en `Program.cs` |
| Guardar un `.cs` no recompila | Falta `DOTNET_USE_POLLING_FILE_WATCHER=1` |
| `cannot drop the currently open database` al reconstruir | Volvió a entrar el `DROP DATABASE` del script original (C3) |
| El front muestra datos con la API apagada | **Imposible por diseño.** Si pasa, alguien le dio acceso a la base |
