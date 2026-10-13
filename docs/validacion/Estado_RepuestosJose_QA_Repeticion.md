# Validacion de Proyecto 1

Fecha UTC: 2026-10-13T16:39:12.8431071Z

Base: `RepuestosJose_QA`

Unidades de inventario antes: 105; despues: 105.

| Tabla | Antes | Despues | Minimo 3 |
|---|---:|---:|---|
| Rol | 3 | 3 | Cumple |
| Usuario | 6 | 6 | Cumple |
| Empleado | 3 | 3 | Cumple |
| Aseguradora | 3 | 3 | Cumple |
| Categoria | 3 | 3 | Cumple |
| Marca | 3 | 3 | Cumple |
| Modelo | 8 | 8 | Cumple |
| Repuesto | 19 | 19 | Cumple |
| RepuestoModelo | 9 | 9 | Cumple |
| Bodega | 5 | 5 | Cumple |
| Proveedor | 4 | 4 | Cumple |
| Compra | 4 | 4 | Cumple |
| DetalleCompra | 4 | 4 | Cumple |
| Inventario | 16 | 16 | Cumple |
| Movimiento | 4 | 4 | Cumple |
| Caso | 5 | 5 | Cumple |
| Cotizacion | 5 | 5 | Cumple |
| DetalleCotizacion | 4 | 4 | Cumple |
| Venta | 4 | 4 | Cumple |
| DetalleVenta | 3 | 3 | Cumple |
| Envio | 3 | 3 | Cumple |
| Incidencia | 3 | 3 | Cumple |
| Auditoria | 33 | 33 | Cumple |

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

