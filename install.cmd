@echo off
rem Double-click to install Claude Usage Tray (downloads the latest version from GitHub).
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/invertedburger/claude-usage-tray/main/install.ps1 | iex"
echo.
pause
