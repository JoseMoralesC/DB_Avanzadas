# Aplicacion de repuestos

Primer avance de Jose: ASP.NET Core MVC (.NET 8), vistas Razor y procedimientos
almacenados. No usa Entity Framework ni incorpora un frontend separado.

## Ejecutar localmente

```powershell
dotnet restore aplicativo/Repuestos.Web
dotnet run --project aplicativo/Repuestos.Web -- --environment Development --urls http://localhost:5180
```

La aplicacion utiliza exclusivamente SQL Server. Debe configurarse la conexion
antes de iniciar sesion; los usuarios y datos se leen de la base configurada.

## Conectar a SQL Server

La aplicacion carga `aplicativo/Repuestos.Web/.env` automaticamente en Development.
El .env local esta ignorado por Git; `.env.example` documenta las claves sin secretos.
Completar `ConnectionStrings__Repuestos` en el archivo
con el usuario y contrasena usados en SSMS. El destino confirmado del laboratorio
es `100.124.109.126,15002`, base `RepuestosAutomotrices`, autenticacion SQL Server.
Mantener comillas alrededor de la cadena para preservar espacios y caracteres.
Si la contrasena contiene delimitadores de SQL como punto y coma, tambien debe
citarse dentro de la cadena de conexion segun el formato de SQL Server.

```powershell
dotnet run --project aplicativo/Repuestos.Web -- --environment Development
```

Reiniciar la aplicacion despues de editar .env. Las variables del sistema y los
argumentos de terminal tienen prioridad sobre .env; .env tiene prioridad sobre
appsettings. El entorno Development se selecciona con el comando, no desde .env.
En Production se usan variables de entorno y no se lee .env.
El login requiere usuarios activos
con hash PasswordHasher y un perfil de empleado/aseguradora valido.

Aplicar primero los scripts indicados en `db/Jose/README.md` y cargar los datos
de prueba del equipo. Para evitar guardar secretos en Git, usar variables de
entorno o Secret Manager. Para una prueba con autenticacion Windows local:

```powershell
$env:ConnectionStrings__Repuestos = 'Server=localhost;Database=RepuestosAutomotrices;Integrated Security=true;Encrypt=true;TrustServerCertificate=true'
dotnet run --project aplicativo/Repuestos.Web -- --environment Development --urls http://localhost:5180
```

Con autenticacion SQL, configurar User ID y Password con los valores asignados,
fuera del repositorio. TrustServerCertificate=true es una excepcion para el
laboratorio; el despliegue debe usar HTTPS y un certificado SQL confiable.
Configurar AllowedHosts para los nombres reales del servidor al desplegar.
`appsettings.Local.json` esta ignorado, pero se recomienda Secret Manager o
variables de entorno. No hay credenciales SQL incluidas.

## Estructura y alcance

- Controllers: HTTP, autorizacion, formularios y seleccion de vistas.
- Models: datos y validacion de formularios.
- Views: presentacion Razor responsive.
- Services/AutenticacionService: verifica contrasenas y vigencia de sesion.
- Data: interfaces pequenas para usuarios y catalogo; implementaciones SQL.

Las dependencias se inyectan por constructor. Los procedimientos y parametros
SQL quedan en los repositorios. Se evita un repositorio generico y capas vacias.
Los codigos de nuevos repuestos se generan en SQL con formato REP-000001.
Se conservan al editar, incluso si cambian nombre o categoria; los codigos
anteriores siguen siendo validos. El formulario no acepta codigos manuales.
Reaplicar db/Jose/03_integracion_repuestos.sql antes de usar esta version.

El cliente consulta catalogo activo y sus casos/cotizaciones. Empleado y
administrador crean, editan y desactivan repuestos, consultan catalogo completo
y ven la conexion activa. Costos solo se muestran en el formulario interno.
Los POST exigen antiforgery; el login tiene limite de solicitudes y solo acepta
redirecciones locales. La sesion se revalida en cada solicitud para detectar
desactivacion, cambio de rol/perfil o cambio de contrasena. Una interrupcion de
SQL invalida la sesion; se inicia nuevamente al recuperar el servicio.

Todavia no implementa registro publico, compras, ventas, movimientos, entregas,
reportes analiticos ni CRUD de todas las tablas. La carga inicial de cuentas es
administrativa; clientes no pueden elegir su propio rol.

## Verificacion

```powershell
dotnet build aplicativo/Repuestos.Web
dotnet build aplicativo/Repuestos.Checks
& ./aplicativo/Repuestos.Checks/Validar-SqlLocal.ps1
```

Para verificar SQL Server local en una base temporal, despues de compilar Checks:

```powershell
& ./aplicativo/Repuestos.Checks/Validar-SqlLocal.ps1
```

La prueba requiere permiso de crear bases en localhost. Crea exclusivamente
RepuestosJose_QA, rechaza una base preexistente con ese nombre y elimina la base
que creo al terminar. No modifica la base compartida ni DB_Practica.

Las pruebas de navegador usan Chrome instalado y Playwright:

```powershell
npm install --prefix .qa --no-save playwright
& ./aplicativo/Repuestos.Checks/Validar-SqlLocal.ps1 -Navegador
```

El script inicia un servidor temporal en localhost:5181 conectado a RepuestosJose_QA,
ejecuta las pruebas y detiene el servidor antes de eliminar esa base. Las capturas
se guardan en .qa/screenshots, fuera de Git. Las cuentas @test.local se crean solo
en la base SQL de pruebas; no son usuarios de la base compartida.

Checks ejecuta comprobaciones de autenticacion, resultados de escritura,
concurrencia y aislamiento sobre SQL Server real, en la base temporal.
Rechaza otras bases y exige que se ejecute con el script de preparacion.
Estas comprobaciones no sustituyen pruebas de Always On.

La consigna de cuatro paginas citada por el roadmap aun no esta en el repositorio.
Contrastar el alcance y la division de verificacion del login con esa consigna
antes de cerrar la entrega.
