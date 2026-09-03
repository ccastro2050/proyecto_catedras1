using ApiCatedras.Excepciones;
using ApiCatedras.Modelos;
using ApiCatedras.Peticiones;
using ApiCatedras.Repositorios;
using ApiCatedras.Servicios;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

namespace ApiCatedras.Controllers;

/// <summary>
/// La capa 1: HTTP y nada más. Traduce la petición a una llamada al servicio,
/// y lo que pase de vuelta a un código de estado.
///
///   ArgumentException      → 400   (la forma es válida, la regla no se cumple)
///   NoEncontradoExcepcion  → 404
///   NpgsqlException        → 500   (aquí cae la llave duplicada)
///
/// El 422 no aparece en este archivo: lo produce el framework ANTES de entrar,
/// con la fábrica que se reemplazó en Program.cs.
/// </summary>
[ApiController]
[Route("api/sede")]
public class SedeController : ControllerBase
{
    private readonly IServicioSede _servicio;

    public SedeController(IServicioSede servicio)
    {
        _servicio = servicio;
    }

    /// <summary>RF1 — Listar sedes activas.</summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodos([FromQuery] int limite = 1000)
    {
        try
        {
            var sedes = (await _servicio.ObtenerTodos(limite)).ToList();

            // 204: éxito SIN contenido — "tabla vacía" no es un error.
            if (sedes.Count == 0) return NoContent();

            return Ok(new { tabla = "sede", limite, total = sedes.Count, datos = sedes });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { estado = 400, mensaje = "Parámetros inválidos.", detalle = ex.Message });
        }
        catch (NpgsqlException ex)
        {
            return StatusCode(500, new { estado = 500, mensaje = "Error al consultar las sedes.", detalle = ex.Message });
        }
    }

    /// <summary>RF2 — Obtener una sede por su código.</summary>
    [HttpGet("{idSede}")]
    public async Task<IActionResult> ObtenerPorId(string idSede)
    {
        try
        {
            return Ok(await _servicio.ObtenerPorId(idSede));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { estado = 400, mensaje = "Parámetros inválidos.", detalle = ex.Message });
        }
        catch (NoEncontradoExcepcion ex)
        {
            return NotFound(new { estado = 404, mensaje = "Sede no encontrada.", detalle = ex.Message });
        }
        catch (NpgsqlException ex)
        {
            return StatusCode(500, new { estado = 500, mensaje = "Error al consultar la sede.", detalle = ex.Message });
        }
    }

    /// <summary>RF3 — Crear una sede.</summary>
    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] SedeCrear peticion)
    {
        try
        {
            // El controlador traduce: la capa 2 recibe la entidad, no el cuerpo HTTP
            var sede = new Sede
            {
                IdSede = peticion.IdSede,
                Nombre = peticion.Nombre,
                Direccion = peticion.Direccion,
                EsVirtual = peticion.EsVirtual!.Value
            };

            await _servicio.Crear(sede);
            return Ok(new { estado = 200, mensaje = "Sede creada exitosamente." });
        }
        catch (NpgsqlException ex)
        {
            // Aquí caen DOS defensas de la base, y las dos son suyas, no de la API:
            //   - la llave primaria repetida (pk_sede)
            //   - el nombre repetido (uq_sede_nombre)
            return StatusCode(500, new { estado = 500, mensaje = "No se pudo crear la sede.", detalle = ex.Message });
        }
    }

    /// <summary>RF4 — Reemplazo COMPLETO.</summary>
    [HttpPut("{idSede}")]
    public async Task<IActionResult> Reemplazar(string idSede, [FromBody] SedeReemplazo peticion)
    {
        try
        {
            var sede = new Sede
            {
                Nombre = peticion.Nombre,
                Direccion = peticion.Direccion,
                EsVirtual = peticion.EsVirtual!.Value
            };

            var filas = await _servicio.Reemplazar(idSede, sede);
            return Ok(new { estado = 200, mensaje = "Sede reemplazada.", filasAfectadas = filas });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { estado = 400, mensaje = "Parámetros inválidos.", detalle = ex.Message });
        }
        catch (NoEncontradoExcepcion ex)
        {
            return NotFound(new { estado = 404, mensaje = "Sede no encontrada.", detalle = ex.Message });
        }
        catch (NpgsqlException ex)
        {
            return StatusCode(500, new { estado = 500, mensaje = "No se pudo reemplazar la sede.", detalle = ex.Message });
        }
    }

    /// <summary>RF5 — Actualización PARCIAL.</summary>
    [HttpPatch("{idSede}")]
    public async Task<IActionResult> ActualizarParcial(string idSede, [FromBody] SedeActualizar peticion)
    {
        try
        {
            var campos = new SedeCampos(peticion.Nombre, peticion.Direccion, peticion.EsVirtual);

            var filas = await _servicio.ActualizarParcial(idSede, campos);
            return Ok(new { estado = 200, mensaje = "Sede actualizada.", filasAfectadas = filas });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { estado = 400, mensaje = "Parámetros inválidos.", detalle = ex.Message });
        }
        catch (NoEncontradoExcepcion ex)
        {
            return NotFound(new { estado = 404, mensaje = "Sede no encontrada.", detalle = ex.Message });
        }
        catch (NpgsqlException ex)
        {
            return StatusCode(500, new { estado = 500, mensaje = "No se pudo actualizar la sede.", detalle = ex.Message });
        }
    }

    /// <summary>RF6 — Eliminar (borrado LÓGICO).</summary>
    [HttpDelete("{idSede}")]
    public async Task<IActionResult> Eliminar(string idSede)
    {
        try
        {
            var filas = await _servicio.Eliminar(idSede);
            return Ok(new { estado = 200, mensaje = "Sede eliminada.", filasAfectadas = filas });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { estado = 400, mensaje = "Parámetros inválidos.", detalle = ex.Message });
        }
        catch (NoEncontradoExcepcion ex)
        {
            return NotFound(new { estado = 404, mensaje = "Sede no encontrada.", detalle = ex.Message });
        }
        catch (NpgsqlException ex)
        {
            return StatusCode(500, new { estado = 500, mensaje = "No se pudo eliminar la sede.", detalle = ex.Message });
        }
    }
}
