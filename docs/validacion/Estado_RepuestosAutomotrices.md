# Validacion de Proyecto 1

Fecha UTC: 2026-10-13T15:51:52.2310140Z

Base: `RepuestosAutomotrices`

Unidades de inventario antes: 81; despues: 93.

| Tabla | Antes | Despues | Minimo 3 |
|---|---:|---:|---|
| Rol | 3 | 3 | Cumple |
| Usuario | 4 | 6 | Cumple |
| Empleado | 3 | 3 | Cumple |
| Aseguradora | 1 | 3 | Cumple |
| Categoria | 3 | 3 | Cumple |
| Marca | 3 | 3 | Cumple |
| Modelo | 6 | 6 | Cumple |
| Repuesto | 9 | 9 | Cumple |
| RepuestoModelo | 9 | 9 | Cumple |
| Bodega | 3 | 3 | Cumple |
| Proveedor | 3 | 3 | Cumple |
| Compra | 0 | 3 | Cumple |
| DetalleCompra | 0 | 3 | Cumple |
| Inventario | 12 | 12 | Cumple |
| Movimiento | 0 | 3 | Cumple |
| Caso | 0 | 3 | Cumple |
| Cotizacion | 0 | 3 | Cumple |
| DetalleCotizacion | 0 | 3 | Cumple |
| Venta | 0 | 3 | Cumple |
| DetalleVenta | 0 | 3 | Cumple |
| Envio | 0 | 3 | Cumple |
| Incidencia | 0 | 3 | Cumple |
| Auditoria | 0 | 11 | Cumple |

## Triggers

- `TR_Aseguradora_ValidarRol`: activo
- `TR_Compra_ValidarBodega`: activo
- `TR_DetalleCompra_Inventario`: activo
- `TR_DetalleCompra_Total`: activo
- `TR_DetalleCotizacion_Total`: activo
- `TR_DetalleVenta_Inventario`: activo
- `TR_DetalleVenta_Total`: activo
- `TR_Empleado_ValidarRol`: activo
- `TR_Inventario_Auditoria`: activo
- `TR_Movimiento_Inventario`: activo
- `TR_Repuesto_Auditoria`: activo
- `TR_Usuario_Auditoria`: activo
- `TR_Usuario_ValidarPerfil`: activo

## Procedimientos

- `ConsultarBaseActiva`
- `ConsultarCatalogo`
- `ConsultarCategorias`
- `ConsultarDatos`
- `ConsultarMarcas`
- `ConsultarMisCasos`
- `ConsultarModelos`
- `ConsultarRepuestoInterno`
- `GuardarRepuestoApp`
- `LoginUsuario`
- `MantenimientoAseguradora`
- `MantenimientoAuditoria`
- `MantenimientoBodega`
- `MantenimientoCaso`
- `MantenimientoCategoria`
- `MantenimientoCompra`
- `MantenimientoCotizacion`
- `MantenimientoDetalleCompra`
- `MantenimientoDetalleCotizacion`
- `MantenimientoDetalleVenta`
- `MantenimientoEmpleado`
- `MantenimientoEnvio`
- `MantenimientoIncidencia`
- `MantenimientoInventario`
- `MantenimientoMarca`
- `MantenimientoModelo`
- `MantenimientoMovimiento`
- `MantenimientoProveedor`
- `MantenimientoRepuesto`
- `MantenimientoRepuestoModelo`
- `MantenimientoRol`
- `MantenimientoUsuario`
- `MantenimientoVenta`
- `ObtenerCredencialLogin`

Llaves foraneas desactivadas o no confiables: 0.

Checks desactivados o no confiables: 0.

## Validaciones

23 selectores devuelven la tabla completa. Totales de compras, cotizaciones y ventas coherentes. Stock no negativo y roles de perfiles coherentes.

