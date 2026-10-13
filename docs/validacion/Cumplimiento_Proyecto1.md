# Cumplimiento de Proyecto 1

Revision de la consigna original docs/requerimientos/Proyecto 1.pdf, realizada
el 13 de octubre de 2026 sobre la conexion configurada del laboratorio.
La alta disponibilidad se reserva para el cierre final por indicacion del equipo.

| Requisito | Evidencia o estado |
|---|---|
| Estructura completa y tipos | 23 tablas en db/JeanC/01_script_Tablas.sql; verificadas en el servidor |
| PK, FK, CHECK | Restricciones activas y confiables; DBCC sin violaciones |
| Mantenimiento de cada tabla | 23 procedimientos Mantenimiento; modificacion de compatibilidad completada |
| Minimo dos triggers | 13 triggers activos en la base compartida |
| Consulta con selector de query | ConsultarDatos(@TipoConsulta), 23 opciones, tabla completa |
| Usuarios cliente y personal | Roles Cliente, Empleado y Administrador; perfiles unicos y coherentes |
| Login que valida clave original | Cumplido: LoginUsuario verifica @Clave en SQL con PBKDF2 y devuelve cuenta y @Valido |
| Tres registros por tabla | Cumplido en las 23 tablas; ver Estado_RepuestosAutomotrices.md |
| Aplicativo minimo | Login, catalogo, alta/modificacion/desactivacion de repuestos y base activa |
| Script generado desde SSMS con datos | Cumplido: docs/evidencias/exportar/script.sql, con los 13 triggers; restauracion validada. Ver Revision_Exportacion_SSMS.md |
| Always On, manual y demostracion | Pendientes, reservados para el final |

## Validaciones realizadas

44 comprobaciones sobre SQL Server local en una base temporal exclusiva del
proyecto. Incluyen login correcto/incorrecto/inactivo, indicador de validez,
autorizacion y aislamiento de aseguradoras, alta/modificacion de repuestos,
codigos concurrentes, triggers de compras/ventas/traslados, totales, auditoria,
stock insuficiente, roles incompatibles, perfiles duplicados y compatibilidades.
La base temporal se elimina al finalizar.

Adicionalmente pasaron 22 comprobaciones de navegador con la firma nueva del
login: administrador y clientes, error de clave, sesion, autorizacion, consulta,
mantenimiento y vista movil. En el servidor compartido se probaron los perfiles
Empleado y Cliente con cuentas temporales dentro de una transaccion revertida:
clave correcta aceptada, incorrecta rechazada y hash como clave rechazado.
Los tiempos observados fueron entre 0.29 y 0.41 segundos por login SQL.

La carga integral se ejecuto dos veces en esa base y tambien se repitio en la
base compartida. La segunda ejecucion conserva conteos y unidades de inventario.
Los 23 selectores devuelven tantos registros como la tabla correspondiente.
Los reportes no contienen claves, cadenas de conexion ni hashes.

La copia SMO se restauro en RepuestosJose_QA y paso la validacion: los conteos
de las 23 tablas, los 13 triggers y las 93 unidades coinciden con el manifiesto
de la exportacion. La restauracion no duplica el stock ni genera auditorias
adicionales. La base temporal se elimino despues de la comprobacion.

## Reglas de los datos de prueba

Los registros existentes se conservaron. Se agregaron dos cuentas Cliente
inactivas con perfiles de aseguradora y tres cadenas de caso, cotizacion,
venta y envio ficticios. Las nuevas cuentas tienen hashes PasswordHasher de
claves aleatorias no publicadas; no son accesos para la demostracion.

Las tres compras recibidas incorporan 15 unidades nuevas; las tres ventas
consumen 3. Los traslados solo cambian la bodega y no aumentan el stock total.
El saldo total pasa de 81 a 93. Los saldos de apertura no se registran otra vez
como compras ni entradas. Incidencia registra observaciones; no modifica stock
automaticamente. Una baja fisica requiere una salida separada cuando corresponda.

Los triggers de compras registran stock al insertar el detalle. Para este
avance los ejemplos son compras ya recibidas; no se demuestra un flujo de
ordenes pendientes de recepcion. Una compra con detalles no puede cambiar su
bodega; se utiliza Movimiento de tipo Traslado.

## Contrato de login

La aplicacion recibe correo y clave original; PasswordHasher verifica la clave
contra el hash guardado. LoginUsuario recibe tambien la clave original y la
verifica independientemente en SQL con dbo.VerificarClave. SQL comprueba cuenta
activa, hash vigente, rol y perfil y devuelve @Valido. El procedimiento funciona
tambien desde SSMS con correo, clave original y el parametro de salida, sin
necesitar una comprobacion previa del aplicativo. No devuelve ni almacena la clave.

El verificador CLR preserva el formato PasswordHasher y utiliza PBKDF2 de
Windows CNG. Acepta Identity V2 y V3, los PRF SHA1/SHA256/SHA512, Unicode y
espacios en la clave; rechaza hashes malformados y parametros nulos. Los hashes
actuales y las claves de las cuentas existentes no se modificaron.

CLR quedo habilitado en el servidor compartido. El ensamblado concreto se
registro por su hash SHA512; clr strict security permanece en 1 y no se activa
TRUSTWORTHY. El permiso UNSAFE del ensamblado permite llamar a la API nativa de
Windows; el codigo llama unicamente al proveedor criptografico de System32.
La instalacion requiere Windows y una cuenta sysadmin o CONTROL SERVER.
Ver db/Jose/Clr/README.md para desplegar y repetir las pruebas.

## Exportacion exigida en SSMS

1. Conectar al destino actual y seleccionar RepuestosAutomotrices.
2. Abrir Tasks > Generate Scripts.
3. Seleccionar las 23 tablas, los procedimientos, la secuencia, el ensamblado Repuestos.Passwords y la funcion VerificarClave.
4. En Advanced, seleccionar Types of data to script = Schema and data.
5. Activar Script Primary Keys, Foreign Keys, Check Constraints, Indexes y Triggers.
6. Guardar el archivo .sql en la carpeta de entrega y comprobar que incluye INSERT con los datos actuales.
7. Adjuntar captura del asistente y validar la restauracion en una base temporal antes de entregar.

La instancia de destino debe habilitar CLR y confiar en el hash SHA512 del
ensamblado antes de cargarlo. La copia SMO incluye esta preparacion para el
administrador; no desactiva clr strict security ni habilita TRUSTWORTHY.

La utilidad `dotnet run --project aplicativo/Repuestos.SqlTools -- --probar --exportar`
prepara una copia mediante SMO, el componente de scripting de SQL Server, en
.qa/entrega/Proyecto1_Estructura_Datos_SMO.sql. No constituye evidencia de que se
haya usado la interfaz de SSMS. La copia incluye los hashes de las cuentas de la
base y queda fuera de Git; no incorpora contrasenas de conexion del servidor.

Para repetir la validacion de esa copia, despues de compilar SqlTools:

```powershell
& ./aplicativo/Repuestos.Checks/Validar-Exportacion.ps1
```

El script rechaza una base QA preexistente, importa exclusivamente en localhost
y compara los conteos con .qa/entrega/Proyecto1_Conteos.json antes de eliminar
la base que creo. No modifica la base compartida.
