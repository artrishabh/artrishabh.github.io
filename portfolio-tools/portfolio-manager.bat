@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0portfolio-manager.ps1"
if errorlevel 1 (
  echo.
  echo Portfolio Manager exited with an error.
  pause
)
