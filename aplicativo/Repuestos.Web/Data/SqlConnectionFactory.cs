using System.Data;
using Microsoft.Data.SqlClient;

namespace Repuestos.Web.Data;

public sealed class SqlConnectionFactory(IConfiguration configuration)
{
    public async Task<SqlConnection> AbrirAsync(CancellationToken ct)
    {
        var connectionString = configuration.GetConnectionString("Repuestos");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Falta configurar ConnectionStrings:Repuestos.");
        var connection = new SqlConnection(connectionString);
        try { await connection.OpenAsync(ct); return connection; }
        catch { await connection.DisposeAsync(); throw; }
    }

    public static SqlCommand Procedimiento(SqlConnection connection, string nombre) =>
        new(nombre, connection) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };

    public static void Parametro(SqlCommand command, string nombre, SqlDbType tipo, object? valor, int tamano = 0)
    {
        var parameter = tamano == 0 ? command.Parameters.Add(nombre, tipo) : command.Parameters.Add(nombre, tipo, tamano);
        parameter.Value = valor ?? DBNull.Value;
        if (tipo == SqlDbType.Decimal) { parameter.Precision = 10; parameter.Scale = 2; }
    }
}
