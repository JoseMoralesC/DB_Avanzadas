-- @HashDemo es un parametro PasswordHasher generado por la utilidad SqlTools.
-- Cuentas nuevas inactivas; no cambia claves ni perfiles de usuarios existentes.
USE RepuestosAutomotrices;
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Lock INT;
    EXEC @Lock = sys.sp_getapplock @Resource = N'Repuestos.DatosPrueba.Integrales',
        @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
    IF @Lock < 0 THROW 50046, 'No se pudo bloquear la carga de prueba.', 1;
    IF @HashDemo IS NULL OR LEN(@HashDemo) < 80 THROW 50047, 'Falta el hash de las cuentas de prueba.', 1;

    INSERT dbo.Rol(Nombre) SELECT v.Nombre FROM (VALUES ('Administrador'), ('Empleado'), ('Cliente')) v(Nombre)
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Rol r WHERE r.Nombre = v.Nombre);
    DECLARE @Cliente INT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = 'Cliente');
    DECLARE @N INT = 1, @Correo VARCHAR(100), @Cedula VARCHAR(20), @Usuario INT;
    DECLARE @RolEmpleado INT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = 'Empleado');
    WHILE (SELECT COUNT(*) FROM dbo.Empleado) < 3
    BEGIN
        SET @Correo = CONCAT('consigna-empleado-', @N, '@example.invalid');
        SET @Cedula = CONCAT('CONSIGNA-E-', @N);
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Correo = @Correo)
            INSERT dbo.Usuario(IdRol, Correo, Contrasena, Activo) VALUES (@RolEmpleado, @Correo, @HashDemo, 0);
        SET @Usuario = NULL;
        SELECT @Usuario = IdUsuario FROM dbo.Usuario WHERE Correo = @Correo AND IdRol = @RolEmpleado;
        IF @Usuario IS NULL THROW 50048, 'La cuenta demo existente tiene otro rol.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE IdUsuario = @Usuario)
            INSERT dbo.Empleado(IdUsuario, Cedula, Nombre, Puesto)
                VALUES (@Usuario, @Cedula, CONCAT(N'Empleado Consigna Demo ', @N), N'Pruebas');
        SET @N += 1;
    END;
    SET @N = 1;
    WHILE (SELECT COUNT(*) FROM dbo.Aseguradora) < 3
    BEGIN
        SET @Correo = CONCAT('consigna-cliente-', @N, '@example.invalid');
        SET @Cedula = CONCAT('CONSIGNA-A-', @N);
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Correo = @Correo)
            INSERT dbo.Usuario(IdRol, Correo, Contrasena, Activo) VALUES (@Cliente, @Correo, @HashDemo, 0);
        SET @Usuario = NULL;
        SELECT @Usuario = IdUsuario FROM dbo.Usuario WHERE Correo = @Correo AND IdRol = @Cliente;
        IF @Usuario IS NULL THROW 50048, 'La cuenta demo existente tiene otro rol.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Aseguradora WHERE IdUsuario = @Usuario)
            INSERT dbo.Aseguradora(IdUsuario, CedulaJuridica, Nombre, Correo)
            VALUES (@Usuario, @Cedula, CONCAT(N'Aseguradora Consigna Demo ', @N), @Correo);
        SET @N += 1;
    END;

    DECLARE @Bodega INT = (SELECT MIN(IdBodega) FROM dbo.Bodega),
        @Destino INT, @Proveedor INT = (SELECT MIN(IdProveedor) FROM dbo.Proveedor),
        @Repuesto INT = (SELECT MIN(IdRepuesto) FROM dbo.Repuesto WHERE Activo = 1),
        @Empleado INT = (SELECT MIN(IdEmpleado) FROM dbo.Empleado),
        @Aseguradora INT = (SELECT MIN(IdAseguradora) FROM dbo.Aseguradora WHERE CedulaJuridica LIKE 'CONSIGNA-A-%'),
        @Modelo INT = (SELECT MIN(IdModelo) FROM dbo.Modelo);
    SELECT @Destino = MIN(IdBodega) FROM dbo.Bodega WHERE IdBodega <> @Bodega;
    SET @Aseguradora = COALESCE(@Aseguradora, (SELECT MIN(IdAseguradora) FROM dbo.Aseguradora));
    IF @Destino IS NULL OR @Repuesto IS NULL OR @Empleado IS NULL OR @Proveedor IS NULL OR @Modelo IS NULL
        THROW 50049, 'Faltan datos base para la carga integral.', 1;

    DECLARE @Costo DECIMAL(10,2), @Precio DECIMAL(10,2), @Fecha DATETIME,
        @Compra INT, @Caso INT, @Cotizacion INT, @Venta INT, @Placa VARCHAR(10);
    SELECT @Costo = Costo, @Precio = PrecioVenta FROM dbo.Repuesto WHERE IdRepuesto = @Repuesto;
    SET @N = 1;
    WHILE @N <= 3
    BEGIN
        SET @Fecha = DATEADD(DAY, @N - 1, CONVERT(DATETIME, '20261001', 112));
        SET @Placa = CONCAT('DEMO00', @N);
        -- La compra ya recibida agrega 5 unidades nuevas, distintas del saldo de apertura.
        SELECT @Compra = MIN(IdCompra) FROM dbo.Compra WHERE IdProveedor = @Proveedor
            AND IdBodega = @Bodega AND Fecha = CONVERT(DATE, @Fecha) AND FechaRecepcion = CONVERT(DATE, @Fecha);
        IF @Compra IS NULL
        BEGIN
            INSERT dbo.Compra(IdProveedor, IdBodega, Fecha, FechaRecepcion)
                VALUES (@Proveedor, @Bodega, @Fecha, @Fecha);
            SET @Compra = SCOPE_IDENTITY();
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.DetalleCompra WHERE IdCompra = @Compra AND IdRepuesto = @Repuesto)
            INSERT dbo.DetalleCompra(IdCompra, IdRepuesto, Cantidad, Costo) VALUES (@Compra, @Repuesto, 5, @Costo);

        SELECT @Caso = MIN(IdCaso) FROM dbo.Caso WHERE Placa = @Placa AND IdAseguradora = @Aseguradora;
        IF @Caso IS NULL
        BEGIN
            INSERT dbo.Caso(IdAseguradora, IdModelo, Placa, Estado, FechaApertura)
                VALUES (@Aseguradora, @Modelo, @Placa, 'En proceso', @Fecha);
            SET @Caso = SCOPE_IDENTITY();
        END;
        SELECT @Cotizacion = MIN(IdCotizacion) FROM dbo.Cotizacion WHERE IdCaso = @Caso AND Fecha = @Fecha;
        IF @Cotizacion IS NULL
        BEGIN
            INSERT dbo.Cotizacion(IdCaso, IdEmpleado, Fecha, Estado) VALUES (@Caso, @Empleado, @Fecha, 'Aprobada');
            SET @Cotizacion = SCOPE_IDENTITY();
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.DetalleCotizacion WHERE IdCotizacion = @Cotizacion AND IdRepuesto = @Repuesto)
            INSERT dbo.DetalleCotizacion(IdCotizacion, IdRepuesto, Cantidad, Precio, Estado)
                VALUES (@Cotizacion, @Repuesto, 1, @Precio, 'Aprobado');

        SELECT @Venta = MIN(IdVenta) FROM dbo.Venta WHERE IdCotizacion = @Cotizacion AND Fecha = @Fecha;
        IF @Venta IS NULL
        BEGIN
            INSERT dbo.Venta(IdCotizacion, IdEmpleado, Fecha) VALUES (@Cotizacion, @Empleado, @Fecha);
            SET @Venta = SCOPE_IDENTITY();
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.DetalleVenta WHERE IdVenta = @Venta AND IdRepuesto = @Repuesto)
            INSERT dbo.DetalleVenta(IdVenta, IdRepuesto, IdBodega, Cantidad, Precio, Costo)
                VALUES (@Venta, @Repuesto, @Bodega, 1, @Precio, @Costo);
        IF NOT EXISTS (SELECT 1 FROM dbo.Envio WHERE IdVenta = @Venta)
            INSERT dbo.Envio(IdVenta, Direccion, Costo, Estado)
                VALUES (@Venta, N'Direccion ficticia Consigna Demo', 1500, 'Pendiente');

        -- El traslado mueve una unidad: no repite la entrada de la compra.
        IF NOT EXISTS (SELECT 1 FROM dbo.Movimiento WHERE IdRepuesto = @Repuesto AND Tipo = 'Traslado'
            AND IdBodegaOrigen = @Bodega AND IdBodegaDestino = @Destino AND Fecha = @Fecha)
            INSERT dbo.Movimiento(IdRepuesto, IdBodegaOrigen, IdBodegaDestino, IdEmpleado, Tipo, Cantidad, Fecha)
                VALUES (@Repuesto, @Bodega, @Destino, @Empleado, 'Traslado', 1, @Fecha);
        IF NOT EXISTS (SELECT 1 FROM dbo.Incidencia WHERE IdCompra = @Compra AND IdRepuesto = @Repuesto AND Fecha = @Fecha)
            INSERT dbo.Incidencia(IdRepuesto, IdProveedor, IdCompra, Tipo, Cantidad, Fecha)
                VALUES (@Repuesto, @Proveedor, @Compra, 'Rechazado', 1, @Fecha);
        SET @N += 1;
    END;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
