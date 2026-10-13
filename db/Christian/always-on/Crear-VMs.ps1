[CmdletBinding()]
param(
    [ValidateSet('Personal','Servidor')][string]$Equipo = 'Personal',
    [string]$Adaptador = 'Ethernet',
    [string]$Iso = '',
    [switch]$SoloPlan
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $Iso) { $Iso = Join-Path $root '.qa\instaladores\WindowsServer2022_Evaluation_es-es.iso' }
$isoPath = (Resolve-Path -LiteralPath $Iso).Path
if ([IO.Path]::GetExtension($isoPath) -ne '.iso') { throw 'El medio debe ser un archivo .iso.' }
$computer = Get-CimInstance Win32_ComputerSystem
if (-not $computer.HypervisorPresent) { throw 'Hyper-V no esta activo. Completar la habilitacion y reiniciar antes de crear VMs.' }
$adapter = Get-NetAdapter -Name $Adaptador
if ($adapter.Status -ne 'Up') { throw 'El adaptador seleccionado no esta conectado.' }
if ($adapter.InterfaceDescription -match 'Tailscale|Hyper-V|Bluetooth') { throw 'Seleccione un adaptador fisico de la red de casa.' }
$definitions = if ($Equipo -eq 'Personal') {
    @(@{Nombre='DC1'; RAM=2GB; Disco=40GB}, @{Nombre='SQL2'; RAM=6GB; Disco=60GB})
} else {
    @(@{Nombre='SQL1'; RAM=4GB; Disco=60GB})
}
$ramTotal = ($definitions | ForEach-Object { $_.RAM } | Measure-Object -Sum).Sum
if (($computer.TotalPhysicalMemory - $ramTotal) -lt 3GB) { throw 'La asignacion no deja al menos 3 GB para el anfitrion.' }
$storage = Join-Path $root '.qa\virtuales'
$volume = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + [IO.Path]::GetPathRoot($storage).TrimEnd('\') + "'")
$minimumFree = if ($Equipo -eq 'Personal') { 65GB } else { 45GB }
if ($volume.FreeSpace -lt $minimumFree) { throw 'Falta espacio libre para las instalaciones del sistema y SQL, mas margen del anfitrion.' }
$plan = [ordered]@{
    Equipo = $Equipo
    Switch = 'CasaLAN'
    Adaptador = $adapter.Name
    Iso = $isoPath
    Almacenamiento = $storage
    Libre_GB = [math]::Round($volume.FreeSpace/1GB,1)
    DiscoMaximo_GB = ($definitions | ForEach-Object { $_.Disco/1GB } | Measure-Object -Sum).Sum
    DiscosDinamicos = $true
    VMs = @($definitions | ForEach-Object { [PSCustomObject]@{Nombre=$_.Nombre; RAM_GB=$_.RAM/1GB; DiscoMaximo_GB=$_.Disco/1GB; CPU=2; Generacion=2} })
}
$plan | ConvertTo-Json -Depth 4
Write-Output 'Los discos son dinamicos. Su capacidad maxima no queda reservada: vigilar el espacio real y mantener al menos 15 GB libres.'
if ($SoloPlan) { Write-Output 'SoloPlan: no se crearon switches, discos ni maquinas virtuales.'; return }

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Ejecutar este script desde Windows PowerShell como administrador.' }
Import-Module Hyper-V

# Reject name and disk collisions before creating any network resources.
foreach ($definition in $definitions) {
    if (Get-VM -Name $definition.Nombre -ErrorAction SilentlyContinue) { throw "La VM $($definition.Nombre) ya existe. Se conserva y no se reemplaza." }
    if (Test-Path -LiteralPath (Join-Path $storage $definition.Nombre)) { throw "Ya existe una carpeta para $($definition.Nombre). No se reemplazara." }
}
$switch = Get-VMSwitch -Name 'CasaLAN' -ErrorAction SilentlyContinue
if ($switch -and ($switch.SwitchType -ne 'External' -or $switch.NetAdapterInterfaceDescription -ne $adapter.InterfaceDescription -or -not $switch.AllowManagementOS)) {
    throw 'CasaLAN existe pero no coincide con la red prevista. No se modificara.'
}
$evidence = Join-Path $root 'docs\evidencias\always-on'
[IO.Directory]::CreateDirectory($evidence) | Out-Null
$result = [ordered]@{FechaUTC=[DateTime]::UtcNow.ToString('O'); Equipo=$Equipo; Estado='Iniciando'; Switch='CasaLAN'; VMs=@(); Mensaje=''}
try {
    if (-not $switch) {
        Write-Output 'Creando CasaLAN sobre el adaptador fisico. Puede interrumpir la red brevemente.'
        $switch = New-VMSwitch -Name 'CasaLAN' -NetAdapterName $adapter.Name -AllowManagementOS $true
    }
    foreach ($definition in $definitions) {
        $vmFolder = Join-Path $storage $definition.Nombre
        [IO.Directory]::CreateDirectory($vmFolder) | Out-Null
        $disk = New-VHD -Path (Join-Path $vmFolder "$($definition.Nombre).vhdx") -SizeBytes $definition.Disco -Dynamic
        $vm = New-VM -Name $definition.Nombre -Generation 2 -MemoryStartupBytes $definition.RAM -VHDPath $disk.Path -Path $vmFolder -SwitchName $switch.Name
        Set-VMProcessor -VM $vm -Count 2
        Set-VMMemory -VM $vm -DynamicMemoryEnabled $false -StartupBytes $definition.RAM
        Set-VM -VM $vm -AutomaticCheckpointsEnabled $false -AutomaticStartAction Nothing -AutomaticStopAction ShutDown -Notes "DB_Avanzadas: laboratorio Always On; anfitrion $Equipo."
        $dvd = Add-VMDvdDrive -VM $vm -Path $isoPath -Passthru
        Set-VMFirmware -VM $vm -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows -FirstBootDevice $dvd
        $result.VMs += [PSCustomObject]@{Nombre=$vm.Name; Id=$vm.Id.ToString(); Estado='Off'; Disco=$disk.Path; ISO=$isoPath}
        Write-Output "VM creada y apagada: $($vm.Name)."
    }
    $result.Estado = 'Creado'
    $result.Mensaje = 'VMs preparadas con la ISO. Falta instalar Windows Server dentro de ellas.'
}
catch {
    $result.Estado = 'Error'
    $result.Mensaje = $_.Exception.Message
    Write-Warning 'Los recursos creados se conservaron para inspeccion. No se eliminaron VMs ni discos.'
}
finally {
    $result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidence "Creacion_VMs_$Equipo.json") -Encoding UTF8
    Write-Output $result.Mensaje
}
if ($result.Estado -eq 'Error') { exit 1 }
