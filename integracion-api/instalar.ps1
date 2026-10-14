# Copia el modulo "usuarios" dentro de la API triunfa-beca-api y lo registra en src/app.js
# Uso:  .\instalar.ps1 -Api "D:\Proyectos\triunfa-beca-api"
param([Parameter(Mandatory = $true)][string]$Api)
$ErrorActionPreference = 'Stop'

$appJs = Join-Path $Api 'src\app.js'
if (-not (Test-Path -LiteralPath $appJs)) { throw "No encontre $appJs. Revisa la ruta de triunfa-beca-api." }

$destino = Join-Path $Api 'src\modules\admin\usuarios'
New-Item -ItemType Directory -Force -Path $destino | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'src\modules\admin\usuarios\*.js') -Destination $destino -Force
Write-Host "Modulo copiado en $destino" -ForegroundColor Green

$c = [IO.File]::ReadAllText($appJs)
if ($c -notmatch 'usuariosRoutes') {
    $c = $c.Replace("import auditoriaRoutes from './modules/admin/auditoria/auditoria.routes.js';",
        "import auditoriaRoutes from './modules/admin/auditoria/auditoria.routes.js';`r`nimport usuariosRoutes from './modules/admin/usuarios/usuarios.routes.js';")
    $c = $c.Replace("app.use('/api/v1/admin/auditoria', auditoriaRoutes);",
        "app.use('/api/v1/admin/auditoria', auditoriaRoutes);`r`napp.use('/api/v1/admin/usuarios', usuariosRoutes);")
    if ($c -notmatch 'usuariosRoutes') { throw "No pude registrar la ruta en app.js; agregala a mano (ver README)." }
    [IO.File]::WriteAllText($appJs, $c)
    Write-Host "Ruta /api/v1/admin/usuarios registrada en src/app.js" -ForegroundColor Green
} else {
    Write-Host "app.js ya tenia la ruta de usuarios" -ForegroundColor Yellow
}
