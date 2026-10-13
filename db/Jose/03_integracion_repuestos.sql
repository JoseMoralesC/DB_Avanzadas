USE RepuestosAutomotrices;
GO

IF OBJECT_ID(N'dbo.SecuenciaCodigoRepuesto', N'SO') IS NULL
    EXEC(N'CREATE SEQUENCE dbo.SecuenciaCodigoRepuesto AS BIGINT START WITH 1 INCREMENT BY 1 NO CYCLE;');
GO

-- Adapta el mantenimiento de Jean Carlo sin modificar sus scripts.
CREATE OR ALTER PROCEDURE dbo.GuardarRepuestoApp
    @IdCategoria INT,
    @Codigo VARCHAR(30) = NULL,
    @Nombre NVARCHAR(120),
    @PrecioVenta DECIMAL(10,2),
    @Costo DECIMAL(10,2),
    @Activo BIT,
    @IdRepuesto INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Nombre)), '') IS NULL
        THROW 50003, 'El nombre es obligatorio.', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @IdRepuesto IS NULL
        BEGIN
            DECLARE @Numero BIGINT;
            -- La secuencia asigna numeros distintos incluso entre sesiones simultaneas.
            -- Se omiten codigos que hayan sido cargados previamente por otra via.
            WHILE 1 = 1
            BEGIN
                SET @Numero = NEXT VALUE FOR dbo.SecuenciaCodigoRepuesto;
                SET @Codigo = 'REP-' + CASE WHEN @Numero < 1000000
                    THEN RIGHT('000000' + CONVERT(VARCHAR(20), @Numero), 6)
                    ELSE CONVERT(VARCHAR(20), @Numero) END;
                IF NOT EXISTS (SELECT 1 FROM dbo.Repuesto WHERE Codigo = @Codigo) BREAK;
            END;
            EXEC dbo.MantenimientoRepuesto @function = 1, @IdCategoria = @IdCategoria,
                @Codigo = @Codigo, @Nombre = @Nombre, @PrecioVenta = @PrecioVenta, @Costo = @Costo, @Activo = @Activo;
            -- El codigo es unico; se recupera dentro de la misma transaccion.
            SELECT @IdRepuesto = IdRepuesto FROM dbo.Repuesto WHERE Codigo = @Codigo;
        END
        ELSE
        BEGIN
            SET @Codigo = NULL;
            SELECT @Codigo = Codigo FROM dbo.Repuesto WITH (UPDLOCK, HOLDLOCK) WHERE IdRepuesto = @IdRepuesto;
            IF @Codigo IS NULL
                THROW 50004, 'El repuesto no existe.', 1;
            EXEC dbo.MantenimientoRepuesto @function = 2, @IdRepuesto = @IdRepuesto,
                @IdCategoria = @IdCategoria, @Codigo = @Codigo, @Nombre = @Nombre,
                @PrecioVenta = @PrecioVenta, @Costo = @Costo, @Activo = @Activo;
        END;
        COMMIT TRANSACTION;
        SELECT @IdRepuesto AS IdRepuesto;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
