-- Ejecutar despues de los tres scripts de db/JeanC. No almacena contrasenas nuevas.
USE RepuestosAutomotrices;
GO

CREATE OR ALTER PROCEDURE dbo.ObtenerCredencialLogin
    @Correo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    -- Una cuenta debe tener un unico perfil coherente antes de permitir el acceso.
    SELECT u.IdUsuario, u.Correo, u.Contrasena AS HashContrasena, r.Nombre AS Rol,
           e.IdEmpleado, a.IdAseguradora, COALESCE(e.Nombre, a.Nombre, u.Correo) AS Nombre
    FROM dbo.Usuario u
    JOIN dbo.Rol r ON r.IdRol = u.IdRol
    LEFT JOIN dbo.Empleado e ON e.IdUsuario = u.IdUsuario
    LEFT JOIN dbo.Aseguradora a ON a.IdUsuario = u.IdUsuario
    WHERE u.Correo = @Correo AND u.Activo = 1
      AND ((r.Nombre IN ('Administrador', 'Empleado')
            AND (SELECT COUNT(*) FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario) = 1
            AND NOT EXISTS (SELECT 1 FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario))
        OR (r.Nombre = 'Cliente'
            AND (SELECT COUNT(*) FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario) = 1
            AND NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario)));
END;
GO

CREATE OR ALTER PROCEDURE dbo.LoginUsuario
    @Correo VARCHAR(100),
    @HashVerificado VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    -- El backend verifica PasswordHasher antes de llamar a este procedimiento.
    -- La comparacion binaria confirma que la credencial no cambio entre ambas lecturas.
    SELECT u.IdUsuario, u.Correo, CAST(NULL AS VARCHAR(255)) AS HashContrasena,
           r.Nombre AS Rol, e.IdEmpleado, a.IdAseguradora,
           COALESCE(e.Nombre, a.Nombre, u.Correo) AS Nombre
    FROM dbo.Usuario u
    JOIN dbo.Rol r ON r.IdRol = u.IdRol
    LEFT JOIN dbo.Empleado e ON e.IdUsuario = u.IdUsuario
    LEFT JOIN dbo.Aseguradora a ON a.IdUsuario = u.IdUsuario
    WHERE u.Correo = @Correo AND u.Activo = 1
      AND CONVERT(VARBINARY(255), u.Contrasena) = CONVERT(VARBINARY(255), @HashVerificado)
      AND ((r.Nombre IN ('Administrador', 'Empleado')
            AND (SELECT COUNT(*) FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario) = 1
            AND NOT EXISTS (SELECT 1 FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario))
        OR (r.Nombre = 'Cliente'
            AND (SELECT COUNT(*) FROM dbo.Aseguradora WHERE IdUsuario = u.IdUsuario) = 1
            AND NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE IdUsuario = u.IdUsuario)));
END;
GO
