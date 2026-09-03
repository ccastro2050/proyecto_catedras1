namespace ApiCatedras.Peticiones;

/// <summary>
/// El cuerpo del PATCH: TODOS los campos son opcionales, y solo se escriben
/// los que lleguen.
///
/// La diferencia con SedeReemplazo es la lección del contrato: el MISMO cuerpo
/// responde 422 en PUT y 200 en PATCH, y no lo decide un if en el servicio —
/// lo decide el tipo.
/// </summary>
public class SedeActualizar
{
    public string? Nombre { get; set; }
    public string? Direccion { get; set; }
    public bool? EsVirtual { get; set; }
}
