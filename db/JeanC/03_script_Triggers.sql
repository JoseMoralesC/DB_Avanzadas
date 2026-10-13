/* 
   TI-156 Bases de Datos Avanzadas - III Cuatrimestre 2026
   Proyecto 1: Sistema de repuestos automotrices para aseguradoras
   Triggers 

 
*/

use RepuestosAutomotrices
go

--INVENTARIO
   

--Compras: suman existencias en la bodega de la compra
create trigger TR_DetalleCompra_Inventario
on DetalleCompra
after insert, update, delete
as
begin
    set nocount on

    declare @Cambios table (IdBodega int, IdRepuesto int, Cantidad int)

    insert into @Cambios (IdBodega, IdRepuesto, Cantidad)
    select x.IdBodega, x.IdRepuesto, sum(x.Cantidad)
    from (
        select c.IdBodega, i.IdRepuesto, i.Cantidad          -- lo nuevo suma
        from inserted i
        join Compra c on c.IdCompra = i.IdCompra
        union all
        select c.IdBodega, d.IdRepuesto, -d.Cantidad         -- lo anterior se revierte
        from deleted d
        join Compra c on c.IdCompra = d.IdCompra
    ) x
    group by x.IdBodega, x.IdRepuesto
    having sum(x.Cantidad) <> 0

    -- validar que ninguna existencia quede negativa
    if exists (
        select 1
        from @Cambios ca
        left join Inventario inv on inv.IdBodega = ca.IdBodega and inv.IdRepuesto = ca.IdRepuesto
        where isnull(inv.Cantidad, 0) + ca.Cantidad < 0
    )
    begin
        raiserror('Error, la operacion deja existencias negativas en inventario',16,1)
        rollback transaction
        return
    end

    -- actualizar existencias que ya existen
    update inv
    set inv.Cantidad = inv.Cantidad + ca.Cantidad
    from Inventario inv
    join @Cambios ca on ca.IdBodega = inv.IdBodega and ca.IdRepuesto = inv.IdRepuesto

    -- crear la fila si el repuesto no existia en esa bodega
    insert into Inventario (IdBodega, IdRepuesto, Cantidad)
    select ca.IdBodega, ca.IdRepuesto, ca.Cantidad
    from @Cambios ca
    where not exists (select 1 from Inventario inv
                      where inv.IdBodega = ca.IdBodega and inv.IdRepuesto = ca.IdRepuesto)
end
go

-- Ventas: restan existencias de la bodega indicada en el detalle
create trigger TR_DetalleVenta_Inventario
on DetalleVenta
after insert, update, delete
as
begin
    set nocount on

    declare @Cambios table (IdBodega int, IdRepuesto int, Cantidad int)

    insert into @Cambios (IdBodega, IdRepuesto, Cantidad)
    select x.IdBodega, x.IdRepuesto, sum(x.Cantidad)
    from (
        select i.IdBodega, i.IdRepuesto, -i.Cantidad as Cantidad   -- lo vendido resta
        from inserted i
        union all
        select d.IdBodega, d.IdRepuesto, d.Cantidad          -- lo anterior se devuelve
        from deleted d
    ) x
    group by x.IdBodega, x.IdRepuesto
    having sum(x.Cantidad) <> 0

    if exists (
        select 1
        from @Cambios ca
        left join Inventario inv on inv.IdBodega = ca.IdBodega and inv.IdRepuesto = ca.IdRepuesto
        where isnull(inv.Cantidad, 0) + ca.Cantidad < 0
    )
    begin
        raiserror('Error, no hay existencia suficiente en la bodega para la venta',16,1)
        rollback transaction
        return
    end

    update inv
    set inv.Cantidad = inv.Cantidad + ca.Cantidad
    from Inventario inv
    join @Cambios ca on ca.IdBodega = inv.IdBodega and ca.IdRepuesto = inv.IdRepuesto

    insert into Inventario (IdBodega, IdRepuesto, Cantidad)
    select ca.IdBodega, ca.IdRepuesto, ca.Cantidad
    from @Cambios ca
    where not exists (select 1 from Inventario inv
                      where inv.IdBodega = ca.IdBodega and inv.IdRepuesto = ca.IdRepuesto)
end
go

--Movimientos: Entrada suma al destino, Salida resta del origen,
--     Traslado resta del origen y suma al destino
create trigger TR_Movimiento_Inventario
on Movimiento
after insert, update, delete
as
begin
    set nocount on

    declare @Cambios table (IdBodega int, IdRepuesto int, Cantidad int)

    insert into @Cambios (IdBodega, IdRepuesto, Cantidad)
    select x.IdBodega, x.IdRepuesto, sum(x.Cantidad)
    from (
        -- movimiento nuevo
        select i.IdBodegaDestino as IdBodega, i.IdRepuesto,  i.Cantidad as Cantidad
        from inserted i where i.IdBodegaDestino is not null
        union all
        select i.IdBodegaOrigen,  i.IdRepuesto, -i.Cantidad
        from inserted i where i.IdBodegaOrigen is not null
        union all
        -- movimiento anterior (se revierte)
        select d.IdBodegaDestino, d.IdRepuesto, -d.Cantidad
        from deleted d where d.IdBodegaDestino is not null
        union all
        select d.IdBodegaOrigen,  d.IdRepuesto,  d.Cantidad
        from deleted d where d.IdBodegaOrigen is not null
    ) x
    group by x.IdBodega, x.IdRepuesto
    having sum(x.Cantidad) <> 0

    if exists (
        select 1
        from @Cambios ca
        left join Inventario inv on inv.IdBodega = ca.IdBodega and inv.IdRepuesto = ca.IdRepuesto
        where isnull(inv.Cantidad, 0) + ca.Cantidad < 0
    )
    begin
        raiserror('Error, no hay existencia suficiente en la bodega de origen',16,1)
        rollback transaction
        return
    end

    update inv
    set inv.Cantidad = inv.Cantidad + ca.Cantidad
    from Inventario inv
    join @Cambios ca on ca.IdBodega = inv.IdBodega and ca.IdRepuesto = inv.IdRepuesto

    insert into Inventario (IdBodega, IdRepuesto, Cantidad)
    select ca.IdBodega, ca.IdRepuesto, ca.Cantidad
    from @Cambios ca
    where not exists (select 1 from Inventario inv
                      where inv.IdBodega = ca.IdBodega and inv.IdRepuesto = ca.IdRepuesto)
end
go

--TOTALES
  

--Compra.Total = suma(Cantidad * Costo)
create trigger TR_DetalleCompra_Total
on DetalleCompra
after insert, update, delete
as
begin
    set nocount on

    update c
    set c.Total = isnull((select sum(dc.Cantidad * dc.Costo)
                          from DetalleCompra dc
                          where dc.IdCompra = c.IdCompra), 0)
    from Compra c
    where c.IdCompra in (select IdCompra from inserted
                         union
                         select IdCompra from deleted)
end
go

--Cotizacion.Total = suma(Cantidad * Precio)
create trigger TR_DetalleCotizacion_Total
on DetalleCotizacion
after insert, update, delete
as
begin
    set nocount on

    update co
    set co.Total = isnull((select sum(dc.Cantidad * dc.Precio)
                           from DetalleCotizacion dc
                           where dc.IdCotizacion = co.IdCotizacion), 0)
    from Cotizacion co
    where co.IdCotizacion in (select IdCotizacion from inserted
                              union
                              select IdCotizacion from deleted)
end
go

--Venta.Total = suma(Cantidad * Precio)
create trigger TR_DetalleVenta_Total
on DetalleVenta
after insert, update, delete
as
begin
    set nocount on

    update v
    set v.Total = isnull((select sum(dv.Cantidad * dv.Precio)
                          from DetalleVenta dv
                          where dv.IdVenta = v.IdVenta), 0)
    from Venta v
    where v.IdVenta in (select IdVenta from inserted
                        union
                        select IdVenta from deleted)
end
go

--AUDITORIA
  

--Repuesto
create trigger TR_Repuesto_Auditoria
on Repuesto
after insert, update, delete
as
begin
    set nocount on

    declare @Accion char(1)

    if exists (select 1 from inserted) and exists (select 1 from deleted)
        set @Accion = 'U'
    else if exists (select 1 from inserted)
        set @Accion = 'I'
    else if exists (select 1 from deleted)
        set @Accion = 'D'
    else
        return  -- la operacion no afecto filas

    insert into Auditoria (Tabla, Accion, Usuario, Fecha)
    values ('Repuesto', @Accion, suser_sname(), getdate())
end
go

--Usuario
create trigger TR_Usuario_Auditoria
on Usuario
after insert, update, delete
as
begin
    set nocount on

    declare @Accion char(1)

    if exists (select 1 from inserted) and exists (select 1 from deleted)
        set @Accion = 'U'
    else if exists (select 1 from inserted)
        set @Accion = 'I'
    else if exists (select 1 from deleted)
        set @Accion = 'D'
    else
        return

    insert into Auditoria (Tabla, Accion, Usuario, Fecha)
    values ('Usuario', @Accion, suser_sname(), getdate())
end
go

--Inventario 
create trigger TR_Inventario_Auditoria
on Inventario
after insert, update, delete
as
begin
    set nocount on

    declare @Accion char(1)

    if exists (select 1 from inserted) and exists (select 1 from deleted)
        set @Accion = 'U'
    else if exists (select 1 from inserted)
        set @Accion = 'I'
    else if exists (select 1 from deleted)
        set @Accion = 'D'
    else
        return

    insert into Auditoria (Tabla, Accion, Usuario, Fecha)
    values ('Inventario', @Accion, suser_sname(), getdate())
end
go

--VALIDACION DE ROL
 --Empleado    -> el usuario debe tener rol 'Administrador' o 'Empleado'
 --Aseguradora -> el usuario debe tener rol 'Cliente'
  

--Empleado
create trigger TR_Empleado_ValidarRol
on Empleado
after insert, update
as
begin
    set nocount on

    if exists (
        select 1
        from inserted i
        join Usuario u on u.IdUsuario = i.IdUsuario
        join Rol r     on r.IdRol     = u.IdRol
        where r.Nombre not in ('Administrador', 'Empleado')
    )
    begin
        raiserror('Error, el usuario asignado al empleado debe tener rol Administrador o Empleado',16,1)
        rollback transaction
        return
    end
end
go

--Aseguradora
create trigger TR_Aseguradora_ValidarRol
on Aseguradora
after insert, update
as
begin
    set nocount on

    if exists (
        select 1
        from inserted i
        join Usuario u on u.IdUsuario = i.IdUsuario
        join Rol r     on r.IdRol     = u.IdRol
        where r.Nombre <> 'Cliente'
    )
    begin
        raiserror('Error, el usuario asignado a la aseguradora debe tener rol Cliente',16,1)
        rollback transaction
        return
    end
end
go