using System.ComponentModel.DataAnnotations;

namespace ApiCatedras.Peticiones;

/// <summary>
/// El cuerpo del PUT. Reemplazar es poner TODO de nuevo, así que los dos
/// obligatorios lo siguen siendo. El idSede no va aquí: identifica la fila y
/// viaja en la ruta.
/// </summary>
public class SedeReemplazo
{
    [Required(ErrorMessage = "El campo nombre es obligatorio.")]
    [MaxLength(80, ErrorMessage = "El campo nombre no puede exceder los 80 caracteres.")]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(200, ErrorMessage = "El campo direccion no puede exceder los 200 caracteres.")]
    public string? Direccion { get; set; }

    [Required(ErrorMessage = "El campo esVirtual es obligatorio.")]
    public bool? EsVirtual { get; set; }
}
