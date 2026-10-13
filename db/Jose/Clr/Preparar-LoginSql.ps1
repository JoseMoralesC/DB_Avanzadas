param([ValidateSet('RepuestosAutomotrices','RepuestosJose_QA')][string]$Base = 'RepuestosAutomotrices')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$output = Join-Path $root '.qa\sqlclr'
[IO.Directory]::CreateDirectory($output) | Out-Null
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw 'Se requiere .NET Framework 4.7.2 o posterior para compilar SQL CLR.' }
$dllPath = Join-Path $output 'Repuestos.Passwords.dll'
& $compiler /nologo /target:library /optimize+ "/out:$dllPath" /reference:System.Data.dll (Join-Path $PSScriptRoot 'PasswordVerifier.cs')
if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar el verificador.' }
$bytes = [IO.File]::ReadAllBytes($dllPath)
$binaryHex = [BitConverter]::ToString($bytes).Replace('-','')
$sha = [Security.Cryptography.SHA512]::Create()
try { $hashHex = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','') } finally { $sha.Dispose() }
$sql = @"
USE master;
GO
IF IS_SRVROLEMEMBER('sysadmin') <> 1 AND COALESCE(HAS_PERMS_BY_NAME(NULL,NULL,'CONTROL SERVER'),0) <> 1
    THROW 50080, 'Se requiere sysadmin o CONTROL SERVER para instalar el verificador.', 1;
DECLARE @Advanced INT = (SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='show advanced options');
IF (SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name='clr enabled') = 0
BEGIN
    IF @Advanced = 0 BEGIN EXEC sys.sp_configure 'show advanced options',1; RECONFIGURE; END;
    EXEC sys.sp_configure 'clr enabled',1; RECONFIGURE;
    IF @Advanced = 0 BEGIN EXEC sys.sp_configure 'show advanced options',0; RECONFIGURE; END;
END;
IF NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x$hashHex)
    EXEC sys.sp_add_trusted_assembly @hash=0x$hashHex, @description=N'Repuestos.Passwords - verificacion PBKDF2';
GO
USE [$Base];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
GO
IF NOT EXISTS (SELECT 1 FROM sys.assemblies WHERE name=N'Repuestos.Passwords')
    CREATE ASSEMBLY [Repuestos.Passwords] FROM 0x$binaryHex WITH PERMISSION_SET=UNSAFE;
ELSE IF NOT EXISTS (SELECT 1 FROM sys.assembly_files f JOIN sys.assemblies a ON a.assembly_id=f.assembly_id WHERE a.name=N'Repuestos.Passwords' AND f.file_id=1 AND HASHBYTES('SHA2_512',f.content)=0x$hashHex)
    ALTER ASSEMBLY [Repuestos.Passwords] FROM 0x$binaryHex WITH PERMISSION_SET=UNSAFE;
GO
CREATE OR ALTER FUNCTION dbo.VerificarClave(@Clave NVARCHAR(256),@Hash NVARCHAR(255))
RETURNS BIT AS EXTERNAL NAME [Repuestos.Passwords].[Repuestos.Passwords.PasswordVerifier].[Verify];
GO
"@
$sql += "`n" + [IO.File]::ReadAllText((Join-Path $root 'db\Jose\06_login_clave.sql')).Replace('RepuestosAutomotrices',$Base)
$sql += "`nCOMMIT TRANSACTION;`nGO`n"
$sqlPath = Join-Path $output "Instalar_LoginSql_$Base.sql"
[IO.File]::WriteAllText($sqlPath,$sql,[Text.UTF8Encoding]::new($true))
[IO.File]::WriteAllText((Join-Path $output 'AssemblySha512.txt'),$hashHex)
Write-Output "Instalador preparado: $sqlPath"
