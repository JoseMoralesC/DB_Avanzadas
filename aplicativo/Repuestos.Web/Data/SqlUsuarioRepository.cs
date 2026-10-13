using System.Data;
using Repuestos.Web.Models;

namespace Repuestos.Web.Data;

public sealed class SqlUsuarioRepository(SqlConnectionFactory factory) : IUsuarioRepository
{
    public Task<Usuario?> ObtenerCredencialAsync(string correo, CancellationToken ct) => LeerAsync("dbo.ObtenerCredencialLogin", correo, null, ct);
    public Task<Usuario?> ConfirmarLoginAsync(string correo, string hashVerificado, CancellationToken ct) => LeerAsync("dbo.LoginUsuario", correo, hashVerificado, ct);

    private async Task<Usuario?> LeerAsync(string procedimiento, string correo, string? hash, CancellationToken ct)
    {
        await using var connection = await factory.AbrirAsync(ct);
        await using var command = SqlConnectionFactory.Procedimiento(connection, procedimiento);
        SqlConnectionFactory.Parametro(command, "@Correo", SqlDbType.VarChar, correo, 100);
        if (hash is not null) SqlConnectionFactory.Parametro(command, "@HashVerificado", SqlDbType.VarChar, hash, 255);
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return null;
        return new Usuario(reader.GetInt32(0), reader.GetString(1), hash ?? reader.GetString(2),
            reader.GetString(3), reader.IsDBNull(4) ? null : reader.GetInt32(4),
            reader.IsDBNull(5) ? null : reader.GetInt32(5), reader.GetString(6));
    }
}
