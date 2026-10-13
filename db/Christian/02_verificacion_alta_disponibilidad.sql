/*
   TI-156 Bases de Datos Avanzadas - III Cuatrimestre 2026
   Proyecto 1: evidencia de conexion y Always On

   Ejecutar en SSMS conectado al mismo destino usado por la aplicacion.
   Tomar captura antes y despues de la conmutacion.
*/

USE RepuestosAutomotrices;
GO

EXEC dbo.ConsultarBaseActiva;
GO

SELECT
    CONVERT(NVARCHAR(128), SERVERPROPERTY('MachineName')) AS Maquina,
    CONVERT(NVARCHAR(128), SERVERPROPERTY('ServerName')) AS Instancia,
    CONVERT(INT, SERVERPROPERTY('IsHadrEnabled')) AS AlwaysOnHabilitado,
    DB_NAME() AS BaseActiva,
    SYSDATETIME() AS FechaHoraServidor;
GO

IF CONVERT(INT, SERVERPROPERTY('IsHadrEnabled')) = 1
BEGIN
    SELECT
        ag.name AS GrupoDisponibilidad,
        ar.replica_server_name AS Replica,
        ars.role_desc AS RolReplica,
        ars.connected_state_desc AS EstadoConexion,
        drs.synchronization_state_desc AS EstadoSincronizacion,
        drs.synchronization_health_desc AS SaludSincronizacion,
        drs.is_local AS EsReplicaLocal
    FROM sys.dm_hadr_availability_replica_states ars
    JOIN sys.availability_replicas ar
      ON ar.replica_id = ars.replica_id
    JOIN sys.availability_groups ag
      ON ag.group_id = ar.group_id
    LEFT JOIN sys.dm_hadr_database_replica_states drs
      ON drs.replica_id = ar.replica_id
     AND drs.group_id = ag.group_id
     AND drs.database_id = DB_ID()
    ORDER BY drs.is_local DESC, ar.replica_server_name;
END
ELSE
BEGIN
    SELECT N'Always On no esta habilitado en esta instancia o no hay permisos para ver el estado.' AS Observacion;
END;
GO
