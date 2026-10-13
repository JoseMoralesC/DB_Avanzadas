/*
   TI-156 Bases de Datos Avanzadas - III Cuatrimestre 2026
   Proyecto 1: permisos minimos para el backend de RepuestosAutomotrices

   Ejecutar como sysadmin o securityadmin/db_owner.
   Cambiar las variables antes de ejecutar en el ambiente real.
*/

USE master;
GO

DECLARE @LoginName SYSNAME = N'repuestos_app';
DECLARE @Password NVARCHAR(128) = N'Cambiar_Esta_Clave_2026!';
DECLARE @Sql NVARCHAR(MAX);

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = @LoginName)
BEGIN
    SET @Sql = N'CREATE LOGIN ' + QUOTENAME(@LoginName)
        + N' WITH PASSWORD = ' + QUOTENAME(@Password, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @Sql;
END;
GO

USE RepuestosAutomotrices;
GO

DECLARE @UserName SYSNAME = N'repuestos_app';
DECLARE @Sql NVARCHAR(MAX);

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @UserName)
BEGIN
    SET @Sql = N'CREATE USER ' + QUOTENAME(@UserName)
        + N' FOR LOGIN ' + QUOTENAME(@UserName) + N';';
    EXEC sys.sp_executesql @Sql;
END;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_repuestos_executor')
    CREATE ROLE app_repuestos_executor AUTHORIZATION dbo;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id
    JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'app_repuestos_executor'
      AND m.name = @UserName)
BEGIN
    SET @Sql = N'ALTER ROLE app_repuestos_executor ADD MEMBER ' + QUOTENAME(@UserName) + N';';
    EXEC sys.sp_executesql @Sql;
END;

GRANT EXECUTE ON dbo.ObtenerCredencialLogin TO app_repuestos_executor;
GRANT EXECUTE ON dbo.LoginUsuario TO app_repuestos_executor;
GRANT EXECUTE ON dbo.ConsultarCategorias TO app_repuestos_executor;
GRANT EXECUTE ON dbo.ConsultarMarcas TO app_repuestos_executor;
GRANT EXECUTE ON dbo.ConsultarModelos TO app_repuestos_executor;
GRANT EXECUTE ON dbo.ConsultarCatalogo TO app_repuestos_executor;
GRANT EXECUTE ON dbo.ConsultarRepuestoInterno TO app_repuestos_executor;
GRANT EXECUTE ON dbo.ConsultarMisCasos TO app_repuestos_executor;
GRANT EXECUTE ON dbo.ConsultarBaseActiva TO app_repuestos_executor;
GRANT EXECUTE ON dbo.GuardarRepuestoApp TO app_repuestos_executor;
GO

SELECT dp.name AS UsuarioBaseDatos,
       rp.name AS RolAplicacion
FROM sys.database_role_members drm
JOIN sys.database_principals rp ON rp.principal_id = drm.role_principal_id
JOIN sys.database_principals dp ON dp.principal_id = drm.member_principal_id
WHERE dp.name = N'repuestos_app';
GO
