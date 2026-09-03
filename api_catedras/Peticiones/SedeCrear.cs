using System.ComponentModel.DataAnnotations;

namespace ApiCatedras.Peticiones;

/// <summary>
/// El cuerpo del POST. Tres campos obligatorios y uno opcional: direccion, que
/// la sede virtual no tiene. Si falta un obligatorio, el framework responde
/// 422 antes de que el negocio se entere (3_plan.md).
/// </summary>
public class SedeCrear
{
    [Required(ErrorMessage = "El campo idSede es obligatorio.")]
    [MaxLength(15, ErrorMessage = "El campo idSede no puede exceder los 15 caracteres.")]
    public string IdSede { get; set; } = string.Empty;

    [Required(ErrorMessage = "El campo nombre es obligatorio.")]
    [MaxLength(80, ErrorMessage = "El campo nombre no puede exceder los 80 caracteres.")]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>El único opcional: la sede virtual no tiene dirección.</summary>
    [MaxLength(200, ErrorMessage = "El campo direccion no puede exceder los 200 caracteres.")]
    public string? Direccion { get; set; }

    /// <summary>Un booleano, no una cadena: si llega "quizas", es 422.</summary>
    [Required(ErrorMessage = "El campo esVirtual es obligatorio.")]
    public bool? EsVirtual { get; set; }
}
