@echo off
chcp 65001 >nul
title Triunfa Beca - apagar todo
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"

echo Apagando la API (puerto 3000)...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do taskkill /F /T /PID %%p >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq API Triunfa Beca*" >nul 2>&1

echo Apagando el emulador...
"%ADB%" emu kill >nul 2>&1
taskkill /F /IM qemu-system-x86_64.exe >nul 2>&1

echo Apagando la base de datos...
docker stop triunfa_beca_db >nul 2>&1

echo.
echo Listo: API, emulador y base de datos apagados.
echo (Docker Desktop sigue abierto; INICIAR_TODO lo usa.)
pause
