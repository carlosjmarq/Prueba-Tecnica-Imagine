# apps.ps1 - Lanza las apps Flutter (Customer y/o Driver) en ventanas separadas.
# Requiere el backend levantado (scripts/dev.ps1) o una URL de API accesible.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File scripts/apps.ps1                     # ambas apps
#   powershell -ExecutionPolicy Bypass -File scripts/apps.ps1 -App customer       # solo customer
#   powershell -ExecutionPolicy Bypass -File scripts/apps.ps1 -App driver         # solo driver
#   powershell -ExecutionPolicy Bypass -File scripts/apps.ps1 -ApiUrl http://10.0.2.2:8000
#
# Notas:
#   - Emulador Android: el host es 10.0.2.2 (no 127.0.0.1). Usar -ApiUrl.
#   - Cada app corre en su propia ventana de PowerShell (Ctrl+C la detiene).

param(
    [ValidateSet("both", "customer", "driver")]
    [string]$App = "both",
    [string]$ApiUrl = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter no esta en el PATH. Ejecuta antes scripts/setup.ps1."
    exit 1
}

$apps = @()
if ($App -in @("both", "customer")) { $apps += @{ Name = "customer_app"; Dir = "mobile\customer_app" } }
if ($App -in @("both", "driver"))   { $apps += @{ Name = "driver_app";   Dir = "mobile\driver_app" } }

$dartDefines = @()
if ($ApiUrl) {
    $wsUrl = $ApiUrl -replace "^http", "ws"
    $dartDefines += "--dart-define=API_BASE_URL=$ApiUrl"
    $dartDefines += "--dart-define=WS_URL=$wsUrl"
    Write-Host "  API: $ApiUrl  |  WS: $wsUrl" -ForegroundColor DarkGray
}

foreach ($app in $apps) {
    $appDir = Join-Path $root $app.Dir
    $args = @("-NoExit", "-Command", "cd '$appDir'; flutter pub get; flutter run $($dartDefines -join ' ')")
    Write-Host "Lanzando $($app.Name)..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList $args
}

Write-Host ""
Write-Host "Ventanas abiertas. Recuerda tener la API corriendo (scripts/dev.ps1)." -ForegroundColor Green