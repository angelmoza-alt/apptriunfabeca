# Prepara el proyecto Flutter la primera vez:
# genera las carpetas de plataforma (android, ios, web, windows),
# permite HTTP local en Android, pone el nombre "Triunfa Beca" y genera el icono.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "1/4 Generando carpetas de plataforma..." -ForegroundColor Cyan
flutter create . --project-name triunfa_beca --org com.triunfabeca --platforms android,ios,web,windows

Write-Host "2/4 Descargando dependencias..." -ForegroundColor Cyan
flutter pub get

Write-Host "3/4 Configurando Android (HTTP local y nombre)..." -ForegroundColor Cyan
$manifest = Join-Path $PSScriptRoot 'android\app\src\main\AndroidManifest.xml'
$c = [IO.File]::ReadAllText($manifest)
if ($c -notmatch 'usesCleartextTraffic') {
    $c = $c -replace '<application', "<uses-permission android:name=`"android.permission.INTERNET`"/>`r`n    <application android:usesCleartextTraffic=`"true`""
}
$c = $c -replace 'android:label="triunfa_beca"', 'android:label="Triunfa Beca"'
[IO.File]::WriteAllText($manifest, $c)

Write-Host "4/4 Generando icono de la app..." -ForegroundColor Cyan
dart run flutter_launcher_icons

Write-Host "Listo. Ahora levanta el backend (docker compose up -d) y ejecuta: flutter run" -ForegroundColor Green
