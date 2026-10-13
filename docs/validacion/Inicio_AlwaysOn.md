# Inicio del laboratorio Always On

## Comprobacion de red estatica de DC1

El usuario confirmo mediante `ipconfig /all` que DC1 tiene DHCP deshabilitado,
IP 192.168.100.10/24, puerta de enlace y DNS temporal 192.168.100.1.
`Test-NetConnection 192.168.100.1 -InformationLevel Detailed` confirma
`PingSucceeded = True`, origen 192.168.100.10 y RTT 0 ms. Esto comprueba acceso
al router, no conectividad entre replicas ni resolucion DNS del futuro dominio.
Permanece pendiente la reserva/exclusion DHCP y la instalacion de AD DS/DNS.

Actualizacion: la captura posterior del usuario confirma que la instalacion de
roles AD DS/DNS termino con Success=True, Restart Needed=No y Exit Code=Success.
La promocion a controlador de dominio sigue pendiente. Para el bosque aislado
del laboratorio se propone repuestos.test, con nombre NetBIOS REPUESTOS.

Actualizacion posterior: el usuario ejecuto Install-ADDSForest para repuestos.test
(NetBIOS REPUESTOS, InstallDns, NoRebootOnCompletion). La captura confirma
Status=Success y RebootRequired=True. Pendientes reinicio manual de DC1 y
validacion de dominio, servicios y registros DNS. Las advertencias de delegacion
DNS y compatibilidad criptografica no bloquearon la promocion.

Tras el reinicio, la captura del usuario confirma DNSRoot=repuestos.test,
NetBIOSName=REPUESTOS y NTDS, DNS y Netlogon en estado Running. El DNS IPv4
de Ethernet es ahora 127.0.0.1 (servidor local). Pendiente comprobar registros
A/SRV consultando explicitamente 192.168.100.10 y conectividad desde SQL1/SQL2.

La captura posterior confirma ejecucion de Set-DnsClientServerAddress para
usar 192.168.100.10 en Ethernet sin error mostrado. Las consultas a ese servidor
DNS devuelven dc1.repuestos.test -> 192.168.100.10 y el SRV
_ldap._tcp.dc._msdcs.repuestos.test -> dc1.repuestos.test:389 (prioridad 0,
peso 100). Validacion local de dominio/servicios/A/SRV completada; no implica
validacion de conectividad desde SQL1, SQL2 o Tailscale.

Preparacion iniciada el 13 de octubre de 2026.

## Arquitectura propuesta

- Servidor fisico en casa, 8 GB RAM: VM SQL1 con Windows Server.
- Equipo personal en casa, 16 GB RAM: VM SQL2 y VM DC1 para dominio, DNS y testigo.
- Equipo del companero en la universidad: aplicativo y SSMS, acceso por Tailscale.

Los nodos SQL virtuales usaran Windows Server. La base original instalada en
Windows 10 queda separada del laboratorio. El primer fallo demostrado sera
el servicio SQL o la VM SQL1. La ubicacion compartida de DC1/testigo y SQL2 no
garantiza tolerancia al apagado de cualquiera de los dos anfitriones fisicos.

## Diagnostico local

El equipo personal tiene Windows 10 Pro, 15.6 GB RAM, 4 nucleos/8 hilos y
virtualizacion de firmware, VM Monitor y SLAT habilitados. El diagnostico
inicial detecto 88.2 GB libres en C: y ningun hipervisor ejecutandose.
Evidencia: docs/evidencias/always-on/Diagnostico_Personal.json.

## Instalacion de Hyper-V

Se preparo db/Christian/always-on/Habilitar-HyperV.ps1 y se comprobo su sintaxis.
La sesion de herramientas no tiene permisos de administrador. Se intento
iniciar el instalador elevado mediante UAC, pero Windows devolvio que el usuario
habia cancelado la operacion. Ese intento no habilito Hyper-V ni reinicio Windows.

Continuar desde Windows PowerShell abierto como administrador:

```powershell
& 'C:\Users\Personal\Desktop\DB_Avanzadas\db\Christian\always-on\Habilitar-HyperV.ps1'
```

El resultado queda en .qa/hyperv/Resultado_Instalacion.json. El script usa
-NoRestart: si el resultado indica ReinicioPendiente=true, guardar el trabajo
y reiniciar manualmente antes de crear las maquinas virtuales.

El usuario ejecuto el instalador en una consola administradora y reinicio.
La comprobacion posterior detecta HypervisorPresent=true y servicio vmms Running.
Hyper-V esta activo. Los indicadores VT/SLAT que ahora aparecen false pueden
estar ocultos por el hipervisor; antes de habilitarlo se comprobaron en true.
La sesion de herramientas sigue sin privilegios para administrar las VMs.

## Medios

Los instaladores se guardan en .qa/instaladores, fuera de Git.
La ISO completa de Windows Server 2022 Evaluation en espanol ya esta descargada:
5055336448 bytes, transferencia BITS completada desde Microsoft Evaluation Center.
El instalador inicial de SQL Server
2025 Standard Developer tiene firma Authenticode valida de Microsoft Corporation.
Este ultimo aun necesita descargar los archivos de instalacion del motor.
Huellas y origen: docs/evidencias/always-on/Medios_Instalacion.json.
Despues de descargar los medios, el espacio libre de C: es aproximadamente 83.5 GB.

El usuario ejecuto Crear-VMs.ps1 como administrador. El resultado guardado
confirma CasaLAN y las VMs DC1 y SQL2 creadas y apagadas, con la ISO montada.
Evidencia: docs/evidencias/always-on/Creacion_VMs_Personal.json.
Falta instalar los sistemas invitados y configurar el dominio y el cluster.
Se preparo Crear-VMs.ps1 y se ejecuto -SoloPlan: DC1 (2 GB RAM, disco dinamico
40 GB) y SQL2 (6 GB RAM, disco dinamico 60 GB), ambas generacion 2 y 2 vCPU.
Los parametros de los cmdlets se contrastaron con el modulo Hyper-V instalado.
El adaptador identificado es Ethernet, direccion 192.168.100.7/24 y gateway
192.168.100.1. El switch previsto es CasaLAN, externo y compartido con el anfitrion.
No se utiliza el adaptador virtual Tailscale para ese switch.

Para crear las VMs desde Windows PowerShell como administrador:

```powershell
& 'C:\Users\Personal\Desktop\DB_Avanzadas\db\Christian\always-on\Crear-VMs.ps1' -Equipo Personal -Adaptador Ethernet
```

El switch puede interrumpir temporalmente la red. Las VMs se crean apagadas;
el sistema operativo se instala despues desde la consola de cada VM.
Los discos pueden crecer hasta 100 GB en total y ese espacio no esta reservado;
vigilar consumo y conservar al menos 15 GB libres en el anfitrion.

## Pendientes inmediatos

1. Instalar Windows Server 2022 Standard Evaluation (Desktop Experience) dentro de DC1 y SQL2 desde sus consolas Hyper-V.
2. Ejecutar Diagnosticar-Equipo.ps1 -Equipo Servidor en el anfitrion de casa para verificar edicion de Windows y virtualizacion.
3. Habilitar Hyper-V en ese anfitrion si es compatible; Windows Home requiere otra alternativa.
4. Vigilar el espacio libre mientras se instalan los sistemas invitados.
5. Definir las direcciones de los invitados tras verificar el rango DHCP y configurar DC1 como dominio/DNS.

Guia: db/Christian/always-on/README.md.

## Instalacion de DC1 y red

El usuario completo Windows Server 2022 Standard Evaluation con escritorio
dentro de DC1 y cambio el nombre de Windows a DC1. La salida ipconfig confirma
192.168.100.10/24, gateway y DNS 192.168.100.1, MAC 00-15-5D-64-07-00 y DHCP
habilitado. Evidencia: docs/evidencias/always-on/Red_DC1.json.

El usuario no tiene acceso administrativo al router. No se conoce el rango DHCP
ni se puede garantizar una exclusion/reserva. Conservar la direccion ya asignada
como configuracion temporal del laboratorio requiere documentar esa limitacion;
no constituye una configuracion permanente protegida contra conflictos DHCP.
El DNS del router se mantiene durante la preparacion; despues de instalar DNS
y promover el primer controlador se configura su propia IP como DNS preferido.
