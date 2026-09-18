# Propuesta de Proyecto: Sistema Web y Analitico para una Verduleria Bimodal

## Portada

**Curso:** TI-156 Bases de Datos Avanzadas  
**Periodo:** III Cuatrimestre, 2026  
**Proyecto:** Propuesta de tema para proyecto 1  
**Tema:** Sistema web y base de datos para una verduleria con ventas fisicas y digitales  
**Integrantes:**  
- [Nombre del integrante 1]
- [Nombre del integrante 2]
- [Nombre del integrante 3]
**Fecha de entrega:** 19 de setiembre de 2026

## Introduccion a la propuesta

La propuesta consiste en desarrollar un sistema para una verduleria que desea modernizar su modelo de ventas mediante un esquema bimodal: venta fisica en el local y venta digital mediante una aplicacion web. El sistema permitira registrar productos, clientes, ventas, inventario, costos, precios, proveedores, temporadas y preferencias de compra, con el objetivo de analizar la rentabilidad del negocio y apoyar la toma de decisiones.

Este tema se ajusta al curso de Bases de Datos Avanzadas porque permite disenar una estructura relacional en SQL Server, aplicar restricciones, procedimientos almacenados, triggers, carga de datos de prueba, respaldos y mecanismos posteriores de alta disponibilidad. Ademas, el negocio puede trabajar con procesos asincronicos cuando no exista conectividad permanente, permitiendo registrar ventas localmente y sincronizar informacion cuando el sistema vuelva a tener conexion con el servidor principal.

## Desarrollo

### Tema

Sistema de administracion, ventas y analisis de datos para una verduleria que opera de forma fisica y digital.

El sistema buscara centralizar la informacion operativa del negocio y convertirla en informacion util para analizar comportamiento de clientes, temporadas de productos, precios, costos, inventario y rentabilidad.

### Objetivo del proyecto

Desarrollar una base de datos y una aplicacion web para administrar las ventas, inventario y clientes de una verduleria bimodal, permitiendo a los empleados gestionar la operacion diaria y a los clientes consultar productos, realizar pedidos y revisar informacion de compra. La informacion almacenada servira para generar reportes y analisis que apoyen decisiones sobre precios, abastecimiento, temporadas y rentabilidad.

### Uso por parte del cliente

Los usuarios finales o clientes podran utilizar la aplicacion web para:

- Registrarse e iniciar sesion.
- Consultar el catalogo de frutas y verduras disponibles.
- Filtrar productos por categoria, precio, disponibilidad o temporada.
- Agregar productos a un carrito de compras.
- Realizar pedidos digitales.
- Seleccionar retiro en tienda o entrega, si el alcance del proyecto lo permite.
- Consultar el estado de sus pedidos.
- Revisar su historial de compras.
- Recibir recomendaciones basadas en temporada o compras frecuentes.

### Uso por parte del empleado o administrador

Los usuarios empleados o administradores podran utilizar la aplicacion web para:

- Registrar, actualizar y desactivar productos.
- Administrar categorias de productos.
- Registrar costos, precios de venta y margenes esperados.
- Controlar inventario disponible.
- Registrar compras a proveedores.
- Registrar ventas fisicas realizadas en el local.
- Gestionar pedidos digitales.
- Administrar clientes y empleados.
- Consultar reportes de ventas, inventario y rentabilidad.
- Ejecutar procesos de carga de datos o sincronizacion cuando existan ventas registradas sin conexion.
- Generar respaldos o preparar la base para la herramienta de alta disponibilidad asignada en clase.

### Propuestas de informacion para analisis de datos

El sistema permitira obtener informacion para estudiar el comportamiento del negocio y apoyar la toma de decisiones. Algunos analisis propuestos son:

- **Rentabilidad por producto:** comparar precio de venta contra costo de adquisicion para determinar margen bruto por producto.
- **Productos mas vendidos:** identificar frutas y verduras con mayor rotacion por periodo.
- **Productos menos vendidos:** detectar inventario con baja demanda para ajustar compras.
- **Analisis por temporada:** estudiar que productos aumentan o disminuyen su demanda segun epoca del ano.
- **Preferencias de clientes:** analizar productos frecuentes por cliente o grupo de clientes.
- **Ventas por canal:** comparar ventas fisicas contra ventas digitales.
- **Comportamiento de precios:** evaluar si cambios de precio afectan la cantidad vendida.
- **Control de inventario:** identificar productos con riesgo de agotarse o con exceso de inventario.
- **Perdidas por merma:** registrar productos vencidos, danados o descartados para medir impacto economico.
- **Ventas por dia y hora:** conocer horarios o dias de mayor demanda.
- **Desempeno de proveedores:** comparar costos, frecuencia de compra y calidad asociada a proveedores.

### Relacion con los contenidos del curso

El proyecto permite aplicar temas propios de Bases de Datos Avanzadas en SQL Server y SSMS, tales como:

- Diseno de base de datos relacional.
- Tablas, llaves primarias y llaves foraneas.
- Restricciones y reglas de validacion.
- Checks para datos como precios, cantidades, estados y fechas.
- Procedimientos almacenados para registrar ventas, compras, pedidos y movimientos de inventario.
- Triggers para actualizar existencias, registrar auditorias o controlar cambios criticos.
- Carga inicial de datos de prueba.
- Backups y restauracion.
- Preparacion para una herramienta de alta disponibilidad, como replicacion, mirroring, Always On o clustering.
- Posible modelo asincronico para registrar informacion sin conectividad permanente y sincronizarla posteriormente.

## Ajuste de la idea original segun la consigna del PDF

La idea original de una verduleria es viable y conveniente para el proyecto porque genera datos suficientes para analisis, permite usuarios clientes y usuarios empleados, y puede implementarse como aplicacion web. Para alinearla mejor con la consigna, conviene presentarla no solo como un tramo de frutas y verduras, sino como un sistema web de administracion y analisis para una verduleria con ventas fisicas y digitales.

Tambien es recomendable explicar que el modelo asincronico no sera el centro unico del proyecto, sino una caracteristica complementaria relacionada con carga de datos, respaldos, sincronizacion y alta disponibilidad. De esta forma, la propuesta queda mas conectada con lo solicitado por la profesora: estructura de base de datos, carga de datos, aplicacion web, analisis de informacion y soporte para decisiones.

## Conclusion

La propuesta de la verduleria bimodal cumple con los requisitos del proyecto porque permite construir una base de datos completa, desarrollar funcionalidades web para clientes y empleados, cargar datos de prueba y generar analisis relevantes para la toma de decisiones. Ademas, el contexto del negocio facilita aplicar procedimientos almacenados, triggers, restricciones, respaldos y una herramienta de alta disponibilidad durante los siguientes avances del cuatrimestre.
