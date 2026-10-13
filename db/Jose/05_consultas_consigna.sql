USE RepuestosAutomotrices;
GO

-- Consulta administrativa: el selector identifica la tabla completa.
-- No se otorga al rol del aplicativo porque Usuario contiene hashes privados.
CREATE OR ALTER PROCEDURE dbo.ConsultarDatos @TipoConsulta INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @TipoConsulta = 1 SELECT * FROM dbo.Rol;
    ELSE IF @TipoConsulta = 2 SELECT * FROM dbo.Usuario;
    ELSE IF @TipoConsulta = 3 SELECT * FROM dbo.Empleado;
    ELSE IF @TipoConsulta = 4 SELECT * FROM dbo.Aseguradora;
    ELSE IF @TipoConsulta = 5 SELECT * FROM dbo.Categoria;
    ELSE IF @TipoConsulta = 6 SELECT * FROM dbo.Marca;
    ELSE IF @TipoConsulta = 7 SELECT * FROM dbo.Modelo;
    ELSE IF @TipoConsulta = 8 SELECT * FROM dbo.Repuesto;
    ELSE IF @TipoConsulta = 9 SELECT * FROM dbo.RepuestoModelo;
    ELSE IF @TipoConsulta = 10 SELECT * FROM dbo.Bodega;
    ELSE IF @TipoConsulta = 11 SELECT * FROM dbo.Proveedor;
    ELSE IF @TipoConsulta = 12 SELECT * FROM dbo.Compra;
    ELSE IF @TipoConsulta = 13 SELECT * FROM dbo.DetalleCompra;
    ELSE IF @TipoConsulta = 14 SELECT * FROM dbo.Inventario;
    ELSE IF @TipoConsulta = 15 SELECT * FROM dbo.Movimiento;
    ELSE IF @TipoConsulta = 16 SELECT * FROM dbo.Caso;
    ELSE IF @TipoConsulta = 17 SELECT * FROM dbo.Cotizacion;
    ELSE IF @TipoConsulta = 18 SELECT * FROM dbo.DetalleCotizacion;
    ELSE IF @TipoConsulta = 19 SELECT * FROM dbo.Venta;
    ELSE IF @TipoConsulta = 20 SELECT * FROM dbo.DetalleVenta;
    ELSE IF @TipoConsulta = 21 SELECT * FROM dbo.Envio;
    ELSE IF @TipoConsulta = 22 SELECT * FROM dbo.Incidencia;
    ELSE IF @TipoConsulta = 23 SELECT * FROM dbo.Auditoria;
    ELSE THROW 50040, 'TipoConsulta debe estar entre 1 y 23.', 1;
END;
GO
