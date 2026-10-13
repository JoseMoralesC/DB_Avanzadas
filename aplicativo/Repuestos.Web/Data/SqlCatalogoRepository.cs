using System.Data;
using Microsoft.Data.SqlClient;
using Repuestos.Web.Models;

namespace Repuestos.Web.Data;

public sealed class SqlCatalogoRepository(SqlConnectionFactory factory) : ICatalogoRepository
{
    public async Task<IReadOnlyList<Repuesto>> ConsultarAsync(FiltroCatalogo filtro, bool incluirInactivos, CancellationToken ct)
    {
        await using var connection = await factory.AbrirAsync(ct);
        await using var command = SqlConnectionFactory.Procedimiento(connection, "dbo.ConsultarCatalogo");
        SqlConnectionFactory.Parametro(command, "@Texto", SqlDbType.NVarChar, filtro.Texto, 120);
        SqlConnectionFactory.Parametro(command, "@IdCategoria", SqlDbType.Int, filtro.IdCategoria);
        SqlConnectionFactory.Parametro(command, "@IdMarca", SqlDbType.Int, filtro.IdMarca);
        SqlConnectionFactory.Parametro(command, "@IdModelo", SqlDbType.Int, filtro.IdModelo);
        SqlConnectionFactory.Parametro(command, "@PrecioMaximo", SqlDbType.Decimal, filtro.PrecioMaximo);
        SqlConnectionFactory.Parametro(command, "@SoloDisponibles", SqlDbType.Bit, filtro.SoloDisponibles);
        SqlConnectionFactory.Parametro(command, "@IncluirInactivos", SqlDbType.Bit, incluirInactivos);
        var list = new List<Repuesto>();
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct)) list.Add(LeerRepuesto(reader));
        return list;
    }

    public Task<IReadOnlyList<Opcion>> CategoriasAsync(CancellationToken ct) => OpcionesAsync("dbo.ConsultarCategorias", null, ct);
    public Task<IReadOnlyList<Opcion>> MarcasAsync(CancellationToken ct) => OpcionesAsync("dbo.ConsultarMarcas", null, ct);
    public Task<IReadOnlyList<Opcion>> ModelosAsync(int? idMarca, CancellationToken ct) => OpcionesAsync("dbo.ConsultarModelos", idMarca, ct);

    private async Task<IReadOnlyList<Opcion>> OpcionesAsync(string procedimiento, int? idMarca, CancellationToken ct)
    {
        await using var connection = await factory.AbrirAsync(ct);
        await using var command = SqlConnectionFactory.Procedimiento(connection, procedimiento);
        if (procedimiento == "dbo.ConsultarModelos") SqlConnectionFactory.Parametro(command, "@IdMarca", SqlDbType.Int, idMarca);
        var list = new List<Opcion>();
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct)) list.Add(new(reader.GetInt32(0), reader.GetString(1)));
        return list;
    }

    public async Task<Repuesto?> ObtenerAsync(int id, CancellationToken ct)
    {
        await using var connection = await factory.AbrirAsync(ct);
        await using var command = SqlConnectionFactory.Procedimiento(connection, "dbo.ConsultarRepuestoInterno");
        SqlConnectionFactory.Parametro(command, "@IdRepuesto", SqlDbType.Int, id);
        await using var reader = await command.ExecuteReaderAsync(ct);
        return await reader.ReadAsync(ct) ? LeerRepuesto(reader) : null;
    }

    public async Task<int> GuardarAsync(RepuestoForm form, CancellationToken ct)
    {
        await using var connection = await factory.AbrirAsync(ct);
        await using var command = SqlConnectionFactory.Procedimiento(connection, "dbo.GuardarRepuestoApp");
        SqlConnectionFactory.Parametro(command, "@IdRepuesto", SqlDbType.Int, form.IdRepuesto == 0 ? null : form.IdRepuesto);
        SqlConnectionFactory.Parametro(command, "@IdCategoria", SqlDbType.Int, form.IdCategoria);
        SqlConnectionFactory.Parametro(command, "@Nombre", SqlDbType.NVarChar, form.Nombre, 120);
        SqlConnectionFactory.Parametro(command, "@PrecioVenta", SqlDbType.Decimal, form.PrecioVenta);
        SqlConnectionFactory.Parametro(command, "@Costo", SqlDbType.Decimal, form.Costo);
        SqlConnectionFactory.Parametro(command, "@Activo", SqlDbType.Bit, form.Activo);
        return Convert.ToInt32(await command.ExecuteScalarAsync(ct));
    }

    public async Task<BaseActiva> BaseActivaAsync(CancellationToken ct)
    {
        await using var connection = await factory.AbrirAsync(ct);
        await using var command = SqlConnectionFactory.Procedimiento(connection, "dbo.ConsultarBaseActiva");
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) throw new InvalidOperationException("Sin informacion de conexion.");
        return new(reader.GetString(0), reader.GetString(1), reader.GetString(2));
    }

    public async Task<MisCasosViewModel> MisCasosAsync(int idUsuario, CancellationToken ct)
    {
        await using var connection = await factory.AbrirAsync(ct);
        await using var command = SqlConnectionFactory.Procedimiento(connection, "dbo.ConsultarMisCasos");
        SqlConnectionFactory.Parametro(command, "@IdUsuario", SqlDbType.Int, idUsuario);
        var casos = new List<CasoCliente>();
        var cotizaciones = new List<CotizacionCliente>();
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct)) casos.Add(new(reader.GetInt32(0), reader.GetString(1), reader.GetString(2), reader.GetDateTime(3)));
        await reader.NextResultAsync(ct);
        while (await reader.ReadAsync(ct)) cotizaciones.Add(new(reader.GetInt32(0), reader.GetInt32(1), reader.GetString(2), reader.GetDecimal(3), reader.GetDateTime(4)));
        return new(casos, cotizaciones);
    }

    private static Repuesto LeerRepuesto(SqlDataReader reader) => new(reader.GetInt32(0), reader.GetInt32(1),
        reader.GetString(2), reader.GetString(3), reader.GetString(4), reader.GetDecimal(5),
        reader.GetDecimal(6), reader.GetBoolean(7), reader.GetInt32(8));
}
