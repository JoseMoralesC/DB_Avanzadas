# SQL de Christian: conexion, permisos y conmutacion

Esta carpeta cubre la parte de alta disponibilidad e infraestructura para la base
`RepuestosAutomotrices`: destino de conexion, permisos SQL del backend y prueba
manual de conmutacion.

## Orden recomendado

1. Aplicar los scripts base indicados en `db/Jose/README.md`.
2. Confirmar el destino de conexion del laboratorio:
   - Listener de Always On, si existe.
   - En laboratorio sin listener, IP o DNS del nodo primario actual.
   - Puerto TCP publicado para SQL Server.
3. Ejecutar `01_permisos_backend.sql` como administrador SQL y ajustar los valores
   de la seccion de parametros.
4. Configurar `ConnectionStrings__Repuestos` en `.env`, variable de entorno o
   Secret Manager. No guardar credenciales reales en Git.
5. Ejecutar `02_verificacion_alta_disponibilidad.sql` antes y despues de la
   conmutacion para dejar evidencia.

## Cadena de conexion

Para Always On con listener:

```text
Server=NOMBRE_LISTENER,PUERTO;Database=RepuestosAutomotrices;User ID=USUARIO_APP;Password=CONTRASENA;Encrypt=true;TrustServerCertificate=true;Connect Timeout=5;MultiSubnetFailover=true
```

Para el laboratorio actual sin listener confirmado:

```text
Server=100.124.109.126,15002;Database=RepuestosAutomotrices;User ID=USUARIO_APP;Password=CONTRASENA;Encrypt=true;TrustServerCertificate=true;Connect Timeout=5;MultiSubnetFailover=true
```

`MultiSubnetFailover=true` no reemplaza el listener ni la configuracion de red;
solamente ayuda al cliente SQL a reconectar mas rapido cuando el destino de
conexion apunta a un grupo de disponibilidad.

## Evidencia minima para la entrega

- Captura de SSMS con `02_verificacion_alta_disponibilidad.sql` antes del failover.
- Captura de la pantalla `Catalogo > Conexion` en la aplicacion antes del failover.
- Ejecucion de conmutacion desde SSMS o Failover Cluster Manager.
- Captura de SSMS con el mismo script despues del failover.
- Captura de `Catalogo > Conexion` despues de volver a iniciar sesion o actualizar.
- Nota con fecha, hora, nodo primario antes, nodo primario despues y resultado.

La conmutacion real depende de la configuracion de SQL Server, Windows Failover
Cluster, endpoints, replicas y permisos del laboratorio. Estos scripts no crean el
grupo Always On; dejan preparado el acceso de la aplicacion y la verificacion.
