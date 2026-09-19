# Propuesta de Proyecto: Sistema Web y Analitico para Empresa de Repuestos Automotrices

## Portada

**Curso:** TI-156 Bases de Datos Avanzadas  
**Periodo:** III Cuatrimestre, 2026  
**Proyecto:** Propuesta de tema para proyecto 1  
**Tema:** Sistema web y base de datos para la administracion, venta y analisis de repuestos automotrices para aseguradoras  
**Integrantes:**  
- Jean Carlo Navarro Solano
- Christian Esteban Rocha Guerrero
- Jose Rodolfo Morales Calderon

**Fecha de entrega:** 19 de setiembre de 2026

## Introduccion a la propuesta

La propuesta consiste en desarrollar un sistema web para una empresa dedicada a la compra, almacenamiento, cotizacion, venta y distribucion de repuestos automotrices, tales como bumpers, faroles, guardabarros y otros componentes utilizados en procesos de reparacion vehicular. La empresa trabaja principalmente con aseguradoras, proveedores, bodegas y empleados internos encargados de gestionar cotizaciones, compras, inventario, ventas y entregas.

El sistema permitira centralizar la informacion del negocio en una base de datos relacional, registrar las operaciones principales y generar analisis utiles para la toma de decisiones. Entre los datos que se podran estudiar se incluyen repuestos mas vendidos, utilidad por producto, costos de envio, demanda por temporada, rotacion de inventario, desempeno de proveedores, comportamiento de las aseguradoras y demanda por marca de vehiculo.

Este tema se ajusta al curso de Bases de Datos Avanzadas porque permite disenar una estructura de base de datos completa en SQL Server, aplicar restricciones, chequeos, procedimientos almacenados, triggers, carga de datos de prueba, respaldos y una herramienta de alta disponibilidad, como replicacion, mirroring, Grupos de Disponibilidad Always On o clustering, segun sea asignado durante el curso.

## Desarrollo

### Tema

Sistema de administracion, ventas, inventario y analisis de datos para una empresa de repuestos automotrices que atiende solicitudes de aseguradoras.

El proyecto buscara administrar el ciclo completo de trabajo de la empresa: solicitud de repuestos, cotizacion, compra a proveedores, ingreso a bodega, venta a aseguradoras, despacho y seguimiento de casos. La informacion registrada servira como base para generar reportes operativos y analiticos.

### Objetivo del proyecto

Desarrollar una base de datos y una aplicacion web que permitan administrar repuestos automotrices, aseguradoras, proveedores, bodegas, cotizaciones, compras, ventas, envios y casos de entrega, con el fin de mejorar el control operativo de la empresa y obtener informacion analitica para apoyar la toma de decisiones.

### Uso por parte del cliente

Los usuarios finales, representados principalmente por las aseguradoras, podran utilizar la aplicacion web para:

- Registrarse e iniciar sesion como cliente autorizado.
- Consultar el catalogo de repuestos disponibles.
- Buscar repuestos por marca de vehiculo, modelo, categoria, disponibilidad o precio.
- Crear solicitudes de cotizacion para casos de reparacion.
- Revisar el estado de sus cotizaciones.
- Confirmar compras aprobadas.
- Consultar el estado de entrega de los repuestos solicitados.
- Revisar historiales de compras, casos y cotizaciones.
- Consultar repuestos rechazados, pendientes o entregados por caso.

### Uso por parte del empleado o administrador

Los usuarios empleados o administradores podran utilizar la aplicacion web para:

- Registrar, actualizar y desactivar repuestos.
- Administrar categorias, marcas de vehiculos y tipos de repuestos.
- Registrar proveedores y condiciones comerciales.
- Gestionar aseguradoras clientes y sus casos.
- Crear y dar seguimiento a cotizaciones.
- Registrar compras realizadas a proveedores.
- Registrar ventas realizadas a aseguradoras.
- Controlar inventario por bodega.
- Registrar ingresos, salidas y traslados de repuestos entre bodegas.
- Controlar costos de compra, precios de venta, costos de envio y utilidad.
- Registrar repuestos danados, rechazados o recibidos en mal estado.
- Consultar casos pendientes de entrega.
- Generar reportes de ventas, inventario, proveedores, aseguradoras y marcas.
- Ejecutar procedimientos administrativos como carga de datos, respaldos y preparacion para alta disponibilidad.

### Propuestas de informacion para analisis de datos

El sistema permitira generar informacion para estudiar el comportamiento del negocio y apoyar decisiones comerciales, logisticas y de inventario. Algunos analisis propuestos son:

- **Repuestos mas vendidos:** identificar los productos con mayor demanda en un periodo determinado.
- **Repuestos con mejor utilidad:** comparar precio de venta, costo de compra y costo de envio para determinar margen de ganancia.
- **Repuestos con mayor costo de envio:** detectar productos que afectan la rentabilidad por gastos logisticos.
- **Demanda por fecha o temporada:** analizar que repuestos son mas cotizados o vendidos segun mes, temporada o periodo.
- **Cantidad de cotizaciones por mes:** medir el volumen de solicitudes recibidas y su conversion a compras.
- **Cantidad de compras por mes:** evaluar el comportamiento de ventas por periodo.
- **Casos pendientes de entrega:** identificar atrasos logisticos y dar seguimiento a solicitudes abiertas.
- **Desempeno de proveedores:** comparar precio, calidad, tiempos de entrega y cantidad de repuestos recibidos en mal estado.
- **Inventario estancado por bodega:** detectar bodegas con repuestos de baja rotacion.
- **Rotacion de repuestos por bodega:** conocer que bodegas mueven inventario con mayor eficiencia.
- **Demanda por marca de vehiculo:** identificar marcas que generan mayor cantidad de solicitudes.
- **Aseguradoras con mayor actividad:** analizar que clientes realizan mas compras, cotizaciones o casos.
- **Casos rechazados por aseguradora:** estudiar patrones de rechazo y sus posibles causas.
- **Repuestos rechazados o danados:** medir perdidas asociadas a calidad, proveedor o manejo logistico.

### Relacion con los contenidos del curso

El proyecto permite aplicar temas propios de Bases de Datos Avanzadas en SQL Server y SSMS, tales como:

- Diseno de base de datos relacional.
- Tablas, llaves primarias y llaves foraneas.
- Restricciones de integridad referencial.
- Chequeos para validar precios, cantidades, estados, fechas y costos.
- Procedimientos almacenados para registrar cotizaciones, compras, ventas, movimientos de inventario y entregas.
- Triggers para actualizar existencias, registrar auditorias y controlar cambios criticos.
- Carga inicial de datos de prueba.
- Consultas y vistas para analisis de datos.
- Backups y restauracion.
- Preparacion para una herramienta de alta disponibilidad, como replicacion, mirroring, Always On o clustering.

## Stack recomendado para el proyecto

Para el desarrollo del proyecto se recomienda utilizar el siguiente stack:

- **Motor de base de datos:** SQL Server.
- **Herramienta de administracion de base de datos:** SQL Server Management Studio (SSMS).
- **Aplicacion web:** ASP.NET Core MVC o ASP.NET Core Web API con una interfaz web en Razor Pages, Blazor o React, segun el alcance que el grupo decida implementar.
- **Lenguaje backend recomendado:** C# con .NET, por su integracion natural con SQL Server.
- **Acceso a datos:** Entity Framework Core o procedimientos almacenados consumidos desde el backend.
- **Reportes y analisis:** consultas SQL, vistas, procedimientos almacenados y paneles dentro de la aplicacion web.
- **Usuarios remotos:** usuarios remotos con igualdad de condiciones, de forma que puedan acceder al sistema bajo los mismos permisos funcionales definidos para su rol.
- **Conectividad remota:** Tailscale instalado en una maquina propia que funcionara como servidor, permitiendo conectividad privada y segura hacia el entorno donde se aloje la base de datos y la aplicacion.
- **Alta disponibilidad:** se ajustara segun la herramienta asignada en clase: replicacion, mirroring, Grupos de Disponibilidad Always On o clustering.

Este stack permite trabajar con tecnologias compatibles con el curso, facilita la administracion de SQL Server y permite simular un ambiente real donde empleados o clientes autorizados puedan conectarse de forma remota al sistema.

## Ajuste de la propuesta segun la consigna del PDF

La propuesta cumple con la consigna porque plantea un tema que permite almacenar informacion suficiente para generar analisis relevantes para la toma de decisiones. Ademas, puede desarrollarse como una aplicacion web con funcionalidades diferenciadas para usuarios finales, representados por las aseguradoras, y usuarios administradores o empleados de la empresa.

El proyecto tambien permite trabajar los entregables del curso durante todo el cuatrimestre, iniciando con la estructura de base de datos, restricciones, chequeos, procedimientos almacenados, triggers y datos de prueba. Posteriormente, se podra ampliar con la aplicacion web, el apartado de analisis de datos y la herramienta de alta disponibilidad asignada.

## Conclusion

La propuesta de un sistema web y analitico para una empresa de repuestos automotrices es adecuada para el proyecto de Bases de Datos Avanzadas porque ofrece un contexto amplio, realista y con suficiente volumen de informacion para disenar una base de datos robusta. Tambien permite aplicar funcionalidades para clientes y empleados, generar reportes utiles para la toma de decisiones y preparar la solucion para escenarios de acceso remoto y alta disponibilidad.
