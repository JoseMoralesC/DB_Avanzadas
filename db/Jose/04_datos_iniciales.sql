-- Datos ficticios para el laboratorio. Ejecutar sobre RepuestosAutomotrices.
-- Solo inserta registros faltantes: no cambia usuarios, precios o saldos existentes.
USE RepuestosAutomotrices;
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Bloqueo INT;
    EXEC @Bloqueo = sys.sp_getapplock @Resource = N'Repuestos.DatosIniciales.Catalogo',
        @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
    IF @Bloqueo < 0 THROW 50030, 'No se pudo bloquear la carga inicial.', 1;

    INSERT dbo.Categoria(Nombre)
    SELECT s.Nombre FROM (VALUES (N'Iluminacion'), (N'Carroceria'), (N'Mecanica')) s(Nombre)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Categoria c WHERE c.Nombre = s.Nombre);

    INSERT dbo.Marca(Nombre)
    SELECT s.Nombre FROM (VALUES (N'Toyota'), (N'Hyundai'), (N'Nissan')) s(Nombre)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Marca m WHERE m.Nombre = s.Nombre);

    DECLARE @Modelos TABLE (Marca NVARCHAR(50), Nombre NVARCHAR(60), AnioInicio INT, AnioFin INT);
    INSERT @Modelos VALUES
        (N'Toyota', N'Corolla', 2014, 2019), (N'Toyota', N'Hilux', 2016, 2024),
        (N'Hyundai', N'Accent', 2018, 2023), (N'Hyundai', N'Tucson', 2016, 2021),
        (N'Nissan', N'Sentra', 2013, 2019), (N'Nissan', N'Frontier', 2016, 2024);
    INSERT dbo.Modelo(IdMarca, Nombre, AnioInicio, AnioFin)
    SELECT m.IdMarca, s.Nombre, s.AnioInicio, s.AnioFin
    FROM @Modelos s JOIN dbo.Marca m ON m.Nombre = s.Marca
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Modelo x
        WHERE x.IdMarca = m.IdMarca AND x.Nombre = s.Nombre AND x.AnioInicio = s.AnioInicio);

    DECLARE @Repuestos TABLE (Codigo VARCHAR(30), Categoria NVARCHAR(60), Nombre NVARCHAR(120),
        PrecioVenta DECIMAL(10,2), Costo DECIMAL(10,2), Modelo NVARCHAR(60));
    INSERT @Repuestos VALUES
        ('INI-FAR-001', N'Iluminacion', N'Farol delantero derecho Corolla', 85000, 55000, N'Corolla'),
        ('INI-FAR-002', N'Iluminacion', N'Farol delantero izquierdo Accent', 78000, 49000, N'Accent'),
        ('INI-FAR-003', N'Iluminacion', N'Farol trasero derecho Sentra', 62000, 39000, N'Sentra'),
        ('INI-BUM-001', N'Carroceria', N'Bumper delantero Hilux', 145000, 97000, N'Hilux'),
        ('INI-BUM-002', N'Carroceria', N'Bumper delantero Tucson', 132000, 88000, N'Tucson'),
        ('INI-GUA-001', N'Carroceria', N'Guardabarro izquierdo Frontier', 95000, 61000, N'Frontier'),
        ('INI-FRE-001', N'Mecanica', N'Juego de pastillas de freno Corolla', 28000, 16500, N'Corolla'),
        ('INI-RAD-001', N'Mecanica', N'Radiador Accent', 115000, 74000, N'Accent'),
        ('INI-AMO-001', N'Mecanica', N'Amortiguador delantero Sentra', 54000, 33500, N'Sentra');
    INSERT dbo.Repuesto(IdCategoria, Codigo, Nombre, PrecioVenta, Costo, Activo)
    SELECT c.IdCategoria, s.Codigo, s.Nombre, s.PrecioVenta, s.Costo, 1
    FROM @Repuestos s JOIN dbo.Categoria c ON c.Nombre = s.Categoria
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Repuesto r WHERE r.Codigo = s.Codigo);

    INSERT dbo.RepuestoModelo(IdRepuesto, IdModelo)
    SELECT r.IdRepuesto, m.IdModelo
    FROM @Repuestos s JOIN dbo.Repuesto r ON r.Codigo = s.Codigo
    JOIN @Modelos sm ON sm.Nombre = s.Modelo
    JOIN dbo.Marca marca ON marca.Nombre = sm.Marca
    JOIN dbo.Modelo m ON m.IdMarca = marca.IdMarca AND m.Nombre = sm.Nombre AND m.AnioInicio = sm.AnioInicio
    WHERE NOT EXISTS (SELECT 1 FROM dbo.RepuestoModelo rm
        WHERE rm.IdRepuesto = r.IdRepuesto AND rm.IdModelo = m.IdModelo);

    INSERT dbo.Bodega(Nombre, Ubicacion)
    SELECT s.Nombre, s.Ubicacion FROM (VALUES
        (N'Bodega Central Demo', N'San Jose - ubicacion de prueba'),
        (N'Bodega Heredia Demo', N'Heredia - ubicacion de prueba'),
        (N'Bodega Alajuela Demo', N'Alajuela - ubicacion de prueba')) s(Nombre, Ubicacion)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Bodega b WHERE b.Nombre = s.Nombre);

    -- Saldos de apertura. No registrar ademas una compra o entrada por estas unidades.
    DECLARE @Saldos TABLE (Codigo VARCHAR(30), Bodega NVARCHAR(60), Cantidad INT);
    INSERT @Saldos VALUES
        ('INI-FAR-001', N'Bodega Central Demo', 12), ('INI-FAR-001', N'Bodega Heredia Demo', 4),
        ('INI-FAR-002', N'Bodega Central Demo', 8), ('INI-FAR-003', N'Bodega Alajuela Demo', 6),
        ('INI-BUM-001', N'Bodega Central Demo', 5), ('INI-BUM-002', N'Bodega Heredia Demo', 3),
        ('INI-GUA-001', N'Bodega Alajuela Demo', 4), ('INI-FRE-001', N'Bodega Central Demo', 20),
        ('INI-FRE-001', N'Bodega Heredia Demo', 10), ('INI-RAD-001', N'Bodega Central Demo', 0),
        ('INI-AMO-001', N'Bodega Alajuela Demo', 7), ('INI-AMO-001', N'Bodega Heredia Demo', 2);
    INSERT dbo.Inventario(IdBodega, IdRepuesto, Cantidad)
    SELECT b.IdBodega, r.IdRepuesto, s.Cantidad
    FROM @Saldos s JOIN dbo.Bodega b ON b.Nombre = s.Bodega
    JOIN dbo.Repuesto r ON r.Codigo = s.Codigo
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Inventario i
        WHERE i.IdBodega = b.IdBodega AND i.IdRepuesto = r.IdRepuesto);

    INSERT dbo.Proveedor(Nombre, Telefono, Correo, DiasEntrega)
    SELECT s.Nombre, s.Telefono, s.Correo, s.DiasEntrega FROM (VALUES
        (N'Autopartes Central Demo', '00000001', 'central@proveedor.example', 3),
        (N'Importadora Pacifico Demo', '00000002', 'pacifico@proveedor.example', 5),
        (N'Repuestos Norte Demo', '00000003', 'norte@proveedor.example', 2)) s(Nombre, Telefono, Correo, DiasEntrega)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Proveedor p WHERE p.Nombre = s.Nombre);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
