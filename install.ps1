#Requires -Version 7
# Nainstaluje (nebo aktualizuje) Claude Usage Tray: zkopiruje skript do %LOCALAPPDATA%,
# prida zastupce do Po spusteni a spusti ho.

$dir    = Join-Path $env:LOCALAPPDATA 'ClaudeUsageTray'
$target = Join-Path $dir 'ClaudeUsageTray.ps1'
$pwsh   = (Get-Command pwsh).Source
$argsLine = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$target`""

Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
    Where-Object CommandLine -like '*ClaudeUsageTray.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'ClaudeUsageTray.ps1') $target -Force

$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Claude Usage Tray.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = $pwsh; $s.Arguments = $argsLine; $s.WorkingDirectory = $dir; $s.WindowStyle = 7
$s.Save()

Start-Process $pwsh -ArgumentList $argsLine -WindowStyle Hidden
Write-Host "Nainstalovano do $dir, spusteno a pridano do Po spusteni."
