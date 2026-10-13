param([string]$Archivo = '.qa/entrega/Proyecto1_Estructura_Datos_SMO.sql',
    [Alias('Manifest')][string]$ArchivoManifest = '.qa/entrega/Proyecto1_Conteos.json')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$exportPath = Join-Path $root $Archivo
$manifest = Get-Content (Join-Path $root $ArchivoManifest) -Raw | ConvertFrom-Json
$previousConnection = $env:ConnectionStrings__Repuestos
$created = $false
$clrBefore = $null
$trustExisted = $true
if ($manifest.ClrAssemblyHash) {
    if ($manifest.ClrAssemblyHash -notmatch '^[A-Fa-f0-9]{128}$') { throw 'Hash de ensamblado invalido.' }
    $clrBefore = [int]((& sqlcmd -S localhost -E -C -h -1 -W -b -Q "SET NOCOUNT ON; SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='clr enabled';") | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar CLR local.' }
    $trustExisted = [int]((& sqlcmd -S localhost -E -C -h -1 -W -b -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=0x$($manifest.ClrAssemblyHash);") | Out-String).Trim() -gt 0
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar confianza CLR.' }
}
try {
    & sqlcmd -S localhost -E -C -l 5 -b -Q "IF DB_ID(N'RepuestosJose_QA') IS NOT NULL THROW 50010, 'La base QA ya existe; no se modificara.', 1; CREATE DATABASE RepuestosJose_QA;"
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la base aislada.' }
    $created = $true
    if ($manifest.ClrAssemblyHash) {
        $clrSetup = "DECLARE @Advanced INT=(SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='show advanced options'); IF (SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='clr enabled')=0 BEGIN IF @Advanced=0 BEGIN EXEC sys.sp_configure 'show advanced options',1; RECONFIGURE; END; EXEC sys.sp_configure 'clr enabled',1; RECONFIGURE; IF @Advanced=0 BEGIN EXEC sys.sp_configure 'show advanced options',0; RECONFIGURE; END; END; IF NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x$($manifest.ClrAssemblyHash)) EXEC sys.sp_add_trusted_assembly @hash=0x$($manifest.ClrAssemblyHash),@description=N'Repuestos.Passwords - prueba de exportacion';"
        & sqlcmd -S localhost -E -C -l 5 -b -Q $clrSetup
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo preparar CLR para restaurar la exportacion.' }
    }
    $sql = [IO.File]::ReadAllText($exportPath).Replace('CREATE DATABASE [RepuestosAutomotrices];', '').Replace('[RepuestosAutomotrices]', '[RepuestosJose_QA]')
    # Map the laboratory account to a database-only principal in the temporary restore.
    $sql = $sql.Replace('CREATE USER [Jose] FOR LOGIN [Jose]', 'CREATE USER [Jose] WITHOUT LOGIN')
    $sql | & sqlcmd -S localhost -E -C -l 5 -b -d RepuestosJose_QA
    if ($LASTEXITCODE -ne 0) { throw 'La exportacion no pudo restaurarse.' }
    $env:ConnectionStrings__Repuestos = 'Server=localhost;Database=RepuestosJose_QA;Integrated Security=true;Encrypt=true;TrustServerCertificate=true'
    Push-Location $root
    try {
        $validationOptions = @('--probar')
        if ($manifest.ClrAssemblyHash) { $validationOptions += '--verificar-login' }
        & dotnet run --no-build --project aplicativo/Repuestos.SqlTools -- @validationOptions
        if ($LASTEXITCODE -ne 0) { throw 'La exportacion restaurada no paso la validacion.' }
    } finally { Pop-Location }
    $comparison = [Text.StringBuilder]::new()
    foreach ($table in $manifest.Tables.PSObject.Properties) {
        if ($table.Name -notmatch '^[A-Za-z]+$') { throw 'Nombre de tabla invalido en manifest.' }
        [void]$comparison.Append("IF (SELECT COUNT_BIG(*) FROM dbo.[$($table.Name)]) <> $([long]$table.Value) THROW 50071, 'Conteo restaurado incorrecto.', 1; ")
    }
    [void]$comparison.Append("IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) <> 23 THROW 50071, 'Cantidad de tablas incorrecta.', 1; IF (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1 AND is_disabled=0) <> $([int]$manifest.ActiveTriggers) THROW 50071, 'Cantidad de triggers incorrecta.', 1; IF (SELECT SUM(CONVERT(BIGINT,Cantidad)) FROM dbo.Inventario) <> $([long]$manifest.Stock) THROW 50071, 'Inventario alterado al restaurar.', 1;")
    & sqlcmd -S localhost -E -C -d RepuestosJose_QA -b -Q $comparison.ToString()
    if ($LASTEXITCODE -ne 0) { throw 'La restauracion no coincide con la evidencia de la base actual.' }
    Write-Output 'Exportacion restaurada y validada: conteos, triggers e inventario coinciden con el manifest.'
}
finally {
    $env:ConnectionStrings__Repuestos = $previousConnection
    if ($created) {
        & sqlcmd -S localhost -E -C -l 5 -b -Q "ALTER DATABASE RepuestosJose_QA SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE RepuestosJose_QA;"
        if ($LASTEXITCODE -ne 0) { Write-Warning 'No se pudo eliminar la base QA creada por esta prueba.' }
    }
    if ($created -and $null -ne $clrBefore) {
        if (-not $trustExisted) {
            & sqlcmd -S localhost -E -C -b -Q "IF EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x$($manifest.ClrAssemblyHash)) EXEC sys.sp_drop_trusted_assembly @hash=0x$($manifest.ClrAssemblyHash);"
        }
        if ($clrBefore -eq 0) {
            & sqlcmd -S localhost -E -C -b -Q "DECLARE @Advanced INT=(SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='show advanced options'); IF @Advanced=0 BEGIN EXEC sys.sp_configure 'show advanced options',1; RECONFIGURE; END; EXEC sys.sp_configure 'clr enabled',0; RECONFIGURE; IF @Advanced=0 BEGIN EXEC sys.sp_configure 'show advanced options',0; RECONFIGURE; END;"
        }
    }
}
