using System.Data;
using ApiCatedras.Modelos;
using Dapper;
using Npgsql;

namespace ApiCatedras.Repositorios;

/// <summary>
/// La capa 3 contra PostgreSQL, con Dapper (Artículo 2): el SQL se escribe a
/// mano, queda a la vista y SIEMPRE va parametrizado (@parametro).
///
/// Todas las consultas filtran por activo = TRUE: el borrado es lógico
/// (Artículo 6).
///
/// **Esta clase es la ÚNICA del proyecto que sabe que el motor es PostgreSQL.**
/// Los otros ejemplos del curso tienen su gemela contra SQL Server, y las
/// diferencias son tres, todas aquí:
///
///   1. `NpgsqlConnection` en vez de `SqlConnection`.
///   2. `LIMIT @Limite` al final, no `TOP (@Limite)` al principio.
///   3. `activo = TRUE` en vez de `activo = 1`: PostgreSQL tiene booleanos
///      de verdad, y usar 1 sería calcar el dialecto de otro motor.
///
/// Que la lista de diferencias sea corta y quepa en un comentario **es el
/// resultado de haber puesto las interfaces**: si el servicio conociera esta
/// clase, cambiar de motor tocaría medio proyecto.
/// </summary>
public class RepositorioSedePostgreSql : IRepositorioSede
{
    private readonly string _cadenaConexion;

    public RepositorioSedePostgreSql(IConfiguration configuracion)
    {
        _cadenaConexion = configuracion.GetConnectionString("PostgreSql")
            ?? throw new InvalidOperationException(
                "No se encontró la cadena de conexión 'PostgreSql'.");
    }

    private IDbConnection CrearConexion() => new NpgsqlConnection(_cadenaConexion);

    // Los alias traducen los nombres de la tabla (snake_case) a los de la
    // entidad (PascalCase): Dapper mapea por nombre.
    private const string COLUMNAS =
        @"id_sede AS IdSede, nombre AS Nombre, direccion AS Direccion,
          es_virtual AS EsVirtual";

    public async Task<IEnumerable<Sede>> ObtenerTodos(int limite)
    {
        using var conexion = CrearConexion();
        var sql = $@"
            SELECT {COLUMNAS}
            FROM sede
            WHERE activo = TRUE
            ORDER BY id_sede ASC
            LIMIT @Limite";

        return await conexion.QueryAsync<Sede>(sql, new { Limite = limite });
    }

    public async Task<Sede?> ObtenerPorId(string idSede)
    {
        using var conexion = CrearConexion();
        // Una sede inactiva responde como inexistente.
        var sql = $@"
            SELECT {COLUMNAS}
            FROM sede
            WHERE id_sede = @IdSede AND activo = TRUE";

        return await conexion.QueryFirstOrDefaultAsync<Sede>(sql, new { IdSede = idSede });
    }

    public async Task Crear(Sede sede)
    {
        using var conexion = CrearConexion();
        const string sql = @"
            INSERT INTO sede (id_sede, nombre, direccion, es_virtual, activo)
            VALUES (@IdSede, @Nombre, @Direccion, @EsVirtual, TRUE)";

        await conexion.ExecuteAsync(sql, sede);
    }

    public async Task<int> Reemplazar(Sede sede)
    {
        using var conexion = CrearConexion();
        const string sql = @"
            UPDATE sede
            SET nombre = @Nombre, direccion = @Direccion, es_virtual = @EsVirtual
            WHERE id_sede = @IdSede AND activo = TRUE";

        return await conexion.ExecuteAsync(sql, sede);
    }

    public async Task<int> ActualizarParcial(string idSede, SedeCampos campos)
    {
        using var conexion = CrearConexion();

        // El PATCH escribe solo lo que llegó, así que la consulta se compone.
        // OJO: lo que se compone son NOMBRES DE COLUMNA de una lista cerrada,
        // escrita aquí; los VALORES siempre viajan como @parametro.
        var asignaciones = new List<string>();
        var parametros = new DynamicParameters();
        parametros.Add("IdSede", idSede);

        void Agregar(string columna, string parametro, object? valor)
        {
            if (valor == null) return;
            asignaciones.Add($"{columna} = @{parametro}");
            parametros.Add(parametro, valor);
        }

        Agregar("nombre", "Nombre", campos.Nombre);
        Agregar("direccion", "Direccion", campos.Direccion);
        Agregar("es_virtual", "EsVirtual", campos.EsVirtual);

        if (asignaciones.Count == 0) return 0;

        var sql = $@"UPDATE sede SET {string.Join(", ", asignaciones)}
                     WHERE id_sede = @IdSede AND activo = TRUE";

        return await conexion.ExecuteAsync(sql, parametros);
    }

    public async Task<int> EliminarLogico(string idSede)
    {
        using var conexion = CrearConexion();
        // Borrado LÓGICO en una sola consulta: cero filas afectadas significa
        // "no existe o ya estaba inactiva", que es el 404 del contrato.
        const string sql = @"
            UPDATE sede
            SET activo = FALSE
            WHERE id_sede = @IdSede AND activo = TRUE";

        return await conexion.ExecuteAsync(sql, new { IdSede = idSede });
    }
}
