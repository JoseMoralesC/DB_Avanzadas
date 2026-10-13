/* 
   TI-156 Bases de Datos Avanzadas - III Cuatrimestre 2026
   Proyecto 1: Sistema de repuestos automotrices para aseguradoras
   Procedimientos almacenados de mantenimiento (23 tablas)
 */

use RepuestosAutomotrices
go


--Rol
create procedure MantenimientoRol
(@function int, @IdRol int = null, @Nombre varchar(30) = null)

as

if @function = 1 -- insert
begin
    insert into Rol(Nombre)
    values(@Nombre)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Rol
    set
    Nombre = isnull(@Nombre, Nombre)
    where IdRol = @IdRol
end
if @function = 3 -- borrar
begin
    delete from Rol
    where IdRol = @IdRol

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Marca
create procedure MantenimientoMarca
(@function int, @IdMarca int = null, @Nombre nvarchar(50) = null)

as

if @function = 1 -- insert
begin
    insert into Marca(Nombre)
    values(@Nombre)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Marca
    set
    Nombre = isnull(@Nombre, Nombre)
    where IdMarca = @IdMarca
end
if @function = 3 -- borrar
begin
    delete from Marca
    where IdMarca = @IdMarca

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Categoria
create procedure MantenimientoCategoria
(@function int, @IdCategoria int = null, @Nombre nvarchar(60) = null)

as

if @function = 1 -- insert
begin
    insert into Categoria(Nombre)
    values(@Nombre)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Categoria
    set
    Nombre = isnull(@Nombre, Nombre)
    where IdCategoria = @IdCategoria
end
if @function = 3 -- borrar
begin
    delete from Categoria
    where IdCategoria = @IdCategoria

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Bodega
create procedure MantenimientoBodega
(@function int, @IdBodega int = null, @Nombre nvarchar(60) = null, @Ubicacion nvarchar(150) = null)

as

if @function = 1 -- insert
begin
    insert into Bodega(Nombre, Ubicacion)
    values(@Nombre, @Ubicacion)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Bodega
    set
    Nombre = isnull(@Nombre, Nombre),
    Ubicacion = isnull(@Ubicacion, Ubicacion)
    where IdBodega = @IdBodega
end
if @function = 3 -- borrar
begin
    delete from Bodega
    where IdBodega = @IdBodega

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Proveedor
create procedure MantenimientoProveedor
(@function int, @IdProveedor int = null, @Nombre nvarchar(100) = null, @Telefono varchar(15) = null, @Correo varchar(100) = null, @DiasEntrega int = null)

as

if @function = 1 -- insert
begin
    insert into Proveedor(Nombre, Telefono, Correo, DiasEntrega)
    values(@Nombre, @Telefono, @Correo, @DiasEntrega)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Proveedor
    set
    Nombre = isnull(@Nombre, Nombre),
    Telefono = isnull(@Telefono, Telefono),
    Correo = isnull(@Correo, Correo),
    DiasEntrega = isnull(@DiasEntrega, DiasEntrega)
    where IdProveedor = @IdProveedor
end
if @function = 3 -- borrar
begin
    delete from Proveedor
    where IdProveedor = @IdProveedor

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

-- Auditoria
create procedure MantenimientoAuditoria
(@function int, @IdAuditoria int = null, @Tabla varchar(50) = null, @Accion char(1) = null, @Usuario varchar(100) = null, @Fecha datetime = null)

as

if @function = 1 -- insert
begin
    insert into Auditoria(Tabla, Accion, Usuario, Fecha)
    values(@Tabla, @Accion, @Usuario, isnull(@Fecha, getdate()))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Auditoria
    set
    Tabla = isnull(@Tabla, Tabla),
    Accion = isnull(@Accion, Accion),
    Usuario = isnull(@Usuario, Usuario),
    Fecha = isnull(@Fecha, Fecha)
    where IdAuditoria = @IdAuditoria
end
if @function = 3 -- borrar
begin
    delete from Auditoria
    where IdAuditoria = @IdAuditoria

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

-- Usuario
create procedure MantenimientoUsuario
(@function int, @IdUsuario int = null, @IdRol int = null, @Correo varchar(100) = null, @Contrasena varchar(255) = null, @Activo bit = null)

as

if @function = 1 -- insert
begin
    insert into Usuario(IdRol, Correo, Contrasena, Activo)
    values(@IdRol, @Correo, @Contrasena, isnull(@Activo, 1))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Usuario
    set
    IdRol = isnull(@IdRol, IdRol),
    Correo = isnull(@Correo, Correo),
    Contrasena = isnull(@Contrasena, Contrasena),
    Activo = isnull(@Activo, Activo)
    where IdUsuario = @IdUsuario
end
if @function = 3 -- borrar
begin
    delete from Usuario
    where IdUsuario = @IdUsuario

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Empleado
create procedure MantenimientoEmpleado
(@function int, @IdEmpleado int = null, @IdUsuario int = null, @Cedula varchar(20) = null, @Nombre nvarchar(100) = null, @Puesto nvarchar(50) = null)

as

if @function = 1 -- insert
begin
    insert into Empleado(IdUsuario, Cedula, Nombre, Puesto)
    values(@IdUsuario, @Cedula, @Nombre, @Puesto)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Empleado
    set
    IdUsuario = isnull(@IdUsuario, IdUsuario),
    Cedula = isnull(@Cedula, Cedula),
    Nombre = isnull(@Nombre, Nombre),
    Puesto = isnull(@Puesto, Puesto)
    where IdEmpleado = @IdEmpleado
end
if @function = 3 -- borrar
begin
    delete from Empleado
    where IdEmpleado = @IdEmpleado

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Aseguradora
create procedure MantenimientoAseguradora
(@function int, @IdAseguradora int = null, @IdUsuario int = null, @CedulaJuridica varchar(20) = null, @Nombre nvarchar(100) = null, @Telefono varchar(15) = null, @Correo varchar(100) = null)

as

if @function = 1 -- insert
begin
    insert into Aseguradora(IdUsuario, CedulaJuridica, Nombre, Telefono, Correo)
    values(@IdUsuario, @CedulaJuridica, @Nombre, @Telefono, @Correo)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Aseguradora
    set
    IdUsuario = isnull(@IdUsuario, IdUsuario),
    CedulaJuridica = isnull(@CedulaJuridica, CedulaJuridica),
    Nombre = isnull(@Nombre, Nombre),
    Telefono = isnull(@Telefono, Telefono),
    Correo = isnull(@Correo, Correo)
    where IdAseguradora = @IdAseguradora
end
if @function = 3 -- borrar
begin
    delete from Aseguradora
    where IdAseguradora = @IdAseguradora

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Modelo
create procedure MantenimientoModelo
(@function int, @IdModelo int = null, @IdMarca int = null, @Nombre nvarchar(60) = null, @AnioInicio int = null, @AnioFin int = null)

as

if @function = 1 -- insert
begin
    insert into Modelo(IdMarca, Nombre, AnioInicio, AnioFin)
    values(@IdMarca, @Nombre, @AnioInicio, @AnioFin)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Modelo
    set
    IdMarca = isnull(@IdMarca, IdMarca),
    Nombre = isnull(@Nombre, Nombre),
    AnioInicio = isnull(@AnioInicio, AnioInicio),
    AnioFin = isnull(@AnioFin, AnioFin)
    where IdModelo = @IdModelo
end
if @function = 3 -- borrar
begin
    delete from Modelo
    where IdModelo = @IdModelo

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Repuesto
create procedure MantenimientoRepuesto
(@function int, @IdRepuesto int = null, @IdCategoria int = null, @Codigo varchar(30) = null, @Nombre nvarchar(120) = null, @PrecioVenta decimal(10,2) = null, @Costo decimal(10,2) = null, @Activo bit = null)

as

if @function = 1 -- insert
begin
    insert into Repuesto(IdCategoria, Codigo, Nombre, PrecioVenta, Costo, Activo)
    values(@IdCategoria, @Codigo, @Nombre, @PrecioVenta, @Costo, isnull(@Activo, 1))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Repuesto
    set
    IdCategoria = isnull(@IdCategoria, IdCategoria),
    Codigo = isnull(@Codigo, Codigo),
    Nombre = isnull(@Nombre, Nombre),
    PrecioVenta = isnull(@PrecioVenta, PrecioVenta),
    Costo = isnull(@Costo, Costo),
    Activo = isnull(@Activo, Activo)
    where IdRepuesto = @IdRepuesto
end
if @function = 3 -- borrar
begin
    delete from Repuesto
    where IdRepuesto = @IdRepuesto

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--RepuestoModelo
create procedure MantenimientoRepuestoModelo
(@function int, @IdRepuesto int = null, @IdModelo int = null)

as

if @function = 1 -- insert
begin
    insert into RepuestoModelo(IdRepuesto, IdModelo)
    values(@IdRepuesto, @IdModelo)
end
if @function = 2 -- update (no aplica: ambas columnas forman la llave primaria)
begin
    raiserror('Error, esta tabla no se actualiza; borre la relacion e inserte la nueva',16,1)
    return -1
end
if @function = 3 -- borrar
begin
    delete from RepuestoModelo
    where IdRepuesto = @IdRepuesto
    and IdModelo = @IdModelo

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Inventario
create procedure MantenimientoInventario
(@function int, @IdInventario int = null, @IdBodega int = null, @IdRepuesto int = null, @Cantidad int = null)

as

if @function = 1 -- insert
begin
    insert into Inventario(IdBodega, IdRepuesto, Cantidad)
    values(@IdBodega, @IdRepuesto, @Cantidad)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Inventario
    set
    IdBodega = isnull(@IdBodega, IdBodega),
    IdRepuesto = isnull(@IdRepuesto, IdRepuesto),
    Cantidad = isnull(@Cantidad, Cantidad)
    where IdInventario = @IdInventario
end
if @function = 3 -- borrar
begin
    delete from Inventario
    where IdInventario = @IdInventario

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Movimiento
create procedure MantenimientoMovimiento
(@function int, @IdMovimiento int = null, @IdRepuesto int = null, @IdBodegaOrigen int = null, @IdBodegaDestino int = null, @IdEmpleado int = null, @Tipo varchar(15) = null, @Cantidad int = null, @Fecha datetime = null)

as

if @function = 1 -- insert
begin
    insert into Movimiento(IdRepuesto, IdBodegaOrigen, IdBodegaDestino, IdEmpleado, Tipo, Cantidad, Fecha)
    values(@IdRepuesto, @IdBodegaOrigen, @IdBodegaDestino, @IdEmpleado, @Tipo, @Cantidad, isnull(@Fecha, getdate()))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Movimiento
    set
    IdRepuesto = isnull(@IdRepuesto, IdRepuesto),
    IdBodegaOrigen = isnull(@IdBodegaOrigen, IdBodegaOrigen),
    IdBodegaDestino = isnull(@IdBodegaDestino, IdBodegaDestino),
    IdEmpleado = isnull(@IdEmpleado, IdEmpleado),
    Tipo = isnull(@Tipo, Tipo),
    Cantidad = isnull(@Cantidad, Cantidad),
    Fecha = isnull(@Fecha, Fecha)
    where IdMovimiento = @IdMovimiento
end
if @function = 3 -- borrar
begin
    delete from Movimiento
    where IdMovimiento = @IdMovimiento

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Compra
create procedure MantenimientoCompra
(@function int, @IdCompra int = null, @IdProveedor int = null, @IdBodega int = null, @Fecha date = null, @FechaRecepcion date = null, @Total decimal(12,2) = null)

as

if @function = 1 -- insert
begin
    insert into Compra(IdProveedor, IdBodega, Fecha, FechaRecepcion, Total)
    values(@IdProveedor, @IdBodega, isnull(@Fecha, cast(getdate() as date)), @FechaRecepcion, isnull(@Total, 0))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Compra
    set
    IdProveedor = isnull(@IdProveedor, IdProveedor),
    IdBodega = isnull(@IdBodega, IdBodega),
    Fecha = isnull(@Fecha, Fecha),
    FechaRecepcion = isnull(@FechaRecepcion, FechaRecepcion),
    Total = isnull(@Total, Total)
    where IdCompra = @IdCompra
end
if @function = 3 -- borrar
begin
    delete from Compra
    where IdCompra = @IdCompra

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--DetalleCompra
create procedure MantenimientoDetalleCompra
(@function int, @IdDetalle int = null, @IdCompra int = null, @IdRepuesto int = null, @Cantidad int = null, @Costo decimal(10,2) = null)

as

if @function = 1 -- insert
begin
    insert into DetalleCompra(IdCompra, IdRepuesto, Cantidad, Costo)
    values(@IdCompra, @IdRepuesto, @Cantidad, @Costo)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update DetalleCompra
    set
    IdCompra = isnull(@IdCompra, IdCompra),
    IdRepuesto = isnull(@IdRepuesto, IdRepuesto),
    Cantidad = isnull(@Cantidad, Cantidad),
    Costo = isnull(@Costo, Costo)
    where IdDetalle = @IdDetalle
end
if @function = 3 -- borrar
begin
    delete from DetalleCompra
    where IdDetalle = @IdDetalle

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Incidencia
create procedure MantenimientoIncidencia
(@function int, @IdIncidencia int = null, @IdRepuesto int = null, @IdProveedor int = null, @IdCompra int = null, @Tipo varchar(20) = null, @Cantidad int = null, @Fecha datetime = null)

as

if @function = 1 -- insert
begin
    insert into Incidencia(IdRepuesto, IdProveedor, IdCompra, Tipo, Cantidad, Fecha)
    values(@IdRepuesto, @IdProveedor, @IdCompra, @Tipo, @Cantidad, isnull(@Fecha, getdate()))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Incidencia
    set
    IdRepuesto = isnull(@IdRepuesto, IdRepuesto),
    IdProveedor = isnull(@IdProveedor, IdProveedor),
    IdCompra = isnull(@IdCompra, IdCompra),
    Tipo = isnull(@Tipo, Tipo),
    Cantidad = isnull(@Cantidad, Cantidad),
    Fecha = isnull(@Fecha, Fecha)
    where IdIncidencia = @IdIncidencia
end
if @function = 3 -- borrar
begin
    delete from Incidencia
    where IdIncidencia = @IdIncidencia

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

-- Caso
create procedure MantenimientoCaso
(@function int, @IdCaso int = null, @IdAseguradora int = null, @IdModelo int = null, @Placa varchar(10) = null, @Estado varchar(20) = null, @FechaApertura datetime = null)

as

if @function = 1 -- insert
begin
    insert into Caso(IdAseguradora, IdModelo, Placa, Estado, FechaApertura)
    values(@IdAseguradora, @IdModelo, @Placa, @Estado, isnull(@FechaApertura, getdate()))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Caso
    set
    IdAseguradora = isnull(@IdAseguradora, IdAseguradora),
    IdModelo = isnull(@IdModelo, IdModelo),
    Placa = isnull(@Placa, Placa),
    Estado = isnull(@Estado, Estado),
    FechaApertura = isnull(@FechaApertura, FechaApertura)
    where IdCaso = @IdCaso
end
if @function = 3 -- borrar
begin
    delete from Caso
    where IdCaso = @IdCaso

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

-- Cotizacion
create procedure MantenimientoCotizacion
(@function int, @IdCotizacion int = null, @IdCaso int = null, @IdEmpleado int = null, @Fecha datetime = null, @Estado varchar(15) = null, @Total decimal(12,2) = null)

as

if @function = 1 -- insert
begin
    insert into Cotizacion(IdCaso, IdEmpleado, Fecha, Estado, Total)
    values(@IdCaso, @IdEmpleado, isnull(@Fecha, getdate()), @Estado, isnull(@Total, 0))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Cotizacion
    set
    IdCaso = isnull(@IdCaso, IdCaso),
    IdEmpleado = isnull(@IdEmpleado, IdEmpleado),
    Fecha = isnull(@Fecha, Fecha),
    Estado = isnull(@Estado, Estado),
    Total = isnull(@Total, Total)
    where IdCotizacion = @IdCotizacion
end
if @function = 3 -- borrar
begin
    delete from Cotizacion
    where IdCotizacion = @IdCotizacion

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

-- DetalleCotizacion
create procedure MantenimientoDetalleCotizacion
(@function int, @IdDetalle int = null, @IdCotizacion int = null, @IdRepuesto int = null, @Cantidad int = null, @Precio decimal(10,2) = null, @Estado varchar(15) = null)

as

if @function = 1 -- insert
begin
    insert into DetalleCotizacion(IdCotizacion, IdRepuesto, Cantidad, Precio, Estado)
    values(@IdCotizacion, @IdRepuesto, @Cantidad, @Precio, @Estado)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update DetalleCotizacion
    set
    IdCotizacion = isnull(@IdCotizacion, IdCotizacion),
    IdRepuesto = isnull(@IdRepuesto, IdRepuesto),
    Cantidad = isnull(@Cantidad, Cantidad),
    Precio = isnull(@Precio, Precio),
    Estado = isnull(@Estado, Estado)
    where IdDetalle = @IdDetalle
end
if @function = 3 -- borrar
begin
    delete from DetalleCotizacion
    where IdDetalle = @IdDetalle

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Venta
create procedure MantenimientoVenta
(@function int, @IdVenta int = null, @IdCotizacion int = null, @IdEmpleado int = null, @Fecha datetime = null, @Total decimal(12,2) = null)

as

if @function = 1 -- insert
begin
    insert into Venta(IdCotizacion, IdEmpleado, Fecha, Total)
    values(@IdCotizacion, @IdEmpleado, isnull(@Fecha, getdate()), isnull(@Total, 0))
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Venta
    set
    IdCotizacion = isnull(@IdCotizacion, IdCotizacion),
    IdEmpleado = isnull(@IdEmpleado, IdEmpleado),
    Fecha = isnull(@Fecha, Fecha),
    Total = isnull(@Total, Total)
    where IdVenta = @IdVenta
end
if @function = 3 -- borrar
begin
    delete from Venta
    where IdVenta = @IdVenta

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--DetalleVenta
create procedure MantenimientoDetalleVenta
(@function int, @IdDetalle int = null, @IdVenta int = null, @IdRepuesto int = null, @IdBodega int = null, @Cantidad int = null, @Precio decimal(10,2) = null, @Costo decimal(10,2) = null)

as

if @function = 1 -- insert
begin
    insert into DetalleVenta(IdVenta, IdRepuesto, IdBodega, Cantidad, Precio, Costo)
    values(@IdVenta, @IdRepuesto, @IdBodega, @Cantidad, @Precio, @Costo)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update DetalleVenta
    set
    IdVenta = isnull(@IdVenta, IdVenta),
    IdRepuesto = isnull(@IdRepuesto, IdRepuesto),
    IdBodega = isnull(@IdBodega, IdBodega),
    Cantidad = isnull(@Cantidad, Cantidad),
    Precio = isnull(@Precio, Precio),
    Costo = isnull(@Costo, Costo)
    where IdDetalle = @IdDetalle
end
if @function = 3 -- borrar
begin
    delete from DetalleVenta
    where IdDetalle = @IdDetalle

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go

--Envio
create procedure MantenimientoEnvio
(@function int, @IdEnvio int = null, @IdVenta int = null, @Direccion nvarchar(200) = null, @Costo decimal(10,2) = null, @Estado varchar(15) = null, @FechaEntrega datetime = null)

as

if @function = 1 -- insert
begin
    insert into Envio(IdVenta, Direccion, Costo, Estado, FechaEntrega)
    values(@IdVenta, @Direccion, @Costo, @Estado, @FechaEntrega)
end
if @function = 2 -- update (si el parametro viene nulo se mantiene el dato actual)
begin
    update Envio
    set
    IdVenta = isnull(@IdVenta, IdVenta),
    Direccion = isnull(@Direccion, Direccion),
    Costo = isnull(@Costo, Costo),
    Estado = isnull(@Estado, Estado),
    FechaEntrega = isnull(@FechaEntrega, FechaEntrega)
    where IdEnvio = @IdEnvio
end
if @function = 3 -- borrar
begin
    delete from Envio
    where IdEnvio = @IdEnvio

    if @@ERROR <> 0 or @@ROWCOUNT = 0 begin
        raiserror('Error, el borrado no encontro dato o fallo',16,1)
        return -1
    end
end
go