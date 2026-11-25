@echo off
chcp 65001 >nul
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
(
  echo @echo off
  echo start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
  echo start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd Pixel_9a -no-boot-anim -gpu host
) > "%STARTUP%\TriunfaBeca_Docker_y_Emulador.bat"
echo Listo: al prender la laptop se abriran Docker y el emulador.
echo Para quitarlo, ejecuta DESACTIVAR_ARRANQUE_AUTOMATICO.bat
pause
