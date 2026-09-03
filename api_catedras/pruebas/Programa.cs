using ApiCatedras.Excepciones;
using ApiCatedras.Modelos;
using ApiCatedras.Repositorios;
using ApiCatedras.Servicios;

namespace PruebaCapas;

/// <summary>
/// Un repositorio que cumple la interfaz pero guarda las filas en una lista.
///
/// No hay base de datos, ni cadena de conexión, ni Npgsql: el proyecto de esta
/// prueba no referencia ninguno de los dos paquetes del motor. Si la prueba
/// pasa así, la separación de capas es REAL y no un dibujo en un documento.
/// </summary>
public class RepositorioDeMentiras : IRepositorioSede
{
    private readonly List<Sede> _filas = new();

    public Task<IEnumerable<Sede>> ObtenerTodos(int limite) =>
        Task.FromResult(_filas.Take(limite).AsEnumerable());

    public Task<Sede?> ObtenerPorId(string idSede) =>
        Task.FromResult(_filas.FirstOrDefault(s => s.IdSede == idSede));

    public Task Crear(Sede sede)
    {
        _filas.Add(sede);
        return Task.CompletedTask;
    }

    public Task<int> Reemplazar(Sede sede)
    {
        var fila = _filas.FirstOrDefault(s => s.IdSede == sede.IdSede);
        if (fila == null) return Task.FromResult(0);
        fila.Nombre = sede.Nombre;
        fila.Direccion = sede.Direccion;
        fila.EsVirtual = sede.EsVirtual;
        return Task.FromResult(1);
    }

    public Task<int> ActualizarParcial(string idSede, SedeCampos campos)
    {
        var fila = _filas.FirstOrDefault(s => s.IdSede == idSede);
        if (fila == null) return Task.FromResult(0);
        if (campos.Nombre != null) fila.Nombre = campos.Nombre;
        if (campos.Direccion != null) fila.Direccion = campos.Direccion;
        if (campos.EsVirtual != null) fila.EsVirtual = campos.EsVirtual.Value;
        return Task.FromResult(1);
    }

    public Task<int> EliminarLogico(string idSede)
    {
        var fila = _filas.FirstOrDefault(s => s.IdSede == idSede);
        if (fila == null) return Task.FromResult(0);
        _filas.Remove(fila);
        return Task.FromResult(1);
    }
}

public static class Programa
{
    private static bool _bien = true;

    private static void Revisar(bool condicion, string ok, string error)
    {
        Console.WriteLine(condicion ? $"[OK] {ok}" : $"[ERROR] {error}");
        if (!condicion) _bien = false;
    }

    public static async Task<int> Main()
    {
        Console.WriteLine("=== Prueba de capas — SIN base de datos ===");
        IServicioSede servicio = new ServicioSede(new RepositorioDeMentiras());

        Revisar(!(await servicio.ObtenerTodos(1000)).Any(),
                "El sistema arranca vacío: sin sedes.",
                "Arrancó con filas que nadie creó.");

        await servicio.Crear(new Sede
        {
            IdSede = "PRUEBA",
            Nombre = "Campus de prueba",
            Direccion = null,
            EsVirtual = true
        });

        var lista = (await servicio.ObtenerTodos(1000)).ToList();
        Revisar(lista.Count == 1 && lista[0].IdSede == "PRUEBA",
                $"Sede creada y listada: {lista[0].Nombre}",
                "La creación no se reflejó en el listado.");

        Revisar(lista[0].Direccion == null,
                "direccion admite nulos: la sede virtual no tiene dirección.",
                "La dirección nula no se conservó.");

        try
        {
            await servicio.ObtenerPorId("NOEXISTE");
            Revisar(false, "", "Un código inexistente NO lanzó NoEncontradoExcepcion.");
        }
        catch (NoEncontradoExcepcion)
        {
            Revisar(true, "Buscar un código inexistente lanza NoEncontradoExcepcion.", "");
        }

        try
        {
            await servicio.ObtenerTodos(0);
            Revisar(false, "", "limite = 0 NO lanzó ArgumentException.");
        }
        catch (ArgumentException)
        {
            Revisar(true, "Límite menor o igual a cero rechazado con ArgumentException.", "");
        }

        try
        {
            await servicio.ActualizarParcial("PRUEBA", new SedeCampos());
            Revisar(false, "", "Un cuerpo vacío NO lanzó ArgumentException.");
        }
        catch (ArgumentException)
        {
            Revisar(true, "Cuerpo vacío en la actualización parcial rechazado.", "");
        }

        await servicio.ActualizarParcial("PRUEBA", new SedeCampos(Nombre: "Campus renombrado"));
        var tras = await servicio.ObtenerPorId("PRUEBA");
        Revisar(tras.Nombre == "Campus renombrado" && tras.EsVirtual,
                "La actualización parcial cambió SOLO el nombre.",
                "La actualización parcial tocó campos que no debía.");

        await servicio.Eliminar("PRUEBA");
        Revisar(!(await servicio.ObtenerTodos(1000)).Any(),
                "Tras el borrado, el sistema vuelve a estar vacío.", "");

        try
        {
            await servicio.Eliminar("PRUEBA");
            Revisar(false, "", "La segunda eliminación NO falló.");
        }
        catch (NoEncontradoExcepcion)
        {
            Revisar(true, "Segunda eliminación rechazada: para la API ya no existe.", "");
        }

        Console.WriteLine(_bien
            ? "=== Prueba de capas completada CON ÉXITO ==="
            : "=== Prueba de capas completada CON ERRORES ===");
        return _bien ? 0 : 1;
    }
}
