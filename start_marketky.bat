@echo off
setlocal
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\scripts\serve_all.ps1"
if errorlevel 1 (
  echo.
  echo MarketKy failed to start. Please check MySQL and the error message above.
  pause
)
