# Detener todos los procesos relacionados
Get-WmiObject Win32_Process | Where-Object { 
    $_.CommandLine -like "*WindowsUpdate.ps1*" -or 
    $_.CommandLine -like "*$env:APPDATA\WindowsUpdate.ps1*"
} | ForEach-Object { 
    Stop-Process -Id $_.ProcessId -Force 
}

# Eliminar múltiples posibles entradas de persistencia
$registryPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

$registryNames = @("WinUpdateService", "WindowsUpdate", "WinUpdate")

foreach ($path in $registryPaths) {
    foreach ($name in $registryNames) {
        if (Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $path -Name $name -Force
            Write-Host "Eliminada entrada $name de $path"
        }
    }
}

# Eliminar el archivo del script en %APPDATA%
$scriptPath = "$env:APPDATA\WindowsUpdate.ps1"
if (Test-Path $scriptPath) {
    Remove-Item $scriptPath -Force
    Write-Host "Archivo $scriptPath eliminado"
}

# Eliminar el archivo del script en C:\Users\Usuario\AppData\Roaming
$altScriptPath = "$env:USERPROFILE\AppData\Roaming\WindowsUpdate.ps1"
if (Test-Path $altScriptPath) {
    Remove-Item $altScriptPath -Force
    Write-Host "Archivo $altScriptPath eliminado"
}

# Eliminar posible tarea programada
Get-ScheduledTask | Where-Object { 
    $_.TaskName -like "*WinUpdate*" -or 
    $_.Actions.Execute -like "*WindowsUpdate.ps1*"
} | Unregister-ScheduledTask -Confirm:$false

Write-Host "Limpieza completa realizada. Verifica con:"
Write-Host "1. Get-Process powershell"
Write-Host "2. Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Write-Host "3. Get-ScheduledTask | Where-Object { `$_.TaskName -like '*WinUpdate*' }"
