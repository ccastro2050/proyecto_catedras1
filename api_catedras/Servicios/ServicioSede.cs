using ApiCatedras.Excepciones;
using ApiCatedras.Modelos;
using ApiCatedras.Repositorios;

namespace ApiCatedras.Servicios;

/// <summary>
/// La capa 2: las reglas de negocio. Depende solo de la interfaz del
/// repositorio, así que no sabe qué motor hay detrás (Artículo 3) — y por eso
/// se puede probar sin base de datos.
/// </summary>
public class ServicioSede : IServicioSede
{
    private readonly IRepositorioSede _repositorio;

    public ServicioSede(IRepositorioSede repositorio)
    {
        _repositorio = repositorio;
    }

    private static string ValidarCodigo(string idSede)
    {
        idSede = (idSede ?? string.Empty).Trim();
        if (idSede.Length == 0)
        {
            throw new ArgumentException("El código de la sede no puede estar vacío.");
        }
        return idSede;
    }

    public async Task<IEnumerable<Sede>> ObtenerTodos(int limite)
    {
        // La FORMA del dato es correcta (sí es un entero), así que esto es 400
        // y no 422.
        if (limite <= 0)
        {
            throw new ArgumentException("El parámetro limite debe ser un número mayor a 0.");
        }

        return await _repositorio.ObtenerTodos(limite);
    }

    public async Task<Sede> ObtenerPorId(string idSede)
    {
        idSede = ValidarCodigo(idSede);
        var sede = await _repositorio.ObtenerPorId(idSede);
        if (sede == null)
        {
            throw new NoEncontradoExcepcion($"No existe una sede con el código {idSede}.");
        }

        return sede;
    }

    public async Task Crear(Sede sede)
    {
        await _repositorio.Crear(sede);
    }

    public async Task<int> Reemplazar(string idSede, Sede sede)
    {
        // El código identifica la fila y viene de la ruta, no del cuerpo
        sede.IdSede = ValidarCodigo(idSede);

        var filasAfectadas = await _repositorio.Reemplazar(sede);
        if (filasAfectadas == 0)
        {
            throw new NoEncontradoExcepcion($"No existe una sede con el código {idSede}.");
        }

        return filasAfectadas;
    }

    public async Task<int> ActualizarParcial(string idSede, SedeCampos campos)
    {
        idSede = ValidarCodigo(idSede);

        // Sin esta comprobación el repositorio devolvería 0 filas, que en toda
        // la demás lógica significa "no existe" — y responderíamos 404 en vez
        // del 400 que exige el contrato para un cuerpo vacío.
        if (!campos.HayAlguno)
        {
            throw new ArgumentException("No se envió ningún campo para actualizar.");
        }

        var filasAfectadas = await _repositorio.ActualizarParcial(idSede, campos);
        if (filasAfectadas == 0)
        {
            throw new NoEncontradoExcepcion($"No existe una sede con el código {idSede}.");
        }

        return filasAfectadas;
    }

    public async Task<int> Eliminar(string idSede)
    {
        idSede = ValidarCodigo(idSede);
        var filasAfectadas = await _repositorio.EliminarLogico(idSede);
        if (filasAfectadas == 0)
        {
            throw new NoEncontradoExcepcion($"No existe una sede con el código {idSede}.");
        }

        return filasAfectadas;
    }
}
