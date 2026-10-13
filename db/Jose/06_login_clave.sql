USE RepuestosAutomotrices;
GO

-- Instalar despues del ensamblado CLR y dbo.VerificarClave.
CREATE OR ALTER PROCEDURE dbo.LoginUsuario
    @Correo VARCHAR(100),
    @Clave NVARCHAR(256),
    @Valido BIT = NULL OUTPUT,
    @HashVerificado VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Valido = 0;
    DECLARE @Hash VARCHAR(255), @IdUsuario INT;
    SELECT @IdUsuario = u.IdUsuario, @Hash = u.Contrasena
    FROM dbo.Usuario u JOIN dbo.Rol r ON r.IdRol = u.IdRol
    WHERE u.Correo = @Correo AND u.Activo = 1
      AND ((r.Nombre IN ('Administrador', 'Empleado')
            AND (SELECT COUNT(*) FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario) = 1
            AND NOT EXISTS (SELECT 1 FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario))
        OR (r.Nombre = 'Cliente'
            AND (SELECT COUNT(*) FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario) = 1
            AND NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario)));
    IF @IdUsuario IS NOT NULL AND dbo.VerificarClave(@Clave, @Hash) = 1
    BEGIN
        -- Releer despues de PBKDF2 para detectar cambios concurrentes de cuenta o clave.
        SELECT u.IdUsuario, u.Correo, CAST(NULL AS VARCHAR(255)) AS HashContrasena,
            r.Nombre AS Rol, e.IdEmpleado, a.IdAseguradora,
            COALESCE(e.Nombre, a.Nombre, u.Correo) AS Nombre
        FROM dbo.Usuario u JOIN dbo.Rol r ON r.IdRol = u.IdRol
        LEFT JOIN dbo.Empleado e ON e.IdUsuario = u.IdUsuario
        LEFT JOIN dbo.Aseguradora a ON a.IdUsuario = u.IdUsuario
        WHERE u.IdUsuario = @IdUsuario AND u.Activo = 1
          AND CONVERT(VARBINARY(255),u.Contrasena) = CONVERT(VARBINARY(255),@Hash)
          AND (@HashVerificado IS NULL OR CONVERT(VARBINARY(255),@HashVerificado) = CONVERT(VARBINARY(255),@Hash))
          AND ((r.Nombre IN ('Administrador', 'Empleado')
                AND (SELECT COUNT(*) FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario) = 1
                AND NOT EXISTS (SELECT 1 FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario))
            OR (r.Nombre = 'Cliente'
                AND (SELECT COUNT(*) FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario) = 1
                AND NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario)));
        IF @@ROWCOUNT = 1 SET @Valido = 1;
    END;
END;
GO
