using ApiCatedras.Modelos;
using ApiCatedras.Repositorios;

namespace ApiCatedras.Servicios;

/// <summary>
/// El contrato de la capa de negocio. Solo conoce Modelos/ y el tipo de campos
/// parciales: las clases de Peticiones/ pertenecen a la frontera HTTP y no
/// cruzan a esta capa.
///
/// Los problemas se comunican con excepciones, que el controlador traduce:
///   ArgumentException      → 400
///   NoEncontradoExcepcion  → 404
/// </summary>
public interface IServicioSede
{
    /// <summary>Hasta 'limite' sedes activas. ArgumentException si limite &lt;= 0.</summary>
    Task<IEnumerable<Sede>> ObtenerTodos(int limite);

    /// <summary>La sede con ese código. NoEncontradoExcepcion si no existe o está inactiva.</summary>
    Task<Sede> ObtenerPorId(string idSede);

    /// <summary>Crea la sede. El cuerpo ya fue validado por SedeCrear.</summary>
    Task Crear(Sede sede);

    /// <summary>Reemplazo completo. NoEncontradoExcepcion si no existe · devuelve filas afectadas.</summary>
    Task<int> Reemplazar(string idSede, Sede sede);

    /// <summary>Escribe solo los campos enviados. ArgumentException si no llegó
    /// ninguno · NoEncontradoExcepcion si no existe · devuelve filas afectadas.</summary>
    Task<int> ActualizarParcial(string idSede, SedeCampos campos);

    /// <summary>Borrado lógico. NoEncontradoExcepcion si no existe o ya estaba inactiva.</summary>
    Task<int> Eliminar(string idSede);
}
