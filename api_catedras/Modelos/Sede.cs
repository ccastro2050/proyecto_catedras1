namespace ApiCatedras.Modelos;

/// <summary>
/// Entidad de dominio que representa la tabla sede: un campus donde se dicta
/// una sesión de cátedra. Es lo que viaja entre las capas.
///
/// No incluye Activo: el borrado lógico es un detalle interno del motor y no
/// forma parte de lo que la API expone (5_data_model.md §4).
/// </summary>
public class Sede
{
    /// <summary>El código de la sede. Es la llave, y es TEXTO: los datos del
    /// proyecto son códigos como 'SAN_BENITO', no números.</summary>
    public string IdSede { get; set; } = string.Empty;

    /// <summary>El nombre. La base exige que sea ÚNICO (uq_sede_nombre): dos
    /// sedes con el mismo nombre responden 500, y esa defensa es de la base,
    /// no de la API.</summary>
    public string Nombre { get; set; } = string.Empty;

    /// <summary>El ÚNICO campo que admite nulos: la sede virtual no tiene
    /// dirección física.</summary>
    public string? Direccion { get; set; }

    /// <summary>Si es virtual. Un BOOLEANO de verdad, no un 0/1 de texto:
    /// PostgreSQL tiene el tipo, y en el JSON sale como true/false.</summary>
    public bool EsVirtual { get; set; }
}
