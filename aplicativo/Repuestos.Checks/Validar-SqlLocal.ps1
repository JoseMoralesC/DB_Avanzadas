param([switch]$Navegador)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$created = $false
$testServer = $null
$previousConnection = $env:ConnectionStrings__Repuestos
$previousTestUrl = $env:TEST_URL
$previousSqlTest = $env:REpuestos_SQL_TEST
try {
    # Refuse an existing database: this script only owns the one it creates.
    & sqlcmd -S localhost -E -C -l 5 -b -Q "IF DB_ID(N'RepuestosJose_QA') IS NOT NULL THROW 50010, 'La base QA ya existe; no se modificara.', 1; CREATE DATABASE RepuestosJose_QA;"
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la base aislada.' }
    $created = $true
    foreach ($relative in @('db\JeanC\01_script_Tablas.sql', 'db\JeanC\02_script_ProcAlmac.sql', 'db\JeanC\03_script_Triggers.sql', 'db\Jose\01_autenticacion.sql', 'db\Jose\02_consultas.sql', 'db\Jose\03_integracion_repuestos.sql')) {
        $sql = [IO.File]::ReadAllText((Join-Path $root $relative)).Replace('CREATE DATABASE RepuestosAutomotrices;', '').Replace('RepuestosAutomotrices', 'RepuestosJose_QA')
        $sql | & sqlcmd -S localhost -E -C -l 5 -b
        if ($LASTEXITCODE -ne 0) { throw "Fallo en $relative" }
    }
    $env:REpuestos_SQL_TEST = 'Server=localhost;Database=RepuestosJose_QA;Integrated Security=true;Encrypt=true;TrustServerCertificate=true'
    & dotnet run --no-build --project (Join-Path $PSScriptRoot 'Repuestos.Checks.csproj')
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las comprobaciones SQL.' }
    if ($Navegador) {
        if (Get-NetTCPConnection -State Listen -LocalPort 5181 -ErrorAction SilentlyContinue) {
            throw 'El puerto 5181 esta ocupado; no se iniciara el servidor de pruebas.'
        }
        & sqlcmd -S localhost -E -C -d RepuestosJose_QA -l 5 -b -Q "UPDATE dbo.Usuario SET Activo = 1 WHERE Correo = 'admin@test.local';"
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo preparar el usuario de navegador.' }
        $env:ConnectionStrings__Repuestos = $env:REpuestos_SQL_TEST
        $env:TEST_URL = 'http://localhost:5181'
        $qaPath = Join-Path $root '.qa'
        [IO.Directory]::CreateDirectory($qaPath) | Out-Null
        $webPath = Join-Path $root 'aplicativo\Repuestos.Web'
        $testServer = Start-Process -FilePath 'dotnet.exe' -ArgumentList @('bin\Debug\net8.0\Repuestos.Web.dll', '--environment', 'Development', '--urls', 'http://localhost:5181') -WorkingDirectory $webPath -WindowStyle Hidden -RedirectStandardOutput (Join-Path $qaPath 'sql-browser-server.log') -RedirectStandardError (Join-Path $qaPath 'sql-browser-errors.log') -PassThru
        $ready = $false
        for ($attempt = 0; $attempt -lt 30; $attempt++) {
            try { $ready = (Invoke-WebRequest -Uri "$env:TEST_URL/Cuenta/Login" -UseBasicParsing -TimeoutSec 1).StatusCode -eq 200 } catch { }
            if ($ready) { break }
            Start-Sleep -Milliseconds 200
        }
        if (-not $ready) { throw 'El servidor SQL de pruebas no respondio.' }
        Push-Location $root
        try {
            & node (Join-Path $PSScriptRoot 'browser.cjs')
            if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas de navegador.' }
        } finally { Pop-Location }
    }
}
finally {
    if ($null -ne $testServer -and -not $testServer.HasExited) { Stop-Process -Id $testServer.Id }
    $env:REpuestos_SQL_TEST = $previousSqlTest
    $env:ConnectionStrings__Repuestos = $previousConnection
    $env:TEST_URL = $previousTestUrl
    if ($created) {
        & sqlcmd -S localhost -E -C -l 5 -b -Q "ALTER DATABASE RepuestosJose_QA SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE RepuestosJose_QA;"
        if ($LASTEXITCODE -ne 0) { Write-Warning 'No se pudo eliminar la base QA creada por esta prueba.' }
    }
}
