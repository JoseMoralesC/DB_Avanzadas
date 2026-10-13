USE RepuestosAutomotrices;
GO

-- Rechazar inconsistencias existentes antes de agregar restricciones.
IF EXISTS (SELECT IdUsuario FROM dbo.Empleado GROUP BY IdUsuario HAVING COUNT(*) > 1)
    OR EXISTS (SELECT IdUsuario FROM dbo.Aseguradora GROUP BY IdUsuario HAVING COUNT(*) > 1)
    OR EXISTS (SELECT 1 FROM dbo.Empleado e JOIN dbo.Aseguradora a ON a.IdUsuario = e.IdUsuario)
    THROW 50041, 'Existen perfiles duplicados; revisar antes de aplicar integridad.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_Empleado_Usuario' AND parent_object_id = OBJECT_ID('dbo.Empleado'))
    ALTER TABLE dbo.Empleado ADD CONSTRAINT UQ_Empleado_Usuario UNIQUE (IdUsuario);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_Aseguradora_Usuario' AND parent_object_id = OBJECT_ID('dbo.Aseguradora'))
    ALTER TABLE dbo.Aseguradora ADD CONSTRAINT UQ_Aseguradora_Usuario UNIQUE (IdUsuario);
GO

CREATE OR ALTER TRIGGER dbo.TR_Usuario_ValidarPerfil
ON dbo.Usuario AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted u JOIN dbo.Rol r ON r.IdRol = u.IdRol
        WHERE (r.Nombre = 'Cliente' AND EXISTS (SELECT 1 FROM dbo.Empleado e WHERE e.IdUsuario = u.IdUsuario))
           OR (r.Nombre <> 'Cliente' AND EXISTS (SELECT 1 FROM dbo.Aseguradora a WHERE a.IdUsuario = u.IdUsuario)))
        THROW 50042, 'El cambio de rol es incompatible con el perfil existente.', 1;
END;
GO

-- Un detalle recibido pertenece a una bodega: no mover la cabecera sin su stock.
CREATE OR ALTER TRIGGER dbo.TR_Compra_ValidarBodega
ON dbo.Compra AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.IdCompra = i.IdCompra
        WHERE i.IdBodega <> d.IdBodega
          AND EXISTS (SELECT 1 FROM dbo.DetalleCompra dc WHERE dc.IdCompra = i.IdCompra))
        THROW 50043, 'Una compra con detalles no puede cambiar de bodega; utilice un traslado.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.MantenimientoRepuestoModelo
    @function INT, @IdRepuesto INT = NULL, @IdModelo INT = NULL,
    @NuevoIdRepuesto INT = NULL, @NuevoIdModelo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @function = 1
        INSERT dbo.RepuestoModelo(IdRepuesto, IdModelo) VALUES (@IdRepuesto, @IdModelo);
    ELSE IF @function = 2
    BEGIN
        UPDATE dbo.RepuestoModelo SET IdRepuesto = COALESCE(@NuevoIdRepuesto, IdRepuesto),
            IdModelo = COALESCE(@NuevoIdModelo, IdModelo)
        WHERE IdRepuesto = @IdRepuesto AND IdModelo = @IdModelo;
        IF @@ROWCOUNT = 0 THROW 50044, 'La compatibilidad no existe.', 1;
    END
    ELSE IF @function = 3
    BEGIN
        DELETE dbo.RepuestoModelo WHERE IdRepuesto = @IdRepuesto AND IdModelo = @IdModelo;
        IF @@ROWCOUNT = 0 THROW 50044, 'La compatibilidad no existe.', 1;
    END
    ELSE THROW 50045, 'function debe ser 1, 2 o 3.', 1;
END;
GO
