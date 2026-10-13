# SQL de Jose: autenticacion e integracion

Estos scripts complementan `db/JeanC/` y usan la base `RepuestosAutomotrices`.
Ejecutar en SSMS, en este orden:

1. `db/JeanC/01_script_Tablas.sql` (solo al crear la base).
2. `db/JeanC/02_script_ProcAlmac.sql`.
3. `db/JeanC/03_script_Triggers.sql`.
4. `db/Jose/01_autenticacion.sql`.
5. `db/Jose/02_consultas.sql`.
6. `db/Jose/03_integracion_repuestos.sql`.
7. `db/Jose/04_datos_iniciales.sql` (carga opcional de datos ficticios del catalogo).
8. `db/JeanC/04_integridad_perfiles.sql`.
9. `db/Jose/05_consultas_consigna.sql`.
10. `db/JeanC/05_datos_prueba_integrales.sql` (mediante SqlTools, que suministra el hash demo).
11. `db/Christian/01_permisos_backend.sql` (ajustando usuario y contrasena).
12. `db/Christian/02_verificacion_alta_disponibilidad.sql` (evidencia antes/despues de conmutar).

Los tres primeros scripts de Jose se pueden volver a ejecutar con CREATE OR ALTER.
El cuarto inserta solamente datos faltantes en una transaccion y puede repetirse.
Los scripts originales de Jean Carlo no son idempotentes. No volver a crear
una base compartida que ya contiene datos.

## Contrato de autenticacion

`ObtenerCredencialLogin(@Correo)` devuelve exclusivamente al backend:
IdUsuario, Correo, HashContrasena, Rol, IdEmpleado, IdAseguradora, Nombre.
Solo devuelve cuentas activas con un perfil unico y coherente con su rol.
La aplicacion verifica el hash con PasswordHasher de ASP.NET Core y llama
`LoginUsuario(@Correo, @Clave, @Valido OUTPUT, @HashVerificado)` para validar
independientemente la clave original dentro de SQL mediante dbo.VerificarClave.
Este segundo procedimiento no devuelve el hash.

La cuenta SQL es una cuenta tecnica del backend. Nunca entregar sus
credenciales a clientes ni exponer directamente estos procedimientos por HTTP.
La autorizacion por rol ocurre en el servidor web; poseer el hash no debe
ser una via publica de inicio de sesion. LoginUsuario verifica la clave original,
cuenta activa, rol y perfil y devuelve @Valido BIT OUTPUT (1 o 0).
El hash opcional detecta cambios de credencial entre las dos verificaciones;
no permite autenticar sin una clave correcta. La clave viaja como parametro
NVARCHAR por la conexion SQL cifrada y no se almacena.

`01_autenticacion.sql` mantiene el contrato anterior como preparacion para bases
sin CLR. El instalador de Clr/Preparar-LoginSql.ps1 agrega el verificador y aplica
`06_login_clave.sql`, que debe quedar al final. SqlTools --aplicar conserva este
contrato si el verificador ya existe. El aplicativo detecta la firma nueva;
su compatibilidad con la firma anterior solo facilita la migracion y no cumple
por si sola la validacion de clave original exigida por la consigna.

`Usuario.Contrasena` debe almacenar el hash generado por PasswordHasher,
nunca una contrasena literal. Generarlo con la utilidad de la aplicacion:

```powershell
dotnet run --project aplicativo/Repuestos.Web -- --hash-password
```

Antes de integrar, cargar los tres roles (Administrador, Empleado, Cliente),
usuarios con hash y sus perfiles correspondientes. No depender de IDs de rol
fijos: resolverlos por Nombre. Los datos de prueba por tabla son responsabilidad
coordinada con Jean Carlo; este avance no los inserta en la base compartida.

## Consultas y mantenimiento

- ConsultarCategorias y ConsultarMarcas: lista completa, columnas Id y Nombre.
- ConsultarModelos: filtro opcional IdMarca; lista completa cuando es NULL.
- ConsultarCatalogo: Texto, IdCategoria, IdMarca, IdModelo, PrecioMaximo,
  SoloDisponibles e IncluirInactivos. Filtros NULL devuelven el catalogo completo.
  Nunca devuelve el costo interno. Existencias suma el inventario por bodega.
- ConsultarRepuestoInterno: detalle con costo, reservado al personal en MVC.
- ConsultarMisCasos: recibe el IdUsuario de la sesion, resuelve la aseguradora
  y devuelve dos resultados: casos y cotizaciones propios. No acepta una
  aseguradora enviada por el navegador.
- ConsultarBaseActiva: servidor, base y estado de replica; no prueba por si solo
  que Always On funcione. La prueba de fallo se coordina con Christian.
- GuardarRepuestoApp: crea o modifica mediante MantenimientoRepuesto,
  devuelve IdRepuesto y rechaza IDs inexistentes. Activo=false desactiva sin
  borrar relaciones historicas. No modifica existencias ni compatibilidades.
  Asigna codigos REP-000001 mediante SecuenciaCodigoRepuesto al crear y conserva
  el codigo original al editar. El parametro opcional Codigo se ignora; se mantiene
  por compatibilidad. La secuencia puede dejar saltos al fallar una operacion.
  Reaplicar 03_integracion_repuestos.sql actualiza el procedimiento sin reiniciar
  la secuencia ni renombrar los repuestos existentes.

La carga integral completa los tres registros por tabla y 04_integridad_perfiles.sql
agrega unicidad de perfiles, coherencia al cambiar roles y proteccion de la bodega
de una compra con detalles. Los mantenimientos originales conservan sus contratos;
MantenimientoRepuestoModelo ahora permite modificar la compatibilidad.
Pendientes de Christian: listener o destino de conexion, permisos SQL y prueba real de conmutacion.
La carpeta `db/Christian/` deja una plantilla para cerrar esos pendientes sin
guardar secretos en Git.

## Primera carga de catalogo

`04_datos_iniciales.sql` agrega 3 categorias, 3 marcas, 6 modelos, 9 repuestos,
9 compatibilidades, 3 bodegas, 12 saldos de inventario y 3 proveedores ficticios.
Los precios y existencias son ejemplos del laboratorio, no datos comerciales.
El radiador se deja sin existencias para probar el filtro de disponibilidad.
Los codigos del conjunto empiezan por `INI-`; no se cambian precios, cantidades
ni cuentas existentes al repetir la carga.

Las existencias son saldos de apertura cargados directamente en Inventario.
No generar tambien compras o movimientos de entrada para esas mismas unidades.
La carga inicial no simula compras, ventas ni casos. La carga integral adicional
de Jean Carlo completa esos datos despues de instalar los triggers.

## Consultas de la consigna

`EXEC dbo.ConsultarDatos @TipoConsulta = 1;` devuelve la tabla Rol completa.
El selector 1..23 sigue el orden de tablas de `docs/validacion/Estado_RepuestosAutomotrices.md`.
Es una consulta administrativa; no se otorga al backend porque Usuario contiene hashes.
Las consultas filtradas del aplicativo conservan sus restricciones por rol.

## Validacion de la base actual

Desde la raiz, usando .env o ConnectionStrings__Repuestos:

```powershell
dotnet run --project aplicativo/Repuestos.SqlTools -- --probar
```

Para instalar objetos complementarios y completar los datos ficticios:

```powershell
dotnet run --project aplicativo/Repuestos.SqlTools -- --aplicar --probar
```

La utilidad no crea la base ni reinstala las tablas. Requiere la estructura y
los mantenimientos existentes. Guarda conteos y resultados sin secretos en docs/validacion.
