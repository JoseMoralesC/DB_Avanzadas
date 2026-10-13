param([ValidateSet('Personal','Servidor')][string]$Equipo = 'Personal')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$service = Get-Service vmms -ErrorAction SilentlyContinue
$diagnosis = [ordered]@{
    FechaUTC = [DateTime]::UtcNow.ToString('O')
    Equipo = $Equipo
    Windows = $os.Caption
    Edicion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
    RAM_GB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
    Nucleos = $cpu.NumberOfCores
    Hilos = $cpu.NumberOfLogicalProcessors
    VirtualizacionFirmware = $cpu.VirtualizationFirmwareEnabled
    SLAT = $cpu.SecondLevelAddressTranslationExtensions
    VMMonitor = $cpu.VMMonitorModeExtensions
    HypervisorDetectado = $computer.HypervisorPresent
    NotaCPU = if ($computer.HypervisorPresent) { 'El hipervisor esta activo; Windows puede ocultar los indicadores VT/SLAT del procesador.' } else { 'Verificar firmware, SLAT y VMMonitor antes de habilitar Hyper-V.' }
    ServicioHyperV = if ($service) { $service.Status.ToString() } else { 'No encontrado' }
    Discos = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,
        @{Name='Libre_GB';Expression={[math]::Round($_.FreeSpace / 1GB, 1)}})
}
$evidence = Join-Path $root 'docs\evidencias\always-on'
[IO.Directory]::CreateDirectory($evidence) | Out-Null
$path = Join-Path $evidence "Diagnostico_$Equipo.json"
$diagnosis | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $path -Encoding UTF8
$diagnosis | ConvertTo-Json -Depth 4
Write-Output "Diagnostico guardado: $path"
