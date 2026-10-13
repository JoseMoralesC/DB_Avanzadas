# Login SQL con clave original

LoginUsuario recibe @Correo VARCHAR(100), @Clave NVARCHAR(256), @Valido BIT OUTPUT
y un @HashVerificado opcional para detectar cambios concurrentes de credencial.
SQL verifica la clave mediante dbo.VerificarClave. Una copia del hash almacenado
no sustituye la clave. No se cambia ninguna clave ni hash de cuentas existentes.

El verificador interpreta el [formato PasswordHasher de Microsoft](https://source.dot.net/Microsoft.Extensions.Identity.Core/PasswordHasher.cs.html)
y deriva la subclave con [BCryptDeriveKeyPBKDF2 de Windows](https://learn.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptderivekeypbkdf2).
Preserva sal, PRF y numero de iteraciones originales; limita a 1000000 iteraciones,
128 bytes de sal/subclave, 255 caracteres de hash y 256 de clave para acotar cargas
malformadas. La comparacion de subclaves recorre todos los bytes.

## Instalacion

Requiere SQL Server en Windows y .NET Framework 4.7.2 o posterior para compilar.
La conexion administradora debe configurarse localmente en .env o mediante
ConnectionStrings__Repuestos, sin publicar credenciales.

Desde la raiz del repositorio:

```powershell
& ./db/Jose/Clr/Preparar-LoginSql.ps1
dotnet run --project aplicativo/Repuestos.SqlTools -- --instalar-login --verificar-login --probar --sin-cambios
```

El generador compila PasswordVerifier.cs y produce un instalador autocontenido
con el ensamblado en hexadecimal en .qa/sqlclr/Instalar_LoginSql_RepuestosAutomotrices.sql.
Tambien puede ejecutarse ese archivo en SSMS con una cuenta administradora.
La DLL no necesita copiarse al sistema de archivos del servidor.

La instalacion habilita CLR, registra solo el hash SHA512 del ensamblado como
confiable y crea dbo.VerificarClave y el contrato nuevo de LoginUsuario.
El ensamblado usa PERMISSION_SET=UNSAFE porque llama al proveedor criptografico
nativo de Windows. No accede a archivos, red ni comandos externos. Se mantiene
clr strict security y el estado de show advanced options se restaura.
No se activa TRUSTWORTHY. [Registrar confianza requiere sysadmin o CONTROL SERVER](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-add-trusted-assembly-transact-sql).

La verificacion remota crea cuentas temporales de Empleado y Cliente dentro de
una transaccion, prueba la clave correcta/incorrecta y el hash como clave y
revierte todos esos registros. Comprueba que los conteos existentes se conservan.
Como en cualquier rollback de inserciones con IDENTITY, pueden quedar saltos de IDs.

## Pruebas

```powershell
dotnet build aplicativo/Repuestos.Checks
dotnet build aplicativo/Repuestos.SqlTools
& ./aplicativo/Repuestos.Checks/Validar-SqlLocal.ps1 -LoginSql -DatosIntegrales -Navegador
```

Las pruebas usan exclusivamente RepuestosJose_QA en localhost y rechazan una
base preexistente con ese nombre. Al terminar eliminan la base temporal, retiran
la confianza agregada exclusivamente para la prueba y restauran el estado de CLR
local. No modifican la base compartida.

La copia SMO incluye ensamblado, funcion, procedimiento y preparacion de confianza.
La exportacion desde la interfaz de SSMS sigue siendo el paso formal de entrega.
En futuras replicas Always On, CLR y la confianza son configuraciones de cada
instancia: deben aplicarse en cada nodo antes de probar el login tras conmutar.

Despues de instalar, la conexion habitual del aplicativo debe volver a su cuenta
tecnica. Esa cuenta necesita EXECUTE en LoginUsuario y ObtenerCredencialLogin;
no necesita sysadmin ni permisos para configurar CLR. La cadena usa Encrypt=true.
