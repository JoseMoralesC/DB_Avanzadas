# Revision de la exportacion SSMS

Fecha: 13 de octubre de 2026. Fuente: docs/evidencias/exportar/script.sql.
Archivo de entrega validado: docs/evidencias/exportar/script.sql.
SHA256: 456752A37CC3FBA27B06C296416DCA5A4581EC077DFEBC4886AD44ABE823F28F.
La exportacion actualizada por el usuario se conservo sin modificaciones.

## Resultado

| Elemento | Encontrado | Estado |
|---|---:|---|
| Tablas | 23 | Completo |
| Procedimientos | 34 | Incluye mantenimientos, consultas y login con clave original |
| INSERT de datos | 104 | Conteos restaurados coinciden con la base actual |
| Llaves primarias | 23 | Incluidas |
| Llaves foraneas | 32 | Incluidas |
| CHECK | 29 | Incluidos |
| Ensamblado Repuestos.Passwords | 1 | Hash SHA512 coincide con el instalado |
| Funcion VerificarClave | 1 | Incluida |
| Triggers | 13 | Incluidos y activos despues de restaurar |

Se reviso la captura docs/evidencias/exportar/4.PNG: corresponde al resumen del
asistente de SSMS y confirma el destino y la base seleccionados. Se encontraron
seis capturas del proceso. La conexion habitual del aplicativo funciona y la
cuenta configurada ya no tiene sysadmin, ALTER SETTINGS ni CONTROL SERVER.

## Restauracion validada

Se valido directamente docs/evidencias/exportar/script.sql, actualizado desde
SSMS para incluir los triggers. La copia complementada de la revision anterior
ya no es necesaria para esta exportacion.

El archivo se restauro exclusivamente en RepuestosJose_QA en localhost. Pasaron
las comprobaciones de conteos de las 23 tablas, triggers, 93 unidades de stock,
restricciones, totales y consultas parametrizadas. Tambien se valido el login
de Empleado y Cliente: clave correcta aceptada, incorrecta y hash como clave
rechazados; funciona con un usuario que solo tiene EXECUTE en LoginUsuario.
Las cuentas de prueba se revirtieron y la base temporal se elimino.
La configuracion CLR y la confianza agregada para la prueba local se restauraron.

Para la prueba se mapearon los contextos de base al nombre temporal y el usuario
SQL Jose a un usuario de base sin login. Esas adaptaciones se aplicaron solo a
la copia en memoria de la restauracion, sin crear logins del servidor compartido.

## Estado de entrega

El requisito de exportacion SSMS con estructura y datos queda cumplido.
Usar docs/evidencias/exportar/script.sql como archivo final validado.
db/exportacion/SQLQuery1.sql sigue siendo la version anterior sin triggers;
su SHA256 es 9D45A2D21D9CB675DCAC4C36AB530E40F46EBC9BFE492AD9FD2A1D306CA03C03.
No utilizar esa version anterior como entrega final. Se conserva sin reemplazarla.

En una instancia nueva debe habilitarse CLR y registrarse la confianza del
ensamblado antes de importarlo. La utilidad de prueba prepara ese requisito
localmente y revierte su configuracion al terminar.

## Repetir la prueba

```powershell
& ./aplicativo/Repuestos.Checks/Validar-Exportacion.ps1 -Archivo docs/evidencias/exportar/script.sql
```

Los conteos se contrastan con .qa/entrega/Proyecto1_Conteos.json, la instantanea
de la base que se genero en la validacion anterior.
