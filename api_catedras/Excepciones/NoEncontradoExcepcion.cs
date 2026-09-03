namespace ApiCatedras.Excepciones;

/// <summary>
/// La forma que tiene el negocio de decir "eso no existe" SIN hablar de HTTP.
///
/// El servicio la lanza; el controlador la traduce a 404. Si el servicio
/// devolviera un 404 directamente, quedaría atado a la web y no se podría usar
/// desde otro sitio — ni probar sin un servidor.
/// </summary>
public class NoEncontradoExcepcion : Exception
{
    public NoEncontradoExcepcion(string mensaje) : base(mensaje) { }
}
