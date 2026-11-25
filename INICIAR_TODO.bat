@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Triunfa Beca - iniciar todo
set "API=C:\Users\Victus\Proyectos\triunfa-beca-api"
set "APP=%~dp0app_flutter"
set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "ADB=%SDK%\platform-tools\adb.exe"
set "EMU=%SDK%\emulator\emulator.exe"
set "AVD=Pixel_9a"

echo ==================================================
echo   TRIUNFA BECA - Iniciando todo
echo ==================================================

echo.
echo [1/5] Docker...
docker info >nul 2>&1
if not errorlevel 1 goto docker_ok
echo    Abriendo Docker Desktop (puede tardar 1 minuto)...
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
set /a intentos=0
:esperar_docker
timeout /t 5 /nobreak >nul
docker info >nul 2>&1
if not errorlevel 1 goto docker_ok
set /a intentos+=1
if %intentos% lss 36 goto esperar_docker
echo    Docker no arranco. Abrelo a mano y vuelve a ejecutar este archivo.
pause
exit /b
:docker_ok
echo    Docker listo.
docker start triunfa_beca_db >nul && echo    Base de datos encendida.

echo.
echo [2/5] API...
netstat -ano | findstr ":3000" | findstr "LISTENING" >nul
if errorlevel 1 (
  start "API Triunfa Beca (NO CERRAR)" cmd /k "cd /d %API% && npm run dev"
  echo    API abierta en otra ventana. No la cierres.
) else (
  echo    La API ya estaba encendida.
)

echo.
echo [3/5] Buscando celular o emulador...
"%ADB%" start-server >nul 2>&1
set "DEV="
for /f "skip=1 tokens=1,2" %%a in ('"%ADB%" devices') do call :revisar %%a %%b
if defined DEV (
  echo    Celular conectado: %DEV%
  goto dispositivo_listo
)

rem Sin celular: usar el emulador (si ya esta prendido, se usa ese)
for /f "skip=1 tokens=1,2" %%a in ('"%ADB%" devices') do call :revisar_emu %%a %%b
if defined DEV goto esperar_boot_ini
echo    No hay celular. Abriendo el emulador %AVD%...
start "" "%EMU%" -avd %AVD% -no-boot-anim -gpu host
:buscar_emu
timeout /t 3 /nobreak >nul
for /f "skip=1 tokens=1,2" %%a in ('"%ADB%" devices') do call :revisar_emu %%a %%b
if not defined DEV goto buscar_emu
:esperar_boot_ini
echo    Esperando a que el emulador termine de prender...
:esperar_boot
set "BOOT="
for /f %%b in ('"%ADB%" -s %DEV% shell getprop sys.boot_completed 2^>nul') do set "BOOT=%%b"
if not "%BOOT%"=="1" (
  timeout /t 3 /nobreak >nul
  goto esperar_boot
)
echo    Emulador listo: %DEV%

:dispositivo_listo
"%ADB%" -s %DEV% reverse tcp:3000 tcp:3000 >nul && echo    Conectado a la API (puerto 3000).

echo.
echo [4/5] Probando la API...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PROBAR_API.ps1" >nul 2>&1
findstr /c:"[FALLO]" "%~dp0resultado_pruebas.txt" >nul && (echo    Hay fallos, revisa resultado_pruebas.txt) || echo    API OK.

echo.
echo [5/5] Abriendo la app en %DEV%...
cd /d "%APP%"
call flutter run -d %DEV%
pause
exit /b

:revisar
if not "%~2"=="device" exit /b
echo %~1 | findstr /b "emulator-" >nul
if errorlevel 1 set "DEV=%~1"
exit /b

:revisar_emu
if not "%~2"=="device" exit /b
echo %~1 | findstr /b "emulator-" >nul
if not errorlevel 1 set "DEV=%~1"
exit /b
