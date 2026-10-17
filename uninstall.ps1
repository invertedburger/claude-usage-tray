#Requires -Version 7
# Ukonci Claude Usage Tray a odstrani ho z %LOCALAPPDATA% i z Po spusteni.

Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
    Where-Object CommandLine -like '*ClaudeUsageTray.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Remove-Item (Join-Path ([Environment]::GetFolderPath('Startup')) 'Claude Usage Tray.lnk') -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:LOCALAPPDATA 'ClaudeUsageTray') -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Claude Usage Tray odinstalovan.'
