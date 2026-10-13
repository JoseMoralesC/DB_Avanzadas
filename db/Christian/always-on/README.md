# Preparacion del laboratorio Always On

Objetivo: dos nodos SQL en Windows Server virtualizado, alojados en los dos
equipos de casa. El equipo del companero accede desde la universidad mediante
Tailscale y ejecuta el aplicativo y SSMS.

| Anfitrion | VM | Memoria inicial |
|---|---|---:|
| Servidor de casa (8 GB, 100 GB libres) | SQL1 | 4 GB |
| Equipo personal (16 GB) | SQL2 | 6 GB |
| Equipo personal | DC1, dominio/DNS/testigo | 2-3 GB |

Son asignaciones propuestas para el laboratorio. Hay que comprobar espacio y
consumo real antes de crear discos virtuales. La base original de Windows 10
continua separada del laboratorio y no se elimina ni migra automaticamente.

## Paso 1: diagnostico e Hyper-V

Desde la raiz del repositorio, sin necesitar permisos de administrador:

```powershell
& ./db/Christian/always-on/Diagnosticar-Equipo.ps1 -Equipo Personal
```

En el servidor de casa ejecutar el mismo script con -Equipo Servidor. Solo lee
requisitos y genera un informe; no cambia Windows ni SQL. Si el servidor usa
Windows Home, detener esa instalacion y elegir un virtualizador compatible.

Para Windows Pro/Enterprise/Education compatible, abrir Windows PowerShell
como administrador y ejecutar:

```powershell
& 'C:\Users\Personal\Desktop\DB_Avanzadas\db\Christian\always-on\Habilitar-HyperV.ps1'
```

El instalador habilita Microsoft-Hyper-V-All con -NoRestart. Guarda el resultado
en .qa/hyperv/Resultado_Instalacion.json. No crea VMs, no configura switches y no
reinicia Windows. Guardar el trabajo y reiniciar manualmente cuando indique
ReinicioPendiente=true. Ejecutar de nuevo el diagnostico despues del reinicio.

[Instalacion oficial de Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-hyper-v).

## Paso 2: medios de instalacion

Obtener la ISO del sistema operativo desde
[Windows Server 2022 Evaluation](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022).
Elegir la ISO completa del sistema, no la ISO auxiliar Languages/Features on Demand.
Para este laboratorio se propone Standard Evaluation con Desktop Experience.
La pagina puede requerir registro; el usuario debe completar sus propios datos.

Obtener SQL Server 2025 Standard Developer desde
[la pagina oficial de SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads).
Instalar la misma version principal en SQL1 y SQL2. No usar Express para los nodos.

## Pasos siguientes

Hyper-V activo en el equipo personal tras el reinicio. El adaptador fisico
identificado es Ethernet (Intel I219-LM), red 192.168.100.0/24, direccion del
anfitrion 192.168.100.7 y gateway 192.168.100.1. No usar Tailscale como adaptador
fisico para el switch externo. La interfaz virtual Tailscale sirve para el acceso remoto.

Revisar el plan sin permisos de administrador ni cambios:

```powershell
& ./db/Christian/always-on/Crear-VMs.ps1 -Equipo Personal -Adaptador Ethernet -SoloPlan
```

Para crear DC1 y SQL2, ejecutar desde Windows PowerShell como administrador:

```powershell
& 'C:\Users\Personal\Desktop\DB_Avanzadas\db\Christian\always-on\Crear-VMs.ps1' -Equipo Personal -Adaptador Ethernet
```

Se crea CasaLAN como switch externo compartido con el anfitrion. La red puede
interrumpirse brevemente. Las VMs quedan apagadas, con la ISO montada, 2 vCPU,
generacion 2, arranque seguro Windows y discos dinamicos de 40 GB (DC1) y
60 GB (SQL2). La capacidad maxima de los discos no esta reservada y supera el
espacio libre actual: mantener al menos 15 GB libres y vigilar el crecimiento.
No se crean checkpoints automaticos para reducir consumo de disco.
No se reemplazan nombres, carpetas ni VMs existentes; una falla conserva los
recursos parciales para inspeccion. Evidencia: docs/evidencias/always-on/Creacion_VMs_Personal.json.

En Hyper-V Manager abrir Conectar para DC1 y luego Iniciar. Presionar una tecla
si el medio pide arrancar desde DVD. Instalar Windows Server 2022 Standard
Evaluation (Desktop Experience) en el disco vacio de esa VM. Crear la clave
administradora dentro de la consola y no enviarla por chat ni guardarla en Git.
Repetir en SQL2; arrancar ambas VMs manualmente cuando sean necesarias.

En el servidor de casa, despues de comprobar su diagnostico y preparar Hyper-V,
usar -Equipo Servidor para crear solo SQL1 con 4 GB RAM y 60 GB de disco dinamico.
El nombre del adaptador debe identificarse alli; no asumir Ethernet ni direcciones
libres de la red. La ISO y los scripts deben estar disponibles en ese equipo.

1. Confirmar que ambos anfitriones tienen virtualizacion activa y Hyper-V funcionando.
2. Crear las tres VMs con Windows Server y nombres SQL1, SQL2 y DC1.
3. Configurar una red externa conectada a la red local de casa; la seleccion del adaptador depende del diagnostico de red.
4. Configurar DC1 como controlador de dominio y DNS; unir SQL1 y SQL2 al dominio.
5. Instalar SQL Server en SQL1 y SQL2 y preparar cuentas de servicio y firewall.
6. Crear/validar WSFC, configurar testigo y habilitar Always On.
7. Restaurar el proyecto, preparar FULL/backups y configurar el Basic Availability Group.
8. Configurar listener, rutas/DNS Tailscale y acceso desde el equipo del companero.
9. Preparar logins y CLR/confianza del verificador en ambas instancias.
10. Probar conmutacion del servicio SQL o de la VM primaria y grabar evidencia.

DC1/testigo comparte equipo fisico con SQL2: no se promete tolerar el apagado
de cualquiera de los anfitriones. El primer fallo demostrado sera SQL1 o su VM.
La conmutacion se realiza desde SQL/SSMS, no moviendo el AG con Cluster Manager.
La configuracion del switch externo puede interrumpir la red temporalmente;
no crearla sin identificar previamente el adaptador correcto.
