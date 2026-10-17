# Stops Claude Usage Tray and removes it from %LOCALAPPDATA% and the Startup folder.
#   irm https://raw.githubusercontent.com/invertedburger/claude-usage-tray/main/uninstall.ps1 | iex

Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
    Where-Object { $_.CommandLine -like '*ClaudeUsageTray.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Start-Sleep -Milliseconds 500
Remove-Item (Join-Path ([Environment]::GetFolderPath('Startup')) 'Claude Usage Tray.lnk') -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:LOCALAPPDATA 'ClaudeUsageTray') -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Claude Usage Tray uninstalled.' -ForegroundColor Green
