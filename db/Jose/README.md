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

Los tres primeros scripts de Jose se pueden volver a ejecutar con CREATE OR ALTER.
El cuarto inserta solamente datos faltantes en una transaccion y puede repetirse.
Los scripts originales de Jean Carlo no son idempotentes. No volver a crear
una base compartida que ya contiene datos.

## Contrato de autenticacion

`ObtenerCredencialLogin(@Correo)` devuelve exclusivamente al backend:
IdUsuario, Correo, HashContrasena, Rol, IdEmpleado, IdAseguradora, Nombre.
Solo devuelve cuentas activas con un perfil unico y coherente con su rol.
La aplicacion verifica el hash con PasswordHasher de ASP.NET Core y llama
`LoginUsuario(@Correo, @HashVerificado)` para confirmar la cuenta y la
credencial. Este segundo procedimiento no devuelve el hash.

La cuenta SQL es una cuenta tecnica del backend. Nunca entregar sus
credenciales a clientes ni exponer directamente estos procedimientos por HTTP.
La autorizacion por rol ocurre en el servidor web; poseer el hash no debe
ser una via publica de inicio de sesion. Esta separacion debe contrastarse con
la consigna de Proyecto 1 si exige verificar la contrasena dentro de SQL.

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

Pendientes de Jean Carlo: datos de prueba, respuesta consistente del resto de
mantenimientos, cardinalidad de perfiles, coherencia al cambiar roles y regla
de recepcion/movimientos para evitar duplicar inventario. Pendientes de Christian:
listener o destino de conexion, permisos SQL y prueba real de conmutacion.

## Primera carga de catalogo

`04_datos_iniciales.sql` agrega 3 categorias, 3 marcas, 6 modelos, 9 repuestos,
9 compatibilidades, 3 bodegas, 12 saldos de inventario y 3 proveedores ficticios.
Los precios y existencias son ejemplos del laboratorio, no datos comerciales.
El radiador se deja sin existencias para probar el filtro de disponibilidad.
Los codigos del conjunto empiezan por `INI-`; no se cambian precios, cantidades
ni cuentas existentes al repetir la carga.

Las existencias son saldos de apertura cargados directamente en Inventario.
No generar tambien compras o movimientos de entrada para esas mismas unidades.
La carga no simula compras, ventas ni casos y no completa el requisito de tres
registros en cada una de las 23 tablas. Esa carga integral se coordina con Jean Carlo
cuando esten instalados los triggers y definidas las reglas operativas.
