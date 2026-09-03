using ApiCatedras.Modelos;

namespace ApiCatedras.Repositorios;

/// <summary>
/// El contrato de la capa de datos. El servicio conoce ESTA interfaz y nada
/// más: no sabe que detrás hay PostgreSQL, y por eso se le puede enchufar un
/// repositorio de mentiras para probarlo sin base de datos (Artículo 3).
/// </summary>
public interface IRepositorioSede
{
    Task<IEnumerable<Sede>> ObtenerTodos(int limite);
    Task<Sede?> ObtenerPorId(string idSede);
    Task Crear(Sede sede);
    Task<int> Reemplazar(Sede sede);
    Task<int> ActualizarParcial(string idSede, SedeCampos campos);
    Task<int> EliminarLogico(string idSede);
}

/// <summary>
/// Los campos que un PATCH puede traer, todos opcionales.
///
/// Este tipo los agrupa SIN que la capa 2 ni la 3 conozcan las clases de
/// Peticiones/, que son la frontera HTTP.
/// </summary>
public record SedeCampos(
    string? Nombre = null,
    string? Direccion = null,
    bool? EsVirtual = null)
{
    /// <summary>¿Llegó algún campo? Si no, el PATCH es un 400 y no un 404.</summary>
    public bool HayAlguno => Nombre != null || Direccion != null || EsVirtual != null;
}
