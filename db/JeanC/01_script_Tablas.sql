/* 
   TI-156 Bases de Datos Avanzadas - III Cuatrimestre 2026
   Proyecto 1: Sistema de repuestos automotrices para aseguradoras
*/

CREATE DATABASE RepuestosAutomotrices;
GO

USE RepuestosAutomotrices;
GO


   --TABLAS SIN LLAVES FORANEAS
  
CREATE TABLE Rol (
    IdRol   INT IDENTITY(1,1) NOT NULL,
    Nombre  VARCHAR(30)       NOT NULL,
    CONSTRAINT PK_Rol PRIMARY KEY (IdRol),
    CONSTRAINT UQ_Rol_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Rol_Nombre CHECK (Nombre IN ('Administrador', 'Empleado', 'Cliente'))
);
GO


CREATE TABLE Marca (
    IdMarca INT IDENTITY(1,1) NOT NULL,
    Nombre  NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_Marca PRIMARY KEY (IdMarca),
    CONSTRAINT UQ_Marca_Nombre UNIQUE (Nombre)
);
GO


CREATE TABLE Categoria (
    IdCategoria INT IDENTITY(1,1) NOT NULL,
    Nombre      NVARCHAR(60)      NOT NULL,
    CONSTRAINT PK_Categoria PRIMARY KEY (IdCategoria),
    CONSTRAINT UQ_Categoria_Nombre UNIQUE (Nombre)
);
GO


CREATE TABLE Bodega (
    IdBodega  INT IDENTITY(1,1) NOT NULL,
    Nombre    NVARCHAR(60)      NOT NULL,
    Ubicacion NVARCHAR(150)     NOT NULL,
    CONSTRAINT PK_Bodega PRIMARY KEY (IdBodega),
    CONSTRAINT UQ_Bodega_Nombre UNIQUE (Nombre)
);
GO


CREATE TABLE Proveedor (
    IdProveedor INT IDENTITY(1,1) NOT NULL,
    Nombre      NVARCHAR(100)     NOT NULL,
    Telefono    VARCHAR(15)       NULL,
    Correo      VARCHAR(100)      NULL,
    DiasEntrega INT               NOT NULL,
    CONSTRAINT PK_Proveedor PRIMARY KEY (IdProveedor),
    CONSTRAINT CK_Proveedor_DiasEntrega CHECK (DiasEntrega >= 0)
);
GO


CREATE TABLE Auditoria (
    IdAuditoria INT IDENTITY(1,1) NOT NULL,
    Tabla       VARCHAR(50)       NOT NULL,
    Accion      CHAR(1)           NOT NULL,
    Usuario     VARCHAR(100)      NOT NULL,
    Fecha       DATETIME          NOT NULL,
    CONSTRAINT PK_Auditoria PRIMARY KEY (IdAuditoria),
    CONSTRAINT CK_Auditoria_Accion CHECK (Accion IN ('I', 'U', 'D'))
);
GO


  --USUARIOS
   


CREATE TABLE Usuario (
    IdUsuario  INT IDENTITY(1,1) NOT NULL,
    IdRol      INT               NOT NULL,
    Correo     VARCHAR(100)      NOT NULL,
    Contrasena VARCHAR(255)      NOT NULL,
    Activo     BIT               NOT NULL,
    CONSTRAINT PK_Usuario PRIMARY KEY (IdUsuario),
    CONSTRAINT UQ_Usuario_Correo UNIQUE (Correo),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (IdRol) REFERENCES Rol (IdRol)
);
GO


CREATE TABLE Empleado (
    IdEmpleado INT IDENTITY(1,1) NOT NULL,
    IdUsuario  INT               NOT NULL,
    Cedula     VARCHAR(20)       NOT NULL,
    Nombre     NVARCHAR(100)     NOT NULL,
    Puesto     NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_Empleado PRIMARY KEY (IdEmpleado),
    CONSTRAINT UQ_Empleado_Cedula UNIQUE (Cedula),
    CONSTRAINT FK_Empleado_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuario (IdUsuario)
);
GO


CREATE TABLE Aseguradora (
    IdAseguradora  INT IDENTITY(1,1) NOT NULL,
    IdUsuario      INT               NOT NULL,
    CedulaJuridica VARCHAR(20)       NOT NULL,
    Nombre         NVARCHAR(100)     NOT NULL,
    Telefono       VARCHAR(15)       NULL,
    Correo         VARCHAR(100)      NULL,
    CONSTRAINT PK_Aseguradora PRIMARY KEY (IdAseguradora),
    CONSTRAINT UQ_Aseguradora_CedulaJuridica UNIQUE (CedulaJuridica),
    CONSTRAINT FK_Aseguradora_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuario (IdUsuario)
);
GO


 --CATALOGO



CREATE TABLE Modelo (
    IdModelo   INT IDENTITY(1,1) NOT NULL,
    IdMarca    INT               NOT NULL,
    Nombre     NVARCHAR(60)      NOT NULL,
    AnioInicio INT               NOT NULL,
    AnioFin    INT               NULL,
    CONSTRAINT PK_Modelo PRIMARY KEY (IdModelo),
    CONSTRAINT FK_Modelo_Marca FOREIGN KEY (IdMarca) REFERENCES Marca (IdMarca),
    CONSTRAINT CK_Modelo_AnioInicio CHECK (AnioInicio >= 1900),
    CONSTRAINT CK_Modelo_AnioFin CHECK (AnioFin IS NULL OR AnioFin >= AnioInicio)
);
GO


CREATE TABLE Repuesto (
    IdRepuesto  INT IDENTITY(1,1) NOT NULL,
    IdCategoria INT               NOT NULL,
    Codigo      VARCHAR(30)       NOT NULL,
    Nombre      NVARCHAR(120)     NOT NULL,
    PrecioVenta DECIMAL(10,2)     NOT NULL,
    Costo       DECIMAL(10,2)     NOT NULL,
    Activo      BIT               NOT NULL,
    CONSTRAINT PK_Repuesto PRIMARY KEY (IdRepuesto),
    CONSTRAINT UQ_Repuesto_Codigo UNIQUE (Codigo),
    CONSTRAINT FK_Repuesto_Categoria FOREIGN KEY (IdCategoria) REFERENCES Categoria (IdCategoria),
    CONSTRAINT CK_Repuesto_PrecioVenta CHECK (PrecioVenta >= 0),
    CONSTRAINT CK_Repuesto_Costo CHECK (Costo >= 0)
);
GO


CREATE TABLE RepuestoModelo (
    IdRepuesto INT NOT NULL,
    IdModelo   INT NOT NULL,
    CONSTRAINT PK_RepuestoModelo PRIMARY KEY (IdRepuesto, IdModelo),
    CONSTRAINT FK_RepuestoModelo_Repuesto FOREIGN KEY (IdRepuesto) REFERENCES Repuesto (IdRepuesto),
    CONSTRAINT FK_RepuestoModelo_Modelo   FOREIGN KEY (IdModelo)   REFERENCES Modelo (IdModelo)
);
GO


   --BODEGAS E INVENTARIO
  


CREATE TABLE Inventario (
    IdInventario INT IDENTITY(1,1) NOT NULL,
    IdBodega     INT               NOT NULL,
    IdRepuesto   INT               NOT NULL,
    Cantidad     INT               NOT NULL,
    CONSTRAINT PK_Inventario PRIMARY KEY (IdInventario),
    CONSTRAINT UQ_Inventario_Bodega_Repuesto UNIQUE (IdBodega, IdRepuesto),
    CONSTRAINT FK_Inventario_Bodega   FOREIGN KEY (IdBodega)   REFERENCES Bodega (IdBodega),
    CONSTRAINT FK_Inventario_Repuesto FOREIGN KEY (IdRepuesto) REFERENCES Repuesto (IdRepuesto),
    CONSTRAINT CK_Inventario_Cantidad CHECK (Cantidad >= 0)
);
GO


CREATE TABLE Movimiento (
    IdMovimiento    INT IDENTITY(1,1) NOT NULL,
    IdRepuesto      INT               NOT NULL,
    IdBodegaOrigen  INT               NULL,
    IdBodegaDestino INT               NULL,
    IdEmpleado      INT               NOT NULL,
    Tipo            VARCHAR(15)       NOT NULL,
    Cantidad        INT               NOT NULL,
    Fecha           DATETIME          NOT NULL,
    CONSTRAINT PK_Movimiento PRIMARY KEY (IdMovimiento),
    CONSTRAINT FK_Movimiento_Repuesto      FOREIGN KEY (IdRepuesto)      REFERENCES Repuesto (IdRepuesto),
    CONSTRAINT FK_Movimiento_BodegaOrigen  FOREIGN KEY (IdBodegaOrigen)  REFERENCES Bodega (IdBodega),
    CONSTRAINT FK_Movimiento_BodegaDestino FOREIGN KEY (IdBodegaDestino) REFERENCES Bodega (IdBodega),
    CONSTRAINT FK_Movimiento_Empleado      FOREIGN KEY (IdEmpleado)      REFERENCES Empleado (IdEmpleado),
    CONSTRAINT CK_Movimiento_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_Movimiento_Tipo CHECK (Tipo IN ('Entrada', 'Salida', 'Traslado')),
    -- Entrada: solo destino
	--Salida: solo origen 
	--Traslado: ambos y distintos
    CONSTRAINT CK_Movimiento_Bodegas CHECK (
          (Tipo = 'Entrada'  AND IdBodegaOrigen IS NULL     AND IdBodegaDestino IS NOT NULL)
       OR (Tipo = 'Salida'   AND IdBodegaOrigen IS NOT NULL AND IdBodegaDestino IS NULL)
       OR (Tipo = 'Traslado' AND IdBodegaOrigen IS NOT NULL AND IdBodegaDestino IS NOT NULL
                             AND IdBodegaOrigen <> IdBodegaDestino)
    )
);
GO


 --COMPRAS
 


CREATE TABLE Compra (
    IdCompra       INT IDENTITY(1,1) NOT NULL,
    IdProveedor    INT               NOT NULL,
    IdBodega       INT               NOT NULL,
    Fecha          DATE              NOT NULL,
    FechaRecepcion DATE              NULL,
    Total          DECIMAL(12,2)     NOT NULL,
    CONSTRAINT PK_Compra PRIMARY KEY (IdCompra),
    CONSTRAINT FK_Compra_Proveedor FOREIGN KEY (IdProveedor) REFERENCES Proveedor (IdProveedor),
    CONSTRAINT FK_Compra_Bodega    FOREIGN KEY (IdBodega)    REFERENCES Bodega (IdBodega),
    CONSTRAINT CK_Compra_Total CHECK (Total >= 0),
    CONSTRAINT CK_Compra_FechaRecepcion CHECK (FechaRecepcion IS NULL OR FechaRecepcion >= Fecha)
);
GO


CREATE TABLE DetalleCompra (
    IdDetalle  INT IDENTITY(1,1) NOT NULL,
    IdCompra   INT               NOT NULL,
    IdRepuesto INT               NOT NULL,
    Cantidad   INT               NOT NULL,
    Costo      DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_DetalleCompra PRIMARY KEY (IdDetalle),
    CONSTRAINT FK_DetalleCompra_Compra   FOREIGN KEY (IdCompra)   REFERENCES Compra (IdCompra),
    CONSTRAINT FK_DetalleCompra_Repuesto FOREIGN KEY (IdRepuesto) REFERENCES Repuesto (IdRepuesto),
    CONSTRAINT CK_DetalleCompra_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleCompra_Costo CHECK (Costo >= 0)
);
GO

CREATE TABLE Incidencia (
    IdIncidencia INT IDENTITY(1,1) NOT NULL,
    IdRepuesto   INT               NOT NULL,
    IdProveedor  INT               NOT NULL,
    IdCompra     INT               NULL,
    Tipo         VARCHAR(20)       NOT NULL,
    Cantidad     INT               NOT NULL,
    Fecha        DATETIME          NOT NULL,
    CONSTRAINT PK_Incidencia PRIMARY KEY (IdIncidencia),
    CONSTRAINT FK_Incidencia_Repuesto  FOREIGN KEY (IdRepuesto)  REFERENCES Repuesto (IdRepuesto),
    CONSTRAINT FK_Incidencia_Proveedor FOREIGN KEY (IdProveedor) REFERENCES Proveedor (IdProveedor),
    CONSTRAINT FK_Incidencia_Compra    FOREIGN KEY (IdCompra)    REFERENCES Compra (IdCompra),
    CONSTRAINT CK_Incidencia_Cantidad CHECK (Cantidad > 0)
);
GO


 --CASOS, COTIZACIONES Y VENTAS
 

CREATE TABLE Caso (
    IdCaso        INT IDENTITY(1,1) NOT NULL,
    IdAseguradora INT               NOT NULL,
    IdModelo      INT               NOT NULL,
    Placa         VARCHAR(10)       NOT NULL,
    Estado        VARCHAR(20)       NOT NULL,
    FechaApertura DATETIME          NOT NULL,
    CONSTRAINT PK_Caso PRIMARY KEY (IdCaso),
    CONSTRAINT FK_Caso_Aseguradora FOREIGN KEY (IdAseguradora) 
	REFERENCES Aseguradora (IdAseguradora),
    CONSTRAINT FK_Caso_Modelo      FOREIGN KEY (IdModelo)      
	REFERENCES Modelo (IdModelo)
);
GO


CREATE TABLE Cotizacion (
    IdCotizacion INT IDENTITY(1,1) NOT NULL,
    IdCaso       INT               NOT NULL,
    IdEmpleado   INT               NOT NULL,
    Fecha        DATETIME          NOT NULL,
    Estado       VARCHAR(15)       NOT NULL,
    Total        DECIMAL(12,2)     NOT NULL,
    CONSTRAINT PK_Cotizacion PRIMARY KEY (IdCotizacion),
    CONSTRAINT FK_Cotizacion_Caso     FOREIGN KEY (IdCaso)     
	REFERENCES Caso (IdCaso),
    CONSTRAINT FK_Cotizacion_Empleado FOREIGN KEY (IdEmpleado) 
	REFERENCES Empleado (IdEmpleado),
    CONSTRAINT CK_Cotizacion_Total CHECK (Total >= 0)
);
GO


CREATE TABLE DetalleCotizacion (
    IdDetalle    INT IDENTITY(1,1) NOT NULL,
    IdCotizacion INT               NOT NULL,
    IdRepuesto   INT               NOT NULL,
    Cantidad     INT               NOT NULL,
    Precio       DECIMAL(10,2)     NOT NULL,
    Estado       VARCHAR(15)       NOT NULL,
    CONSTRAINT PK_DetalleCotizacion PRIMARY KEY (IdDetalle),
    CONSTRAINT FK_DetalleCotizacion_Cotizacion FOREIGN KEY (IdCotizacion) 
	REFERENCES Cotizacion (IdCotizacion),
    CONSTRAINT FK_DetalleCotizacion_Repuesto   FOREIGN KEY (IdRepuesto)  
	REFERENCES Repuesto (IdRepuesto),
    CONSTRAINT CK_DetalleCotizacion_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleCotizacion_Precio CHECK (Precio >= 0)
);
GO


CREATE TABLE Venta (
    IdVenta      INT IDENTITY(1,1) NOT NULL,
    IdCotizacion INT               NOT NULL,
    IdEmpleado   INT               NOT NULL,
    Fecha        DATETIME          NOT NULL,
    Total        DECIMAL(12,2)     NOT NULL,
    CONSTRAINT PK_Venta PRIMARY KEY (IdVenta),
    CONSTRAINT FK_Venta_Cotizacion FOREIGN KEY (IdCotizacion) 
	REFERENCES Cotizacion (IdCotizacion),
    CONSTRAINT FK_Venta_Empleado   FOREIGN KEY (IdEmpleado)   
	REFERENCES Empleado (IdEmpleado),
    CONSTRAINT CK_Venta_Total CHECK (Total >= 0)
);
GO


CREATE TABLE DetalleVenta (
    IdDetalle  INT IDENTITY(1,1) NOT NULL,
    IdVenta    INT               NOT NULL,
    IdRepuesto INT               NOT NULL,
    IdBodega   INT               NOT NULL,
    Cantidad   INT               NOT NULL,
    Precio     DECIMAL(10,2)     NOT NULL,
    Costo      DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_DetalleVenta PRIMARY KEY (IdDetalle),
    CONSTRAINT FK_DetalleVenta_Venta    FOREIGN KEY (IdVenta)    
	REFERENCES Venta (IdVenta),
    CONSTRAINT FK_DetalleVenta_Repuesto FOREIGN KEY (IdRepuesto) 
	REFERENCES Repuesto (IdRepuesto),
    CONSTRAINT FK_DetalleVenta_Bodega   FOREIGN KEY (IdBodega)   
	REFERENCES Bodega (IdBodega),
    CONSTRAINT CK_DetalleVenta_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleVenta_Precio CHECK (Precio >= 0),
    CONSTRAINT CK_DetalleVenta_Costo CHECK (Costo >= 0)
);
GO


CREATE TABLE Envio (
    IdEnvio      INT IDENTITY(1,1) NOT NULL,
    IdVenta      INT               NOT NULL,
    Direccion    NVARCHAR(200)     NOT NULL,
    Costo        DECIMAL(10,2)     NOT NULL,
    Estado       VARCHAR(15)       NOT NULL,
    FechaEntrega DATETIME          NULL,
    CONSTRAINT PK_Envio PRIMARY KEY (IdEnvio),
    CONSTRAINT FK_Envio_Venta FOREIGN KEY (IdVenta) 
	REFERENCES Venta (IdVenta),
    CONSTRAINT CK_Envio_Costo CHECK (Costo >= 0)
);
GO

/* =====================================================================
   7. VALORES POR DEFECTO 
   ===================================================================== */

ALTER TABLE Usuario    ADD CONSTRAINT DF_Usuario_Activo          DEFAULT (1)                        FOR Activo;
ALTER TABLE Repuesto   ADD CONSTRAINT DF_Repuesto_Activo         DEFAULT (1)                        FOR Activo;
ALTER TABLE Auditoria  ADD CONSTRAINT DF_Auditoria_Fecha         DEFAULT (GETDATE())                FOR Fecha;
ALTER TABLE Movimiento ADD CONSTRAINT DF_Movimiento_Fecha        DEFAULT (GETDATE())                FOR Fecha;
ALTER TABLE Compra     ADD CONSTRAINT DF_Compra_Fecha            DEFAULT (CAST(GETDATE() AS DATE))  FOR Fecha;
ALTER TABLE Incidencia ADD CONSTRAINT DF_Incidencia_Fecha        DEFAULT (GETDATE())                FOR Fecha;
ALTER TABLE Caso       ADD CONSTRAINT DF_Caso_FechaApertura      DEFAULT (GETDATE())                FOR FechaApertura;
ALTER TABLE Cotizacion ADD CONSTRAINT DF_Cotizacion_Fecha        DEFAULT (GETDATE())                FOR Fecha;
ALTER TABLE Venta      ADD CONSTRAINT DF_Venta_Fecha             DEFAULT (GETDATE())                FOR Fecha;
GO



  -- VALORES POR DEFECTO PARA TOTALES
   

ALTER TABLE Compra     ADD CONSTRAINT DF_Compra_Total            DEFAULT (0)                        FOR Total;
ALTER TABLE Cotizacion ADD CONSTRAINT DF_Cotizacion_Total        DEFAULT (0)                        FOR Total;
ALTER TABLE Venta      ADD CONSTRAINT DF_Venta_Total             DEFAULT (0)                        FOR Total;
GO 



  --CHECKS DE ESTADOS Y TIPOS
     
  

ALTER TABLE Caso ADD CONSTRAINT CK_Caso_Estado
    CHECK (Estado IN ('Abierto', 'En proceso', 'Cerrado', 'Rechazado'));

ALTER TABLE Cotizacion ADD CONSTRAINT CK_Cotizacion_Estado
    CHECK (Estado IN ('Pendiente', 'Aprobada', 'Rechazada'));

ALTER TABLE DetalleCotizacion ADD CONSTRAINT CK_DetalleCotizacion_Estado
    CHECK (Estado IN ('Pendiente', 'Aprobado', 'Rechazado'));

ALTER TABLE Envio ADD CONSTRAINT CK_Envio_Estado
    CHECK (Estado IN ('Pendiente', 'En camino', 'Entregado'));

ALTER TABLE Incidencia ADD CONSTRAINT CK_Incidencia_Tipo
    CHECK (Tipo IN ('Dañado', 'Defectuoso', 'Faltante', 'Rechazado'));
GO