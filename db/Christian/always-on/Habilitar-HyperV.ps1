#Requires -RunAsAdministrator
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$resultDirectory = Join-Path $root '.qa\hyperv'
[IO.Directory]::CreateDirectory($resultDirectory) | Out-Null
$resultPath = Join-Path $resultDirectory 'Resultado_Instalacion.json'
$result = [ordered]@{ FechaUTC = [DateTime]::UtcNow.ToString('O'); Estado = 'Iniciando'; ReinicioPendiente = $false; Mensaje = '' }
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
    $computer = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    if ($os.ProductType -ne 1) { throw 'Este instalador es para Windows cliente Pro/Enterprise/Education; Windows Server utiliza Install-WindowsFeature.' }
    if ($edition -notmatch '^(Professional|Enterprise|Education)') { throw 'Esta edicion no admite Hyper-V. No se modificaron las caracteristicas de Windows.' }
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Se requiere Windows de 64 bits.' }
    if (-not $computer.HypervisorPresent -and (-not $cpu.VirtualizationFirmwareEnabled -or -not $cpu.SecondLevelAddressTranslationExtensions -or -not $cpu.VMMonitorModeExtensions)) {
        throw 'Falta habilitar virtualizacion en BIOS/UEFI o el procesador no cumple los requisitos.'
    }
    $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    if ($feature.State -eq 'Enabled') {
        $result.Estado = 'Habilitado'
        $result.ReinicioPendiente = -not $computer.HypervisorPresent
        $result.Mensaje = 'Hyper-V ya estaba habilitado.'
    }
    else {
        $installation = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
        $result.Estado = 'Habilitado'
        $result.ReinicioPendiente = [bool]$installation.RestartNeeded -or -not $computer.HypervisorPresent
        $result.Mensaje = 'Hyper-V habilitado. No se reinicio Windows automaticamente.'
    }
}
catch {
    $result.Estado = 'Error'
    $result.Mensaje = $_.Exception.Message
}
finally {
    $result | ConvertTo-Json | Set-Content -LiteralPath $resultPath -Encoding UTF8
    Write-Output $result.Mensaje
    Write-Output "Resultado: $resultPath"
}
if ($result.Estado -eq 'Error') { exit 1 }
