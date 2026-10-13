USE RepuestosAutomotrices;
GO

CREATE OR ALTER PROCEDURE dbo.ConsultarCategorias AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdCategoria AS Id, Nombre FROM dbo.Categoria ORDER BY Nombre;
END;
GO
CREATE OR ALTER PROCEDURE dbo.ConsultarMarcas AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdMarca AS Id, Nombre FROM dbo.Marca ORDER BY Nombre;
END;
GO
CREATE OR ALTER PROCEDURE dbo.ConsultarModelos @IdMarca INT = NULL AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdModelo AS Id, Nombre FROM dbo.Modelo
    WHERE @IdMarca IS NULL OR IdMarca = @IdMarca ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.ConsultarCatalogo
    @Texto NVARCHAR(120) = NULL,
    @IdCategoria INT = NULL,
    @IdMarca INT = NULL,
    @IdModelo INT = NULL,
    @PrecioMaximo DECIMAL(10,2) = NULL,
    @SoloDisponibles BIT = 0,
    @IncluirInactivos BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.IdRepuesto, r.IdCategoria, c.Nombre AS Categoria, r.Codigo, r.Nombre,
           r.PrecioVenta, CAST(0 AS DECIMAL(10,2)) AS Costo, r.Activo,
           COALESCE(i.Existencias, 0) AS Existencias
    FROM dbo.Repuesto r
    JOIN dbo.Categoria c ON c.IdCategoria = r.IdCategoria
    LEFT JOIN (SELECT IdRepuesto, SUM(Cantidad) AS Existencias FROM dbo.Inventario GROUP BY IdRepuesto) i
        ON i.IdRepuesto = r.IdRepuesto
    WHERE (@IncluirInactivos = 1 OR r.Activo = 1)
      AND (@Texto IS NULL OR CHARINDEX(@Texto, r.Nombre) > 0 OR CHARINDEX(@Texto, r.Codigo) > 0)
      AND (@IdCategoria IS NULL OR r.IdCategoria = @IdCategoria)
      AND (@PrecioMaximo IS NULL OR r.PrecioVenta <= @PrecioMaximo)
      AND (@SoloDisponibles = 0 OR COALESCE(i.Existencias, 0) > 0)
      AND ((@IdMarca IS NULL AND @IdModelo IS NULL) OR EXISTS (
          SELECT 1 FROM dbo.RepuestoModelo rm JOIN dbo.Modelo m ON m.IdModelo = rm.IdModelo
          WHERE rm.IdRepuesto = r.IdRepuesto
            AND (@IdMarca IS NULL OR m.IdMarca = @IdMarca)
            AND (@IdModelo IS NULL OR m.IdModelo = @IdModelo)))
    ORDER BY r.Nombre, r.IdRepuesto;
END;
GO

CREATE OR ALTER PROCEDURE dbo.ConsultarRepuestoInterno @IdRepuesto INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.IdRepuesto, r.IdCategoria, c.Nombre AS Categoria, r.Codigo, r.Nombre,
           r.PrecioVenta, r.Costo, r.Activo,
           COALESCE((SELECT SUM(Cantidad) FROM dbo.Inventario WHERE IdRepuesto = r.IdRepuesto), 0) AS Existencias
    FROM dbo.Repuesto r JOIN dbo.Categoria c ON c.IdCategoria = r.IdCategoria
    WHERE r.IdRepuesto = @IdRepuesto;
END;
GO

CREATE OR ALTER PROCEDURE dbo.ConsultarMisCasos @IdUsuario INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdAseguradora INT;
    IF (SELECT COUNT(*) FROM dbo.Aseguradora WHERE IdUsuario = @IdUsuario) <> 1
        THROW 50001, 'El usuario no tiene un perfil de aseguradora unico.', 1;

    SELECT @IdAseguradora = a.IdAseguradora
    FROM dbo.Aseguradora a JOIN dbo.Usuario u ON u.IdUsuario = a.IdUsuario
    JOIN dbo.Rol r ON r.IdRol = u.IdRol
    WHERE u.IdUsuario = @IdUsuario AND u.Activo = 1 AND r.Nombre = 'Cliente'
      AND NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario);
    IF @IdAseguradora IS NULL THROW 50002, 'Usuario no autorizado.', 1;

    SELECT IdCaso, Placa, Estado, FechaApertura
    FROM dbo.Caso WHERE IdAseguradora = @IdAseguradora ORDER BY FechaApertura DESC, IdCaso DESC;
    SELECT co.IdCotizacion, co.IdCaso, co.Estado, co.Total, co.Fecha
    FROM dbo.Cotizacion co JOIN dbo.Caso c ON c.IdCaso = co.IdCaso
    WHERE c.IdAseguradora = @IdAseguradora ORDER BY co.Fecha DESC, co.IdCotizacion DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.ConsultarBaseActiva AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Nodo NVARCHAR(256) = NULL;
    DECLARE @GrupoDisponibilidad SYSNAME = NULL;
    DECLARE @EstadoSincronizacion NVARCHAR(60) = NULL;

    IF CONVERT(INT, SERVERPROPERTY('IsHadrEnabled')) = 1
    BEGIN
        BEGIN TRY
            SELECT TOP (1)
                   @Nodo = ar.replica_server_name,
                   @GrupoDisponibilidad = ag.name,
                   @EstadoSincronizacion = drs.synchronization_state_desc
            FROM sys.dm_hadr_database_replica_states drs
            JOIN sys.availability_databases_cluster adc
              ON adc.group_database_id = drs.group_database_id
            JOIN sys.availability_groups ag
              ON ag.group_id = adc.group_id
            LEFT JOIN sys.availability_replicas ar
              ON ar.replica_id = drs.replica_id
            WHERE drs.database_id = DB_ID()
              AND drs.is_local = 1;
        END TRY
        BEGIN CATCH
            SET @EstadoSincronizacion = N'Sin permiso para consultar DMV';
        END CATCH;
    END;

    SELECT CONVERT(NVARCHAR(128), SERVERPROPERTY('ServerName')) AS Servidor,
           DB_NAME() AS Base,
           CASE sys.fn_hadr_is_primary_replica(DB_NAME())
               WHEN 1 THEN N'Primaria'
               WHEN 0 THEN N'Secundaria'
               ELSE N'Sin grupo de disponibilidad'
           END AS Estado,
           @Nodo AS Nodo,
           @GrupoDisponibilidad AS GrupoDisponibilidad,
           @EstadoSincronizacion AS EstadoSincronizacion;
END;
GO
