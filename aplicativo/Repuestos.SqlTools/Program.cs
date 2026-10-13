using System.Data;
using System.Text;
using System.Text.RegularExpressions;
using System.Text.Json;
using DotNetEnv;
using DotNetEnv.Configuration;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.Management.Sdk.Sfc;
using Repuestos.Web.Models;

var configuration = new ConfigurationBuilder()
    .AddDotNetEnv(Path.GetFullPath("aplicativo/Repuestos.Web/.env"), LoadOptions.NoEnvVars())
    .AddEnvironmentVariables().Build();
var configuredConnectionString = configuration.GetConnectionString("Repuestos");
await using var connection = new SqlConnection(configuredConnectionString);
await connection.OpenAsync();
if (connection.Database is not ("RepuestosAutomotrices" or "RepuestosJose_QA"))
    throw new InvalidOperationException("La utilidad solo admite la base del proyecto o la base QA.");
var completeExportIndex = Array.IndexOf(args, "--completar-exportacion");
if (completeExportIndex >= 0)
{
    if (completeExportIndex + 1 >= args.Length) throw new ArgumentException("Falta el archivo exportado por SSMS.");
    var original = await File.ReadAllTextAsync(args[completeExportIndex + 1]);
    if (Regex.IsMatch(original, @"\bCREATE\s+(?:OR\s+ALTER\s+)?TRIGGER\b", RegexOptions.IgnoreCase))
        throw new InvalidOperationException("La exportacion ya incluye triggers; validar directamente para evitar duplicarlos.");
    var completed = new StringBuilder(original);
    completed.AppendLine("\nGO\n-- Complemento: triggers leidos de la base actual. El archivo original de SSMS se conserva.\n");
    await using var triggers = connection.CreateCommand();
    triggers.CommandText = "SELECT name,OBJECT_DEFINITION(object_id) FROM sys.triggers WHERE parent_class=1 AND is_ms_shipped=0 ORDER BY name;";
    await using var reader = await triggers.ExecuteReaderAsync();
    var count = 0;
    while (await reader.ReadAsync())
    {
        if (reader.IsDBNull(1)) throw new InvalidOperationException("Falta permiso para leer la definicion del trigger.");
        completed.AppendLine("SET ANSI_NULLS ON;\nGO\nSET QUOTED_IDENTIFIER ON;\nGO");
        completed.AppendLine(reader.GetString(1));
        completed.AppendLine("\nGO");
        count++;
    }
    if (count < 2) throw new InvalidOperationException("La base no tiene el minimo de triggers requerido.");
    Directory.CreateDirectory(".qa/entrega");
    await File.WriteAllTextAsync(".qa/entrega/Proyecto1_SSMS_Complementado.sql", completed.ToString(), new UTF8Encoding(true));
    Console.WriteLine($"Copia complementada: {count} triggers agregados en .qa/entrega/Proyecto1_SSMS_Complementado.sql.");
    return;
}
if (args.Contains("--capacidades"))
{
    await using var capabilities = connection.CreateCommand();
    capabilities.CommandText = """
        SELECT CONVERT(NVARCHAR(200),SERVERPROPERTY('ProductVersion')) AS Version,
            CONVERT(NVARCHAR(200),SERVERPROPERTY('Edition')) AS Edicion,
            (SELECT host_platform FROM sys.dm_os_host_info) AS Plataforma,
            IS_SRVROLEMEMBER('sysadmin') AS Administrador,
            HAS_PERMS_BY_NAME(NULL,NULL,'ALTER SETTINGS') AS ConfigurarServidor,
            HAS_PERMS_BY_NAME(NULL,NULL,'CONTROL SERVER') AS ControlServidor;
        SELECT name, CONVERT(INT,value_in_use) FROM sys.configurations WHERE name IN ('clr enabled','clr strict security');
        SELECT name, permission_set_desc FROM sys.assemblies WHERE is_user_defined=1;
        """;
    await using var reader = await capabilities.ExecuteReaderAsync();
    do
    {
        while (await reader.ReadAsync())
            Console.WriteLine(string.Join("; ", Enumerable.Range(0,reader.FieldCount).Select(i => $"{reader.GetName(i)}={reader.GetValue(i)}")));
    } while (await reader.NextResultAsync());
    return;
}

string[] tables = ["Rol", "Usuario", "Empleado", "Aseguradora", "Categoria", "Marca", "Modelo", "Repuesto",
    "RepuestoModelo", "Bodega", "Proveedor", "Compra", "DetalleCompra", "Inventario", "Movimiento", "Caso",
    "Cotizacion", "DetalleCotizacion", "Venta", "DetalleVenta", "Envio", "Incidencia", "Auditoria"];
var report = new StringBuilder("# Validacion de Proyecto 1\n\n");
report.AppendLine($"Fecha UTC: {DateTime.UtcNow:O}\n\nBase: `{connection.Database}`\n");
var before = await CountsAsync();
var stockBefore = await StockAsync();
if (args.Contains("--instalar-login"))
{
    var installer = $".qa/sqlclr/Instalar_LoginSql_{connection.Database}.sql";
    foreach (var batch in Regex.Split(await File.ReadAllTextAsync(installer), @"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase))
        if (!string.IsNullOrWhiteSpace(batch)) await ExecuteAsync(batch);
    Console.WriteLine("Verificador CLR y login con clave original instalados.");
}
if (args.Contains("--aplicar"))
{
    await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync();
    try
    {
        foreach (var path in new[] { "db/JeanC/03_script_Triggers.sql", "db/JeanC/04_integridad_perfiles.sql",
            "db/Jose/01_autenticacion.sql", "db/Jose/02_consultas.sql", "db/Jose/03_integracion_repuestos.sql",
            "db/Jose/05_consultas_consigna.sql" })
        {
            var sql = await File.ReadAllTextAsync(path);
            // Los scripts originales tambien deben poder aplicarse a una base existente.
            sql = Regex.Replace(sql, @"\bcreate\s+trigger\b", "CREATE OR ALTER TRIGGER", RegexOptions.IgnoreCase);
            foreach (var batch in Regex.Split(sql, @"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase))
            {
                if (string.IsNullOrWhiteSpace(batch)) continue;
                await ExecuteAsync(batch.Replace("RepuestosAutomotrices", connection.Database), transaction);
            }
            Console.WriteLine($"Aplicado: {path}");
        }
        await using (var verifier = connection.CreateCommand())
        {
            verifier.Transaction = transaction;
            verifier.CommandText = "SELECT COUNT(*) FROM sys.objects WHERE object_id=OBJECT_ID('dbo.VerificarClave');";
            if ((int)(await verifier.ExecuteScalarAsync())! > 0)
                foreach (var batch in Regex.Split(await File.ReadAllTextAsync("db/Jose/06_login_clave.sql"), @"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase))
                    if (!string.IsNullOrWhiteSpace(batch)) await ExecuteAsync(batch.Replace("RepuestosAutomotrices", connection.Database), transaction);
        }
        await transaction.CommitAsync();
    }
    catch { if (transaction.Connection is not null) await transaction.RollbackAsync(); throw; }

    await ExecuteAsync((await File.ReadAllTextAsync("db/Jose/04_datos_iniciales.sql"))
        .Replace("RepuestosAutomotrices", connection.Database));
    await using var seed = connection.CreateCommand();
    seed.CommandTimeout = 60;
    seed.CommandText = (await File.ReadAllTextAsync("db/JeanC/05_datos_prueba_integrales.sql"))
        .Replace("RepuestosAutomotrices", connection.Database);
    seed.Parameters.Add("@HashDemo", SqlDbType.VarChar, 255).Value =
        new PasswordHasher<Usuario>().HashPassword(null!, Guid.NewGuid().ToString("N"));
    await seed.ExecuteNonQueryAsync();
    Console.WriteLine("Datos integrales completados.");
}

var after = await CountsAsync();
var stockAfter = await StockAsync();
if (args.Contains("--verificar-login"))
{
    await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync();
    try
    {
        var suffix = Guid.NewGuid().ToString("N")[..12];
        var password = " SQL-Prueba-\u00f1-" + Guid.NewGuid().ToString("N") + " ";
        var hash = new PasswordHasher<Usuario>().HashPassword(null!, password);
        foreach (var role in new[] { "Empleado", "Cliente" })
        {
            var email = $"login-{role}-{suffix}@example.invalid";
            await using var seedLogin = connection.CreateCommand();
            seedLogin.Transaction = transaction;
            seedLogin.CommandText = """
                DECLARE @Rol INT = (SELECT IdRol FROM dbo.Rol WHERE Nombre=@RolNombre), @Id INT;
                INSERT dbo.Usuario(IdRol,Correo,Contrasena,Activo) VALUES (@Rol,@Correo,@Hash,1);
                SET @Id=SCOPE_IDENTITY();
                IF @RolNombre='Empleado' INSERT dbo.Empleado(IdUsuario,Cedula,Nombre,Puesto) VALUES (@Id,@Cedula,N'Prueba temporal',N'Prueba');
                ELSE INSERT dbo.Aseguradora(IdUsuario,CedulaJuridica,Nombre) VALUES (@Id,@Cedula,N'Prueba temporal');
                """;
            seedLogin.Parameters.AddWithValue("@RolNombre", role);
            seedLogin.Parameters.AddWithValue("@Correo", email);
            seedLogin.Parameters.AddWithValue("@Hash", hash);
            seedLogin.Parameters.AddWithValue("@Cedula", "LOGIN-" + suffix);
            await seedLogin.ExecuteNonQueryAsync();
            foreach (var attempt in new[] { (Password: password, Expected: true), (Password: "incorrecta", Expected: false), (Password: hash, Expected: false) })
            {
                await using var login = connection.CreateCommand();
                login.Transaction = transaction;
                login.CommandType = CommandType.StoredProcedure;
                login.CommandText = "dbo.LoginUsuario";
                login.CommandTimeout = 30;
                login.Parameters.Add("@Correo",SqlDbType.VarChar,100).Value = email;
                login.Parameters.Add("@Clave",SqlDbType.NVarChar,256).Value = attempt.Password;
                var output = login.Parameters.Add("@Valido",SqlDbType.Bit);
                output.Direction = ParameterDirection.Output;
                var timer = System.Diagnostics.Stopwatch.StartNew();
                await using var reader = await login.ExecuteReaderAsync();
                var returned = await reader.ReadAsync();
                if (returned && (reader.GetString(3) != role || !reader.IsDBNull(2))) throw new InvalidOperationException("Resultado de login incorrecto.");
                await reader.DisposeAsync();
                if (returned != attempt.Expected || (bool)output.Value != attempt.Expected)
                    throw new InvalidOperationException("El login SQL no valido correctamente la clave.");
                Console.WriteLine($"Login SQL {role}: caso {(attempt.Expected ? "correcto" : "rechazado")}, {timer.Elapsed.TotalSeconds:F2}s.");
            }
        }
        await using (var restricted = connection.CreateCommand())
        {
            restricted.Transaction = transaction;
            var databaseUser = "QaLogin_" + suffix;
            restricted.CommandText = $"""
                CREATE USER [{databaseUser}] WITHOUT LOGIN;
                GRANT EXECUTE ON dbo.LoginUsuario TO [{databaseUser}];
                EXECUTE AS USER=N'{databaseUser}';
                BEGIN TRY
                    DECLARE @Valido BIT;
                    IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID('dbo.LoginUsuario') AND name='@Clave') <> 1
                        THROW 50081, 'El backend no puede detectar el contrato nuevo.', 1;
                    EXEC dbo.LoginUsuario @Correo=@CorreoPrueba,@Clave=@ClavePrueba,@Valido=@Valido OUTPUT;
                    IF @Valido<>1 THROW 50081, 'El backend restringido no puede validar el login.', 1;
                END TRY
                BEGIN CATCH
                    REVERT;
                    THROW;
                END CATCH;
                REVERT;
                """;
            restricted.Parameters.Add("@CorreoPrueba",SqlDbType.VarChar,100).Value = $"login-Cliente-{suffix}@example.invalid";
            restricted.Parameters.Add("@ClavePrueba",SqlDbType.NVarChar,256).Value = password;
            await restricted.ExecuteNonQueryAsync();
            Console.WriteLine("Login SQL: funciona con usuario restringido y permiso EXECUTE.");
        }
        report.AppendLine("\nLogin SQL con clave original: empleado y cliente aceptados; clave incorrecta y hash como clave rechazados. Pruebas temporales revertidas.\n");
    }
    finally { if (transaction.Connection is not null) await transaction.RollbackAsync(); }
    var restored = await CountsAsync();
    if (tables.Any(t => after[t] != restored[t])) throw new InvalidOperationException("Las pruebas temporales cambiaron conteos persistentes.");
    Console.WriteLine("Pruebas de login revertidas; registros existentes conservados.");
}
if (args.Contains("--sin-cambios") && (tables.Any(t => before[t] != after[t]) || stockBefore != stockAfter))
    throw new InvalidOperationException("La segunda carga cambio registros o existencias.");
report.AppendLine($"Unidades de inventario antes: {stockBefore}; despues: {stockAfter}.\n");
report.AppendLine("| Tabla | Antes | Despues | Minimo 3 |\n|---|---:|---:|---|");
foreach (var table in tables)
{
    report.AppendLine($"| {table} | {before[table]} | {after[table]} | {(after[table] >= 3 ? "Cumple" : "FALTA")} |");
    Console.WriteLine($"{table}: {after[table]} ({(after[table] >= 3 ? "cumple" : "FALTA")})");
}

var activeTriggers = 0;
await using (var command = connection.CreateCommand())
{
    command.CommandText = """
        SELECT name, is_disabled FROM sys.triggers WHERE parent_class = 1 ORDER BY name;
        SELECT name FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') ORDER BY name;
        SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled = 1 OR is_not_trusted = 1;
        SELECT COUNT(*) FROM sys.check_constraints WHERE is_disabled = 1 OR is_not_trusted = 1;
        """;
    await using var reader = await command.ExecuteReaderAsync();
    report.AppendLine("\n## Triggers\n");
    while (await reader.ReadAsync())
    {
        if (!reader.GetBoolean(1)) activeTriggers++;
        report.AppendLine($"- `{reader.GetString(0)}`: {(reader.GetBoolean(1) ? "DESACTIVADO" : "activo")}");
    }
    await reader.NextResultAsync();
    report.AppendLine("\n## Procedimientos\n");
    while (await reader.ReadAsync()) report.AppendLine($"- `{reader.GetString(0)}`");
    await reader.NextResultAsync(); await reader.ReadAsync();
    report.AppendLine($"\nLlaves foraneas desactivadas o no confiables: {reader.GetInt32(0)}.");
    await reader.NextResultAsync(); await reader.ReadAsync();
    report.AppendLine($"\nChecks desactivados o no confiables: {reader.GetInt32(0)}.");
}

if (args.Contains("--probar"))
{
    for (var index = 0; index < tables.Length; index++)
    {
        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.ConsultarDatos";
        command.Parameters.Add("@TipoConsulta", SqlDbType.Int).Value = index + 1;
        await using var reader = await command.ExecuteReaderAsync();
        long count = 0;
        while (await reader.ReadAsync()) count++;
        if (count != after[tables[index]]) throw new InvalidOperationException($"Consulta incompleta: {tables[index]}");
    }
    await using (var integrity = connection.CreateCommand())
    {
        integrity.CommandText = "DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;";
        await using var violations = await integrity.ExecuteReaderAsync();
        do
        {
            if (await violations.ReadAsync()) throw new InvalidOperationException("DBCC encontro violaciones de integridad.");
        } while (await violations.NextResultAsync());
    }
    // Consultas de integridad no modifican los datos compartidos.
    await using var checks = connection.CreateCommand();
    checks.CommandText = """
        IF EXISTS (SELECT 1 FROM dbo.Inventario WHERE Cantidad < 0) THROW 50060, 'Stock negativo.', 1;
        IF EXISTS (SELECT 1 FROM dbo.Compra c WHERE c.Total <> COALESCE((SELECT SUM(d.Cantidad*d.Costo) FROM dbo.DetalleCompra d WHERE d.IdCompra=c.IdCompra),0)) THROW 50061, 'Total de compra inconsistente.', 1;
        IF EXISTS (SELECT 1 FROM dbo.Cotizacion c WHERE c.Total <> COALESCE((SELECT SUM(d.Cantidad*d.Precio) FROM dbo.DetalleCotizacion d WHERE d.IdCotizacion=c.IdCotizacion),0)) THROW 50062, 'Total de cotizacion inconsistente.', 1;
        IF EXISTS (SELECT 1 FROM dbo.Venta c WHERE c.Total <> COALESCE((SELECT SUM(d.Cantidad*d.Precio) FROM dbo.DetalleVenta d WHERE d.IdVenta=c.IdVenta),0)) THROW 50063, 'Total de venta inconsistente.', 1;
        IF EXISTS (SELECT 1 FROM dbo.Empleado e JOIN dbo.Usuario u ON u.IdUsuario=e.IdUsuario JOIN dbo.Rol r ON r.IdRol=u.IdRol WHERE r.Nombre NOT IN ('Administrador','Empleado')) THROW 50064, 'Perfil empleado incoherente.', 1;
        IF EXISTS (SELECT 1 FROM dbo.Aseguradora a JOIN dbo.Usuario u ON u.IdUsuario=a.IdUsuario JOIN dbo.Rol r ON r.IdRol=u.IdRol WHERE r.Nombre <> 'Cliente') THROW 50065, 'Perfil cliente incoherente.', 1;
        """;
    await checks.ExecuteNonQueryAsync();
    report.AppendLine("\n## Validaciones\n\n23 selectores devuelven la tabla completa. Totales de compras, cotizaciones y ventas coherentes. Stock no negativo y roles de perfiles coherentes.\n");
    Console.WriteLine("Consultas e integridad: correctas.");
}

if (args.Contains("--exportar"))
{
    await using var exportConnection = new SqlConnection(configuredConnectionString);
    var serverConnection = new ServerConnection(exportConnection);
    var server = new Server(serverConnection);
    server.SetDefaultInitFields(typeof(Table), "IsSystemObject");
    server.SetDefaultInitFields(typeof(StoredProcedure), "IsSystemObject");
    var database = server.Databases[connection.Database];
    var objects = new List<Urn>();
    foreach (Table table in database.Tables) if (!table.IsSystemObject) objects.Add(table.Urn);
    foreach (StoredProcedure procedure in database.StoredProcedures) if (!procedure.IsSystemObject) objects.Add(procedure.Urn);
    foreach (Sequence sequence in database.Sequences) objects.Add(sequence.Urn);
    var passwordAssembly = database.Assemblies["Repuestos.Passwords"];
    if (passwordAssembly is not null) objects.Add(passwordAssembly.Urn);
    var passwordFunction = database.UserDefinedFunctions["VerificarClave", "dbo"];
    if (passwordFunction is not null) objects.Add(passwordFunction.Urn);
    string? assemblyHash = null;
    await using (var assemblyCommand = connection.CreateCommand())
    {
        assemblyCommand.CommandText = "SELECT HASHBYTES('SHA2_512',f.content) FROM sys.assembly_files f JOIN sys.assemblies a ON a.assembly_id=f.assembly_id WHERE a.name='Repuestos.Passwords' AND f.file_id=1;";
        if (await assemblyCommand.ExecuteScalarAsync() is byte[] hashBytes) assemblyHash = Convert.ToHexString(hashBytes);
    }
    var scripter = new Scripter(server);
    scripter.Options.ScriptSchema = true;
    scripter.Options.ScriptData = true;
    scripter.Options.DriAll = true;
    scripter.Options.Indexes = true;
    scripter.Options.Triggers = true;
    scripter.Options.WithDependencies = true;
    scripter.Options.SchemaQualify = true;
    scripter.Options.IncludeDatabaseContext = true;
    scripter.Options.ScriptBatchTerminator = true;
    scripter.Options.NoCollation = false;
    Directory.CreateDirectory(".qa/entrega");
    using var writer = new StreamWriter(".qa/entrega/Proyecto1_Estructura_Datos_SMO.sql", false, new UTF8Encoding(true));
    await writer.WriteLineAsync($"-- Exportacion SMO {DateTime.UtcNow:O}. Incluye datos y hashes de cuentas, sin credenciales del servidor.\nCREATE DATABASE [{connection.Database}];\nGO");
    if (assemblyHash is not null)
        await writer.WriteLineAsync($"""
            USE master;
            GO
            DECLARE @Advanced INT=(SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='show advanced options');
            IF (SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='clr enabled')=0
            BEGIN
                IF @Advanced=0 BEGIN EXEC sys.sp_configure 'show advanced options',1; RECONFIGURE; END;
                EXEC sys.sp_configure 'clr enabled',1; RECONFIGURE;
                IF @Advanced=0 BEGIN EXEC sys.sp_configure 'show advanced options',0; RECONFIGURE; END;
            END;
            IF NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x{assemblyHash})
                EXEC sys.sp_add_trusted_assembly @hash=0x{assemblyHash},@description=N'Repuestos.Passwords - verificacion PBKDF2';
            GO
            USE [{connection.Database}];
            GO
            """);
    foreach (var sql in scripter.EnumScript(objects.ToArray()))
    {
        await writer.WriteLineAsync(sql);
        await writer.WriteLineAsync("GO");
    }
    await File.WriteAllTextAsync(".qa/entrega/Proyecto1_Conteos.json",
        JsonSerializer.Serialize(new { Base = connection.Database, Tables = after, Stock = stockAfter, ActiveTriggers = activeTriggers, ClrAssemblyHash = assemblyHash },
            new JsonSerializerOptions { WriteIndented = true }));
    serverConnection.Disconnect();
    Console.WriteLine("Exportacion SMO creada en .qa/entrega/Proyecto1_Estructura_Datos_SMO.sql.");
}

Directory.CreateDirectory("docs/validacion");
var reportSuffix = args.Contains("--sin-cambios") ? "_Repeticion" : "";
await File.WriteAllTextAsync($"docs/validacion/Estado_{connection.Database}{reportSuffix}.md", report.ToString());
if (after.Values.Any(count => count < 3)) Environment.ExitCode = 1;

async Task<Dictionary<string, long>> CountsAsync()
{
    var counts = new Dictionary<string, long>();
    foreach (var table in tables)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = $"SELECT COUNT_BIG(*) FROM dbo.[{table}];";
        counts[table] = (long)(await command.ExecuteScalarAsync())!;
    }
    return counts;
}

async Task<long> StockAsync()
{
    await using var command = connection.CreateCommand();
    command.CommandText = "SELECT COALESCE(SUM(CONVERT(BIGINT,Cantidad)),0) FROM dbo.Inventario;";
    return (long)(await command.ExecuteScalarAsync())!;
}

async Task ExecuteAsync(string sql, SqlTransaction? transaction = null)
{
    await using var command = connection.CreateCommand();
    command.CommandTimeout = 60;
    command.Transaction = transaction;
    command.CommandText = sql;
    await command.ExecuteNonQueryAsync();
}
