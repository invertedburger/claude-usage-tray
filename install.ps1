# Installs (or updates) Claude Usage Tray: copies the app to %LOCALAPPDATA%\ClaudeUsageTray,
# adds it to the Startup folder (autostart on login) and starts it.
# Works when run from a clone or straight from GitHub:
#   irm https://raw.githubusercontent.com/invertedburger/claude-usage-tray/main/install.ps1 | iex
# Keep this file ASCII-only (it is piped into Windows PowerShell 5.1).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$RawBase = 'https://raw.githubusercontent.com/invertedburger/claude-usage-tray/main'
$dir     = Join-Path $env:LOCALAPPDATA 'ClaudeUsageTray'
$target  = Join-Path $dir 'ClaudeUsageTray.ps1'
$ps      = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$argLine = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$target`""

# stop a running instance
Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
    Where-Object { $_.CommandLine -like '*ClaudeUsageTray.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

New-Item -ItemType Directory -Force $dir | Out-Null
$local = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'ClaudeUsageTray.ps1' }
if ($local -and (Test-Path $local)) {
    Copy-Item $local $target -Force
} else {
    Invoke-WebRequest "$RawBase/ClaudeUsageTray.ps1" -OutFile $target -UseBasicParsing
}

# autostart
$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Claude Usage Tray.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = $ps; $s.Arguments = $argLine; $s.WorkingDirectory = $dir; $s.WindowStyle = 7
$s.Description = 'Claude Usage Tray'
$s.Save()

Start-Process $ps -ArgumentList $argLine -WindowStyle Hidden

Write-Host ''
Write-Host 'Claude Usage Tray installed and running.' -ForegroundColor Green
Write-Host '  clock = 5-hour limit, calendar = weekly limit (% left)'
Write-Host '  Starts automatically when you log in.'
Write-Host '  Windows hides new tray icons under the ^ arrow - drag them onto the taskbar.'
if (-not (Test-Path (Join-Path $env:USERPROFILE '.claude\.credentials.json'))) {
    Write-Host ''
    Write-Host 'Warning: no Claude Code login found (~\.claude\.credentials.json).' -ForegroundColor Yellow
    Write-Host 'Sign in to Claude Code (CLI or desktop app) - until then the icons show "?".' -ForegroundColor Yellow
}
