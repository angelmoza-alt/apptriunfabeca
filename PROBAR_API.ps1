# Prueba la API de Triunfa Beca y guarda el resultado en resultado_pruebas.txt
$ErrorActionPreference = 'Continue'
$base = 'http://localhost:3000/api/v1'
$log = Join-Path $PSScriptRoot 'resultado_pruebas.txt'
"Pruebas API Triunfa Beca - $(Get-Date)" | Out-File $log -Encoding utf8
function Anotar($t) { Write-Host $t; $t | Out-File $log -Append -Encoding utf8 }
function Probar($nombre, [scriptblock]$accion) {
  try { $r = & $accion; Anotar "[OK]    $nombre $r" }
  catch {
    $msg = $_.Exception.Message
    if ($_.ErrorDetails.Message) { $msg = "$msg | $($_.ErrorDetails.Message)" }
    Anotar "[FALLO] $nombre -> $msg"
  }
}

# Espera a que la API responda (hasta 40 s)
for ($i = 0; $i -lt 20; $i++) {
  try { Invoke-RestMethod "$base/public/navegacion" -TimeoutSec 3 | Out-Null; break } catch { Start-Sleep 2 }
}

Probar 'API en linea (public/navegacion)' { Invoke-RestMethod "$base/public/navegacion" | Out-Null; '' }

$script:tok = $null
Probar 'Login admin2@triunfabeca.com' {
  $r = Invoke-RestMethod "$base/admin/auth/login" -Method Post -ContentType 'application/json' -Body (@{correo='admin2@triunfabeca.com'; password='triunfa2026'} | ConvertTo-Json)
  $script:tok = $r.data.token; "-> rol $($r.data.usuario.role)"
}
$h = @{ Authorization = "Bearer $script:tok" }

Probar 'GET /auth/me' { $r = Invoke-RestMethod "$base/admin/auth/me" -Headers $h; "-> $($r.data.correo)" }
Probar 'GET /usuarios (app Flutter)' { $r = Invoke-RestMethod "$base/admin/usuarios" -Headers $h; "-> $(@($r.data).Count) usuarios" }
Probar 'GET /usuarios/resumen (reportes)' { $r = Invoke-RestMethod "$base/admin/usuarios/resumen" -Headers $h; "-> total $($r.data.total)" }

# IA nueva (rama feature/solicitudes-ia)
$script:sol = $null
Probar 'GET /solicitudes' {
  $r = Invoke-RestMethod "$base/admin/solicitudes" -Headers $h
  $lista = @($r.data)
  $script:sol = @($lista)[0].id; "-> $(@($lista).Count) solicitudes (primera: $($script:sol))"
}
if ($script:sol) {
  Probar 'IA: POST /solicitudes/:id/sugerir-respuesta' {
    $r = Invoke-RestMethod "$base/admin/solicitudes/$script:sol/sugerir-respuesta" -Method Post -Headers $h -TimeoutSec 90
    $t = "$($r.data.mensaje)"; "-> " + $t.Substring(0, [Math]::Min(160, $t.Length)).Replace("`n", ' ')
  }
} else { Anotar '[AVISO] No hay solicitudes para probar la IA (crea una desde la pagina web)' }

Anotar ''
Anotar "Resultado guardado en $log"
