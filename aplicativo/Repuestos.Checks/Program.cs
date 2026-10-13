using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Repuestos.Web.Data;
using Repuestos.Web.Models;
using Repuestos.Web.Services;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

var hasher = new PasswordHasher<Usuario>();
var ct = CancellationToken.None;
var checks = 0;
void Check(bool condition, string name) { if (!condition) throw new Exception(name); Console.WriteLine("OK: " + name); checks++; }

if (Environment.GetEnvironmentVariable("REpuestos_SQL_TEST") is string sqlConnection)
{
    var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> { ["ConnectionStrings:Repuestos"] = sqlConnection }).Build();
    var factory = new SqlConnectionFactory(configuration);
    await using (var connection = await factory.AbrirAsync(ct))
    {
        await using var guard = connection.CreateCommand();
        guard.CommandText = "SELECT DB_NAME();";
        if ((string?)await guard.ExecuteScalarAsync(ct) != "RepuestosJose_QA")
            throw new InvalidOperationException("Las pruebas solo pueden ejecutarse en RepuestosJose_QA.");
    }
    var sqlUsers = new SqlUsuarioRepository(factory);
    var sqlCatalog = new SqlCatalogoRepository(factory);
    await using (var connection = await factory.AbrirAsync(ct))
    {
        await using var seed = connection.CreateCommand();
        seed.CommandText = """
            INSERT INTO Rol(Nombre) VALUES ('Administrador'), ('Empleado'), ('Cliente');
            INSERT INTO Usuario(IdRol,Correo,Contrasena,Activo) VALUES
              (1,'admin@test.local',@Hash,1),(3,'cliente@test.local',@Hash,1),
              (3,'cliente2@test.local',@Hash,1),(3,'inactivo@test.local',@Hash,0);
            INSERT INTO Empleado(IdUsuario,Cedula,Nombre,Puesto) VALUES (1,'QA-EMP','Admin SQL','Administrador');
            INSERT INTO Aseguradora(IdUsuario,CedulaJuridica,Nombre) VALUES
              (2,'QA-A1','Aseguradora Uno'),(3,'QA-A2','Aseguradora Dos'),(4,'QA-A3','Inactiva');
            INSERT INTO Categoria(Nombre) VALUES ('Iluminacion');
            INSERT INTO Marca(Nombre) VALUES ('Toyota');
            INSERT INTO Modelo(IdMarca,Nombre,AnioInicio) VALUES (1,'Corolla',2000);
            INSERT INTO Caso(IdAseguradora,IdModelo,Placa,Estado) VALUES (1,1,'ABC123','Abierto'),(2,1,'XYZ789','Abierto');
            INSERT INTO Cotizacion(IdCaso,IdEmpleado,Estado) VALUES (1,1,'Pendiente'),(2,1,'Pendiente');
            """;
        seed.Parameters.AddWithValue("@Hash", hasher.HashPassword(null!, "TestRepuestos2026!"));
        await seed.ExecuteNonQueryAsync(ct);
    }
    var sqlAuth = new AutenticacionService(sqlUsers, hasher);
    Check(await sqlAuth.LoginAsync("noexiste@test.local", "TestRepuestos2026!", ct) is null, "SQL: rechaza usuario inexistente");
    var principal = await sqlAuth.LoginAsync("admin@test.local", "TestRepuestos2026!", ct);
    Check(await sqlAuth.SesionValidaAsync(principal!, ct), "SQL: valida sesion vigente");
    var changed = new ClaimsPrincipal(new ClaimsIdentity(principal!.Claims.Where(c => c.Type != ClaimTypes.Role).Append(new Claim(ClaimTypes.Role, "Cliente")), "test"));
    Check(!await sqlAuth.SesionValidaAsync(changed, ct), "SQL: rechaza sesion con rol distinto al almacenado");
    Check((await sqlAuth.LoginAsync("admin@test.local", "TestRepuestos2026!", ct))?.IsInRole("Administrador") == true, "SQL: login real mediante procedimientos");
    Check(await sqlAuth.LoginAsync("admin@test.local", "incorrecta", ct) is null, "SQL: rechaza contrasena incorrecta");
    Check(await sqlAuth.LoginAsync("inactivo@test.local", "TestRepuestos2026!", ct) is null, "SQL: rechaza usuario inactivo");
    Check(await sqlUsers.ConfirmarLoginAsync("admin@test.local", "hash distinto", ct) is null, "SQL: rechaza hash no verificado");
    var sqlId = await sqlCatalog.GuardarAsync(new() { IdCategoria = 1, Codigo = "SQL-001", Nombre = "Farol SQL", PrecioVenta = 100, Costo = 50 }, ct);
    Check(sqlId > 0 && (await sqlCatalog.ObtenerAsync(sqlId, ct))?.Costo == 50, "SQL: alta y lectura interna");
    var codigoSql = (await sqlCatalog.ObtenerAsync(sqlId, ct))!.Codigo;
    Check(codigoSql == "REP-000001", "SQL: genera codigo sin entrada manual");
    Check((await sqlCatalog.ConsultarAsync(new() { Texto = codigoSql }, false, ct)).Single().Costo == 0, "SQL: consulta publica oculta costo");
    await sqlCatalog.GuardarAsync(new() { IdRepuesto = sqlId, IdCategoria = 1, Codigo = "SQL-001", Nombre = "Farol editado", PrecioVenta = 120, Costo = 50, Activo = false }, ct);
    Check((await sqlCatalog.ConsultarAsync(new(), false, ct)).Count == 0, "SQL: desactivacion oculta repuesto");
    Check((await sqlCatalog.ConsultarAsync(new(), true, ct)).Single().Nombre == "Farol editado", "SQL: personal consulta inactivos");
    Check((await sqlCatalog.ObtenerAsync(sqlId, ct))!.Codigo == codigoSql, "SQL: conserva codigo al editar");
    try { await sqlCatalog.GuardarAsync(new() { IdRepuesto = 999, IdCategoria = 1, Codigo = "SQL-999", Nombre = "Inexistente" }, ct); throw new Exception("Acepto ID inexistente SQL"); }
    catch (SqlException ex) when (ex.Number == 50004) { Check(true, "SQL: error de actualizacion inexistente"); }
    await using (var connection = await factory.AbrirAsync(ct))
    {
        await using var legacy = connection.CreateCommand();
        legacy.CommandText = "INSERT dbo.Repuesto(IdCategoria,Codigo,Nombre,PrecioVenta,Costo,Activo) VALUES (1,'REP-000002','Codigo previo',10,5,1);";
        await legacy.ExecuteNonQueryAsync(ct);
    }
    var concurrentes = await Task.WhenAll(Enumerable.Range(0, 8).Select(i => sqlCatalog.GuardarAsync(new() { IdCategoria = 1, Nombre = $"Concurrente {i}" }, ct)));
    var codigosConcurrentes = await Task.WhenAll(concurrentes.Select(i => sqlCatalog.ObtenerAsync(i, ct)));
    Check(codigosConcurrentes.Select(r => r!.Codigo).Distinct().Count() == 8
        && codigosConcurrentes.All(r => r!.Codigo != "REP-000002"), "SQL: altas simultaneas sin duplicados y omite codigo preexistente");
    Check((await sqlCatalog.MisCasosAsync(2, ct)).Casos.Single().Placa == "ABC123"
        && (await sqlCatalog.MisCasosAsync(3, ct)).Casos.Single().Placa == "XYZ789", "SQL: aislamiento entre aseguradoras");
    Check((await sqlCatalog.MisCasosAsync(2, ct)).Cotizaciones.Single().IdCaso == 1, "SQL: aislamiento de cotizaciones");
    Check((await sqlCatalog.BaseActivaAsync(ct)).Base == "RepuestosJose_QA", "SQL: identifica base activa sin Always On");
    var sqlPrincipal = await sqlAuth.LoginAsync("admin@test.local", "TestRepuestos2026!", ct);
    await using (var connection = await factory.AbrirAsync(ct))
    {
        await using var update = connection.CreateCommand();
        update.CommandText = "UPDATE Usuario SET Activo = 0 WHERE Correo = 'admin@test.local';";
        await update.ExecuteNonQueryAsync(ct);
    }
    Check(!await sqlAuth.SesionValidaAsync(sqlPrincipal!, ct), "SQL: revoca sesion de cuenta desactivada");
    Console.WriteLine($"Total: {checks} comprobaciones correctas.");
}

else
{
    Console.Error.WriteLine("Ejecute Validar-SqlLocal.ps1 para preparar y comprobar la base SQL aislada.");
    Environment.ExitCode = 1;
}
