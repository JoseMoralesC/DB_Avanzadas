using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Repuestos.Web.Data;
using Repuestos.Web.Models;
using Repuestos.Web.Services;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;
using System.Data;
using System.Buffers.Binary;

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
    bool loginSql;
    await using (var connection = await factory.AbrirAsync(ct))
    {
        await using var mode = connection.CreateCommand();
        mode.CommandText = "SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID('dbo.LoginUsuario') AND name='@Clave';";
        loginSql = (int)(await mode.ExecuteScalarAsync(ct))! == 1;
    }
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
    Check(await sqlUsers.ConfirmarLoginAsync("admin@test.local", "TestRepuestos2026!", "hash distinto", ct) is null, "SQL: rechaza hash no verificado");
    await using (var connection = await factory.AbrirAsync(ct))
    {
        await using var loginCheck = connection.CreateCommand();
        loginCheck.CommandTimeout = 120;
        loginCheck.CommandText = loginSql ? """
            DECLARE @Valido BIT;
            EXEC dbo.LoginUsuario @Correo='admin@test.local', @Clave=N'TestRepuestos2026!', @Valido=@Valido OUTPUT;
            IF @Valido <> 1 THROW 50070, 'Login valido no confirmado.', 1;
            EXEC dbo.LoginUsuario @Correo='admin@test.local', @Clave=N'incorrecta', @Valido=@Valido OUTPUT;
            IF @Valido <> 0 THROW 50070, 'Login invalido aceptado.', 1;
            DECLARE @Hash VARCHAR(255) = (SELECT Contrasena FROM dbo.Usuario WHERE Correo='admin@test.local');
            EXEC dbo.LoginUsuario @Correo='admin@test.local', @Clave=@Hash, @HashVerificado=@Hash, @Valido=@Valido OUTPUT;
            IF @Valido <> 0 THROW 50070, 'Un hash no puede sustituir la clave.', 1;
            EXEC dbo.LoginUsuario @Correo='inactivo@test.local', @Clave=N'TestRepuestos2026!', @Valido=@Valido OUTPUT;
            IF @Valido <> 0 THROW 50070, 'Login inactivo aceptado.', 1;
            EXEC dbo.LoginUsuario @Correo='noexiste@test.local', @Clave=N'TestRepuestos2026!', @Valido=@Valido OUTPUT;
            IF @Valido <> 0 THROW 50070, 'Login inexistente aceptado.', 1;
            """ : """
            DECLARE @Hash VARCHAR(255) = (SELECT Contrasena FROM dbo.Usuario WHERE Correo='admin@test.local'), @Valido BIT;
            EXEC dbo.LoginUsuario @Correo='admin@test.local', @HashVerificado=@Hash, @Valido=@Valido OUTPUT;
            IF @Valido <> 1 THROW 50070, 'Login valido no confirmado.', 1;
            EXEC dbo.LoginUsuario @Correo='admin@test.local', @HashVerificado='incorrecto', @Valido=@Valido OUTPUT;
            IF @Valido <> 0 THROW 50070, 'Login invalido aceptado.', 1;
            """;
        await loginCheck.ExecuteNonQueryAsync(ct);
    }
    Check(true, "SQL: login devuelve indicador explicito de validez");
    if (loginSql)
    {
        await using var connection = await factory.AbrirAsync(ct);
        async Task<bool> Verify(string? hash, string? password)
        {
            await using var command = connection.CreateCommand();
            command.CommandText = "SELECT dbo.VerificarClave(@Clave,@Hash);";
            command.Parameters.Add("@Clave", SqlDbType.NVarChar, 256).Value = (object?)password ?? DBNull.Value;
            command.Parameters.Add("@Hash", SqlDbType.NVarChar, 255).Value = (object?)hash ?? DBNull.Value;
            return (bool)(await command.ExecuteScalarAsync(ct))!;
        }
        var passwords = new[] { "TestRepuestos2026!", " Espa\u00f1ol\u6f22\u5b57\ud83d\udd11 " };
        foreach (var password in passwords)
        {
            var modernHash = hasher.HashPassword(null!, password);
            Check(await Verify(modernHash, password) && !await Verify(modernHash, password + "x"), "CLR: Identity V3 y sensibilidad a la clave");
            var v2 = new PasswordHasher<Usuario>(Options.Create(new PasswordHasherOptions { CompatibilityMode = PasswordHasherCompatibilityMode.IdentityV2 }));
            Check(await Verify(v2.HashPassword(null!, password), password), "CLR: compatibilidad Identity V2");
            foreach (var prf in new[] { KeyDerivationPrf.HMACSHA1, KeyDerivationPrf.HMACSHA256, KeyDerivationPrf.HMACSHA512 })
            {
                var salt = Enumerable.Range(1, 16).Select(i => (byte)i).ToArray();
                var subkey = KeyDerivation.Pbkdf2(password, salt, prf, 10000, 32);
                var payload = new byte[61]; payload[0] = 1;
                BinaryPrimitives.WriteUInt32BigEndian(payload.AsSpan(1, 4), (uint)prf);
                BinaryPrimitives.WriteUInt32BigEndian(payload.AsSpan(5, 4), 10000);
                BinaryPrimitives.WriteUInt32BigEndian(payload.AsSpan(9, 4), 16);
                salt.CopyTo(payload, 13); subkey.CopyTo(payload, 29);
                Check(await Verify(Convert.ToBase64String(payload), password), "CLR: formato V3 y PRF " + prf);
            }
        }
        foreach (var invalid in new[] { "", "no-es-base64", "AQ==", Convert.ToBase64String(new byte[61]), "Ag==" })
            Check(!await Verify(invalid, "TestRepuestos2026!"), "CLR: hash malformado rechazado");
        Check(!await Verify(null, "clave") && !await Verify(hasher.HashPassword(null!, "clave"), null), "CLR: argumentos nulos rechazados");
        Check(true, "SQL: valida clave directamente sin backend y rechaza reutilizar el hash como clave");
    }
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
    await using (var connection = await factory.AbrirAsync(ct))
    {
        async Task Execute(string sql)
        {
            await using var command = connection.CreateCommand();
            command.CommandText = sql;
            await command.ExecuteNonQueryAsync(ct);
        }
        async Task ExpectError(string sql, int number, string label)
        {
            try { await Execute(sql); throw new Exception("No rechazo: " + label); }
            catch (SqlException ex) when (ex.Errors.Cast<SqlError>().Any(e => e.Number == number)) { Check(true, label); }
        }
        await Execute("""
            INSERT dbo.Bodega(Nombre,Ubicacion) VALUES ('QA Origen','QA'),('QA Destino','QA');
            INSERT dbo.Proveedor(Nombre,DiasEntrega) VALUES ('QA Proveedor',1);
            INSERT dbo.Compra(IdProveedor,IdBodega,FechaRecepcion) VALUES (1,1,CONVERT(date,GETDATE()));
            INSERT dbo.DetalleCompra(IdCompra,IdRepuesto,Cantidad,Costo) VALUES (1,1,10,5);
            IF (SELECT Cantidad FROM dbo.Inventario WHERE IdBodega=1 AND IdRepuesto=1) <> 10 THROW 50070, 'Stock compra incorrecto.', 1;
            IF (SELECT Total FROM dbo.Compra WHERE IdCompra=1) <> 50 THROW 50070, 'Total compra incorrecto.', 1;
            UPDATE dbo.DetalleCompra SET Cantidad=12 WHERE IdCompra=1;
            IF (SELECT Cantidad FROM dbo.Inventario WHERE IdBodega=1 AND IdRepuesto=1) <> 12 THROW 50070, 'Stock update incorrecto.', 1;
            INSERT dbo.Movimiento(IdRepuesto,IdBodegaOrigen,IdBodegaDestino,IdEmpleado,Tipo,Cantidad) VALUES (1,1,2,1,'Traslado',2);
            IF (SELECT Cantidad FROM dbo.Inventario WHERE IdBodega=1 AND IdRepuesto=1) <> 10 THROW 50070, 'Origen traslado incorrecto.', 1;
            IF (SELECT Cantidad FROM dbo.Inventario WHERE IdBodega=2 AND IdRepuesto=1) <> 2 THROW 50070, 'Destino traslado incorrecto.', 1;
            INSERT dbo.DetalleCotizacion(IdCotizacion,IdRepuesto,Cantidad,Precio,Estado) VALUES (1,1,2,8,'Aprobado');
            IF (SELECT Total FROM dbo.Cotizacion WHERE IdCotizacion=1) <> 16 THROW 50070, 'Total cotizacion incorrecto.', 1;
            INSERT dbo.Venta(IdCotizacion,IdEmpleado) VALUES (1,1);
            INSERT dbo.DetalleVenta(IdVenta,IdRepuesto,IdBodega,Cantidad,Precio,Costo) VALUES (1,1,1,2,8,5);
            IF (SELECT Total FROM dbo.Venta WHERE IdVenta=1) <> 16 THROW 50070, 'Total venta incorrecto.', 1;
            IF (SELECT Cantidad FROM dbo.Inventario WHERE IdBodega=1 AND IdRepuesto=1) <> 8 THROW 50070, 'Stock venta incorrecto.', 1;
            DELETE dbo.DetalleVenta WHERE IdVenta=1;
            IF (SELECT Total FROM dbo.Venta WHERE IdVenta=1) <> 0 THROW 50070, 'Total delete incorrecto.', 1;
            IF (SELECT Cantidad FROM dbo.Inventario WHERE IdBodega=1 AND IdRepuesto=1) <> 10 THROW 50070, 'Stock delete incorrecto.', 1;
            IF (SELECT COUNT(*) FROM dbo.Auditoria) < 3 THROW 50070, 'No se genero auditoria.', 1;
            """);
        Check(true, "SQL: triggers de compra, venta, traslado, totales y auditoria");
        await ExpectError("INSERT dbo.DetalleVenta(IdVenta,IdRepuesto,IdBodega,Cantidad,Precio,Costo) VALUES (1,1,1,999,8,5);", 50000, "SQL: rechaza venta sin existencias");
        await ExpectError("UPDATE dbo.Compra SET IdBodega=2 WHERE IdCompra=1;", 50043, "SQL: protege bodega de compra recibida");
        await ExpectError("UPDATE dbo.Usuario SET IdRol=3 WHERE IdUsuario=1;", 50042, "SQL: rechaza cambio de rol incompatible");
        await ExpectError("INSERT dbo.Empleado(IdUsuario,Cedula,Nombre,Puesto) VALUES (1,'QA-DUP','Duplicado','QA');", 2627, "SQL: un perfil empleado por usuario");
        await ExpectError("EXEC dbo.ConsultarDatos @TipoConsulta=24;", 50040, "SQL: rechaza selector de consulta invalido");
        await Execute("""
            INSERT dbo.Modelo(IdMarca,Nombre,AnioInicio) VALUES (1,'QA Segundo',2001);
            EXEC dbo.MantenimientoRepuestoModelo @function=1,@IdRepuesto=1,@IdModelo=1;
            EXEC dbo.MantenimientoRepuestoModelo @function=2,@IdRepuesto=1,@IdModelo=1,@NuevoIdModelo=2;
            IF NOT EXISTS (SELECT 1 FROM dbo.RepuestoModelo WHERE IdRepuesto=1 AND IdModelo=2) THROW 50070, 'No actualizo compatibilidad.', 1;
            EXEC dbo.MantenimientoRepuestoModelo @function=3,@IdRepuesto=1,@IdModelo=2;
            """);
        Check(true, "SQL: alta, modificacion y borrado de compatibilidad");
    }
    Console.WriteLine($"Total: {checks} comprobaciones correctas.");
}

else
{
    Console.Error.WriteLine("Ejecute Validar-SqlLocal.ps1 para preparar y comprobar la base SQL aislada.");
    Environment.ExitCode = 1;
}
